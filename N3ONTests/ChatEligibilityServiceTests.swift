// ChatEligibilityServiceTests.swift
// N3ONTests
//
// Role-matrix rules that resolve without touching DataStore, plus the
// 48-hour expiry boundary. DJ↔Venue eligibility requires live EventDJLink
// data and is intentionally not covered here.

import XCTest
@testable import N3ON

final class ChatEligibilityServiceTests: XCTestCase {

    // MARK: — Role matrix (pure paths)

    func testDJToDJAlwaysEligible() async {
        let result = await ChatEligibilityService.check(
            currentUserID: "a", currentRole: .dj,
            recipientUserID: "b", recipientRole: .dj
        )
        guard case .eligible(let type) = result, case .djToDJ = type else {
            return XCTFail("Expected .eligible(.djToDJ), got \(result)")
        }
    }

    func testRegularUsersHaveNoChatAccess() async {
        let asSender = await ChatEligibilityService.check(
            currentUserID: "a", currentRole: .regular,
            recipientUserID: "b", recipientRole: .dj
        )
        guard case .ineligible(let reason) = asSender, case .regularUserCannotChat = reason else {
            return XCTFail("Expected regularUserCannotChat, got \(asSender)")
        }

        let asRecipient = await ChatEligibilityService.check(
            currentUserID: "a", currentRole: .dj,
            recipientUserID: "b", recipientRole: .regular
        )
        guard case .ineligible(let reason) = asRecipient, case .regularUserCannotChat = reason else {
            return XCTFail("Expected regularUserCannotChat, got \(asRecipient)")
        }
    }

    func testVenueToVenueIncompatible() async {
        let result = await ChatEligibilityService.check(
            currentUserID: "a", currentRole: .venue,
            recipientUserID: "b", recipientRole: .venue
        )
        guard case .ineligible(let reason) = result, case .rolesIncompatible = reason else {
            return XCTFail("Expected rolesIncompatible, got \(result)")
        }
    }

    // MARK: — 48-hour expiry window

    func testEventNotExpiredInsideWindow() {
        let eventDate = Date().addingTimeInterval(-chatEventExpiryInterval + 60)
        XCTAssertFalse(ChatEligibilityService.isEventExpired(eventDate: eventDate))
    }

    func testEventExpiredPastWindow() {
        let eventDate = Date().addingTimeInterval(-chatEventExpiryInterval - 60)
        XCTAssertTrue(ChatEligibilityService.isEventExpired(eventDate: eventDate))
    }

    func testFutureEventNeverExpired() {
        let eventDate = Date().addingTimeInterval(3_600)
        XCTAssertFalse(ChatEligibilityService.isEventExpired(eventDate: eventDate))
    }
}
