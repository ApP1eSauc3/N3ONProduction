// ChatRoomServiceTests.swift
// N3ONTests
//
// ChatRoom/Message read access is scoped to participantIDs (schema @auth), so
// the member list ChatRoomService writes decides who can see a chat at all.
// Only the pure list-building helper is covered here — the DataStore paths
// need the two-account smoke test (LAUNCH-CHECKLIST Phase 2, step 6).

import XCTest
@testable import N3ON

final class ChatRoomServiceTests: XCTestCase {

    func testMemberIDsAddsCallerAndDeduplicates() {
        let ids = ChatRoomService.memberIDs(["b", "a"], adding: ["a", "c"])
        XCTAssertEqual(ids, ["a", "b", "c"])
    }

    func testMemberIDsDropsNilEntriesFromGeneratedShape() {
        // Generated models type the list as [String?]?.
        let ids = ChatRoomService.memberIDs([nil, "b", nil], adding: [])
        XCTAssertEqual(ids, ["b"])
    }

    func testMemberIDsFromLegacyRoomWithNoList() {
        // Rooms created before participantIDs existed have nil; the sender must
        // still end up in the list or they can't read their own message.
        let ids = ChatRoomService.memberIDs(nil, adding: ["sender"])
        XCTAssertEqual(ids, ["sender"])
    }

    func testMemberIDsIsOrderIndependent() {
        XCTAssertEqual(
            ChatRoomService.memberIDs(["x", "y"], adding: ["z"]),
            ChatRoomService.memberIDs(["z", "y"], adding: ["x"])
        )
    }

    // MARK: - dmRoomName (F14) — same cases as lambda-tests/join.test.js

    func testDMRoomNameMirrorsLambda() {
        let a = "0b6e1c2a-7f9d-4a51-9c3e-2f1d8b7a6e50"
        let b = "f3a9d2c1-5e7b-4c8a-b1d6-9e2f4a7c3b81"
        XCTAssertEqual(ChatRoomService.dmRoomName(b, a), "dm-\(a)-\(b)")
        XCTAssertEqual(ChatRoomService.dmRoomName(a, b), "dm-\(a)-\(b)")
        // U+1F600 (astral) vs U+FF21: ordered by scalar value, emoji last.
        XCTAssertEqual(ChatRoomService.dmRoomName("\u{1F600}", "\u{FF21}"), "dm-\u{FF21}-\u{1F600}")
        XCTAssertEqual(ChatRoomService.dmRoomName("ab", "a"), "dm-a-ab")
    }
}
