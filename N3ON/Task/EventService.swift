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
        try await Backend.dataStore.query(
            Event.self,
            where: Event.keys.eventDate >= Temporal.DateTime.now()
        )
        .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    // Fetch a single event by ID — used after purchase to refresh availableTickets
    static func fetchEvent(byId id: String) async throws -> Event? {
        try await Backend.dataStore.query(Event.self, byId: id)
    }

    // Fetch events hosted by a specific DJ
    static func fetchEvents(forHostDJID hostDJID: String) async throws -> [Event] {
        try await Backend.dataStore.query(
            Event.self,
            where: Event.keys.hostDJID == hostDJID
        )
    }

    // Fetch events at a specific venue
    static func fetchEvents(forVenueID venueID: String) async throws -> [Event] {
        try await Backend.dataStore.query(
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
        guard let event = try await Backend.dataStore.query(Event.self, byId: id) else { return }
        try await requireHost(of: event)
        try await Backend.dataStore.delete(event)
    }

    /// Only an event's host writes or deletes it from the app. The server
    /// limits Event writes to the owner (and admins, who use AdminService);
    /// the client never attempts someone else's.
    static func requireHost(of event: Event) async throws {
        guard event.hostDJID == (try await AuthService.currentUserId()) else { throw EventServiceError.notHost }
    }

    // All registered DJs excluding the requesting user.
    // Used by EventInviteSheet to build the invite list.
    static func allDJs(excludingID myID: String) async -> [User] {
        let all = (try? await Backend.dataStore.query(User.self)) ?? []
        return all.filter { $0.isDJ && $0.id != myID }
    }

    // DJ lineup links for an event — used to display the lineup and compute the tally.
    static func djLinks(forEventID eventID: String) async throws -> [EventDJLink] {
        try await Backend.dataStore.query(
            EventDJLink.self,
            where: EventDJLink.keys.event == eventID
        )
    }

    // Upserts an event record.
    /// Events the signed-in user organises or plays: hosted events plus any
    /// event they hold a lineup link for. De-duplicated, soonest first.
    static func myEvents() async throws -> [Event] {
        let me = try await AuthService.currentUserId()
        var byID: [String: Event] = [:]
        for event in try await fetchEvents(forHostDJID: me) { byID[event.id] = event }
        let links = try await Backend.dataStore.query(EventDJLink.self, where: EventDJLink.keys.djID == me)
        for link in links {
            guard let eventID = link.event?.id, byID[eventID] == nil,
                  let event = try await fetchEvent(byId: eventID) else { continue }
            byID[eventID] = event
        }
        return byID.values.sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    /// A DJ's upcoming events: ones they host or are on the lineup of, soonest
    /// first. (The DJ profile used to show every upcoming event on the platform.)
    static func upcomingEvents(forDJ djID: String, after date: Date = Date()) async throws -> [Event] {
        var byID: [String: Event] = [:]
        for event in try await fetchEvents(forHostDJID: djID) { byID[event.id] = event }
        let links = try await Backend.dataStore.query(EventDJLink.self, where: EventDJLink.keys.djID == djID)
        for link in links {
            guard let eventID = link.event?.id, byID[eventID] == nil,
                  let event = try await fetchEvent(byId: eventID) else { continue }
            byID[eventID] = event
        }
        return byID.values
            .filter { $0.eventDate.foundationDate >= date && $0.status != EventStatus.cancelled.rawValue }
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    static func save(_ event: Event) async throws {
        try await requireHost(of: event)
        try await Backend.dataStore.save(event)
    }

    // MARK: - Lineup (joinEvent Lambda)

    /// Adds the signed-in DJ to an event's lineup via POST /events/join.
    /// The Lambda verifies the caller is the host or holds the host's chat
    /// invite, and stamps rankAtJoining / coinContribution server-side — the
    /// client never writes EventDJLink. Idempotent: re-joining returns the
    /// existing link. Returns the DJ's coin contribution to the tally.
    @discardableResult
    static func joinLineup(eventID: String) async throws -> JoinLineupResult {
        let data: Data
        do {
            data = try await N3ONRESTClient.post(path: "/events/join", json: ["eventID": eventID])
        } catch {
            throw JoinLineupError.serverError(error.localizedDescription)
        }
        return try decodeJoin(data)
    }

    /// Decodes the Lambda envelope. Internal for unit tests.
    static func decodeJoin(_ data: Data) throws -> JoinLineupResult {
        guard let response = try? JSONDecoder().decode(JoinLineupResult.self, from: data) else {
            throw JoinLineupError.serverError("Unexpected response")
        }
        guard response.success else { throw JoinLineupError(errorCode: response.errorCode) }
        return response
    }
}

struct JoinLineupResult: Decodable, Equatable {
    let success: Bool
    let errorCode: String?
    let linkID: String?
    let coinContribution: Int?
    let alreadyJoined: Bool?
}

enum EventServiceError: LocalizedError, Equatable {
    case notHost
    var errorDescription: String? { "Only the event's host can change it." }
}
