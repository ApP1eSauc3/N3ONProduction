// EndorsementServiceTests.swift
// N3ONTests
//
// F8 (LEAN-RESEARCH.md): the candidate's progress display must count
// endorsements the way rankPromotion does — distinct endorsers, no
// self-endorsement, no rows created pre-approved, endorser rank ≥ target —
// not raw `status == "approved"` rows. Server side: lambda-tests/rank.test.js.

import XCTest
import Amplify
@testable import N3ON

final class EndorsementServiceTests: XCTestCase {

    private let candidateID = "cand"
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func dj(_ id: String, rank: Int, isDJ: Bool = true) -> User {
        User(id: id, username: id, isDJ: isDJ, djRank: rank, isCurated: false,
             isSharingLocation: false, coinBalance: 0)
    }

    /// A synced request. `touched: false` = updatedAt == createdAt (never
    /// written after creation — what a candidate-forged approval looks like).
    private func request(
        to endorser: User,
        from candidate: User? = nil,
        targetRank: Int = 2,
        status: String = "approved",
        touched: Bool = true,
        synced: Bool = true
    ) -> EndorsementRequest {
        let createdAt = Temporal.DateTime(created, timeZone: .current)
        let updatedAt = Temporal.DateTime(created.addingTimeInterval(touched ? 60 : 0), timeZone: .current)
        return EndorsementRequest(
            fromUser: candidate ?? dj(candidateID, rank: targetRank - 1),
            toUser: endorser,
            targetRank: targetRank,
            message: "",
            status: status,
            timestamp: createdAt,
            createdAt: synced ? createdAt : nil,
            updatedAt: synced ? updatedAt : nil
        )
    }

    private func count(_ requests: [EndorsementRequest], target: Int = 2) -> Int {
        EndorsementService.countedEndorsers(in: requests, candidateID: candidateID, targetRank: target)
    }

    func testCountsDistinctGenuineEndorsers() {
        let a = dj("a", rank: 2), b = dj("b", rank: 3)
        XCTAssertEqual(count([request(to: a), request(to: b)]), 2)
    }

    func testDuplicateApprovalsFromOneEndorserCountOnce() {
        let a = dj("a", rank: 2)
        XCTAssertEqual(count([request(to: a), request(to: a), request(to: a)]), 1)
    }

    func testSelfEndorsementDoesNotCount() {
        let me = dj(candidateID, rank: 2)
        XCTAssertEqual(count([request(to: me, from: me)]), 0)
    }

    func testRowCreatedAlreadyApprovedDoesNotCount() {
        let a = dj("a", rank: 2)
        XCTAssertEqual(count([request(to: a, touched: false)]), 0, "updatedAt == createdAt: a forgery")
        XCTAssertEqual(count([request(to: a, synced: false)]), 0, "unsynced: no server timestamps yet")
    }

    func testEndorserMustBeAnActiveDJAtTargetRankOrAbove() {
        XCTAssertEqual(count([request(to: dj("junior", rank: 1))]), 0)
        XCTAssertEqual(count([request(to: dj("exdj", rank: 3, isDJ: false))]), 0)
        XCTAssertEqual(count([request(to: dj("senior", rank: 5))]), 1, "server accepts rank ≥ target")
    }

    func testOnlyApprovedRowsForThisTargetCount() {
        let a = dj("a", rank: 4)
        XCTAssertEqual(count([request(to: a, status: "pending"), request(to: a, status: "rejected")]), 0)
        XCTAssertEqual(count([request(to: a, targetRank: 3)], target: 2), 0)
    }

    func testCanEndorseMirrorsServerRule() {
        XCTAssertTrue(EndorsementService.canEndorse(dj("x", rank: 2), targetRank: 2))
        XCTAssertTrue(EndorsementService.canEndorse(dj("x", rank: 4), targetRank: 2))
        XCTAssertFalse(EndorsementService.canEndorse(dj("x", rank: 1), targetRank: 2))
        XCTAssertFalse(EndorsementService.canEndorse(dj("x", rank: 4, isDJ: false), targetRank: 2))
    }
}
