// MapService.swift
// N3ON — Task layer
// All DataStore queries for the map live here.
// MapViewModel never calls Amplify.DataStore directly.

import Foundation
import Amplify

struct MapService {

    // MARK: - Venues

    /// All venues owned by the given user ID.
    // Every filter is a DataStore predicate, so SQLite does the work instead
    // of the map loading whole tables into memory on each refresh.

    static func venues(ownedBy ownerID: String) async throws -> [Venue] {
        try await Backend.dataStore.query(Venue.self, where: Venue.keys.owner == ownerID)
    }

    /// All venues with `approvalStatus == "approved"`.
    static func approvedVenues() async throws -> [Venue] {
        try await Backend.dataStore.query(Venue.self, where: Venue.keys.approvalStatus == VenueStatus.approved.rawValue)
    }

    // MARK: - Events

    /// All events at a set of venue IDs whose eventDate is on or after `after`.
    static func upcomingEvents(atVenueIDs venueIDs: Set<String>, after date: Date = Date()) async throws -> [Event] {
        guard !venueIDs.isEmpty else { return [] }
        let upcoming = try await Backend.dataStore.query(
            Event.self, where: Event.keys.eventDate >= Temporal.DateTime(date, timeZone: .current))
        return upcoming.filter { venueIDs.contains($0.venueID) }
    }

    /// All upcoming events across all venues (date ≥ now).
    static func allUpcomingEvents(after date: Date = Date()) async throws -> [Event] {
        try await Backend.dataStore.query(
            Event.self, where: Event.keys.eventDate >= Temporal.DateTime(date, timeZone: .current))
    }

    /// Ids per OR-predicate: DataStore has no IN(), and one statement per
    /// small chunk keeps SQLite's expression depth bounded.
    static let predicateChunk = 50

    // MARK: - DJs

    /// `EventDJLink` records whose event ID is in the supplied set.
    static func djLinks(forEventIDs eventIDs: Set<String>) async throws -> [EventDJLink] {
        let ids = eventIDs.sorted()
        var links: [EventDJLink] = []
        for start in stride(from: 0, to: ids.count, by: predicateChunk) {
            let chunk = ids[start..<min(start + predicateChunk, ids.count)]
            let anyOf = QueryPredicateGroup(type: .or, predicates: chunk.map { EventDJLink.keys.event == $0 })
            links += try await Backend.dataStore.query(EventDJLink.self, where: anyOf)
        }
        return links
    }

    /// The `User` record for a given DJ ID. Returns `nil` if not found.
    static func user(byId id: String) async throws -> User? {
        try await Backend.dataStore.query(User.self, byId: id)
    }

    // MARK: - Follows

    /// All `followeeID` strings for a given follower.
    static func followedUserIDs(for followerID: String) async throws -> Set<String> {
        let follows = try await Backend.dataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followerID == followerID
        )
        return Set(follows.map { $0.followeeID })
    }
}
