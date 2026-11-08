//
//  StepProgressSegment.swift
//  N3ON — Tools layer
//
// One segment of a multi-step progress bar (event creation, venue
// application). A reached segment's neon fill sweeps in from the leading edge
// under a mask, and sweeps back out if the user steps back, instead of the
// colour fading in place (Prompt/CLAUDE.md §4: masks for reveals and colour).

import SwiftUI

struct StepProgressSegment: View {
    let reached: Bool

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .overlay {
                Capsule()
                    .fill(Color("neonPurpleBackground"))
                    .mask(alignment: .leading) {
                        Rectangle()
                            .scaleEffect(x: reached ? 1 : 0, anchor: .leading)
                    }
            }
            .frame(height: 3)
            .animation(Motion.move(), value: reached)
            .accessibilityHidden(true)
    }
}
