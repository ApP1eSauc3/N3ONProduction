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

    private static func checkDJVenue(djUserID: String, venueUserID: String) async -> ChatEligibility {
        do {
            // 1. All EventDJLinks for this DJ
            let allLinks = try await Amplify.DataStore.query(EventDJLink.self)
            let linkedEventIDs = Set(allLinks
                .filter { $0.djID == djUserID }
                .compactMap { $0.event?.id })
            guard !linkedEventIDs.isEmpty else { return .ineligible(reason: .noSharedActiveEvent) }

            // 2. Venues owned by the venue user
            let allVenues = try await Amplify.DataStore.query(Venue.self)
            let venueIDs = Set(allVenues
                .filter { $0.owner?.id == venueUserID }
                .map { $0.id })
            guard !venueIDs.isEmpty else { return .ineligible(reason: .noSharedActiveEvent) }

            // 3. Events the DJ is linked to that are hosted at one of those venues
            let allEvents = try await Amplify.DataStore.query(Event.self)
            let sharedEvents = allEvents.filter {
                linkedEventIDs.contains($0.id) && venueIDs.contains($0.venueID)
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
