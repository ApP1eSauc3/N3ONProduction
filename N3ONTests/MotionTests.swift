// MotionTests.swift
// N3ONTests
//
// Pins the motion system (Tools/Motion.swift, Prompt/CLAUDE.md §4) to the
// numbers in the animation guideline, and checks the pure helpers behind the
// gestures and list stagger.

import XCTest
@testable import N3ON

final class MotionTests: XCTestCase {

    // MARK: - Guideline values

    func testGuidelineNumbers() {
        XCTAssertEqual(Motion.pressScale, 0.97)                    // scale to 0.97 on press
        XCTAssertEqual(Motion.popoverStartScale, 0.95)             // start popovers at 0.95
        XCTAssertEqual(Motion.staggerStep, 0.03, accuracy: 1e-9)   // stagger rows by 30ms
        XCTAssertEqual(Motion.stretchAmount, 0.12)                 // stretch moving knobs 12%
        XCTAssertTrue((0.15...0.25).contains(Motion.dropdownDuration), "dropdowns at 150–250ms")
        XCTAssertLessThan(Motion.enterDuration, 0.3, "UI animations stay under 300ms")
    }

    func testExitsAreTwentyPercentShorter() {
        XCTAssertEqual(Motion.exitDuration(for: 0.25), 0.2, accuracy: 1e-9)
        XCTAssertEqual(Motion.exitDuration(for: Motion.dropdownDuration), 0.16, accuracy: 1e-9)
    }

    // MARK: - Stagger

    func testStaggerDelayStepsBy30msAndCaps() {
        XCTAssertEqual(Motion.staggerDelay(for: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(Motion.staggerDelay(for: 1), 0.03, accuracy: 1e-9)
        XCTAssertEqual(Motion.staggerDelay(for: 10), 0.3, accuracy: 1e-9)
        XCTAssertEqual(Motion.staggerDelay(for: 500), 0.3, accuracy: 1e-9, "a long list never waits longer")
        XCTAssertEqual(Motion.staggerDelay(for: -4), 0, accuracy: 1e-9)
    }

    // MARK: - Rubber band

    func testRubberBandMatchesUIScrollViewCurve() {
        // (1 − 1/(x·0.55/d + 1))·d at x = d → d·(1 − 1/1.55)
        XCTAssertEqual(Motion.rubberBand(100, dimension: 100), 100 * (1 - 1 / 1.55), accuracy: 1e-6)
        XCTAssertEqual(Motion.rubberBand(0, dimension: 100), 0)
        XCTAssertEqual(Motion.rubberBand(50, dimension: 0), 0, "no dimension, no travel")
    }

    func testRubberBandResistsSymmetricallyAndNeverReachesTheDimension() {
        var previous: CGFloat = 0
        for x in stride(from: CGFloat(10), through: 10_000, by: 10) {
            let r = Motion.rubberBand(x, dimension: 300)
            XCTAssertGreaterThan(r, previous, "monotonic")
            XCTAssertLessThan(r, 300, "bounded by the dimension")
            XCTAssertLessThan(r, x, "always resisted")
            XCTAssertEqual(Motion.rubberBand(-x, dimension: 300), -r, accuracy: 1e-9)
            previous = r
        }
    }

    func testRubberBandedPassesThroughInsideTheRange() {
        XCTAssertEqual(Motion.rubberBanded(-120, in: -300...0, dimension: 300), -120)
        XCTAssertEqual(Motion.rubberBanded(0, in: -300...0, dimension: 300), 0)
        // Past either bound: continuous at the bound and resisted beyond it.
        let over = Motion.rubberBanded(40, in: -300...0, dimension: 300)
        XCTAssertGreaterThan(over, 0); XCTAssertLessThan(over, 40)
        let under = Motion.rubberBanded(-340, in: -300...0, dimension: 300)
        XCTAssertLessThan(under, -300); XCTAssertGreaterThan(under, -340)
        // Open-ended range (QR card: free upward, resisted downward).
        XCTAssertEqual(Motion.rubberBanded(-500, in: -.infinity...0, dimension: 120), -500)
        XCTAssertLessThan(Motion.rubberBanded(80, in: -.infinity...0, dimension: 120), 80)
    }

    // MARK: - Stretch

    func testStretchPeaksMidMoveAndRestsAtOne() {
        XCTAssertEqual(StretchEffect.scale(progress: 0, amount: 0.12), 1, accuracy: 1e-9)
        XCTAssertEqual(StretchEffect.scale(progress: 0.5, amount: 0.12), 1.12, accuracy: 1e-9)
        XCTAssertEqual(StretchEffect.scale(progress: 1, amount: 0.12), 1, accuracy: 1e-9)
        XCTAssertEqual(StretchEffect.scale(progress: 7.5, amount: 0.12), 1.12, accuracy: 1e-9, "every move")
        XCTAssertEqual(StretchEffect.scale(progress: 0.5, amount: 0), 1, accuracy: 1e-9, "Reduce Motion")
        for p in stride(from: 0.0, through: 3.0, by: 0.05) {
            let s = StretchEffect.scale(progress: p, amount: 0.12)
            XCTAssertTrue((1.0...1.12 + 1e-9).contains(Double(s)), "\(p) → \(s)")
        }
    }
}
