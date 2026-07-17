// CurationServiceTests.swift
// N3ONTests
//
// The curation gate is the launch-critical switch: flipping
// CurationConfig.platformMode from .curated to .community must re-enforce
// every ranking rule with no other change. These tests pin both modes.

import XCTest
@testable import N3ON

final class CurationServiceTests: XCTestCase {

    // MARK: — Rank ≥ 4 hosts in every mode

    func testRank4CanCreateInBothModes() {
        let dj = Fixtures.user(rank: 4)
        XCTAssertTrue(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .curated))
        XCTAssertTrue(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .community))
    }

    func testRank5CanCreateInBothModes() {
        let dj = Fixtures.user(rank: 5)
        XCTAssertTrue(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .curated))
        XCTAssertTrue(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .community))
    }

    // MARK: — Curated-mode overrides

    func testCuratedDJBelowRank4CanCreateOnlyInCuratedMode() {
        let dj = Fixtures.user(rank: 1, isCurated: true)
        XCTAssertTrue(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .curated))
        XCTAssertFalse(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .community))
    }

    func testAdminBelowRank4CanCreateOnlyInCuratedMode() {
        let admin = Fixtures.user(rank: nil)
        XCTAssertTrue(CurationService.canCreateEvent(user: admin, isAdmin: true, mode: .curated))
        XCTAssertFalse(CurationService.canCreateEvent(user: admin, isAdmin: true, mode: .community))
    }

    // MARK: — Denials

    func testUncuratedLowRankDJDeniedInBothModes() {
        let dj = Fixtures.user(rank: 3)
        XCTAssertFalse(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .curated))
        XCTAssertFalse(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .community))
    }

    func testNilRankTreatedAsZero() {
        let dj = Fixtures.user(rank: nil)
        XCTAssertFalse(CurationService.canCreateEvent(user: dj, isAdmin: false, mode: .community))
    }

    // MARK: — Tally gate

    func testTallyEnforcedOnlyInCommunityMode() {
        XCTAssertFalse(CurationService.tallyEnforced(in: .curated))
        XCTAssertTrue(CurationService.tallyEnforced(in: .community))
    }

    /// Pins the live config: the app currently runs in curated (bootstrap) mode.
    /// When the platform flips to community, update CurationConfig — this test
    /// documents that the flip is deliberate, not accidental.
    func testLiveConfigIsCuratedBootstrapMode() {
        XCTAssertEqual(CurationConfig.platformMode, .curated)
        XCTAssertFalse(CurationService.tallyEnforced)
    }
}
