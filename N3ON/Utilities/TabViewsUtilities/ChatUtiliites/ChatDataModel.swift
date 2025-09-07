//
//  MessageModel.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//
// ===============================================
// File: Chat/ChatDataModel.swift
// WHY: Map Message → ChatMessage using relation; stable id.
// ===============================================
import Foundation
import Amplify

extension ChatMessage {
    init(from message: Message, currentUserID: String) {
        let ts = message.timestamp.foundationDate
        let sid = message.sender?.id ?? "unknown"
        self.init(
            id: message.id,            
            sender: sid,
            content: message.content,
            timestamp: ts,
            isCurrentUser: sid == currentUserID
        )
    }
}
