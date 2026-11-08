//
//  Colour.swift
//  N3ON
//
//  Created by liam howe on 23/6/2024.
//

import SwiftUI

extension Color {
    // DESIGN §1.1 — single dark-gray surface token
    static let customDarkGray = Color("appDarkGray")
    // DESIGN §3.2 — one neon accent only; neonPurpleBackground is the token, used via Color("neonPurpleBackground")
    // neonGreen and neonRed removed — they violated the single-accent rule

    // MARK: DESIGN §1.4 — text on the purple hero surface (Color("dullPurple"))
    //
    // The §1.4 opacity ladder (1.0 / 0.7 / 0.5 / 0.3) is measured on black.
    // dullPurple is RGB(146, 6, 157) — far brighter than black — so the same
    // opacities fail WCAG AA there: white 0.5 = 2.8:1, white 0.3 = 1.8:1, and
    // neonPurpleBackground text = 1.1:1 (invisible). AA (4.5:1) starts at
    // white 0.78 on dullPurple and on a white-0.06 input field on it; these
    // tokens keep a margin above that (PurpleSurfaceContrastTests measures
    // them against the asset colours). Never use neon text here.

    /// Primary text on dullPurple — 7.7:1.
    static let onPurplePrimary = Color.white
    /// Secondary text on dullPurple (subtitles, links, field labels) — 6.4:1.
    static let onPurpleSecondary = Color.white.opacity(Self.onPurpleSecondaryOpacity)
    /// Tertiary text on dullPurple (placeholders, hints, disabled) — 5.3:1.
    static let onPurpleTertiary = Color.white.opacity(Self.onPurpleTertiaryOpacity)

    static let onPurpleSecondaryOpacity: Double = 0.9
    static let onPurpleTertiaryOpacity: Double = 0.8
}
