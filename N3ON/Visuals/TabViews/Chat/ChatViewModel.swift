//
//  ChatViewModel.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

// ===============================================
// File: Chat/ChatViewModel.swift
// WHY: Use `sender: User` relation, compute unread with relation, update last message.
// ===============================================
import SwiftUI
import Amplify
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var participants: [User] = []

    let currentUserID: String
    private let chatRoomID: String
    private var cancellables = Set<AnyCancellable>()

    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
        Task { await loadChatRoom(); observeNewMessages() }
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messageText = ""
        Task {
            do {
                guard let meUser = try await Amplify.DataStore.query(User.self, byId: currentUserID) else {
                    print("Send failed: current user not found"); return
                }
                let msg = Message(
                    id: UUID().uuidString,
                    sender: meUser,
                    chatRoomID: chatRoomID,
                    content: text,
                    timestamp: Temporal.DateTime.now(),
                    isRead: false,
                    readBy: []
                )
                try await Amplify.DataStore.save(msg)
                try await updateChatRoomLastMessage(with: text)
            } catch {
                print("Send failed:", error.localizedDescription)
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
                where: UserChatRooms.keys.chatRoomId == chatRoomID
            )
            let users = links.compactMap { $0.user }

            await MainActor.run {
                self.messages = messageResults.sorted {
                    ($0.timestamp.foundationDate ?? .distantPast) < ($1.timestamp.foundationDate ?? .distantPast)
                }
                self.participants = users
            }
        } catch {
            print("Failed to load chat room:", error.localizedDescription)
        }
    }

    private func observeNewMessages() {
        Amplify.Hub.publisher(for: .dataStore)
            .sink { _ in } receiveValue: { [weak self] event in
                guard let self else { return }
                if event.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let mutationEvent = event.data as? MutationEvent,
                   mutationEvent.modelName == "Message",
                   let newMessage = try? mutationEvent.decodeModel(as: Message.self),
                   newMessage.chatRoomID == self.chatRoomID {
                    DispatchQueue.main.async { self.messages.append(newMessage) }
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
        }
        await MainActor.run { messages = messages.map { var x = $0; x.isRead = true; return x } }
    }
}
