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
    
     var currentUserID = "exampleUserID"
    private var currentChatRoomID = "default-room"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMessages()
        observeNewMessages()
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = Message(
            id: UUID().uuidString,
            sender: nil,
            chatRoomID: currentChatRoomID,
            content: messageText,
            timestamp: Temporal.DateTime.now(),
            isRead: false,
            readBy: nil
        )
        
        Task {
            do {
                try await Amplify.DataStore.save(newMessage)
                DispatchQueue.main.async { self.messageText = "" }
                print("Message sent")
            } catch {
                print("Failed to send message: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func loadMessages() {
        Task {
            do {
                let messages = try await Amplify.DataStore.query(Message.self, where: Message.keys.chatRoomID == currentChatRoomID)
                DispatchQueue.main.async {
                    self.messages = messages
                }
            } catch {
                print("Failed to load messages: \(error.localizedDescription)")
            }
        }
    }
    
    private func observeNewMessages() {
        Amplify.Hub.publisher(for: .dataStore)
            .sink { event in
                if event.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let mutationEvent = event.data as? MutationEvent,
                   mutationEvent.modelName == "Message" {
                    if let newMessage = try? mutationEvent.decodeModel(as: Message.self),
                       newMessage.chatRoomID == self.currentChatRoomID {
                        self.messages.append(newMessage)
                    }
                }
            }
            .store(in: &cancellables)
    }
    func markMessageAsRead() {
        Task{
            let unreadMessages = messages.filter {
                !$0.isRead && $0.sender?.id != currentUserID
            }
            
            for var message in unreadMessages {
                message.isRead = true
                do {
                    try await Amplify.DataStore.save(message)
                } catch {
                    print("Failed to mark message as read: \(error)")
                }
            }
            
        await MainActor.run {
            messages = messages.map { msg in
                var newMsg = msg
                newMsg.isRead = true
                return newMsg
            }

            }
        }
    }
}


