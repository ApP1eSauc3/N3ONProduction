//
//
//  EventService.swift
//  N3ON
//

import Foundation
import Amplify
import CoreLocation

enum EventService {

    // Fetch all upcoming events sorted by date.
    // DataStore cannot geo-filter — filter client-side by distance if needed.
    static func fetchUpcomingEvents() async throws -> [Event] {
        try await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.eventDate >= Temporal.DateTime.now()
        )
        .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    // Fetch a single event by ID — used after purchase to refresh availableTickets
    static func fetchEvent(byId id: String) async throws -> Event? {
        try await Amplify.DataStore.query(Event.self, byId: id)
    }

    // Fetch events hosted by a specific DJ
    static func fetchEvents(forHostDJID hostDJID: String) async throws -> [Event] {
        try await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.hostDJID == hostDJID
        )
    }

    // Fetch events at a specific venue
    static func fetchEvents(forVenueID venueID: String) async throws -> [Event] {
        try await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.venueID == venueID
        )
    }
}
