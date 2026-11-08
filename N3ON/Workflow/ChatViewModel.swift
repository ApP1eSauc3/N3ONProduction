// ChatViewModel.swift
// N3ON — Workflow layer
//
// 2026 architecture:
//   • Real-time observation via Backend.dataStore.observe() (AsyncSequence, not Combine Hub)
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

    // Sender resolution. `Message.sender` is a belongsTo that DataStore leaves
    // nil until the sender's User row is in the local store, which showed the
    // other person as "Unknown" and could misplace a message's side. The stored
    // senderID column is always present, so it's resolved from that instead.
    private var memberIDs: [String] = []
    private var senderByMessage: [String: String] = [:]
    private var names: [String: String] = [:]

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
            let room = try? await ChatRoomService.room(byId: chatRoomID)
            let listed = (room?.participantIDs ?? []).compactMap { $0 }
            // A member-scoped room you're not in shows nothing (the server
            // scopes sync too; the client never renders someone else's chat).
            guard listed.isEmpty || listed.contains(currentUserID) else {
                errorMessage = "You're not in this chat."
                return
            }
            let raw = try await ChatRoomService.messages(for: chatRoomID)
            memberIDs = Array(Set(listed + [currentUserID]))
            senderByMessage = await ChatRoomService.senderIDs(in: chatRoomID, candidates: memberIDs)
            await resolveNames(for: memberIDs)
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
        // Refuse before the optimistic insert, so it never shows as "sending".
        guard messageText.count <= ChatRoomService.maxMessageLength else {
            errorMessage = "Messages can be up to \(ChatRoomService.maxMessageLength) characters."
            return
        }

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
    func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await change in Backend.dataStore.observe(Message.self) {
                    guard !Task.isCancelled else { return }

                    // Only handle creates for this room from other participants
                    guard change.mutationType == MutationEvent.MutationType.create.rawValue,
                          let incoming = try? change.decodeModel(as: Message.self),
                          incoming.chatRoomID == self.chatRoomID
                    else { continue }

                    let senderID = await self.resolveSender(of: incoming)
                    guard senderID != self.currentUserID else { continue }
                    await self.resolveNames(for: [senderID])

                    // De-duplicate: optimistic insert may already hold this id
                    guard !self.messages.contains(where: { $0.id == incoming.id }) else { continue }
                    self.messages.append(self.toChatMessage(incoming))
                }
            } catch {
                // Stream ended — DataStore offline or session signed out.
                // ChatView's .task modifier will re-call load() when the view re-appears.
            }
        }
    }

    func toChatMessage(_ m: Message) -> ChatMessage {
        let senderID = m.sender?.id ?? senderByMessage[m.id] ?? ""
        return ChatMessage(
            id: m.id,
            sender: m.sender?.username ?? names[senderID] ?? "DJ",
            content: m.content,
            timestamp: m.timestamp.foundationDate ?? Date(),
            isCurrentUser: senderID == currentUserID,
            deliveryStatus: m.isRead ? .read : .delivered
        )
    }

    /// The sender of a live message — from the association if loaded, else
    /// from the stored senderID column.
    func resolveSender(of m: Message) async -> String {
        if let id = m.sender?.id { return id }
        if let known = senderByMessage[m.id] { return known }
        let fresh = await ChatRoomService.senderIDs(in: chatRoomID, candidates: memberIDs)
        senderByMessage.merge(fresh) { _, new in new }
        return fresh[m.id] ?? ""
    }

    func resolveNames(for ids: [String]) async {
        for id in ids where !id.isEmpty && names[id] == nil {
            if let user = await UserService.fetchAnywhere(byId: id) { names[id] = user.username }
        }
    }

    func updateStatus(id: String, to status: ChatMessage.DeliveryStatus) {
        guard let i = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[i].deliveryStatus = status
    }
}
