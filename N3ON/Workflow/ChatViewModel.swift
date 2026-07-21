// ChatViewModel.swift
// N3ON — Workflow layer
//
// 2026 architecture:
//   • Real-time observation via Amplify.DataStore.observe() (AsyncSequence, not Combine Hub)
//   • Optimistic message inserts — message appears at .sending before DataStore confirms
//   • All DataStore calls delegated to ChatRoomService (Task layer)
//   • Observation task cancelled on deinit — no memory leaks

import Foundation
import Amplify

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var participants: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let currentUserID: String
    let chatRoomID: String
    private var currentUser: User?

    // Structured concurrency: one child task owns the observation stream.
    // Cancelled automatically when this VM is deallocated.
    private var observationTask: Task<Void, Never>?

    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        currentUser = try? await UserService.fetch(byId: currentUserID)

        do {
            let raw = try await ChatRoomService.messages(for: chatRoomID)
            messages = raw.map(toChatMessage)
            participants = try await ChatRoomService.participants(for: chatRoomID, excludingID: currentUserID)
        } catch {
            errorMessage = "Could not load messages."
            return
        }

        startObserving()
        await ChatRoomService.markRead(in: chatRoomID, userID: currentUserID)
    }

    // MARK: - Send

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
              let sender = currentUser else { return }

        let text = messageText
        messageText = ""

        // Optimistic insert — visible immediately with .sending state
        let tempID = UUID().uuidString
        messages.append(ChatMessage(
            id: tempID,
            sender: sender.username,
            content: text,
            timestamp: Date(),
            isCurrentUser: true,
            deliveryStatus: .sending
        ))

        Task {
            do {
                let msg = Message(
                    id: tempID,
                    sender: sender,
                    chatRoomID: chatRoomID,
                    content: text,
                    timestamp: Temporal.DateTime(Date(), timeZone: .current),
                    isRead: false,
                    readBy: []
                )
                try await ChatRoomService.send(message: msg)
                updateStatus(id: tempID, to: .sent)
            } catch {
                updateStatus(id: tempID, to: .failed)
                // Restore text so the user can retry
                messageText = text
                errorMessage = "Send failed — tap to retry."
            }
        }
    }

    // MARK: - Mark read

    func markRead() async {
        await ChatRoomService.markRead(in: chatRoomID, userID: currentUserID)
        for i in messages.indices where !messages[i].isCurrentUser {
            messages[i].deliveryStatus = .read
        }
    }

    // MARK: - Lifecycle

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Private

    /// Observes the DataStore mutation stream using AsyncSequence.
    /// Replaces the Combine Hub subscription with structured concurrency.
    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await change in Amplify.DataStore.observe(Message.self) {
                    guard !Task.isCancelled else { return }

                    // Only handle creates for this room from other participants
                    guard change.mutationType == MutationEvent.MutationType.create.rawValue,
                          let incoming = try? change.decodeModel(as: Message.self),
                          incoming.chatRoomID == self.chatRoomID,
                          (incoming.sender?.id ?? "") != self.currentUserID
                    else { continue }

                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        // De-duplicate: optimistic insert may already hold this id
                        guard !self.messages.contains(where: { $0.id == incoming.id }) else { return }
                        self.messages.append(self.toChatMessage(incoming))
                    }
                }
            } catch {
                // Stream ended — DataStore offline or session signed out.
                // ChatView's .task modifier will re-call load() when the view re-appears.
            }
        }
    }

    private func toChatMessage(_ m: Message) -> ChatMessage {
        ChatMessage(
            id: m.id,
            sender: m.sender?.username ?? "Unknown",
            content: m.content,
            timestamp: m.timestamp.foundationDate ?? Date(),
            isCurrentUser: (m.sender?.id ?? "") == currentUserID,
            deliveryStatus: m.isRead ? .read : .delivered
        )
    }

    private func updateStatus(id: String, to status: ChatMessage.DeliveryStatus) {
        guard let i = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[i].deliveryStatus = status
    }
}
