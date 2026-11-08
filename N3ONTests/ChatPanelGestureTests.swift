// ChatPanelGestureTests.swift
// N3ONTests
//
// The chat panel's close-drag rules (Prompt/Chat/ChatPanelView.swift): the
// axis locks once, so scrolling the inbox never slides the panel; the left
// 30pt belong to the navigation back-swipe; dragging past fully open
// rubber-bands; and only a deliberate rightward swipe closes.

import XCTest
import SwiftUI
@testable import N3ON

final class ChatPanelGestureTests: XCTestCase {

    private let width: CGFloat = 390
    private let mid = CGPoint(x: 200, y: 400)

    func testAxisLocksOnTheFirstUpdateAndStaysLocked() {
        // Starts vertical (an inbox scroll)…
        var drag = ChatPanelView.track(.init(), start: mid, translation: CGSize(width: 2, height: 30), panelWidth: width)
        XCTAssertEqual(drag.axis, .vertical)
        // …then drifts sideways: still locked vertical, panel does not move.
        drag = ChatPanelView.track(drag, start: mid, translation: CGSize(width: 150, height: 40), panelWidth: width)
        XCTAssertEqual(drag.axis, .vertical)
        XCTAssertEqual(drag.offset, 0)
    }

    func testHorizontalDragTracksTheFinger() {
        var drag = ChatPanelView.track(.init(), start: mid, translation: CGSize(width: 30, height: 2), panelWidth: width)
        XCTAssertEqual(drag.axis, .horizontal)
        drag = ChatPanelView.track(drag, start: mid, translation: CGSize(width: 120, height: 10), panelWidth: width)
        XCTAssertEqual(drag.offset, 120, "1:1 inside the range")
    }

    func testDraggingPastFullyOpenRubberBands() {
        let drag = ChatPanelView.track(.init(), start: mid, translation: CGSize(width: -200, height: 0), panelWidth: width)
        XCTAssertLessThan(drag.offset, 0)
        XCTAssertGreaterThan(drag.offset, -200, "resisted, not 1:1")
    }

    func testLeftEdgeBelongsToTheBackSwipe() {
        XCTAssertEqual(ChatPanelView.axis(start: CGPoint(x: 12, y: 400), translation: CGSize(width: 200, height: 0)), .vertical)
        XCTAssertFalse(ChatPanelView.closes(start: CGPoint(x: 12, y: 400), translation: CGSize(width: 200, height: 0),
                                            predicted: CGSize(width: 400, height: 0), panelWidth: width))
    }

    func testOnlyADeliberateRightSwipeCloses() {
        func closes(_ dx: CGFloat, _ dy: CGFloat, predicted: CGFloat) -> Bool {
            ChatPanelView.closes(start: mid, translation: CGSize(width: dx, height: dy),
                                 predicted: CGSize(width: predicted, height: dy), panelWidth: width)
        }
        XCTAssertTrue(closes(81, 5, predicted: 81), "far enough")
        XCTAssertTrue(closes(40, 5, predicted: 200), "flicked: lands past 40%")
        XCTAssertFalse(closes(60, 5, predicted: 100), "short and slow — springs back")
        XCTAssertFalse(closes(-120, 5, predicted: -300), "leftward never closes")
        XCTAssertFalse(closes(100, 300, predicted: 100), "a scroll that drifted sideways")
    }
}
