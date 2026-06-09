//
//  FilledButtonStyle.swift
//  N3ON
//

import SwiftUI

// DESIGN §1.8 — primary filled button: neon purple fill, 50pt minimum height
struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)                          // DESIGN §1.8 CTA minimum height
            .background(
                Color("neonPurpleBackground")
                    .opacity(configuration.isPressed ? 0.7 : 1.0)              // DESIGN §1.2 pressed state — lower B
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))  // DESIGN §1.6 standard card radius
    }
}
