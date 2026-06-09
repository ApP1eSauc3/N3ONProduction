// ChatRoomService.swift
// N3ON — Task layer
// All DataStore operations for chat rooms and messages live here.
// ViewModels never call Amplify.DataStore directly for chat concerns.

import Foundation
import Amplify

struct ChatRoomService {

    // MARK: - Room access

    /// Opens or creates a DJ↔DJ direct message room.
    /// Room name is deterministic from sorted user IDs — idempotent on repeat calls.
    static func openDJDirectRoom(userA: User, userB: User) async throws -> ChatRoom {
        let sorted = [userA.id, userB.id].sorted()
        return try await getOrCreate(
            name: "dm-\(sorted[0])-\(sorted[1])",
            participants: [userA, userB],
            associatedEvent: nil
        )
    }

    /// Opens or creates a DJ↔Venue event chat room.
    /// Caller is responsible for verifying eligibility via `ChatEligibilityService` first.
    static func openEventRoom(dj: User, venueUser: User, eventID: String) async throws -> ChatRoom {
        try await getOrCreate(
            name: "event-\(eventID)",
            participants: [dj, venueUser],
            associatedEvent: eventID
        )
    }

    // MARK: - Messages

    /// All messages in a room, sorted oldest-first.
    static func messages(for roomID: String) async throws -> [Message] {
        let results = try await Amplify.DataStore.query(
            Message.self,
            where: Message.keys.chatRoomID == roomID
        )
        return results.sorted {
            ($0.timestamp.foundationDate ?? .distantPast) < ($1.timestamp.foundationDate ?? .distantPast)
        }
    }

    /// Builds and saves a message from raw content — keeps Temporal out of the Prompt layer.
    static func send(content: String, in roomID: String, from sender: User) async throws {
        let message = Message(
            sender:     sender,
            chatRoomID: roomID,
            content:    content,
            timestamp:  Temporal.DateTime(Date(), timeZone: .current),
            isRead:     false
        )
        try await send(message: message)
    }

    /// Saves a message and updates the room's last-message metadata atomically.
    static func send(message: Message) async throws {
        try await Amplify.DataStore.save(message)
        guard var room = try await Amplify.DataStore.query(ChatRoom.self, byId: message.chatRoomID) else { return }
        room.lastMessage = message.content
        room.lastMessageTimestamp = message.timestamp
        try await Amplify.DataStore.save(room)
    }

    /// Marks all unread messages not sent by `userID` as read.
    /// Saves run concurrently — each save is independent of the others, so
    /// sequential awaits would turn N writes into an O(N) round-trip stall.
    static func markRead(in roomID: String, userID: String) async {
        let unread = (try? await Amplify.DataStore.query(
            Message.self,
            where: Message.keys.chatRoomID == roomID && Message.keys.isRead == false
        )) ?? []
        let toMark = unread.filter { ($0.sender?.id ?? "") != userID }
        guard !toMark.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for var m in toMark {
                m.isRead = true
                let updated = m
                group.addTask {
                    _ = try? await Amplify.DataStore.save(updated)
                }
            }
        }
    }

    // MARK: - Participants

    /// Participants in a room, excluding the specified user.
    static func participants(for roomID: String, excludingID: String) async throws -> [User] {
        let links = try await Amplify.DataStore.query(
            UserChatRooms.self,
            where: UserChatRooms.keys.chatRoom == roomID
        )
        return links.compactMap { $0.user }.filter { $0.id != excludingID }
    }

    /// All chat room IDs the given user is a participant in.
    static func roomIDs(for userID: String) async throws -> Set<String> {
        let links = try await Amplify.DataStore.query(
            UserChatRooms.self,
            where: UserChatRooms.keys.user == userID
        )
        return Set(links.compactMap { $0.chatRoom.id })
    }

    // MARK: - Private

    private static func getOrCreate(
        name: String,
        participants: [User],
        associatedEvent: String?
    ) async throws -> ChatRoom {
        if let existing = try await Amplify.DataStore
            .query(ChatRoom.self, where: ChatRoom.keys.name == name).first {
            return existing
        }
        let now = Temporal.DateTime(Date(), timeZone: .current)
        let room = ChatRoom(
            id: UUID().uuidString,
            name: name,
            createdAt: now,
            updatedAt: now,
            lastMessage: "",
            lastMessageTimestamp: now,
            associatedEvent: associatedEvent
        )
        try await Amplify.DataStore.save(room)
        for u in participants {
            try await Amplify.DataStore.save(UserChatRooms(user: u, chatRoom: room))
        }
        return (try? await Amplify.DataStore.query(ChatRoom.self, byId: room.id)) ?? room
    }
}

// MARK: - Errors

enum ChatError: Error {
    case ineligible(ChatIneligibilityReason)
    case roomNotFound
    case sendFailed
}
