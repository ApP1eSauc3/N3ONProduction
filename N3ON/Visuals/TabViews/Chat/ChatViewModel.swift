//
//  ChatViewModel.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

import SwiftUI
import Amplify
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var participants: [User] = []

    var currentUserID: String
    private let chatRoomID: String
    private var cancellables = Set<AnyCancellable>()

    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
        Task {
            await loadChatRoom()
            observeNewMessages()
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }

        let newMessage = Message(
            id: UUID().uuidString,
            sender: try? await getCurrentUser(),
            chatRoomID: chatRoomID,
            content: messageText,
            timestamp: Temporal.DateTime.now(),
            isRead: false,
            readBy: nil
        )

        Task {
            do {
                try await Amplify.DataStore.save(newMessage)
                try await updateChatRoomLastMessage(newMessage)
                DispatchQueue.main.async { self.messageText = "" }
            } catch {
                print("Send failed: \(error)")
            }
        }
    }

    private func loadChatRoom() async {
        do {
            guard let chatRoom = try await Amplify.DataStore.query(ChatRoom.self, byId: chatRoomID) else {
                print("ChatRoom not found")
                return
            }

            let messageResults = try await Amplify.DataStore.query(Message.self, where: Message.keys.chatRoomID == chatRoomID)
            let users = chatRoom.participants ?? []

            await MainActor.run {
                self.messages = messageResults.sorted { $0.timestamp.iso8601String < $1.timestamp.iso8601String }
                self.participants = users
            }
        } catch {
            print("Failed to load chat room: \(error)")
        }
    }

    private func observeNewMessages() {
        Amplify.Hub.publisher(for: .dataStore)
            .sink { event in
                if event.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let mutationEvent = event.data as? MutationEvent,
                   mutationEvent.modelName == "Message" {
                    if let newMessage = try? mutationEvent.decodeModel(as: Message.self),
                       newMessage.chatRoomID == self.chatRoomID {
                        DispatchQueue.main.async {
                            self.messages.append(newMessage)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updateChatRoomLastMessage(_ message: Message) async throws {
        guard var chatRoom = try await Amplify.DataStore.query(ChatRoom.self, byId: chatRoomID) else { return }
        chatRoom.lastMessage = message.content
        chatRoom.lastMessageTimestamp = message.timestamp
        try await Amplify.DataStore.save(chatRoom)
    }

    private func getCurrentUser() async throws -> User? {
        guard let userID = await AuthService.currentUserId else { return nil }
        return try await Amplify.DataStore.query(User.self, byId: userID)
    }

    func markMessageAsRead() async {
        let unread = messages.filter {
            !$0.isRead && $0.sender?.id != currentUserID
        }

        for var message in unread {
            message.isRead = true
            try? await Amplify.DataStore.save(message)
        }

        await MainActor.run {
            messages = messages.map { var m = $0; m.isRead = true; return m }
        }
    }
}
