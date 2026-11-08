// ChatSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for ChatRoomService. Chat is user-generated
// content between strangers: no impersonation, no posting into rooms you're
// not in, no squatting an event's room, bounded message size; and every read
// path stays O(room), not O(all messages on the device).

import XCTest
import Amplify
@testable import N3ON

final class ChatSecPerfTests: BackendTestCase {

    private let me = Make.user("me"), dj = Make.user("dj2"), venueOwner = Make.user("owner", isDJ: false)

    private func room(_ id: String, members: [String]?, name: String? = nil) -> ChatRoom {
        ChatRoom(id: id, name: name ?? "room-\(id)", createdAt: Make.now(), updatedAt: Make.now(),
                 lastMessage: "", lastMessageTimestamp: Make.now(), participantIDs: members)
    }

    private func message(_ id: String, in roomID: String, from sender: User?, content: String = "hi",
                         read: Bool = false, minutesAgo: Double = 0) -> Message {
        Message(id: id, sender: sender, chatRoomID: roomID, content: content,
                timestamp: Temporal.DateTime(Date().addingTimeInterval(-minutesAgo * 60), timeZone: .current),
                isRead: read)
    }

    // MARK: - Room naming / creation

    func test_ChatRoomService_dmRoomName_security() {
        // Order-independent: neither side can open a second, parallel DM room.
        XCTAssertEqual(ChatRoomService.dmRoomName("a", "b"), ChatRoomService.dmRoomName("b", "a"))
        // A crafted id can't collide with another pair's room: the "-" joiner
        // is unambiguous for fixed-length subs.
        let x = "0b6e1c2a-7f9d-4a51-9c3e-2f1d8b7a6e50", y = "f3a9d2c1-5e7b-4c8a-b1d6-9e2f4a7c3b81"
        XCTAssertNotEqual(ChatRoomService.dmRoomName(x, y), ChatRoomService.dmRoomName(x, x))
    }

