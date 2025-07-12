//
//  VenuePopupView.swift
//  N3ON
//
//  Created by liam howe on 30/6/2025.
//

import SwiftUI

// Define the User model
struct User: Model {
    public let username: String
    public var isSharingLocation: Bool
    
    public init(username: String, isSharingLocation: Bool = false) {
        self.username = username
        self.isSharingLocation = isSharingLocation
    }
}

// Define the Venue model
public struct Venue: Model {
    public let id: String
    public var name: String
    public var description: String
    public var address: String
    public var latitude: Double
    public var longitude: Double
    public var rating: Double?
    public var imageKey: [String]?
    public var owner: User?
    public var maxCapacity: Int?
    public var currentUsers: Int?
    public var revenue: Double?
    public var dailyUserCounts: List<DailyUserCount>?
    public var reviews: List<Review>?
    public var approvalStatus: String
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        address: String,
        latitude: Double,
        longitude: Double,
        rating: Double? = nil,
        imageKey: [String]? = nil,
        owner: User? = nil,
        maxCapacity: Int? = nil,
        currentUsers: Int? = nil,
        revenue: Double? = nil,
        dailyUserCounts: List<DailyUserCount>? = [],
        reviews: List<Review>? = [],
        approvalStatus: String
    ) {
        self.init(
            id: id,
            name: name,
            description: description,
            address: address,
            latitude: latitude,
            longitude: longitude,
            rating: rating,
            imageKey: imageKey,
            owner: owner,
            maxCapacity: maxCapacity,
            currentUsers: currentUsers,
            revenue: revenue,
            dailyUserCounts: dailyUserCounts,
            reviews: reviews,
            approvalStatus: approvalStatus,
            createdAt: nil,
            updatedAt: nil
        )
    }
    
    internal init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        address: String,
        latitude: Double,
        longitude: Double,
        rating: Double? = nil,
        imageKey: [String]? = nil,
        owner: User? = nil,
        maxCapacity: Int? = nil,
        currentUsers: Int? = nil,
        revenue: Double? = nil,
        dailyUserCounts: List<DailyUserCount>? = [],
        reviews: List<Review>? = [],
        approvalStatus: String,
        createdAt: Temporal.DateTime? = nil,
        updatedAt: Temporal.DateTime? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.imageKey = imageKey
        self.owner = owner
        self.maxCapacity = maxCapacity
        self.currentUsers = currentUsers
        self.revenue = revenue
        self.dailyUserCounts = dailyUserCounts
        self.reviews = reviews
        self.approvalStatus = approvalStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Define the VenuePopupView
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
