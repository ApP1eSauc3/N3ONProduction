// RankWeightTests.swift
// N3ONTests
//
// Pins the coin-weight table (0 / 5 / 7 / 10 / 25). Must stay in lockstep
// with the joinEvent Lambda's WEIGHTS constant — same cases as
// lambda-tests/join.test.js "weight table matches RankWeight.swift".

import XCTest
@testable import N3ON

final class RankWeightTests: XCTestCase {

    func testDocumentedWeightTable() {
        XCTAssertEqual(RankWeight.coins(forRank: 2), 5)
        XCTAssertEqual(RankWeight.coins(forRank: 3), 7)
        XCTAssertEqual(RankWeight.coins(forRank: 4), 10)
        XCTAssertEqual(RankWeight.coins(forRank: 5), 25)
    }

    func testUnrankedAndRank1ContributeNothing() {
        XCTAssertEqual(RankWeight.coins(forRank: 0), 0)
        XCTAssertEqual(RankWeight.coins(forRank: 1), 0)
        XCTAssertEqual(RankWeight.coins(forRank: -1), 0)
    }

    func testRanksAbove5UseHostWeight() {
        XCTAssertEqual(RankWeight.coins(forRank: 6), 25)
    }
}
