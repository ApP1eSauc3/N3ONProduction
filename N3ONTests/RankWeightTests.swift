// RankWeightTests.swift
// N3ONTests
//
// Pins the bootstrap coin-weight table (0 / 5 / 7 / 10 / 25) that admin
// lineup curation stamps onto EventDJLink records. Must stay in lockstep
// with the Lambda's RankWeights DynamoDB config.

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
