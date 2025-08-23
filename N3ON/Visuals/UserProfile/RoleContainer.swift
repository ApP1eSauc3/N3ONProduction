//
//  RoleContainer.swift
//  N3ON
//
//  Created by liam howe on 21/8/2025.
//

import SwiftUI

struct RoleContainer<Regular: View, DJ: View, Venue: View>: View {
    let roles: Set<AppRole>
    let isDJMode: Bool
    @ViewBuilder var regular: Regular
    @ViewBuilder var dj: DJ
    @ViewBuilder var venue: Venue

    var body: some View {
        VStack(spacing: 20) {
            if roles.contains(.venue) && !isDJMode {
                venue
            } else if roles.contains(.dj) && isDJMode {
                dj
            } else {
                regular
            }
        }
        .padding(.horizontal)
    }
}
