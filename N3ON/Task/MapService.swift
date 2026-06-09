// MapService.swift
// N3ON — Task layer
// All DataStore queries for the map live here.
// MapViewModel never calls Amplify.DataStore directly.

import Foundation
import Amplify

struct MapService {

    // MARK: - Venues

    /// All venues owned by the given user ID.
    static func venues(ownedBy ownerID: String) async throws -> [Venue] {
        let all = try await Amplify.DataStore.query(Venue.self)
        return all.filter { $0.owner?.id == ownerID }
    }

    /// All venues with `approvalStatus == "approved"`.
    static func approvedVenues() async throws -> [Venue] {
        let all = try await Amplify.DataStore.query(Venue.self)
        return all.filter { $0.approvalStatus == "approved" }
    }

    // MARK: - Events

    /// All events at a set of venue IDs whose eventDate is on or after `after`.
    static func upcomingEvents(atVenueIDs venueIDs: Set<String>, after date: Date = Date()) async throws -> [Event] {
        let all = try await Amplify.DataStore.query(Event.self)
        return all.filter { venueIDs.contains($0.venueID) && $0.eventDate.foundationDate >= date }
    }

    /// All upcoming events across all venues (date ≥ now).
    static func allUpcomingEvents(after date: Date = Date()) async throws -> [Event] {
        let all = try await Amplify.DataStore.query(Event.self)
        return all.filter { $0.eventDate.foundationDate >= date }
    }

    // MARK: - DJs

    /// `EventDJLink` records whose event ID is in the supplied set.
    static func djLinks(forEventIDs eventIDs: Set<String>) async throws -> [EventDJLink] {
        let all = try await Amplify.DataStore.query(EventDJLink.self)
        return all.filter {
            guard let eid = $0.event?.id else { return false }
            return eventIDs.contains(eid)
        }
    }

    /// The `User` record for a given DJ ID. Returns `nil` if not found.
    static func user(byId id: String) async throws -> User? {
        try await Amplify.DataStore.query(User.self, byId: id)
    }

    // MARK: - Follows

    /// All `followeeID` strings for a given follower.
    static func followedUserIDs(for followerID: String) async throws -> Set<String> {
        let follows = try await Amplify.DataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followerID == followerID
        )
        return Set(follows.map { $0.followeeID })
    }
}
