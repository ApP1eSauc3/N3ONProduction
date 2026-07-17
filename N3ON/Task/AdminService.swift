// AdminService.swift
// N3ON — Task layer
//
// Admin curation actions for the bootstrap phase (see Data/CurationConfig.swift).
//
// Every write here is also authorised server-side by the `AdminUser` @auth rules
// in schema.graphql — a non-admin call is rejected by AppSync on sync. The UI only
// surfaces these where `AccessControlService.isAdmin()` is true.
//
// These SUPERSEDE ranking rules during bootstrap; they do not remove or alter the
// ranking system itself.

import Foundation
import Amplify

enum AdminService {

    // MARK: - Reads (admin console)

    /// All DJ users, alphabetical. Admin-console roster source.
    /// Throws on query failure — an admin tool must distinguish "no DJs"
    /// from "query failed", so errors are never swallowed here.
    static func allDJs() async throws -> [User] {
        let users = try await Amplify.DataStore.query(User.self)
        return users.filter { $0.isDJ }.sorted { $0.username < $1.username }
    }

    /// All events, soonest-first by event date. Admin-console event source.
    /// Throws on query failure (see allDJs).
    static func allEvents() async throws -> [Event] {
        let events = try await Amplify.DataStore.query(Event.self)
        return events.sorted { $0.eventDate.foundationDate > $1.eventDate.foundationDate }
    }

    // MARK: - DJ curation

    /// Seeds a DJ's rank directly — the bootstrap shortcut for endorsement-based
    /// promotion. Pass `nil` to clear the rank.
    static func setDJRank(_ rank: Int?, for user: User) async throws -> User {
        var updated = user
        updated.djRank = rank
        try await Amplify.DataStore.save(updated)
        return updated
    }

    /// Marks (or unmarks) a DJ as curated — a curated DJ can host events during
    /// bootstrap regardless of `djRank`. See `CurationService.canCreateEvent`.
    static func setCurated(_ isCurated: Bool, for user: User) async throws -> User {
        var updated = user
        updated.isCurated = isCurated
        try await Amplify.DataStore.save(updated)
        return updated
    }

    // MARK: - Event curation

    /// Features (or unfeatures) an event so it surfaces on the map regardless of status.
    static func setFeatured(_ isFeatured: Bool, for event: Event) async throws -> Event {
        var updated = event
        updated.isFeatured = isFeatured
        try await Amplify.DataStore.save(updated)
        return updated
    }

    /// Force-publishes an event (status → live) without the tally gate — for
    /// hand-curated events during bootstrap.
    static func forcePublish(eventID: String) async throws {
        guard var event = try await Amplify.DataStore.query(Event.self, byId: eventID) else {
            throw AdminError.eventNotFound
        }
        event.status = EventStatus.live.rawValue
        try await Amplify.DataStore.save(event)
    }

    /// Attaches a DJ to an event's lineup directly, bypassing the join/tally flow.
    /// Stamps a snapshot `coinContribution` from the DJ's current rank (bootstrap
    /// mirror of Lambda config — see `Data/RankWeight.swift`). No-op if the DJ is
    /// already on this event's lineup.
    static func attachDJ(_ dj: User, toEventID eventID: String) async throws {
        guard let event = try await Amplify.DataStore.query(Event.self, byId: eventID) else {
            throw AdminError.eventNotFound
        }
        let existing = (try? await Amplify.DataStore.query(
            EventDJLink.self,
            where: EventDJLink.keys.event == eventID
        )) ?? []
        guard !existing.contains(where: { $0.djID == dj.id }) else { return }

        let rank = dj.djRank ?? 1
        let link = EventDJLink(
            event: event,
            djID: dj.id,
            rankAtJoining: rank,
            coinContribution: RankWeight.coins(forRank: rank),
            createdAt: Temporal.DateTime(Date(), timeZone: .current)
        )
        try await Amplify.DataStore.save(link)
    }
}

enum AdminError: LocalizedError {
    case eventNotFound
    var errorDescription: String? {
        switch self {
        case .eventNotFound: return "That event could not be found."
        }
    }
}
