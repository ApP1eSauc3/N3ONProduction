// VenueStatus.swift
// N3ON — Data layer
// Canonical status strings for Venue.approvalStatus.
// Use .rawValue when writing to / comparing with DataStore strings.

enum VenueStatus: String {
    case approved
    case pending
    case rejected
}
