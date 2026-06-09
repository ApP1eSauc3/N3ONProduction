// ChatEligibility.swift
// N3ON — Data layer
// Pure types describing chat access rules. No async, no network, no SwiftUI.

import Foundation

/// Whether two users may open a chat, and what kind.
/// Roles are mutually exclusive — the three cases below cover every valid combination.
enum ChatEligibility: Equatable {
    case eligible(type: ChatType)
    case ineligible(reason: ChatIneligibilityReason)
}

/// The permitted chat channel between two eligible users.
enum ChatType: Equatable {
    /// Both participants hold the .dj role. No expiry.
    case djToDJ
    /// One DJ, one VenueOwner, linked via a shared active event.
    /// Expires `chatEventExpiryInterval` seconds after the event's scheduled date.
    case djToVenue(eventID: String)
}

/// Why a chat request was denied.
enum ChatIneligibilityReason: Equatable {
    case regularUserCannotChat    // .regular role has no chat access
    case noSharedActiveEvent      // DJ-Venue pair has no current EventDJLink
    case eventExpired             // 48-hour post-event window has closed
    case rolesIncompatible        // e.g. venue↔venue, regular↔venue
}

/// How long after an event's scheduled date the DJ↔Venue chat channel remains open.
let chatEventExpiryInterval: TimeInterval = 48 * 60 * 60 // 48 hours
