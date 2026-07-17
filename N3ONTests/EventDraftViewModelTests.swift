// EventDraftViewModelTests.swift
// N3ONTests
//
// Pure draft-state logic: tally thresholds, revenue splits, break-even,
// glow weighting, and reset. No Amplify calls — these run offline.

import XCTest
@testable import N3ON

@MainActor
final class EventDraftViewModelTests: XCTestCase {

    private func makeVM(capacity: Int? = nil, price: Double = 0) -> EventDraftViewModel {
        let vm = EventDraftViewModel()
        if let capacity { vm.venue = Fixtures.venue(capacity: capacity) }
        vm.ticketPrice = price
        return vm
    }

    // MARK: — requiredTally capacity tiers

    func testRequiredTallyDefaultsTo40WithoutVenue() {
        XCTAssertEqual(makeVM().requiredTally, 40)
    }

    func testRequiredTallyBaseTiers() {
        // Zero price → full tier threshold.
        XCTAssertEqual(makeVM(capacity: 150).requiredTally, 40)
        XCTAssertEqual(makeVM(capacity: 350).requiredTally, 55)
        XCTAssertEqual(makeVM(capacity: 800).requiredTally, 80)
    }

    func testRequiredTallyTierBoundaries() {
        XCTAssertEqual(makeVM(capacity: 200).requiredTally, 40)   // top of small tier
        XCTAssertEqual(makeVM(capacity: 201).requiredTally, 55)   // bottom of mid tier
        XCTAssertEqual(makeVM(capacity: 500).requiredTally, 55)   // top of mid tier
        XCTAssertEqual(makeVM(capacity: 501).requiredTally, 80)   // bottom of large tier
    }

    // MARK: — requiredTally price factor

    func testMidpointPriceKeepsFullThreshold() {
        XCTAssertEqual(makeVM(capacity: 150, price: 20).requiredTally, 40)
    }

    func testBelowMidpointPriceClampsFactorToOne() {
        // Cheaper tickets never raise the threshold above the tier base.
        XCTAssertEqual(makeVM(capacity: 150, price: 10).requiredTally, 40)
    }

    func testHighPriceReducesThresholdProportionally() {
        // capacity 800: base 80, midpoint 50 → price 100 gives factor 0.5 → 40
        XCTAssertEqual(makeVM(capacity: 800, price: 100).requiredTally, 40)
        // capacity 350: base 55, midpoint 30 → price 60 gives 27.5 → rounds to 28
        XCTAssertEqual(makeVM(capacity: 350, price: 60).requiredTally, 28)
    }

    func testExtremePriceFloorsAtHalfBase() {
        // Factor clamps at 0.5 no matter how expensive the ticket.
        XCTAssertEqual(makeVM(capacity: 150, price: 500).requiredTally, 20)
    }

    // MARK: — tallyMet

    func testTallyMetAtExactThreshold() {
        let vm = makeVM()   // required 40
        vm.currentTally = 39
        XCTAssertFalse(vm.tallyMet)
        vm.currentTally = 40
        XCTAssertTrue(vm.tallyMet)
    }

    /// In the live bootstrap config the tally is not enforced, so limbo is
    /// always exitable. Flipping to community makes tallyMet the real gate.
    func testCanLeaveLimboInBootstrapModeRegardlessOfTally() {
        let vm = makeVM()
        vm.currentTally = 0
        XCTAssertTrue(vm.canLeaveLimbo)
    }

    // MARK: — breakEvenPreview

    func testBreakEvenPreviewNilWithoutPriceOrVenue() {
        XCTAssertNil(makeVM(capacity: 150, price: 0).breakEvenPreview)
        XCTAssertNil(makeVM(capacity: nil, price: 20).breakEvenPreview)
    }

    func testBreakEvenPreviewAt30PercentFill() {
        let preview = makeVM(capacity: 150, price: 20).breakEvenPreview
        XCTAssertEqual(preview?.attendees, 45)
        XCTAssertEqual(preview?.revenue, 900)
    }

    // MARK: — revenueBreakdown

    func testRevenueSplits40Venue60Pool() {
        let vm = makeVM(capacity: 150, price: 20)
        vm.estimatedAttendance = 100
        let breakdown = vm.revenueBreakdown
        XCTAssertEqual(breakdown.totalRevenue, 2000, accuracy: 0.001)
        XCTAssertEqual(breakdown.venueRevenue, 800, accuracy: 0.001)
    }

    func testOnlyRank5HostTakesDJShare() {
        let vm = makeVM(capacity: 150, price: 20)
        vm.estimatedAttendance = 100
        vm.djSharePercentage = 50

        vm.hostDJRank = 5
        XCTAssertEqual(vm.revenueBreakdown.hostDJRevenue, 600, accuracy: 0.001)

        vm.hostDJRank = 4
        XCTAssertEqual(vm.revenueBreakdown.hostDJRevenue, 0, accuracy: 0.001)
    }

    // MARK: — glowStrength

    func testGlowStrengthBucketsByProximity() {
        let vm = makeVM()
        let venue = Fixtures.venue(capacity: 150)

        // 3 days out → 1.0, capped
        let soon = [Fixtures.event(venueID: venue.id, daysFromNow: 3)]
        XCTAssertEqual(vm.glowStrength(for: venue, allEvents: soon), 1.0, accuracy: 0.001)

        // 20 days out → 0.3
        let later = [Fixtures.event(venueID: venue.id, daysFromNow: 20)]
        XCTAssertEqual(vm.glowStrength(for: venue, allEvents: later), 0.3, accuracy: 0.001)

        // Other venues contribute nothing
        let elsewhere = [Fixtures.event(venueID: "other-venue", daysFromNow: 3)]
        XCTAssertEqual(vm.glowStrength(for: venue, allEvents: elsewhere), 0.0, accuracy: 0.001)
    }

    func testGlowStrengthCapsAtOne() {
        let vm = makeVM()
        let venue = Fixtures.venue(capacity: 150)
        let stacked = (0..<5).map { _ in Fixtures.event(venueID: venue.id, daysFromNow: 3) }
        XCTAssertEqual(vm.glowStrength(for: venue, allEvents: stacked), 1.0, accuracy: 0.001)
    }

    // MARK: — reset

    func testResetRestoresDefaults() {
        let vm = makeVM(capacity: 150, price: 25)
        vm.eventName = "Warehouse Rave"
        vm.currentTally = 99
        vm.createdEventID = "abc"
        vm.currentStep = .limbo

        vm.reset()

        XCTAssertEqual(vm.eventName, "")
        XCTAssertEqual(vm.currentTally, 0)
        XCTAssertNil(vm.createdEventID)
        XCTAssertNil(vm.venue)
        XCTAssertEqual(vm.ticketPrice, 0)
        XCTAssertEqual(vm.currentStep, .datePicker)
    }
}
