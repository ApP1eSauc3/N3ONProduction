// EventStatus.swift
// N3ON — Data layer

enum EventStatus: String, Codable {
    case pending    // limbo — tally not yet met, not visible on map
    case live       // tally met, poster uploaded, visible to all users
    case cancelled
}
