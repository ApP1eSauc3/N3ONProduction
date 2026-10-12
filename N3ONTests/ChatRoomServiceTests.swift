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
}
