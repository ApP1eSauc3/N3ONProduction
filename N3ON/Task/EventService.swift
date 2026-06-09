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

    // Set of calendar start-of-day dates that already have an event at this venue.
    // Used by EventDatePickerView to warn on date conflicts.
    static func bookedDates(forVenueID venueID: String) async -> Set<Date> {
        let events = (try? await fetchEvents(forVenueID: venueID)) ?? []
        let cal = Calendar.current
        return Set(events.map { cal.startOfDay(for: $0.eventDate.foundationDate) })
    }

    // Delete an event by ID. Called when a host DJ cancels during the limbo stage.
    static func cancelEvent(id: String) async throws {
        guard let event = try await Amplify.DataStore.query(Event.self, byId: id) else { return }
        try await Amplify.DataStore.delete(event)
    }

    // All registered DJs excluding the requesting user.
    // Used by EventInviteSheet to build the invite list.
    static func allDJs(excludingID myID: String) async -> [User] {
        let all = (try? await Amplify.DataStore.query(User.self)) ?? []
        return all.filter { $0.isDJ && $0.id != myID }
    }
}
