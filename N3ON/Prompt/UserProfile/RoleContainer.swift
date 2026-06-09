//
//  RoleContainer.swift
//  N3ON
//
//  Created by liam howe on 21/8/2025.
//

import SwiftUI

struct RoleContainer<Regular: View, DJ: View, Venue: View>: View {
    let role: AppRole
    @ViewBuilder var regular: Regular
    @ViewBuilder var dj: DJ
    @ViewBuilder var venue: Venue

    var body: some View {
        // DESIGN §2.4 RoleContainer internal spacing — 20pt (off-grid, should be 24pt space6). Change here.
        VStack(spacing: 20) {
            if role == .venue {
                venue
            } else if role == .dj {
                dj
            } else {
                regular
            }
        }
        // DESIGN §2.4 RoleContainer horizontal padding — .padding(.horizontal) uses system default (~16pt).
        // Replace with .padding(.horizontal, 16) to make it explicit and locked to the §2.4 page margin.
        .padding(.horizontal)
    }
}
