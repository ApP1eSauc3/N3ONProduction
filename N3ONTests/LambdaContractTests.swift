// LambdaContractTests.swift
// N3ONTests
//
// Pins the client side of the n3onAPI Lambda contracts: the event-invite wire
// format the joinEvent Lambda re-parses, the error-code → error mapping, and
// envelope decoding. The server side of each contract is tested in Node
// (amplify/backend/function/*/src); change both together.

import XCTest
@testable import N3ON

final class LambdaContractTests: XCTestCase {

    // MARK: - EventInvitePayload

    func testInviteRoundTripsThroughMessageContent() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let payload = EventInvitePayload(eventID: "ev1", eventName: "Warehouse", venueName: "Benga Box", eventDate: date)
        let content = try XCTUnwrap(payload.encodedContent())
        XCTAssertEqual(EventInvitePayload.parse(content), payload)
        XCTAssertEqual(payload.date, date)
        XCTAssertTrue(content.contains("\"type\":\"event_invite\""))
    }

    /// The bug this replaced: detection used hasPrefix("{\"type\":\"event_invite\"")
    /// but JSONSerialization does not guarantee key order.
    func testParseIsIndependentOfKeyOrder() {
        let reordered = #"{"eventDate":"2027-01-01T00:00:00Z","venueName":"V","eventName":"N","eventID":"ev1","type":"event_invite"}"#
        XCTAssertEqual(EventInvitePayload.parse(reordered)?.eventID, "ev1")
    }

    func testParseRejectsNonInvites() {
        XCTAssertNil(EventInvitePayload.parse("hey, want to play my night?"))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"something_else","eventID":"e","eventName":"","venueName":"","eventDate":""}"#))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"event_invite","eventID":"","eventName":"","venueName":"","eventDate":""}"#))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"event_invite"}"#))
        XCTAssertNil(EventInvitePayload.parse("{not json"))
    }

    // MARK: - joinEvent

    func testJoinErrorCodesMap() {
        XCTAssertEqual(JoinLineupError(errorCode: "EVENT_NOT_FOUND"), .eventNotFound)
        XCTAssertEqual(JoinLineupError(errorCode: "EVENT_NOT_OPEN"), .eventNotOpen)
        XCTAssertEqual(JoinLineupError(errorCode: "NOT_A_DJ"), .notADJ)
        XCTAssertEqual(JoinLineupError(errorCode: "NOT_INVITED"), .notInvited)
        XCTAssertEqual(JoinLineupError(errorCode: "SERVER_ERROR"), .serverError("SERVER_ERROR"))
        XCTAssertEqual(JoinLineupError(errorCode: nil), .serverError("Unknown"))
    }

    func testJoinEnvelopeDecoding() throws {
        let okBody = Data(#"{"success":true,"linkID":"ev1_dj","coinContribution":7,"alreadyJoined":false}"#.utf8)
        let result = try EventService.decodeJoin(okBody)
        XCTAssertEqual(result.coinContribution, 7)
        XCTAssertEqual(result.alreadyJoined, false)

        let refused = Data(#"{"success":false,"errorCode":"NOT_INVITED"}"#.utf8)
        XCTAssertThrowsError(try EventService.decodeJoin(refused)) {
            XCTAssertEqual($0 as? JoinLineupError, .notInvited)
        }
        // The old Express scaffold replied {"success":"post call succeed!"} — must not read as success.
        let scaffold = Data(#"{"success":"post call succeed!","url":"/events/join"}"#.utf8)
        XCTAssertThrowsError(try EventService.decodeJoin(scaffold)) {
            XCTAssertEqual($0 as? JoinLineupError, .serverError("Unexpected response"))
        }
    }

    // MARK: - purchaseTicket

    func testPurchaseErrorCodesMap() {
        XCTAssertEqual(TicketPurchaseError(errorCode: "SOLD_OUT"), .soldOut)
        XCTAssertEqual(TicketPurchaseError(errorCode: "EVENT_NOT_FOUND"), .eventNotFound)
        XCTAssertEqual(TicketPurchaseError(errorCode: "EVENT_NOT_ON_SALE"), .notOnSale)
        XCTAssertEqual(TicketPurchaseError(errorCode: "EVENT_ENDED"), .eventEnded)
        XCTAssertEqual(TicketPurchaseError(errorCode: "PAYMENT_REQUIRED"), .paymentRequired)
        XCTAssertEqual(TicketPurchaseError(errorCode: "LIMIT_REACHED"), .limitReached)
        XCTAssertEqual(TicketPurchaseError(errorCode: "INVALID_REQUEST"), .serverError("INVALID_REQUEST"))
    }

    func testPurchaseEnvelopeDecoding() throws {
        let okBody = Data(#"{"success":true,"ticketID":"t1","remainingStock":3}"#.utf8)
        XCTAssertEqual(try TicketService.decodePurchase(okBody).remainingStock, 3)

        let paid = Data(#"{"success":false,"errorCode":"PAYMENT_REQUIRED"}"#.utf8)
        XCTAssertThrowsError(try TicketService.decodePurchase(paid)) {
            XCTAssertEqual($0 as? TicketPurchaseError, .paymentRequired)
        }
        XCTAssertThrowsError(try TicketService.decodePurchase(Data("<html>".utf8))) {
            XCTAssertEqual($0 as? TicketPurchaseError, .serverError("Unexpected response"))
        }
    }

    /// Mirrors the joinEvent Lambda's DEFAULT_WEIGHTS — keep in lockstep with
    /// amplify/backend/function/joinEvent/src/index.js.
    func testLambdaWeightTableMatchesClientMirror() {
        let lambdaDefaults = [1: 0, 2: 5, 3: 7, 4: 10, 5: 25]
        for (rank, coins) in lambdaDefaults {
            XCTAssertEqual(RankWeight.coins(forRank: rank), coins, "rank \(rank)")
        }
    }
}
