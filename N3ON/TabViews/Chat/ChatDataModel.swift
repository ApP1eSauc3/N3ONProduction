//
//  MessageModel.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

import Foundation

struct ChatMessage: Identifiable{
    let id = UUID()
    let sender: String
    let content: String
    let timestamp: Date
    let isCurrentUser: Bool
}

extension ChatMessage {
    init(from message: Message, currentUserID: String) {
        self.init(
            sender: message.senderID,
            content: message.content,
            timestamp: message.timestamp,
            isCurrentUser: message.senderID == currentUserID
        )
    }
}
