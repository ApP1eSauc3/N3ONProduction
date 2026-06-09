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
}
