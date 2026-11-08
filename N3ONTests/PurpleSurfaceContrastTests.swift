// PurpleSurfaceContrastTests.swift
// N3ONTests
//
// Text on the purple hero surface (Color("dullPurple") — login, sign-up,
// reset, profile hero, DJ preview, venue hero) must clear WCAG 2.x AA:
// 4.5:1 for text, 3:1 for non-text UI cues. Measured against the REAL asset
// colours, so an asset change that breaks contrast fails here, not in a club.

import XCTest
import UIKit
import SwiftUI
@testable import N3ON

final class PurpleSurfaceContrastTests: XCTestCase {

    // MARK: - WCAG 2.x relative luminance / contrast ratio

    private struct RGB { var r, g, b: Double }

    private func rgb(named name: String) throws -> RGB {
        let color = try XCTUnwrap(UIColor(named: name, in: Bundle.main, compatibleWith: nil), "asset \(name)")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(color.getRed(&r, green: &g, blue: &b, alpha: &a))
        return RGB(r: Double(r), g: Double(g), b: Double(b))
    }

    private func over(_ top: RGB, alpha: Double, _ bottom: RGB) -> RGB {
        RGB(r: top.r * alpha + bottom.r * (1 - alpha),
            g: top.g * alpha + bottom.g * (1 - alpha),
            b: top.b * alpha + bottom.b * (1 - alpha))
    }

    private func luminance(_ c: RGB) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    private func contrast(_ a: RGB, _ b: RGB) -> Double {
        let (hi, lo) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (hi + 0.05) / (lo + 0.05)
    }

    private let white = RGB(r: 1, g: 1, b: 1)

    // MARK: - Tests

    func testContrastFormulaMatchesWCAGReferencePoints() {
        XCTAssertEqual(contrast(white, RGB(r: 0, g: 0, b: 0)), 21, accuracy: 1e-9)
        XCTAssertEqual(contrast(white, white), 1, accuracy: 1e-9)
    }

    func testOnPurpleTextTokensClearAAOnTheSurfaceAndOnInputFields() throws {
        let purple = try rgb(named: "dullPurple")
        let field = over(white, alpha: 0.06, purple)   // the Color.white.opacity(0.06) input fields
        for (name, alpha) in [("primary", 1.0),
                              ("secondary", Color.onPurpleSecondaryOpacity),
                              ("tertiary", Color.onPurpleTertiaryOpacity)] {
            let onSurface = contrast(over(white, alpha: alpha, purple), purple)
            let onField = contrast(over(white, alpha: alpha, field), field)
            XCTAssertGreaterThanOrEqual(onSurface, 4.5, "\(name) on dullPurple: \(onSurface)")
            XCTAssertGreaterThanOrEqual(onField, 4.5, "\(name) on a field: \(onField)")
        }
    }

    /// Why the black-background ladder (0.5 / 0.3) and neon text were replaced.
    func testTheOldValuesFailOnPurple() throws {
        let purple = try rgb(named: "dullPurple")
        let neon = try rgb(named: "neonPurpleBackground")
        XCTAssertLessThan(contrast(neon, purple), 3, "neon text is invisible on dullPurple")
        XCTAssertLessThan(contrast(over(white, alpha: 0.5, purple), purple), 4.5)
        XCTAssertLessThan(contrast(over(white, alpha: 0.3, purple), purple), 4.5)
    }

    func testDJPillCyanStrokeClearsNonTextContrast() throws {
        let purple = try rgb(named: "dullPurple")
        // SwiftUI's Color.cyan is systemCyan; the app runs dark.
        let cyan = UIColor.systemCyan.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        cyan.getRed(&r, green: &g, blue: &b, alpha: &a)
        let stroke = RGB(r: Double(r), g: Double(g), b: Double(b))
        // WCAG 1.4.11: the pill outline is a UI cue (3:1); its text is white (4.5:1).
        XCTAssertGreaterThanOrEqual(contrast(stroke, purple), 3, "cyan outline on dullPurple")
        XCTAssertLessThan(contrast(over(stroke, alpha: 0.6, purple), purple), 3, "a faded cyan outline would fail")
        XCTAssertGreaterThanOrEqual(contrast(white, purple), 4.5)
    }
}
