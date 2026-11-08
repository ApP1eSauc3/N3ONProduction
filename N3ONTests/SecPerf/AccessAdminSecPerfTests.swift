// AccessAdminSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for AccessControlService, AdminService,
// ChatEligibilityService and CurationService — the client-side trust
// boundaries (MASVS-AUTH). Each runs the real service against FakeBackend.

import XCTest
import Amplify
@testable import N3ON

final class AccessAdminSecPerfTests: BackendTestCase {

    private func signIn(groups: [String]?) {
        backend.auth.userID = "me"
        backend.auth.idToken = FakeAuth.token(groups: groups)
    }

    // MARK: - AccessControlService

    func test_AccessControlService_currentUserRole_security() async {
        // Roles come only from the token's groups; unknown or forged-looking
        // claims fall back to the least privileged role.
        signIn(groups: ["VenueOwnerUser", "DJUser"])
        let venue = await AccessControlService.currentUserRole()
        XCTAssertEqual(venue, .venue, "venue wins over dj")
        signIn(groups: ["SuperAdmin", "root"])
        let unknown = await AccessControlService.currentUserRole()
        XCTAssertEqual(unknown, .regular)
        backend.auth.idToken = "not-a-jwt"
        let malformed = await AccessControlService.currentUserRole()
        XCTAssertEqual(malformed, .regular)
        backend.auth.userID = nil; backend.auth.idToken = nil
        let signedOut = await AccessControlService.currentUserRole()
        XCTAssertEqual(signedOut, .regular)
    }

    func test_AccessControlService_currentUserRole_performance() async {
        signIn(groups: ["DJUser"])
        let t = await elapsed(iterations: 2_000) { _ = await AccessControlService.currentUserRole() }
        XCTAssertLessThan(t, 2.0, "2k role resolutions: \(t)s")
    }

    func test_AccessControlService_role_security() async {
        // isDJ on the profile can't promote anyone to venue; venue needs the group.
        signIn(groups: ["UserGroup"])
        let dj = await AccessControlService.role(for: Make.user("me", isDJ: true))
        XCTAssertEqual(dj, .dj)
        let none = await AccessControlService.role(for: nil)
        XCTAssertEqual(none, .regular)
        signIn(groups: ["VenueOwnerUser"])
        let venue = await AccessControlService.role(for: Make.user("me", isDJ: false))
        XCTAssertEqual(venue, .venue)
    }

