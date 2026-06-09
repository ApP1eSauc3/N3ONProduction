// SearchService.swift
// N3ON — Task layer
// Queries DataStore for DJs, Events, and Venues matching a search string.
// Amplify DataStore has no LIKE/contains predicate — all filtering is in-memory.
// Results are limited to 50 per category to keep response snappy.

import Foundation
import Amplify

struct SearchResults {
    var djs: [User] = []
    var events: [Event] = []
    var venues: [Venue] = []
}

enum SearchService {

    // MARK: — Unified search

    static func search(query: String) async -> SearchResults {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        async let djs    = fetchDJs(query: q)
        async let events = fetchEvents(query: q)
        async let venues = fetchVenues(query: q)
        return await SearchResults(djs: djs, events: events, venues: venues)
    }

    // MARK: — Category search

    static func fetchDJs(query: String) async -> [User] {
        guard let all = try? await Amplify.DataStore.query(
            User.self,
            where: User.keys.isDJ == true
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(50)) }
        return Array(
            all.filter { $0.username.lowercased().contains(query) }
               .prefix(50)
        )
    }

    static func fetchEvents(query: String) async -> [Event] {
        guard let all = try? await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.eventDate >= Temporal.DateTime(Date(), timeZone: .current)
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(50)) }
        return Array(
            all.filter { $0.eventName.lowercased().contains(query) }
               .prefix(50)
        )
    }

    static func fetchVenues(query: String) async -> [Venue] {
        guard let all = try? await Amplify.DataStore.query(
            Venue.self,
            where: Venue.keys.approvalStatus == VenueStatus.approved.rawValue
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(50)) }
        return Array(
            all.filter {
                $0.name.lowercased().contains(query) ||
                $0.address.lowercased().contains(query)
            }
            .prefix(50)
        )
    }
}
