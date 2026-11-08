// EventVenueSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for EventService, FollowService, MapService,
// SearchService, TicketService, TransactionService and VenueService.
// Writes are owner/host-only and validated; reads are predicate-filtered
// (no whole-table scans on the map's load path) and bounded.

import XCTest
import UIKit
import CoreLocation
import Amplify
@testable import N3ON

final class EventVenueSecPerfTests: BackendTestCase {

    private func image(_ w: Int, _ h: Int) -> UIImage {
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { c in
            UIColor.cyan.setFill(); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    // MARK: - EventService

    func test_EventService_fetchUpcomingEvents_security() async throws {
        db.seed([Make.event("past", days: -2), Make.event("soon", days: 2)])
        let upcoming = try await EventService.fetchUpcomingEvents()
        XCTAssertEqual(upcoming.map(\.id), ["soon"], "ended events aren't offered for sale")
    }

    func test_EventService_fetchUpcomingEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", days: ($0 % 200) - 100) })
        db.resetCounters()
        let t = try await elapsed { _ = try await EventService.fetchUpcomingEvents() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_EventService_fetchEvent_security() async throws {
        db.seed([Make.event("e1")])
        let none = try await EventService.fetchEvent(byId: "e1\u{0}")
        XCTAssertNil(none)
    }

    func test_EventService_fetchEvent_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)") })
        db.resetCounters()
        let t = try await elapsed(iterations: 1_000) { _ = try await EventService.fetchEvent(byId: "e9") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_EventService_fetchEvents_security() async throws {
        db.seed([Make.event("a", venueID: "v1", host: "h1"), Make.event("b", venueID: "v2", host: "h2")])
        let byHost = try await EventService.fetchEvents(forHostDJID: "h1")
        XCTAssertEqual(byHost.map(\.id), ["a"])
        let byVenue = try await EventService.fetchEvents(forVenueID: "v2")
        XCTAssertEqual(byVenue.map(\.id), ["b"])
    }

    func test_EventService_fetchEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 100)", host: "h\($0 % 50)") })
        db.resetCounters()
        let t = try await elapsed(iterations: 20) {
            _ = try await EventService.fetchEvents(forHostDJID: "h3")
            _ = try await EventService.fetchEvents(forVenueID: "v3")
        }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_EventService_bookedDates_security() async {
        db.failNext = FakeError(tag: "x")
        let onError = await EventService.bookedDates(forVenueID: "v1")
        XCTAssertEqual(onError, [], "no data → no blocked dates (the server re-checks on save)")
    }

    func test_EventService_bookedDates_performance() async {
        db.seed(Make.many(3_000) { Make.event("e\($0)", venueID: "v1", days: $0) })
        let t = await elapsed { _ = await EventService.bookedDates(forVenueID: "v1") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_EventService_requireHost_security() async throws {
        do { try await EventService.requireHost(of: Make.event("e", host: "someoneElse")); XCTFail() }
        catch { XCTAssertEqual(error as? EventServiceError, .notHost) }
        try await EventService.requireHost(of: Make.event("e", host: "me"))
    }

    func test_EventService_requireHost_performance() async throws {
        let e = Make.event("e", host: "me")
        let t = try await elapsed(iterations: 5_000) { try await EventService.requireHost(of: e) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventService_cancelEvent_security() async throws {
        db.seed([Make.event("theirs", host: "other"), Make.event("mine", host: "me")])
        do { try await EventService.cancelEvent(id: "theirs"); XCTFail("cancelled another host's event") }
        catch { XCTAssertEqual(error as? EventServiceError, .notHost) }
        try await EventService.cancelEvent(id: "mine")
        XCTAssertEqual(db.all(Event.self).map(\.id), ["theirs"])
    }

    func test_EventService_cancelEvent_performance() async throws {
        db.seed(Make.many(2_000) { Make.event("e\($0)", host: "me") })
        let t = try await elapsed { for i in 0..<200 { try await EventService.cancelEvent(id: "e\(i)") } }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventService_allDJs_security() async {
        db.seed([Make.user("me"), Make.user("dj"), Make.user("fan", isDJ: false)])
        let djs = await EventService.allDJs(excludingID: "me")
        XCTAssertEqual(djs.map(\.id), ["dj"], "no fans, not yourself")
    }

    func test_EventService_allDJs_performance() async {
        db.seed(Make.many(10_000) { Make.user("u\($0)", isDJ: $0 % 3 == 0) })
        let t = await elapsed { _ = await EventService.allDJs(excludingID: "u0") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_EventService_djLinks_security() async throws {
        let a = Make.event("a"), b = Make.event("b")
        db.seed([a, b]); db.seed([Make.link(event: a, dj: "d1"), Make.link(event: b, dj: "d2")])
        let links = try await EventService.djLinks(forEventID: "a")
        XCTAssertEqual(links.map(\.djID), ["d1"])
    }

    func test_EventService_djLinks_performance() async throws {
        let events = Make.many(500) { Make.event("e\($0)") }
        db.seed(events); db.seed(Make.many(5_000) { Make.link(event: events[$0 % 500], dj: "d\($0)") })
        db.resetCounters()
        let t = try await elapsed(iterations: 20) { _ = try await EventService.djLinks(forEventID: "e7") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_EventService_myEvents_security() async throws {
        let hosted = Make.event("hosted", host: "me"), playing = Make.event("playing", host: "x"), other = Make.event("other", host: "x")
        db.seed([hosted, playing, other]); db.seed([Make.link(event: playing, dj: "me"), Make.link(event: other, dj: "y")])
        let mine = try await EventService.myEvents()
        XCTAssertEqual(Set(mine.map(\.id)), ["hosted", "playing"], "hosted or on the lineup — nothing else")
        backend.auth.userID = nil
        do { _ = try await EventService.myEvents(); XCTFail("signed out") } catch {}
    }

    func test_EventService_myEvents_performance() async throws {
        let events = Make.many(300) { Make.event("e\($0)", host: $0 < 50 ? "me" : "x") }
        db.seed(events); db.seed(Make.many(300) { Make.link(event: events[$0], dj: "me") })
        db.resetCounters()
        let t = try await elapsed { _ = try await EventService.myEvents() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertLessThanOrEqual(db.queryCount, 2 + 250, "hosted + links + one by-id read per non-hosted lineup event")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_EventService_save_security() async throws {
        do { try await EventService.save(Make.event("e", host: "other")); XCTFail("saved another host's event") }
        catch { XCTAssertEqual(error as? EventServiceError, .notHost) }
        XCTAssertTrue(db.all(Event.self).isEmpty)
        try await EventService.save(Make.event("e", host: "me"))
        XCTAssertEqual(db.all(Event.self).count, 1)
    }

    func test_EventService_save_performance() async throws {
        let t = try await elapsed(iterations: 1_000) { try await EventService.save(Make.event("e", host: "me")) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventService_joinLineup_security() async throws {
        backend.rest.responses["/events/join"] = Data(#"{"success":true,"linkID":"e1_me","coinContribution":5}"#.utf8)
        _ = try await EventService.joinLineup(eventID: "e1")
        let sent = try XCTUnwrap(backend.rest.requests.last)
        XCTAssertEqual(sent.body.keys.sorted(), ["eventID"], "only the event — the server derives who is joining")
    }

    func test_EventService_joinLineup_performance() async throws {
        let t = try await elapsed(iterations: 1_000) { _ = try await EventService.joinLineup(eventID: "e1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventService_decodeJoin_security() {
        XCTAssertThrowsError(try EventService.decodeJoin(Data("<html>502</html>".utf8)))
        XCTAssertThrowsError(try EventService.decodeJoin(Data(#"{"success":false,"errorCode":"NOT_INVITED"}"#.utf8)))
        XCTAssertThrowsError(try EventService.decodeJoin(Data(#"{"success":"true"}"#.utf8)), "type confusion is not success")
    }

    func test_EventService_decodeJoin_performance() throws {
        let data = Data(#"{"success":true,"linkID":"l","coinContribution":5,"alreadyJoined":false}"#.utf8)
        let t = try elapsedSync(iterations: 20_000) { _ = try EventService.decodeJoin(data) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - FollowService

    func test_FollowService_follow_security() async throws {
        try await FollowService.follow(djID: "me")
        try await FollowService.follow(djID: "")
        XCTAssertTrue(db.all(UserFollows.self).isEmpty, "no self-follow, no empty follow")
        try await FollowService.follow(djID: "dj"); try await FollowService.follow(djID: "dj")
        let follows = db.all(UserFollows.self)
        XCTAssertEqual(follows.count, 1, "idempotent")
        XCTAssertEqual(follows.first?.followerID, "me", "follower is the session user")
    }

    func test_FollowService_follow_performance() async throws {
        db.seed(Make.many(2_000) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let t = try await elapsed(iterations: 100) { try await FollowService.follow(djID: "d5") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_FollowService_unfollow_security() async throws {
        db.seed([UserFollows(followerID: "other", followeeID: "dj", createdAt: Make.now())])
        try await FollowService.unfollow(djID: "dj")
        XCTAssertEqual(db.all(UserFollows.self).count, 1, "can't remove someone else's follow")
    }

    func test_FollowService_unfollow_performance() async throws {
        db.seed(Make.many(2_000) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let t = try await elapsed { for i in 0..<100 { try await FollowService.unfollow(djID: "d\(i)") } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_FollowService_isFollowing_security() async throws {
        db.seed([UserFollows(followerID: "other", followeeID: "dj", createdAt: Make.now())])
        let following = try await FollowService.isFollowing(djID: "dj")
        XCTAssertFalse(following, "someone else's follow isn't mine")
    }

    func test_FollowService_isFollowing_performance() async throws {
        db.seed(Make.many(5_000) { UserFollows(followerID: $0 % 2 == 0 ? "me" : "x", followeeID: "d\($0)", createdAt: Make.now()) })
        db.resetCounters()
        let t = try await elapsed(iterations: 20) { _ = try await FollowService.isFollowing(djID: "d4") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_FollowService_followedDJIDs_security() async {
        backend.auth.userID = nil
        do { _ = try await FollowService.followedDJIDs(); XCTFail("signed out") } catch {}
    }

    func test_FollowService_followedDJIDs_performance() async throws {
        db.seed(Make.many(5_000) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let t = try await elapsed { _ = try await FollowService.followedDJIDs() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_FollowService_followerCount_security() async {
        db.failNext = FakeError(tag: "x")
        let n = await FollowService.followerCount(for: "dj")
        XCTAssertEqual(n, 0, "an error shows 0, never a stale or invented count")
    }

    func test_FollowService_followerCount_performance() async {
        db.seed(Make.many(10_000) { UserFollows(followerID: "f\($0)", followeeID: $0 % 4 == 0 ? "dj" : "x", createdAt: Make.now()) })
        let t = await elapsed(iterations: 5) { _ = await FollowService.followerCount(for: "dj") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - MapService

    func test_MapService_venues_security() async throws {
        let me = Make.user("me", isDJ: false), other = Make.user("o", isDJ: false)
        db.seed([Make.venue("v1", owner: me), Make.venue("v2", owner: other)])
        let mine = try await MapService.venues(ownedBy: "me")
        XCTAssertEqual(mine.map(\.id), ["v1"])
    }

    func test_MapService_venues_performance() async throws {
        db.seed(Make.many(3_000) { Make.venue("v\($0)", owner: Make.user("o\($0 % 300)", isDJ: false)) })
        db.resetCounters()
        let t = try await elapsed { _ = try await MapService.venues(ownedBy: "o1") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0, "was a whole-table scan")
    }

    func test_MapService_approvedVenues_security() async throws {
        db.seed([Make.venue("ok"), Make.venue("pending", status: "pending"), Make.venue("rej", status: "rejected")])
        let pins = try await MapService.approvedVenues()
        XCTAssertEqual(pins.map(\.id), ["ok"], "unapproved venues never reach the public map")
    }

    func test_MapService_approvedVenues_performance() async throws {
        db.seed(Make.many(3_000) { Make.venue("v\($0)", status: $0 % 2 == 0 ? "approved" : "pending") })
        db.resetCounters()
        let t = try await elapsed { _ = try await MapService.approvedVenues() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_MapService_upcomingEvents_security() async throws {
        db.seed([Make.event("a", venueID: "v1", days: 3), Make.event("b", venueID: "v2", days: 3), Make.event("old", venueID: "v1", days: -3)])
        let at = try await MapService.upcomingEvents(atVenueIDs: ["v1"])
        XCTAssertEqual(at.map(\.id), ["a"])
        let none = try await MapService.upcomingEvents(atVenueIDs: [])
        XCTAssertTrue(none.isEmpty, "no venues → nothing, not everything")
    }

    func test_MapService_upcomingEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 50)", days: ($0 % 60) - 30) })
        db.resetCounters()
        let t = try await elapsed { _ = try await MapService.upcomingEvents(atVenueIDs: ["v1", "v2"]) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_MapService_allUpcomingEvents_security() async throws {
        db.seed([Make.event("past", days: -1), Make.event("next", days: 1)])
        let upcoming = try await MapService.allUpcomingEvents()
        XCTAssertEqual(upcoming.map(\.id), ["next"])
    }

    func test_MapService_allUpcomingEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", days: ($0 % 60) - 30) })
        db.resetCounters()
        let t = try await elapsed { _ = try await MapService.allUpcomingEvents() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_MapService_djLinks_security() async throws {
        let a = Make.event("a"), b = Make.event("b")
        db.seed([a, b]); db.seed([Make.link(event: a, dj: "d1"), Make.link(event: b, dj: "d2")])
        let links = try await MapService.djLinks(forEventIDs: ["a"])
        XCTAssertEqual(links.map(\.djID), ["d1"])
        let none = try await MapService.djLinks(forEventIDs: [])
        XCTAssertTrue(none.isEmpty, "an empty id set returns nothing")
    }

    func test_MapService_djLinks_performance() async throws {
        let events = Make.many(400) { Make.event("e\($0)") }
        db.seed(events); db.seed(Make.many(4_000) { Make.link(event: events[$0 % 400], dj: "d\($0)") })
        db.resetCounters()
        let ids = Set((0..<120).map { "e\($0)" })
        let t = try await elapsed { _ = try await MapService.djLinks(forEventIDs: ids) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.queryCount, 3, "120 ids in chunks of 50")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_MapService_user_security() async throws {
        let none = try await MapService.user(byId: "")
        XCTAssertNil(none)
    }

    func test_MapService_user_performance() async throws {
        db.seed(Make.many(5_000) { Make.user("u\($0)") })
        let t = try await elapsed(iterations: 1_000) { _ = try await MapService.user(byId: "u3") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapService_followedUserIDs_security() async throws {
        db.seed([UserFollows(followerID: "me", followeeID: "a", createdAt: Make.now()),
                 UserFollows(followerID: "x", followeeID: "b", createdAt: Make.now())])
        let ids = try await MapService.followedUserIDs(for: "me")
        XCTAssertEqual(ids, ["a"])
    }

    func test_MapService_followedUserIDs_performance() async throws {
        db.seed(Make.many(5_000) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let t = try await elapsed { _ = try await MapService.followedUserIDs(for: "me") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - SearchService

    func test_SearchService_search_security() async {
        db.seed([Make.user("a", username: "luna")]); db.seed([Make.venue("v", name: "Benga Box")])
        // Pattern-looking input is matched literally — no wildcard/regex expansion.
        let wild = await SearchService.search(query: ".*")
        XCTAssertTrue(wild.djs.isEmpty && wild.venues.isEmpty)
        let sql = await SearchService.search(query: "' OR 1=1 --")
        XCTAssertTrue(sql.djs.isEmpty)
        let ok = await SearchService.search(query: "  LUNA ")
        XCTAssertEqual(ok.djs.map(\.id), ["a"])
    }

    func test_SearchService_search_performance() async {
        db.seed(Make.many(5_000) { Make.user("u\($0)", username: "dj\($0)") })
        db.seed(Make.many(2_000) { Make.event("e\($0)", name: "Night \($0)") })
        let huge = String(repeating: "z", count: 1_000_000)
        let t = await elapsed(iterations: 10) {
            _ = await SearchService.search(query: "dj1")
            _ = await SearchService.search(query: huge)
        }
        XCTAssertLessThan(t, 3.0, "10 keystroke searches + 10 hostile 1MB queries: \(t)s")
    }

    func test_SearchService_fetchDJs_security() async {
        db.seed([Make.user("fan", isDJ: false, username: "luna"), Make.user("dj", username: "luna2")])
        let djs = await SearchService.fetchDJs(query: "luna")
        XCTAssertEqual(djs.map(\.id), ["dj"], "fans aren't searchable as DJs")
    }

    func test_SearchService_fetchDJs_performance() async {
        db.seed(Make.many(10_000) { Make.user("u\($0)", username: "dj\($0)") })
        let t = await elapsed(iterations: 5) { _ = await SearchService.fetchDJs(query: "dj") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        let capped = await SearchService.fetchDJs(query: "dj")
        XCTAssertEqual(capped.count, SearchService.resultLimit)
    }

    func test_SearchService_fetchEvents_security() async {
        db.seed([Make.event("past", days: -1, name: "Rave"), Make.event("next", days: 1, name: "Rave")])
        let events = await SearchService.fetchEvents(query: "rave")
        XCTAssertEqual(events.map(\.id), ["next"], "ended events aren't returned")
    }

    func test_SearchService_fetchEvents_performance() async {
        db.seed(Make.many(5_000) { Make.event("e\($0)", days: 5, name: "Rave \($0)") })
        let t = await elapsed(iterations: 5) { _ = await SearchService.fetchEvents(query: "rave") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_SearchService_fetchVenues_security() async {
        db.seed([Make.venue("ok", name: "Club"), Make.venue("p", status: "pending", name: "Club 2")])
        let venues = await SearchService.fetchVenues(query: "club")
        XCTAssertEqual(venues.map(\.id), ["ok"], "pending venues aren't searchable")
    }

    func test_SearchService_fetchVenues_performance() async {
        db.seed(Make.many(3_000) { Make.venue("v\($0)", name: "Club \($0)") })
        let t = await elapsed(iterations: 5) { _ = await SearchService.fetchVenues(query: "club") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - TicketService

    func test_TicketService_purchaseTicket_security() async throws {
        backend.rest.responses["/tickets/purchase"] = Data(#"{"success":true,"ticketID":"t1","remainingStock":9}"#.utf8)
        _ = try await TicketService.purchaseTicket(eventID: "e1", quantity: 9_999)
        let body = try XCTUnwrap(backend.rest.requests.last?.body)
        XCTAssertEqual(body["quantity"] as? Int, TicketService.maxPerRequest, "clamped to the server's limit")
        XCTAssertNil(body["userID"]); XCTAssertNil(body["price"]); XCTAssertNil(body["pricePaid"])
        _ = try await TicketService.purchaseTicket(eventID: "e1", quantity: -5)
        XCTAssertEqual(backend.rest.requests.last?.body["quantity"] as? Int, 1)
    }

    func test_TicketService_purchaseTicket_performance() async throws {
        backend.rest.responses["/tickets/purchase"] = Data(#"{"success":true}"#.utf8)
        let t = try await elapsed(iterations: 1_000) { _ = try await TicketService.purchaseTicket(eventID: "e1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_TicketService_decodePurchase_security() {
        XCTAssertThrowsError(try TicketService.decodePurchase(Data("not json".utf8)))
        XCTAssertThrowsError(try TicketService.decodePurchase(Data(#"{"success":false,"errorCode":"SOLD_OUT"}"#.utf8))) {
            XCTAssertEqual($0 as? TicketPurchaseError, .soldOut)
        }
        XCTAssertThrowsError(try TicketService.decodePurchase(Data(#"{"success":false,"errorCode":"<script>"}"#.utf8))) {
            XCTAssertEqual($0 as? TicketPurchaseError, .serverError("<script>"), "unknown codes don't map to success")
        }
    }

    func test_TicketService_decodePurchase_performance() throws {
        let d = Data(#"{"success":true,"ticketID":"t","remainingStock":3}"#.utf8)
        let t = try elapsedSync(iterations: 20_000) { _ = try TicketService.decodePurchase(d) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_TicketService_tickets_security() async throws {
        db.seed([Make.ticket("a", event: "e1", user: "u"), Make.ticket("b", event: "e2", user: "u")])
        let t = try await TicketService.tickets(for: "e1")
        XCTAssertEqual(t.map(\.id), ["a"])
    }

    func test_TicketService_tickets_performance() async throws {
        db.seed(Make.many(10_000) { Make.ticket("t\($0)", event: "e\($0 % 100)", user: "u\($0)") })
        db.resetCounters()
        let t = try await elapsed(iterations: 5) { _ = try await TicketService.tickets(for: "e5") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_TicketService_myTickets_security() async throws {
        db.seed([Make.ticket("mine", event: "e", user: "me"), Make.ticket("theirs", event: "e", user: "other")])
        let mine = try await TicketService.myTickets()
        XCTAssertEqual(mine.map(\.id), ["mine"], "only the session user's tickets")
    }

    func test_TicketService_myTickets_performance() async throws {
        db.seed(Make.many(10_000) { Make.ticket("t\($0)", event: "e", user: $0 % 100 == 0 ? "me" : "u\($0)") })
        let t = try await elapsed(iterations: 5) { _ = try await TicketService.myTickets() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - TransactionService

    func test_TransactionService_transactions_security() async throws {
        db.seed([Transaction(id: "a", fromUserID: "me", toUserID: "x", amount: 5, type: "dj_payout", createdAt: Make.now()),
                 Transaction(id: "b", fromUserID: "x", toUserID: "me", amount: 5, type: "dj_payout", createdAt: Make.now(-1)),
                 Transaction(id: "c", fromUserID: "x", toUserID: "y", amount: 5, type: "dj_payout", createdAt: Make.now())])
        let mine = try await TransactionService.transactions(for: "me")
        XCTAssertEqual(mine.map(\.id), ["a", "b"], "sent or received by me, newest first, nobody else's")
    }

    func test_TransactionService_transactions_performance() async throws {
        db.seed(Make.many(5_000) { Transaction(id: "t\($0)", fromUserID: $0 % 3 == 0 ? "me" : "x", toUserID: $0 % 5 == 0 ? "me" : "y",
                                                amount: 1, type: "dj_payout", createdAt: Make.now(-$0)) })
        let t = try await elapsed { _ = try await TransactionService.transactions(for: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        let rows = try await TransactionService.transactions(for: "me")
        XCTAssertEqual(rows.count, Set(rows.map(\.id)).count, "a self-transfer isn't counted twice")
    }

    func test_TransactionService_totalEarned_security() async throws {
        db.seed([Transaction(id: "a", fromUserID: "x", toUserID: "me", amount: 10, type: "dj_payout", createdAt: Make.now()),
                 Transaction(id: "r", fromUserID: "x", toUserID: "me", amount: 999, type: "refund", createdAt: Make.now())])
        let earned = try await TransactionService.totalEarned(by: "me")
        XCTAssertEqual(earned, 10, "refunds are not earnings")
    }

    func test_TransactionService_totalEarned_performance() async throws {
        db.seed(Make.many(10_000) { Transaction(id: "t\($0)", fromUserID: "x", toUserID: "me", amount: 1, type: "dj_payout", createdAt: Make.now()) })
        let t = try await elapsed { _ = try await TransactionService.totalEarned(by: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - VenueService

    private var meUser: User { Make.user("me", isDJ: false) }

    func test_VenueService_create_security() async throws {
        db.seed([meUser])
        let v = try await VenueService.create(name: "Club", description: "d", address: "1 St", latitude: -27.4, longitude: 153.0,
                                              maxCapacity: 300, imageKeys: [])
        XCTAssertEqual(v.approvalStatus, "pending", "a new venue is never self-approved")
        XCTAssertEqual(v.owner?.id, "me", "owner is the session user")
        for (cap, lat) in [(-1, 0.0), (0, 0.0), (1_000_000, 0.0), (100, 999.0)] {
            do { _ = try await VenueService.create(name: "X", description: "", address: "A", latitude: lat, longitude: 0,
                                                    maxCapacity: cap, imageKeys: []); XCTFail("accepted cap \(cap) lat \(lat)") }
            catch { XCTAssertTrue(error is VenueServiceError) }
        }
    }

    func test_VenueService_create_performance() async throws {
        db.seed([meUser])
        let t = try await elapsed(iterations: 500) {
            _ = try await VenueService.create(name: "Club", description: "d", address: "1 St", latitude: 0, longitude: 0, maxCapacity: 200, imageKeys: [])
        }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_validate_security() {
        XCTAssertThrowsError(try VenueService.validate(name: "  ", address: "a", latitude: 0, longitude: 0, maxCapacity: 10))
        XCTAssertThrowsError(try VenueService.validate(name: String(repeating: "n", count: 121), address: "a", latitude: 0, longitude: 0, maxCapacity: 10))
        XCTAssertThrowsError(try VenueService.validate(name: "n", address: "a", latitude: .nan, longitude: 0, maxCapacity: 10))
        XCTAssertNoThrow(try VenueService.validate(name: "n", address: "a", latitude: -90, longitude: 180, maxCapacity: 100_000))
    }

    func test_VenueService_validate_performance() throws {
        let t = try elapsedSync(iterations: 100_000) {
            try VenueService.validate(name: "Benga Box", address: "1 Ann St", latitude: -27.4, longitude: 153.0, maxCapacity: 500)
        }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_requireOwner_security() async throws {
        do { try await VenueService.requireOwner(of: Make.venue("v", owner: Make.user("x"))); XCTFail() }
        catch { XCTAssertEqual(error as? VenueServiceError, .notOwner) }
        do { try await VenueService.requireOwner(of: Make.venue("v", owner: nil)); XCTFail("ownerless venue is nobody's") } catch {}
        try await VenueService.requireOwner(of: Make.venue("v", owner: meUser))
    }

    func test_VenueService_requireOwner_performance() async throws {
        let v = Make.venue("v", owner: meUser)
        let t = try await elapsed(iterations: 5_000) { try await VenueService.requireOwner(of: v) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_update_security() async throws {
        db.seed([Make.venue("mine", owner: meUser, status: "pending"), Make.venue("theirs", owner: Make.user("x"))])
        // Self-approval attempt: the stored status wins.
        var edited = try XCTUnwrap(db.all(Venue.self).first { $0.id == "mine" })
        edited.approvalStatus = "approved"; edited.name = "New name"
        let saved = try await VenueService.update(edited)
        XCTAssertEqual(saved.approvalStatus, "pending", "no self-approval")
        XCTAssertEqual(saved.name, "New name", "normal edits still apply")
        var hijack = try XCTUnwrap(db.all(Venue.self).first { $0.id == "theirs" }); hijack.name = "pwned"
        do { _ = try await VenueService.update(hijack); XCTFail("edited another owner's venue") }
        catch { XCTAssertEqual(error as? VenueServiceError, .notOwner) }
    }

    func test_VenueService_update_performance() async throws {
        let v = Make.venue("mine", owner: meUser); db.seed([v])
        let t = try await elapsed(iterations: 500) { _ = try await VenueService.update(v) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_fetch_security() async throws {
        let none = try await VenueService.fetch(byId: "../v1")
        XCTAssertNil(none)
    }

    func test_VenueService_fetch_performance() async throws {
        db.seed(Make.many(3_000) { Make.venue("v\($0)") })
        let t = try await elapsed(iterations: 1_000) { _ = try await VenueService.fetch(byId: "v7") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_fetchOwned_security() async throws {
        db.seed([Make.venue("a", owner: meUser), Make.venue("b", owner: Make.user("x"))])
        let owned = try await VenueService.fetchOwned(by: "me")
        XCTAssertEqual(owned.map(\.id), ["a"])
    }

    func test_VenueService_fetchOwned_performance() async throws {
        db.seed(Make.many(3_000) { Make.venue("v\($0)", owner: Make.user("o\($0 % 100)")) })
        db.resetCounters()
        let t = try await elapsed { _ = try await VenueService.fetchOwned(by: "o1") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_VenueService_fetchApproved_security() async throws {
        db.seed([Make.venue("ok"), Make.venue("no", status: "pending")])
        let v = try await VenueService.fetchApproved()
        XCTAssertEqual(v.map(\.id), ["ok"])
    }

    func test_VenueService_fetchApproved_performance() async throws {
        db.seed(Make.many(3_000) { Make.venue("v\($0)", status: $0 % 2 == 0 ? "approved" : "pending") })
        let t = try await elapsed { _ = try await VenueService.fetchApproved() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_VenueService_fetchUpcomingEvents_security() async throws {
        db.seed([Make.event("a", venueID: "v1", days: 2), Make.event("old", venueID: "v1", days: -2), Make.event("b", venueID: "v2", days: 2)])
        let e = try await VenueService.fetchUpcomingEvents(venueID: "v1")
        XCTAssertEqual(e.map(\.id), ["a"])
    }

    func test_VenueService_fetchUpcomingEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 20)", days: ($0 % 100) - 50) })
        let t = try await elapsed { _ = try await VenueService.fetchUpcomingEvents(venueID: "v1") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_VenueService_geocode_security() async {
        // Rejected before any request reaches Apple's rate-limited geocoder.
        for bad in ["", "   \n", String(repeating: "a", count: 10_000)] {
            do { _ = try await VenueService.geocode(address: bad); XCTFail("geocoded \(bad.prefix(10))") }
            catch { XCTAssertTrue(error is VenueServiceError) }
        }
    }

    func test_VenueService_geocode_performance() async {
        let hostile = String(repeating: "a", count: 1_000_000)
        let t = await elapsed(iterations: 100) { _ = try? await VenueService.geocode(address: hostile) }
        XCTAssertLessThan(t, 3.0, "100 rejected 1MB addresses, no network: \(t)s")
    }

    func test_VenueService_reverseGeocode_security() async {
        do { _ = try await VenueService.reverseGeocode(CLLocation(latitude: 999, longitude: 0)); XCTFail() }
        catch { XCTAssertTrue(error is VenueServiceError, "invalid coordinates never sent") }
    }

    func test_VenueService_reverseGeocode_performance() async {
        let bad = CLLocation(latitude: -999, longitude: 999)
        let t = await elapsed(iterations: 10_000) { _ = try? await VenueService.reverseGeocode(bad) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueService_uploadImages_security() async throws {
        db.seed([Make.venue("theirs", owner: Make.user("x"))])
        do { _ = try await VenueService.uploadImages([image(10, 10)], venueID: "theirs"); XCTFail("uploaded into another owner's venue") }
        catch { XCTAssertEqual(error as? VenueServiceError, .notOwner) }
        do { _ = try await VenueService.uploadImages(Array(repeating: image(5, 5), count: 11), venueID: "new"); XCTFail("no photo cap") }
        catch { XCTAssertTrue(error is VenueServiceError) }
        let keys = try await VenueService.uploadImages([image(10, 10)], venueID: "brand-new")
        XCTAssertTrue(keys[0].hasPrefix("venues/brand-new/img-"), "a new application may upload before the record exists")
    }

    func test_VenueService_uploadImages_performance() async throws {
        let photos = Array(repeating: image(4_032, 3_024), count: 3)
        let t = try await elapsed { _ = try await VenueService.uploadImages(photos, venueID: "new") }
        XCTAssertLessThan(t, 8.0, "3 × 12MP: \(t)s")
        let maxBytes = backend.storage.uploads.map(\.bytes).max() ?? 0
        XCTAssertLessThan(maxBytes, 2_000_000, "downscaled to poster size, not full-res (\(maxBytes) B)")
    }

    func test_VenueService_saveCompliance_security() async throws {
        db.seed([Make.venue("theirs", owner: Make.user("x")), Make.venue("mine", owner: meUser)])
        do { try await VenueService.saveCompliance(venueID: "theirs", licenseType: "L", contractorName: "C"); XCTFail() }
        catch { XCTAssertEqual(error as? VenueServiceError, .notOwner) }
        do { try await VenueService.saveCompliance(venueID: "mine", licenseType: String(repeating: "x", count: 500), contractorName: ""); XCTFail() }
        catch { XCTAssertTrue(error is VenueServiceError) }
        try await VenueService.saveCompliance(venueID: "mine", licenseType: " Liquor ", contractorName: " Sec Co ")
        let s = try XCTUnwrap(db.all(VenueComplianceSubmission.self).first)
        XCTAssertEqual(s.status, "pending_review", "a submission is never self-approved")
        XCTAssertEqual(s.licenseType, "Liquor")
    }

    func test_VenueService_saveCompliance_performance() async throws {
        db.seed([Make.venue("mine", owner: meUser)])
        let t = try await elapsed(iterations: 500) { try await VenueService.saveCompliance(venueID: "mine", licenseType: "L", contractorName: "C") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }
}
