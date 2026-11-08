// ChatEligibilityService.swift
// N3ON — Task layer
// Enforces chat access rules against live DataStore data.
// Called before any chat room is opened or created.

import Foundation
import Amplify

struct ChatEligibilityService {

    // MARK: - Public API

    /// Determines whether `currentUserID` (with `currentRole`) may chat
    /// with `recipientUserID` (with `recipientRole`).
    ///
    /// Rules:
    ///   DJ  ↔ DJ    — always eligible
    ///   DJ  ↔ Venue — eligible only while sharing a live/upcoming event,
    ///                 and for up to 48 hrs after that event's scheduled date
    ///   Any ↔ Regular — ineligible (regular users have no chat access)
    ///   Venue ↔ Venue — ineligible
    static func check(
        currentUserID: String,
        currentRole: AppRole,
        recipientUserID: String,
        recipientRole: AppRole
    ) async -> ChatEligibility {
        switch (currentRole, recipientRole) {
        case (.dj, .dj):
            return .eligible(type: .djToDJ)
        case (.dj, .venue):
            return await checkDJVenue(djUserID: currentUserID, venueUserID: recipientUserID)
        case (.venue, .dj):
            return await checkDJVenue(djUserID: recipientUserID, venueUserID: currentUserID)
        case (_, .regular), (.regular, _):
            return .ineligible(reason: .regularUserCannotChat)
        default:
            return .ineligible(reason: .rolesIncompatible)
        }
    }

    /// Returns `true` if the 48-hour post-event window has closed for a given event date.
    static func isEventExpired(eventDate: Date) -> Bool {
        Date() > eventDate.addingTimeInterval(chatEventExpiryInterval)
    }

    // MARK: - Private

    static func checkDJVenue(djUserID: String, venueUserID: String) async -> ChatEligibility {
        do {
            // 1. All EventDJLinks for this DJ
            // Filters run in DataStore's SQLite (predicates), not over every
            // row on the device — this check runs before each chat opens.
            let links = try await Backend.dataStore.query(EventDJLink.self, where: EventDJLink.keys.djID == djUserID)
            let linkedEventIDs = Set(links.compactMap { $0.event?.id })
            guard !linkedEventIDs.isEmpty else { return .ineligible(reason: .noSharedActiveEvent) }

            // 2. Venues owned by the venue user
            let venues = try await Backend.dataStore.query(Venue.self, where: Venue.keys.owner == venueUserID)
            let venueIDs = Set(venues.map { $0.id })
            guard !venueIDs.isEmpty else { return .ineligible(reason: .noSharedActiveEvent) }

            // 3. Events the DJ is linked to that are hosted at one of those venues
            var sharedEvents: [Event] = []
            for venueID in venueIDs {
                let atVenue = try await Backend.dataStore.query(Event.self, where: Event.keys.venueID == venueID)
                sharedEvents += atVenue.filter { linkedEventIDs.contains($0.id) }
            }
            guard !sharedEvents.isEmpty else { return .ineligible(reason: .noSharedActiveEvent) }

            // 4. Pick the most recent eligible event within the 48-hr window
            let sorted = sharedEvents.sorted {
                $0.eventDate.foundationDate > $1.eventDate.foundationDate
            }
            for event in sorted {
                guard !Task.isCancelled else { return .ineligible(reason: .noSharedActiveEvent) }
                if !isEventExpired(eventDate: event.eventDate.foundationDate) {
                    return .eligible(type: .djToVenue(eventID: event.id))
                }
            }

            // Shared events exist but all windows have closed
            return .ineligible(reason: .eventExpired)
        } catch {
            return .ineligible(reason: .noSharedActiveEvent)
        }
    }
}
