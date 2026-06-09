// EventDJSummary.swift
// N3ON
//
// Display-only snapshot of a DJ participating in an event.
// Built from EventDJLink + User records at load time.

import Foundation

struct EventDJSummary: Identifiable {
    let id: String          // djID
    let username: String
    let avatarKey: String?
    let rank: Int
    let coinContribution: Int
}
