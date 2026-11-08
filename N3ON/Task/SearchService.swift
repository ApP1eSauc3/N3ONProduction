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

    /// Results per category, and the longest query honoured (no name is longer).
    static let resultLimit = 50
    static let maxQueryLength = 100

    static func search(query: String) async -> SearchResults {
        let q = String(query.trimmingCharacters(in: .whitespaces).lowercased().prefix(maxQueryLength))
        async let djs    = fetchDJs(query: q)
        async let events = fetchEvents(query: q)
        async let venues = fetchVenues(query: q)
        return await SearchResults(djs: djs, events: events, venues: venues)
    }

    // MARK: — Category search

    static func fetchDJs(query: String) async -> [User] {
        guard let all = try? await Backend.dataStore.query(
            User.self,
            where: User.keys.isDJ == true
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(resultLimit)) }
        // Lazy: stops scanning at the 50th match instead of filtering everything.
        return Array(all.lazy.filter { $0.username.lowercased().contains(query) }.prefix(resultLimit))
    }

    static func fetchEvents(query: String) async -> [Event] {
        guard let all = try? await Backend.dataStore.query(
            Event.self,
            where: Event.keys.eventDate >= Temporal.DateTime(Date(), timeZone: .current)
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(resultLimit)) }
        return Array(all.lazy.filter { $0.eventName.lowercased().contains(query) }.prefix(resultLimit))
    }

    static func fetchVenues(query: String) async -> [Venue] {
        guard let all = try? await Backend.dataStore.query(
            Venue.self,
            where: Venue.keys.approvalStatus == VenueStatus.approved.rawValue
        ) else { return [] }
        guard !Task.isCancelled else { return [] }
        guard !query.isEmpty else { return Array(all.prefix(resultLimit)) }
        return Array(all.lazy.filter {
            $0.name.lowercased().contains(query) || $0.address.lowercased().contains(query)
        }.prefix(resultLimit))
    }
}
