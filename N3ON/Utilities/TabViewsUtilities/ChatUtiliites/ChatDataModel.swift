//
//  MessageModel.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//
import Foundation
import Amplify

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let content: String
    let timestamp: Date
    let isCurrentUser: Bool
}

extension ChatMessage {
    init(from message: Message, currentUserID: String) {
        // Convert Temporal.DateTime to Foundation.Date using foundationDate
        let timestampDate = message.timestamp.foundationDate
        
        self.init(
            sender: message.sender?.id ?? "uknown",
            content: message.content,
            timestamp: timestampDate,
            isCurrentUser: message.sender?.id == currentUserID
        )
    }
}
