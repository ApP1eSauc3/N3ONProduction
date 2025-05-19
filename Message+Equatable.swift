//
//  Message+Equatable.swift
//  N3ON
//
//  Created by liam howe on 9/5/2025.
//

import Foundation

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.chatRoomID == rhs.chatRoomID &&
        lhs.content == rhs.content &&
        lhs.timestamp.iso8601String == rhs.timestamp.iso8601String &&
        lhs.isRead == rhs.isRead &&
        lhs.readBy?.compactMap { $0 } == rhs.readBy?.compactMap { $0 } &&
        lhs.sender?.id == rhs.sender?.id
    }
}
