// ChatRoomService.swift
// N3ON — Task layer
// All DataStore operations for chat rooms and messages live here.
// ViewModels never call Amplify.DataStore directly for chat concerns.

import Foundation
import Amplify

struct ChatRoomService {

    // MARK: - Room access

    /// Deterministic DJ↔DJ room name: `dm-<lower>-<higher>`, the same whoever
    /// opens it. The single Swift source of this name — the joinEvent Lambda's
    /// `dmRoomName` must produce the same string.
    ///
    /// Ordered by Unicode scalar value on both sides. Swift's `String <`
    /// applies canonical equivalence and JS `.sort()` compares UTF-16 units, so
    /// the two disagreed for some non-ASCII IDs (LEAN-RESEARCH.md F14). Cognito
    /// subs are ASCII UUIDs, where every ordering agrees, so no existing room
    /// name changes.
    static func dmRoomName(_ a: String, _ b: String) -> String {
        let (lower, higher) = b.unicodeScalars.lexicographicallyPrecedes(a.unicodeScalars) ? (b, a) : (a, b)
        return "dm-\(lower)-\(higher)"
    }

    /// Opens or creates a DJ↔DJ direct message room.
    /// Room name is deterministic (`dmRoomName`) — idempotent on repeat calls.
    static func openDJDirectRoom(userA: User, userB: User) async throws -> ChatRoom {
        try await getOrCreate(
            name: dmRoomName(userA.id, userB.id),
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

    /// All chat rooms. DataStore has no .in() predicate, so callers that need
    /// a specific subset (e.g. rooms a user belongs to) filter this in memory.
    static func allRooms() async throws -> [ChatRoom] {
        try await Backend.dataStore.query(ChatRoom.self)
    }

    /// Creates the event chat room record for a newly-published event.
    /// The creator is its first member: ChatRoom @auth gives the creator no read,
    /// so a room without them in `participantIDs` would be invisible to them.
    static func createEventChatRoom(eventID: String) async throws {
        let creatorID = try await AuthService.currentUserId()
        // Only the event's host creates its room. Otherwise anyone could
        // pre-create "event-<id>" — and getOrCreate reuses rooms by name, so
        // the squatter's room (with them in it) would become the event chat.
        guard let event = try await Backend.dataStore.query(Event.self, byId: eventID),
              event.hostDJID == creatorID
        else { throw ChatError.notAllowed }
        let now = Temporal.DateTime.now()
        let chatRoom = ChatRoom(
            id: UUID().uuidString,
            name: "event-\(eventID)",
            createdAt: now,
            updatedAt: now,
            lastMessage: "",
            lastMessageTimestamp: now,
            associatedEvent: eventID,
            participantIDs: [creatorID]
        )
        try await Backend.dataStore.save(chatRoom)
    }

    // MARK: - Messages

    static func room(byId id: String) async throws -> ChatRoom? {
        try await Backend.dataStore.query(ChatRoom.self, byId: id)
    }

    /// messageID → senderID for the room, resolved by querying on the stored
    /// `senderID` column for each candidate sender. `Message.sender` is a
    /// belongsTo that DataStore leaves nil when the sender's User row isn't in
    /// the local store yet — the column itself is always there.
    static func senderIDs(in roomID: String, candidates: [String]) async -> [String: String] {
        var map: [String: String] = [:]
        for candidate in Set(candidates) {
            let sent = (try? await Backend.dataStore.query(
                Message.self,
                where: Message.keys.chatRoomID == roomID && Message.keys.sender == candidate
            )) ?? []
            for m in sent { map[m.id] = candidate }
        }
        return map
    }

    /// All messages in a room, sorted oldest-first.
    static func messages(for roomID: String) async throws -> [Message] {
        let results = try await Backend.dataStore.query(
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

    /// Saves a message and updates the room's last-message metadata.
    /// The room's members are copied onto the message — `Message.participantIDs`
    /// is its read scope, so a message saved without them reaches nobody.
    /// Longest message accepted. The text is also copied into
    /// `ChatRoom.lastMessage`, so it is bounded once, here.
    static let maxMessageLength = 4_000

    static func send(message: Message) async throws {
        let trimmed = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ChatError.emptyMessage }
        guard message.content.count <= maxMessageLength else { throw ChatError.messageTooLong }
        // Send only as yourself — the server rejects a forged senderID
        // (Message @auth ownerField), and the client never tries.
        let me = try await AuthService.currentUserId()
        guard message.sender?.id == me else { throw ChatError.notAllowed }
        guard var room = try await Backend.dataStore.query(ChatRoom.self, byId: message.chatRoomID)
        else { throw ChatError.roomNotFound }
        // A member-scoped room only takes messages from its members. (Legacy
        // rooms without participantIDs are healed by getOrCreate.)
        let members = (room.participantIDs ?? []).compactMap { $0 }
        guard members.isEmpty || members.contains(me) else { throw ChatError.notAllowed }
        var message = message
        // The sender is always included so they can read their own message back.
        message.participantIDs = memberIDs(room.participantIDs, adding: [message.sender?.id].compactMap { $0 })
        try await Backend.dataStore.save(message)
        room.lastMessage = message.content
        room.lastMessageTimestamp = message.timestamp
        try await Backend.dataStore.save(room)
    }

    /// Marks all unread messages not sent by `userID` as read.
    /// Saves run concurrently — each save is independent of the others, so
    /// sequential awaits would turn N writes into an O(N) round-trip stall.
    static func markRead(in roomID: String, userID: String) async {
        let unread = (try? await Backend.dataStore.query(
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
                    _ = try? await Backend.dataStore.save(updated)
                }
            }
        }
    }

    /// Count of unread messages in `roomID` not sent by `excludingSenderID`.
    static func unreadCount(in roomID: String, excludingSenderID: String) async throws -> Int {
        let msgs = try await Backend.dataStore.query(
            Message.self,
            where: Message.keys.chatRoomID == roomID && Message.keys.isRead == false
        )
        return msgs.filter { ($0.sender?.id ?? "") != excludingSenderID }.count
    }

    // MARK: - Participants

    /// Participants in a room, excluding the specified user.
    static func participants(for roomID: String, excludingID: String) async throws -> [User] {
        let links = try await Backend.dataStore.query(
            UserChatRooms.self,
            where: UserChatRooms.keys.chatRoom == roomID
        )
        return links.compactMap { $0.user }.filter { $0.id != excludingID }
    }

    /// All chat room IDs the given user is a participant in.
    static func roomIDs(for userID: String) async throws -> Set<String> {
        let links = try await Backend.dataStore.query(
            UserChatRooms.self,
            where: UserChatRooms.keys.user == userID
        )
        return Set(links.compactMap { $0.chatRoom.id })
    }

    // MARK: - Private

    static func getOrCreate(
        name: String,
        participants: [User],
        associatedEvent: String?
    ) async throws -> ChatRoom {
        // The caller is always a member — the creator rule on ChatRoom has no read.
        let callerID = try await AuthService.currentUserId()
        let members = memberIDs(nil, adding: participants.map(\.id) + [callerID])

        if var existing = try await Backend.dataStore
            .query(ChatRoom.self, where: ChatRoom.keys.name == name).first {
            // Rooms created before participantIDs existed (or missing a member):
            // add the members. Non-fatal — only a creator or member may update.
            let healed = memberIDs(existing.participantIDs, adding: members.compactMap { $0 })
            if Set(healed) != Set(existing.participantIDs ?? []) {
                existing.participantIDs = healed
                _ = try? await Backend.dataStore.save(existing)
            }
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
            associatedEvent: associatedEvent,
            participantIDs: members
        )
        try await Backend.dataStore.save(room)
        for u in participants {
            try await Backend.dataStore.save(UserChatRooms(user: u, chatRoom: room))
        }
        return (try? await Backend.dataStore.query(ChatRoom.self, byId: room.id)) ?? room
    }

    /// Sorted, de-duplicated member IDs (Cognito subs) in the generated `[String?]` shape.
    static func memberIDs(_ existing: [String?]?, adding extra: [String]) -> [String?] {
        Set((existing ?? []).compactMap { $0 } + extra).sorted()
    }
}

// MARK: - Errors

enum ChatError: Error, Equatable {
    case ineligible(ChatIneligibilityReason)
    case roomNotFound
    case sendFailed
    case emptyMessage
    case messageTooLong
    /// Not the sender / not a member / not the event's host.
    case notAllowed
}
