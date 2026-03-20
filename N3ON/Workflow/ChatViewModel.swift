// ChatViewModel.swift
// N3ON
//

import Foundation
import Amplify
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var participants: [User] = []
    @Published var errorMessage: String?

    let currentUserID: String
    private let chatRoomID: String
    private var currentUser: User?
    private var cancellables = Set<AnyCancellable>()

    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
        Task {
            await loadCurrentUser()
            await loadChatRoom()
            observeNewMessages()
        }
    }

    private func loadCurrentUser() async {
        currentUser = try? await Amplify.DataStore.query(User.self, byId: currentUserID)
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        guard let sender = currentUser else {
            errorMessage = "Could not identify sender. Please try again."
            return
        }

        let text = messageText
        messageText = ""

        Task {
            do {
                let msg = Message(
                    id: UUID().uuidString,
                    sender: sender,
                    chatRoomID: chatRoomID,
                    content: text,
                    timestamp: Temporal.DateTime.now(),
                    isRead: false,
                    readBy: []
                )
                try await Amplify.DataStore.save(msg)
                try await updateChatRoomLastMessage(with: text)
            } catch {
                errorMessage = "Send failed: \(error.localizedDescription)"
                messageText = text
            }
        }
    }

    private func loadChatRoom() async {
        do {
            guard let _ = try await Amplify.DataStore.query(ChatRoom.self, byId: chatRoomID) else { return }

            let messageResults = try await Amplify.DataStore.query(
                Message.self,
                where: Message.keys.chatRoomID == chatRoomID
            )
            let links = try await Amplify.DataStore.query(
                UserChatRooms.self,
                // NOTE: Amplify manyToMany codegen field naming is inconsistent.
                // After running `amplify codegen models`, verify whether the generated
                // field is chatRoomId or chatRoomID — check the generated UserChatRooms.swift file.
                where: UserChatRooms.keys.chatRoom == chatRoomID
            )

            messages = messageResults.sorted {
                ($0.timestamp.foundationDate ?? .distantPast) < ($1.timestamp.foundationDate ?? .distantPast)
            }
            participants = links.compactMap { $0.user }

        } catch {
            errorMessage = "Failed to load chat: \(error.localizedDescription)"
        }
    }

    private func observeNewMessages() {
        Amplify.Hub.publisher(for: .dataStore)
            .sink(receiveCompletion: { _ in }) { [weak self] event in
                guard let self else { return }
                guard
                    event.eventName == HubPayload.EventName.DataStore.syncReceived,
                    let mutationEvent = event.data as? MutationEvent,
                    mutationEvent.modelName == "Message",
                    let newMessage = try? mutationEvent.decodeModel(as: Message.self),
                    newMessage.chatRoomID == self.chatRoomID
                else { return }

                Task { @MainActor [weak self] in
                    self?.messages.append(newMessage)
                }
            }
            .store(in: &cancellables)
    }

    private func updateChatRoomLastMessage(with text: String) async throws {
        guard var chatRoom = try await Amplify.DataStore.query(ChatRoom.self, byId: chatRoomID) else { return }
        chatRoom.lastMessage = text
        chatRoom.lastMessageTimestamp = Temporal.DateTime.now()
        try await Amplify.DataStore.save(chatRoom)
    }

    func markMessageAsRead() async {
        let unread = messages.filter { !$0.isRead && ($0.sender?.id ?? "") != currentUserID }

        for var m in unread {
            m.isRead = true
            try? await Amplify.DataStore.save(m)
            if let i = messages.firstIndex(where: { $0.id == m.id }) {
                messages[i] = m
            }
        }
    }
}