    func test_AccessControlService_role_performance() async {
        signIn(groups: ["UserGroup"])
        let u = Make.user("me")
        let t = await elapsed(iterations: 2_000) { _ = await AccessControlService.role(for: u) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AccessControlService_isAdmin_security() async {
        signIn(groups: ["DJUser"])
        let notAdmin = await AccessControlService.isAdmin()
        XCTAssertFalse(notAdmin)
        signIn(groups: ["adminuser"])   // case matters: Cognito group names are exact
        let wrongCase = await AccessControlService.isAdmin()
        XCTAssertFalse(wrongCase)
        backend.auth.idToken = FakeAuth.token(groups: nil, extra: ["cognito:groups": "AdminUser"])
        let stringClaim = await AccessControlService.isAdmin()
        XCTAssertFalse(stringClaim, "a non-array claim is not trusted")
        signIn(groups: ["AdminUser"])
        let admin = await AccessControlService.isAdmin()
        XCTAssertTrue(admin)
    }

    func test_AccessControlService_isAdmin_performance() async {
        signIn(groups: ["AdminUser"])
        let t = await elapsed(iterations: 2_000) { _ = await AccessControlService.isAdmin() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AccessControlService_currentGroups_security() async {
        backend.auth.failNext = FakeError(tag: "network")
        let onError = await AccessControlService.currentGroups()
        XCTAssertEqual(onError, [], "fails closed")
        signIn(groups: ["DJUser", "AdminUser"])
        let groups = await AccessControlService.currentGroups()
        XCTAssertEqual(groups, ["DJUser", "AdminUser"])
    }

    func test_AccessControlService_currentGroups_performance() async {
        signIn(groups: Make.many(50) { "Group\($0)" })
        let t = await elapsed(iterations: 1_000) { _ = await AccessControlService.currentGroups() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AccessControlService_validateTicket_security() async {
        let e1 = Make.event("e1"), e2 = Make.event("e2")
        db.seed([e1, e2])
        db.seed([Make.ticket("t1", event: "e2", user: "fan")])
        let otherEvent = await AccessControlService.validateTicket(userID: "fan", eventID: "e1")
        XCTAssertFalse(otherEvent, "a ticket for another event does not admit")
        let empty = await AccessControlService.validateTicket(userID: "", eventID: "e2")
        XCTAssertFalse(empty)
        let injected = await AccessControlService.validateTicket(userID: "fan' OR '1'='1", eventID: "e2")
        XCTAssertFalse(injected)
        let ok = await AccessControlService.validateTicket(userID: "fan", eventID: "e2")
        XCTAssertTrue(ok)
        db.failNext = FakeError(tag: "x")
        let onError = await AccessControlService.validateTicket(userID: "fan", eventID: "e2")
        XCTAssertFalse(onError, "fails closed")
    }

    func test_AccessControlService_validateTicket_performance() async {
        db.seed(Make.many(5_000) { Make.ticket("t\($0)", event: $0 % 10 == 0 ? "big" : "e\($0)", user: "u\($0)") })
        db.resetCounters()
        let t = await elapsed(iterations: 20) { _ = await AccessControlService.validateTicket(userID: "u4990", eventID: "big") }
        XCTAssertLessThan(t, 2.0, "20 scans over 5k tickets: \(t)s")
        XCTAssertEqual(db.queryCount, 20, "one query per scan")
    }

    func test_AccessControlService_decodeJWT_security() {
        XCTAssertNil(AccessControlService.decodeJWT(""))
        XCTAssertNil(AccessControlService.decodeJWT("onlyonesegment"))
        XCTAssertNil(AccessControlService.decodeJWT("a.!!!notbase64!!!.c"))
        XCTAssertNil(AccessControlService.decodeJWT("a.\(Data("[1,2]".utf8).base64EncodedString()).c"), "payload must be an object")
        let huge = "a." + String(repeating: "A", count: AccessControlService.maxTokenBytes) + ".c"
        XCTAssertNil(AccessControlService.decodeJWT(huge), "oversized tokens are not decoded")
        let good = FakeAuth.token(groups: ["DJUser"])
        XCTAssertEqual(AccessControlService.decodeJWT(good)?["cognito:groups"] as? [String], ["DJUser"])
    }

    func test_AccessControlService_decodeJWT_performance() {
        let token = FakeAuth.token(groups: ["DJUser"], extra: ["sub": UUID().uuidString, "email": "a@b.co"])
        let huge = "a." + String(repeating: "A", count: 1_000_000) + ".c"
        let t = elapsedSync(iterations: 10_000) {
            _ = AccessControlService.decodeJWT(token)
            _ = AccessControlService.decodeJWT(huge)
        }
        XCTAssertLessThan(t, 3.0, "10k decodes + 10k rejected 1MB tokens: \(t)s")
    }

    // MARK: - AdminService

    func test_AdminService_requireAdmin_security() async {
        signIn(groups: ["DJUser"])
        do { try await AdminService.requireAdmin(); XCTFail("non-admin passed") }
        catch { XCTAssertEqual(error as? AdminError, .notAuthorized) }
        signIn(groups: ["AdminUser"])
        do { try await AdminService.requireAdmin() } catch { XCTFail("admin refused: \(error)") }
    }

    func test_AdminService_requireAdmin_performance() async throws {
        signIn(groups: ["AdminUser"])
        let t = try await elapsed(iterations: 2_000) { try await AdminService.requireAdmin() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminService_allDJs_security() async throws {
        // Regular users never appear in the DJ roster the console can rank.
        db.seed([Make.user("a", isDJ: true), Make.user("fan", isDJ: false)])
        let djs = try await AdminService.allDJs()
        XCTAssertEqual(djs.map(\.id), ["a"])
    }

    func test_AdminService_allDJs_performance() async throws {
        db.seed(Make.many(5_000) { Make.user("u\($0)", isDJ: $0 % 2 == 0, username: "dj\(5_000 - $0)") })
        let t = try await elapsed { _ = try await AdminService.allDJs() }
        XCTAssertLessThan(t, 1.0, "5k users filtered + sorted: \(t)s")
    }

    func test_AdminService_allEvents_security() async throws {
        db.failNext = FakeError(tag: "x")
        do { _ = try await AdminService.allEvents(); XCTFail("errors must surface, not show an empty console") } catch {}
    }

    func test_AdminService_allEvents_performance() async throws {
        db.seed(Make.many(5_000) { Make.event("e\($0)", days: $0 % 365) })
        let t = try await elapsed { _ = try await AdminService.allEvents() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_AdminService_setDJRank_security() async throws {
        let dj = Make.user("d", rank: 1)
        db.seed([dj])
        signIn(groups: ["DJUser"])
        do { _ = try await AdminService.setDJRank(5, for: dj); XCTFail("non-admin re-ranked a DJ") }
        catch { XCTAssertEqual(error as? AdminError, .notAuthorized) }
        XCTAssertEqual(db.all(User.self).first?.djRank, 1, "nothing written")
        signIn(groups: ["AdminUser"])
        _ = try await AdminService.setDJRank(4, for: dj)
        XCTAssertEqual(db.all(User.self).first?.djRank, 4)
    }

    func test_AdminService_setDJRank_performance() async throws {
        signIn(groups: ["AdminUser"])
        let djs = Make.many(200) { Make.user("d\($0)", rank: 1) }
        db.seed(djs)
        let t = try await elapsed { for d in djs { _ = try await AdminService.setDJRank(2, for: d) } }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.saveCount, 200)
    }

    func test_AdminService_setCurated_security() async throws {
        let dj = Make.user("d")
        db.seed([dj])
        signIn(groups: nil)
        do { _ = try await AdminService.setCurated(true, for: dj); XCTFail("non-admin curated a DJ") } catch {}
        XCTAssertEqual(db.all(User.self).first?.isCurated, false)
    }

    func test_AdminService_setCurated_performance() async throws {
        signIn(groups: ["AdminUser"])
        let dj = Make.user("d"); db.seed([dj])
        let t = try await elapsed(iterations: 200) { _ = try await AdminService.setCurated(true, for: dj) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminService_setFeatured_security() async throws {
        let e = Make.event("e"); db.seed([e])
        signIn(groups: ["VenueOwnerUser"])
        do { _ = try await AdminService.setFeatured(true, for: e); XCTFail("non-admin featured an event") } catch {}
        XCTAssertEqual(db.all(Event.self).first?.isFeatured, false)
    }

    func test_AdminService_setFeatured_performance() async throws {
        signIn(groups: ["AdminUser"])
        let e = Make.event("e"); db.seed([e])
        let t = try await elapsed(iterations: 200) { _ = try await AdminService.setFeatured(true, for: e) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminService_forcePublish_security() async throws {
        db.seed([Make.event("e", status: "pending")])
        signIn(groups: ["DJUser"])
        do { try await AdminService.forcePublish(eventID: "e"); XCTFail("non-admin published") } catch {}
        XCTAssertEqual(db.all(Event.self).first?.status, "pending")
        signIn(groups: ["AdminUser"])
        do { try await AdminService.forcePublish(eventID: "missing"); XCTFail() }
        catch { XCTAssertEqual(error as? AdminError, .eventNotFound) }
    }

    func test_AdminService_forcePublish_performance() async throws {
        signIn(groups: ["AdminUser"])
        db.seed(Make.many(1_000) { Make.event("e\($0)", status: "pending") })
        db.resetCounters()
        let t = try await elapsed { try await AdminService.forcePublish(eventID: "e500") }
        XCTAssertLessThan(t, 0.5, "\(t)s")
        XCTAssertEqual(db.queryCount, 1, "by-id read, not a scan")
    }

    func test_AdminService_attachDJ_security() async throws {
        let e = Make.event("e"); db.seed([e])
        signIn(groups: nil)
        do { try await AdminService.attachDJ(Make.user("d"), toEventID: "e"); XCTFail("non-admin attached") } catch {}
        XCTAssertTrue(db.all(EventDJLink.self).isEmpty)
        signIn(groups: ["AdminUser"])
        try await AdminService.attachDJ(Make.user("d", rank: 99), toEventID: "e")
        try await AdminService.attachDJ(Make.user("d", rank: 99), toEventID: "e")
        let links = db.all(EventDJLink.self)
        XCTAssertEqual(links.count, 1, "idempotent — no double tally")
        XCTAssertLessThanOrEqual(links[0].coinContribution, 25, "corrupt rank can't mint coins")
    }

    func test_AdminService_attachDJ_performance() async throws {
        signIn(groups: ["AdminUser"])
        let e = Make.event("e"); db.seed([e])
        db.seed(Make.many(2_000) { Make.link(event: e, dj: "d\($0)") })
        let t = try await elapsed { try await AdminService.attachDJ(Make.user("new"), toEventID: "e") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - ChatEligibilityService

    func test_ChatEligibilityService_check_security() async {
        // A regular user can't open any chat, whatever ids they pass.
        let fan = await ChatEligibilityService.check(currentUserID: "fan", currentRole: .regular,
                                                     recipientUserID: "dj", recipientRole: .dj)
        XCTAssertEqual(fan, .ineligible(reason: .regularUserCannotChat))
        // A DJ claiming a venue chat with no shared event is refused.
        let noEvent = await ChatEligibilityService.check(currentUserID: "dj", currentRole: .dj,
                                                         recipientUserID: "venueOwner", recipientRole: .venue)
        XCTAssertEqual(noEvent, .ineligible(reason: .noSharedActiveEvent))
    }

    func test_ChatEligibilityService_check_performance() async {
        let t = await elapsed(iterations: 5_000) {
            _ = await ChatEligibilityService.check(currentUserID: "a", currentRole: .dj, recipientUserID: "b", recipientRole: .dj)
        }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_ChatEligibilityService_isEventExpired_security() {
        // The window can't be extended by a far-future date: it is never "expired",
        // and a past one beyond 48h is.
        XCTAssertFalse(ChatEligibilityService.isEventExpired(eventDate: .distantFuture))
        XCTAssertTrue(ChatEligibilityService.isEventExpired(eventDate: .distantPast))
        XCTAssertTrue(ChatEligibilityService.isEventExpired(eventDate: Date().addingTimeInterval(-chatEventExpiryInterval - 1)))
    }

    func test_ChatEligibilityService_isEventExpired_performance() {
        let d = Date()
        let t = elapsedSync(iterations: 1_000_000) { _ = ChatEligibilityService.isEventExpired(eventDate: d) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_ChatEligibilityService_checkDJVenue_security() async {
        let owner = Make.user("owner", isDJ: false), other = Make.user("other", isDJ: false)
        let mine = Make.venue("v1", owner: owner), theirs = Make.venue("v2", owner: other)
        let atMine = Make.event("e1", venueID: "v1", days: 5), atTheirs = Make.event("e2", venueID: "v2", days: 5)
        db.seed([owner, other]); db.seed([mine, theirs]); db.seed([atMine, atTheirs])
        db.seed([Make.link(event: atTheirs, dj: "dj")])
        // The DJ is on a lineup — but at someone else's venue: no chat with this owner.
        let wrongVenue = await ChatEligibilityService.checkDJVenue(djUserID: "dj", venueUserID: "owner")
        XCTAssertEqual(wrongVenue, .ineligible(reason: .noSharedActiveEvent))
        db.seed([Make.link(event: atMine, dj: "dj")])
        let ok = await ChatEligibilityService.checkDJVenue(djUserID: "dj", venueUserID: "owner")
        XCTAssertEqual(ok, .eligible(type: .djToVenue(eventID: "e1")))
        db.failNext = FakeError(tag: "x")
        let onError = await ChatEligibilityService.checkDJVenue(djUserID: "dj", venueUserID: "owner")
        XCTAssertEqual(onError, .ineligible(reason: .noSharedActiveEvent), "fails closed")
    }

    func test_ChatEligibilityService_checkDJVenue_performance() async {
        let owner = Make.user("owner", isDJ: false); db.seed([owner])
        db.seed([Make.venue("v1", owner: owner)])
        let events = Make.many(3_000) { Make.event("e\($0)", venueID: $0 == 2_999 ? "v1" : "vx\($0)", days: 5) }
        db.seed(events)
        db.seed(Make.many(3_000) { Make.link(event: events[$0], dj: $0 % 3 == 0 ? "dj" : "x\($0)") })
        db.resetCounters()
        let t = await elapsed { _ = await ChatEligibilityService.checkDJVenue(djUserID: "dj", venueUserID: "owner") }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.queryCount, 3, "links by DJ, venues by owner, events per owned venue")
        XCTAssertEqual(db.unfilteredQueryCount, 0, "no whole-table scans (the old code made 3)")
    }

    // MARK: - CurationService

    func test_CurationService_canCreateEvent_security() {
        // Community mode: curation and admin flags grant nothing below rank 4.
        let curated = Make.user("c", rank: 1, curated: true)
        XCTAssertFalse(CurationService.canCreateEvent(user: curated, isAdmin: true, mode: .community))
        XCTAssertFalse(CurationService.canCreateEvent(user: Make.user("x", rank: nil), isAdmin: false, mode: .curated))
        XCTAssertTrue(CurationService.canCreateEvent(user: Make.user("r", rank: 4), isAdmin: false, mode: .community))
    }

    func test_CurationService_canCreateEvent_performance() {
        let u = Make.user("u", rank: 2)
        let t = elapsedSync(iterations: 1_000_000) { _ = CurationService.canCreateEvent(user: u, isAdmin: false, mode: .curated) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_CurationService_tallyEnforced_security() {
        XCTAssertTrue(CurationService.tallyEnforced(in: .community), "community always enforces the tally")
        XCTAssertFalse(CurationService.tallyEnforced(in: .curated))
    }

    func test_CurationService_tallyEnforced_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = CurationService.tallyEnforced(in: .community) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }
}
