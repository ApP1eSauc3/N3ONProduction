//
//  VenueSummaryStep.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct VenueSummaryStep: View {
    var venue: Venue

    var body: some View {
        VStack(spacing: 16) {
            Text("Venue: \(venue.name)")
                .font(.title2)
            Text(venue.description)
            Text("Address: \(venue.address)")
            Text("Capacity: \(venue.maxCapacity)")
        }
    }
}
