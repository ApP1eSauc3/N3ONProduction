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

        if let existing = try await Amplify.DataStore
            .query(ChatRoom.self, where: ChatRoom.keys.name == roomName).first {
            return existing
        }

        let now = Temporal.DateTime.now()

        var room = ChatRoom(
            id: UUID().uuidString,
            name: roomName,
            createdAt: now,
            updatedAt: now,
            lastMessage: "",
            lastMessageTimestamp: now,
            associatedEvent: nil
        )
        try await Amplify.DataStore.save(room)
        try await attachParticipants([userA, userB], to: room)

        return try await Amplify.DataStore.query(ChatRoom.self, byId: room.id) ?? room
    }

    static func getOrCreateEventChatRoom(dj: User, venue: User, eventID: String) async throws -> ChatRoom {
        let roomName = "event-\(eventID)"

        if let existing = try await Amplify.DataStore
            .query(ChatRoom.self, where: ChatRoom.keys.name == roomName).first {
            return existing
        }

        let now = Temporal.DateTime.now()

        var room = ChatRoom(
            id: UUID().uuidString,
            name: roomName,
            createdAt: now,
            updatedAt: now,
            lastMessage: "",
            lastMessageTimestamp: now,
            associatedEvent: eventID
        )
        try await Amplify.DataStore.save(room)
        try await attachParticipants([dj, venue], to: room)

        return try await Amplify.DataStore.query(ChatRoom.self, byId: room.id) ?? room
    }

    // MARK: - Helpers

    private static func attachParticipants(_ users: [User], to room: ChatRoom) async throws {
        for u in users {
            let link = UserChatRooms(user: u, chatRoom: room)
            try await Amplify.DataStore.save(link)
        }
    }
}
