//
//  ChatRoomService.swift
//  N3ON
//
//  Created by liam howe on 13/7/2025.
//

import SwiftUI
import Amplify

struct ChatRoomService {
    
    static func getOrCreateDirectChatRoom(userA: User, userB: User) async throws -> ChatRoom {
        let sortedIDs = [userA.id, userB.id].sorted()
        let roomName = "dm-\(sortedIDs[0])-\(sortedIDs[1])"
        
        // Try to find existing room with same name
        let existingRooms = try await Amplify.DataStore.query(ChatRoom.self, where: ChatRoom.keys.name == roomName)
        if let existing = existingRooms.first {
            return existing
        }
        
        let newRoom = ChatRoom(
            id: UUID().uuidString,
            name: roomName,
            participants: [userA, userB],
            messages: [],
            lastMessage: "",
            lastMessageTimestamp: .now(),
            associatedEvent: nil
        )
        
        try await Amplify.DataStore.save(newRoom)
        return newRoom
    }

    static func getOrCreateEventChatRoom(dj: User, venue: User, eventID: String) async throws -> ChatRoom {
        let roomName = "event-\(eventID)"
        
        let existing = try await Amplify.DataStore.query(ChatRoom.self, where: ChatRoom.keys.name == roomName)
        if let room = existing.first {
            return room
        }

        let room = ChatRoom(
            id: UUID().uuidString,
            name: roomName,
            participants: [dj, venue],
            messages: [],
            lastMessage: "",
            lastMessageTimestamp: .now(),
            associatedEvent: eventID
        )

        try await Amplify.DataStore.save(room)
        return room
    }
}