    func test_ChatRoomService_dmRoomName_performance() {
        let a = UUID().uuidString, b = UUID().uuidString
        let t = elapsedSync(iterations: 200_000) { _ = ChatRoomService.dmRoomName(a, b) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatRoomService_openDJDirectRoom_security() async throws {
        let room = try await ChatRoomService.openDJDirectRoom(userA: me, userB: dj)
        XCTAssertEqual(Set((room.participantIDs ?? []).compactMap { $0 }), ["me", "dj2"], "exactly the two DJs")
        let again = try await ChatRoomService.openDJDirectRoom(userA: dj, userB: me)
        XCTAssertEqual(again.id, room.id, "idempotent — no duplicate rooms")
    }

    func test_ChatRoomService_openDJDirectRoom_performance() async throws {
        db.seed(Make.many(3_000) { room("r\($0)", members: ["x"]) })
        let t = try await elapsed(iterations: 100) { _ = try await ChatRoomService.openDJDirectRoom(userA: self.me, userB: self.dj) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.all(ChatRoom.self).count, 3_001, "one room, however often opened")
    }

    func test_ChatRoomService_openEventRoom_security() async throws {
        let room = try await ChatRoomService.openEventRoom(dj: dj, venueUser: venueOwner, eventID: "e1")
        XCTAssertEqual(room.associatedEvent, "e1")
        XCTAssertTrue((room.participantIDs ?? []).contains("me"), "the caller is always a member (else they can't read it)")
    }

    func test_ChatRoomService_openEventRoom_performance() async throws {
        let t = try await elapsed(iterations: 100) { _ = try await ChatRoomService.openEventRoom(dj: self.dj, venueUser: self.venueOwner, eventID: "e1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatRoomService_allRooms_security() async {
        db.failNext = FakeError(tag: "x")
        do { _ = try await ChatRoomService.allRooms(); XCTFail("errors must surface") } catch {}
    }

    func test_ChatRoomService_allRooms_performance() async throws {
        db.seed(Make.many(5_000) { room("r\($0)", members: ["me"]) })
        let t = try await elapsed { _ = try await ChatRoomService.allRooms() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_ChatRoomService_createEventChatRoom_security() async throws {
        db.seed([Make.event("mine", host: "me"), Make.event("theirs", host: "dj2")])
        do { try await ChatRoomService.createEventChatRoom(eventID: "theirs"); XCTFail("squatted another host's event room") }
        catch { XCTAssertEqual(error as? ChatError, .notAllowed) }
        do { try await ChatRoomService.createEventChatRoom(eventID: "ghost"); XCTFail("room for a nonexistent event") }
        catch { XCTAssertEqual(error as? ChatError, .notAllowed) }
        XCTAssertTrue(db.all(ChatRoom.self).isEmpty)
        try await ChatRoomService.createEventChatRoom(eventID: "mine")
        XCTAssertEqual(db.all(ChatRoom.self).first?.participantIDs, ["me"])
    }

    func test_ChatRoomService_createEventChatRoom_performance() async throws {
        db.seed([Make.event("mine", host: "me")])
        db.seed(Make.many(5_000) { Make.event("e\($0)") })
        db.resetCounters()
        let t = try await elapsed { try await ChatRoomService.createEventChatRoom(eventID: "mine") }
        XCTAssertLessThan(t, 0.5, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_ChatRoomService_getOrCreate_security() async throws {
        // An existing room missing the caller gets them added (healed), but a
        // room is never handed back with a stranger silently removed.
        db.seed([room("r1", members: ["dj2", "stranger"], name: "dm-x")])
        let r = try await ChatRoomService.getOrCreate(name: "dm-x", participants: [dj], associatedEvent: nil)
        XCTAssertEqual(Set((r.participantIDs ?? []).compactMap { $0 }), ["dj2", "stranger", "me"])
        backend.auth.userID = nil
        do { _ = try await ChatRoomService.getOrCreate(name: "n", participants: [], associatedEvent: nil); XCTFail("signed out") } catch {}
    }

    func test_ChatRoomService_getOrCreate_performance() async throws {
        let t = try await elapsed(iterations: 200) { _ = try await ChatRoomService.getOrCreate(name: "dm-p", participants: [self.dj], associatedEvent: nil) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.all(UserChatRooms.self).count, 1, "membership rows written once, on creation")
    }

    func test_ChatRoomService_memberIDs_security() {
        // Nils and duplicates can't smuggle an empty/duplicate member in.
        XCTAssertEqual(ChatRoomService.memberIDs([nil, "a", "a"], adding: ["a", "b"]), ["a", "b"])
    }

    func test_ChatRoomService_memberIDs_performance() {
        let existing: [String?] = Make.many(1_000) { "u\($0)" }
        let t = elapsedSync(iterations: 1_000) { _ = ChatRoomService.memberIDs(existing, adding: ["new"]) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - Messages

    func test_ChatRoomService_room_security() async throws {
        db.seed([room("r1", members: ["me"])])
        let missing = try await ChatRoomService.room(byId: "r1' OR 'x")
        XCTAssertNil(missing)
    }

    func test_ChatRoomService_room_performance() async throws {
        db.seed(Make.many(5_000) { room("r\($0)", members: nil) })
        db.resetCounters()
        let t = try await elapsed(iterations: 1_000) { _ = try await ChatRoomService.room(byId: "r77") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_ChatRoomService_senderIDs_security() async {
        // Only messages in THIS room are attributed, and only to listed members.
        db.seed([message("m1", in: "r1", from: me), message("m2", in: "r2", from: me), message("m3", in: "r1", from: dj)])
        let map = await ChatRoomService.senderIDs(in: "r1", candidates: ["me"])
        XCTAssertEqual(map, ["m1": "me"], "no cross-room or non-candidate attribution")
    }

    func test_ChatRoomService_senderIDs_performance() async {
        db.seed(Make.many(5_000) { message("m\($0)", in: $0 % 5 == 0 ? "r1" : "r\($0)", from: $0 % 2 == 0 ? self.me : self.dj) })
        db.resetCounters()
        let t = await elapsed { _ = await ChatRoomService.senderIDs(in: "r1", candidates: ["me", "dj2", "me", "dj2"]) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.queryCount, 2, "one query per DISTINCT sender, not per message")
    }

    func test_ChatRoomService_messages_security() async throws {
        db.seed([message("a", in: "r1", from: me), message("b", in: "r2", from: dj)])
        let r1 = try await ChatRoomService.messages(for: "r1")
        XCTAssertEqual(r1.map(\.id), ["a"], "never another room's messages")
    }

    func test_ChatRoomService_messages_performance() async throws {
        db.seed(Make.many(10_000) { message("m\($0)", in: $0 < 1_000 ? "r1" : "rx", from: self.me, minutesAgo: Double($0)) })
        let t = try await elapsed { _ = try await ChatRoomService.messages(for: "r1") }
        XCTAssertLessThan(t, 1.0, "1k of 10k messages, sorted: \(t)s")
        let sorted = try await ChatRoomService.messages(for: "r1")
        XCTAssertEqual(sorted.first?.id, "m999", "oldest first")
    }

    func test_ChatRoomService_send_security() async throws {
        db.seed([room("r1", members: ["me", "dj2"]), room("locked", members: ["dj2", "owner"])])
        // Impersonation.
        do { try await ChatRoomService.send(message: message("x", in: "r1", from: dj)); XCTFail("posted as someone else") }
        catch { XCTAssertEqual(error as? ChatError, .notAllowed) }
        // Not a member.
        do { try await ChatRoomService.send(message: message("y", in: "locked", from: me)); XCTFail("posted into a room I'm not in") }
        catch { XCTAssertEqual(error as? ChatError, .notAllowed) }
        // Empty / oversized.
        do { try await ChatRoomService.send(message: message("z", in: "r1", from: me, content: " \n ")); XCTFail() }
        catch { XCTAssertEqual(error as? ChatError, .emptyMessage) }
        let big = String(repeating: "a", count: ChatRoomService.maxMessageLength + 1)
        do { try await ChatRoomService.send(message: message("w", in: "r1", from: me, content: big)); XCTFail() }
        catch { XCTAssertEqual(error as? ChatError, .messageTooLong) }
        XCTAssertTrue(db.all(Message.self).isEmpty, "none of those were written")
        // A genuine message is scoped to the room's members.
        try await ChatRoomService.send(content: "hello", in: "r1", from: me)
        XCTAssertEqual(Set((db.all(Message.self).first?.participantIDs ?? []).compactMap { $0 }), ["me", "dj2"])
    }

    func test_ChatRoomService_send_performance() async throws {
        db.seed([room("r1", members: ["me", "dj2"])])
        let t = try await elapsed(iterations: 500) { try await ChatRoomService.send(content: "yo", in: "r1", from: self.me) }
        XCTAssertLessThan(t, 2.0, "500 sends: \(t)s")
        XCTAssertEqual(db.saveCount, 1_000, "one message + one room update per send")
    }

    func test_ChatRoomService_markRead_security() async {
        db.seed([message("mine", in: "r1", from: me), message("theirs", in: "r1", from: dj), message("other", in: "r2", from: dj)])
        await ChatRoomService.markRead(in: "r1", userID: "me")
        let all = db.all(Message.self)
        XCTAssertEqual(all.first { $0.id == "theirs" }?.isRead, true)
        XCTAssertEqual(all.first { $0.id == "mine" }?.isRead, false, "your own messages aren't 'read' by you")
        XCTAssertEqual(all.first { $0.id == "other" }?.isRead, false, "other rooms untouched")
    }

    func test_ChatRoomService_markRead_performance() async {
        db.seed(Make.many(2_000) { message("m\($0)", in: "r1", from: self.dj) })
        let t = await elapsed { await ChatRoomService.markRead(in: "r1", userID: "me") }
        XCTAssertLessThan(t, 2.0, "2k concurrent read receipts: \(t)s")
        XCTAssertTrue(db.all(Message.self).allSatisfy(\.isRead))
    }

    func test_ChatRoomService_unreadCount_security() async throws {
        db.seed([message("a", in: "r1", from: me), message("b", in: "r1", from: dj), message("c", in: "r1", from: dj, read: true)])
        let n = try await ChatRoomService.unreadCount(in: "r1", excludingSenderID: "me")
        XCTAssertEqual(n, 1)
    }

    func test_ChatRoomService_unreadCount_performance() async throws {
        db.seed(Make.many(10_000) { message("m\($0)", in: "r\($0 % 50)", from: self.dj, read: $0 % 2 == 0) })
        db.resetCounters()
        // The fake evaluates predicates row by row (real DataStore uses an
        // indexed SQLite query), so the wall clock here is mostly the fake:
        // the scalability guarantee is the no-table-scan assertion.
        let t = try await elapsed(iterations: 5) { _ = try await ChatRoomService.unreadCount(in: "r7", excludingSenderID: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    // MARK: - Participants

    func test_ChatRoomService_participants_security() async throws {
        let r = room("r1", members: ["me", "dj2"])
        db.seed([r]); db.seed([UserChatRooms(user: me, chatRoom: r), UserChatRooms(user: dj, chatRoom: r)])
        let others = try await ChatRoomService.participants(for: "r1", excludingID: "me")
        XCTAssertEqual(others.map(\.id), ["dj2"])
    }

    func test_ChatRoomService_participants_performance() async throws {
        let rooms = Make.many(500) { room("r\($0)", members: nil) }
        db.seed(rooms)
        db.seed(Make.many(5_000) { UserChatRooms(user: Make.user("u\($0)"), chatRoom: rooms[$0 % 500]) })
        let t = try await elapsed(iterations: 50) { _ = try await ChatRoomService.participants(for: "r3", excludingID: "u3") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatRoomService_roomIDs_security() async throws {
        let r1 = room("r1", members: nil), r2 = room("r2", members: nil)
        db.seed([r1, r2]); db.seed([UserChatRooms(user: me, chatRoom: r1), UserChatRooms(user: dj, chatRoom: r2)])
        let mine = try await ChatRoomService.roomIDs(for: "me")
        XCTAssertEqual(mine, ["r1"], "only rooms I'm a member of")
    }

    func test_ChatRoomService_roomIDs_performance() async throws {
        let rooms = Make.many(1_000) { room("r\($0)", members: nil) }
        db.seed(rooms)
        db.seed(Make.many(10_000) { UserChatRooms(user: $0 % 10 == 0 ? self.me : Make.user("u\($0)"), chatRoom: rooms[$0 % 1_000]) })
        let t = try await elapsed(iterations: 20) { _ = try await ChatRoomService.roomIDs(for: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }
}
