// TestFixtures.swift
// N3ONTests
//
// Minimal Amplify-model fixtures. Field lists mirror the generated
// initializers in amplify/generated/models/ — update here if codegen changes.

import Foundation
import Amplify
@testable import N3ON

enum Fixtures {

    static func user(
        rank: Int? = nil,
        isCurated: Bool = false,
        isDJ: Bool = true,
        username: String = "test-dj"
    ) -> User {
        User(
            username: username,
            isDJ: isDJ,
            djRank: rank,
            isCurated: isCurated,
            isSharingLocation: false,
            coinBalance: 0
        )
    }

    static func venue(capacity: Int, id: String = UUID().uuidString) -> Venue {
        Venue(
            id: id,
            name: "Test Venue",
            description: "A venue",
            address: "1 Test St",
            latitude: 0,
            longitude: 0,
            maxCapacity: capacity,
            approvalStatus: "approved"
        )
    }

    static func event(
        venueID: String,
        daysFromNow: Int,
        name: String = "Test Event"
    ) -> Event {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        return Event(
            venueID: venueID,
            hostDJID: "host",
            package: "basic",
            eventDate: Temporal.DateTime(date, timeZone: .current),
            eventName: name,
            description: "desc",
            ticketPrice: 0,
            availableTickets: 100,
            status: "live",
            isFeatured: false
        )
    }
}
