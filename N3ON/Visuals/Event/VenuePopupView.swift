//
//  VenuePopupView.swift
//  N3ON
//
//  Created by liam howe on 30/6/2025.
//

import SwiftUI

struct VenuePopupView: View {
    let venue: Venue
    let onStartEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(venue.imageKey ?? [], id: \.self) { key in
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 120, height: 90)
                            .overlay(Text("\(key)")
                                .font(.caption)
                                .foregroundColor(.white))
                            .cornerRadius(10)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(venue.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(venue.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(venue.description)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .lineLimit(3)
            }
            
            HStack {
                Spacer()
                Button(action: onStartEvent) {
                    Text("Start Event")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// Preview Provider
struct VenuePopupView_Previews: PreviewProvider {
    static var previews: some View {
        VenuePopupView(
            venue: Venue(
                id: "1",
                name: "Electric Lounge",
                description: "Spacious venue with immersive sound system and LED walls.",
                address: "123 Club St",
                latitude: 0.0,
                longitude: 0.0,
                rating: 4.5,
                imageKey: ["img1", "img2"],
                owner: User(username: "user123", isSharingLocation: true),
                maxCapacity: 300,
                currentUsers: 0,
                revenue: 0,
                dailyUserCounts: [],
                reviews: [],
                approvalStatus: "APPROVED"
            ),
            onStartEvent: {}
        )
    }
}
