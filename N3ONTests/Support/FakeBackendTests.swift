// FakeBackendTests.swift
// N3ONTests
//
// The fake must behave like DataStore for the predicates the app uses, or every
// service test built on it proves nothing. These pin that behaviour.

import XCTest
import Amplify
import AWSPluginsCore
@testable import N3ON

final class FakeBackendTests: BackendTestCase {

    private func dj(_ id: String, rank: Int? = nil, isDJ: Bool = true) -> User {
        User(id: id, username: id, isDJ: isDJ, djRank: rank, isCurated: false, isSharingLocation: false, coinBalance: 0)
    }

    func testScalarEqualityAndNegation() async throws {
        db.seed([dj("a", rank: 1), dj("b", rank: 4), dj("c", rank: 4, isDJ: false)])
        let fours = try await Backend.dataStore.query(User.self, where: User.keys.djRank == 4)
        XCTAssertEqual(Set(fours.map(\.id)), ["b", "c"])
        let both = try await Backend.dataStore.query(User.self, where: User.keys.djRank == 4 && User.keys.isDJ == true)
        XCTAssertEqual(both.map(\.id), ["b"])
        let either = try await Backend.dataStore.query(User.self, where: User.keys.id == "a" || User.keys.id == "c")
        XCTAssertEqual(Set(either.map(\.id)), ["a", "c"])
        let notA = try await Backend.dataStore.query(User.self, where: not(User.keys.id == "a"))
        XCTAssertEqual(Set(notA.map(\.id)), ["b", "c"])
    }

    func testDateComparisonUsesTemporalOrdering() async throws {
        let past = Fixtures.event(venueID: "v", daysFromNow: -3, name: "past")
        let future = Fixtures.event(venueID: "v", daysFromNow: 3, name: "future")
        db.seed([past, future])
        let upcoming = try await Backend.dataStore.query(Event.self, where: Event.keys.eventDate >= Temporal.DateTime.now())
        XCTAssertEqual(upcoming.map(\.eventName), ["future"])
    }

    func testAssociationKeysCompareByIdentifierLikeAForeignKey() async throws {
        let me = dj("me", rank: 1), senior = dj("s", rank: 2)
        let req = EndorsementRequest(fromUser: me, toUser: senior, targetRank: 2, message: "", status: "pending",
                                     timestamp: Temporal.DateTime(Date(), timeZone: .current))
        db.seed([req])
        let mine = try await Backend.dataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.fromUser == "me")
        XCTAssertEqual(mine.count, 1)
        let theirs = try await Backend.dataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.fromUser == "s")
        XCTAssertEqual(theirs.count, 0)
    }

    func testSaveUpsertsDeleteRemovesAndByIdReads() async throws {
        try await Backend.dataStore.save(dj("x", rank: 1))
        try await Backend.dataStore.save(dj("x", rank: 3))
        let all = try await Backend.dataStore.query(User.self)
        XCTAssertEqual(all.count, 1)
        let updated = try await Backend.dataStore.query(User.self, byId: "x")
        XCTAssertEqual(updated?.djRank, 3)
        try await Backend.dataStore.delete(all[0])
        let gone = try await Backend.dataStore.query(User.self, byId: "x")
        XCTAssertNil(gone)
    }

    func testObserveDeliversDecodableCreateAndUpdateEvents() async throws {
        let stream = Backend.dataStore.observe(User.self)
        try await Backend.dataStore.save(dj("o", rank: 1))
        try await Backend.dataStore.save(dj("o", rank: 2))
        db.finishStreams()
        var seen: [(String, Int?)] = []
        for try await change in stream {
            seen.append((change.mutationType, try change.decodeModel(as: User.self).djRank))
        }
        XCTAssertEqual(seen.map(\.0), ["create", "update"])
        XCTAssertEqual(seen.map(\.1), [1, 2])
    }

    func testFailureInjectionFiresOnce() async {
        db.failNext = FakeError(tag: "boom")
        do { _ = try await Backend.dataStore.query(User.self); XCTFail("should throw") }
        catch { XCTAssertEqual(error as? FakeError, FakeError(tag: "boom")) }
        let after = try? await Backend.dataStore.query(User.self)
        XCTAssertNotNil(after)
    }

    func testFakeAuthSignedOutThrowsAndTokensCarryGroups() async throws {
        backend.auth.userID = nil
        do { _ = try await Backend.auth.getCurrentUser(); XCTFail("signed out must throw") } catch {}
        backend.auth.idToken = FakeAuth.token(groups: ["AdminUser"])
        backend.auth.userID = "me"
        let session = try await Backend.auth.fetchAuthSession()
        XCTAssertNotNil(session as? AuthCognitoTokensProvider)
    }
}
