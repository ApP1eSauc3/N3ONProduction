// EventInviteContext.swift
// N3ON — Data layer
// Passed from EventLimboView into EventInviteSheet so the sheet
// knows which event to attach the invitation message to.

import Foundation

struct EventInviteContext {
    let eventID: String
    let eventName: String
    let venueName: String
    let eventDate: Date
}
