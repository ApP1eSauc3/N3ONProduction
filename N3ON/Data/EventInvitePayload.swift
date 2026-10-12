// EventInvitePayload.swift
// N3ON — Data layer
//
// Wire format of an event invitation sent as a chat message (Message.content):
//   {"type":"event_invite","eventID":"...","eventName":"...","venueName":"...","eventDate":"<ISO8601>"}
//
// Single definition shared by the sender (EventInviteSheet), the renderer
// (MessageRow) and — by contract — the joinEvent Lambda, which re-parses the
// host's message to verify an invite before adding a DJ to a lineup.
// Detection must parse, never prefix-match: JSON key order is not guaranteed.

import Foundation

struct EventInvitePayload: Codable, Equatable {
    static let messageType = "event_invite"

    let type: String
    let eventID: String
    let eventName: String
    let venueName: String
    let eventDate: String   // ISO 8601

    init(eventID: String, eventName: String, venueName: String, eventDate: Date) {
        self.type = Self.messageType
        self.eventID = eventID
        self.eventName = eventName
        self.venueName = venueName
        self.eventDate = ISO8601DateFormatter().string(from: eventDate)
    }

    /// Returns the payload when `content` is an event invitation, else nil.
    static func parse(_ content: String) -> EventInvitePayload? {
        guard content.first == "{",
              let data = content.data(using: .utf8),
              let payload = try? JSONDecoder().decode(EventInvitePayload.self, from: data),
              payload.type == messageType,
              !payload.eventID.isEmpty
        else { return nil }
        return payload
    }

    /// JSON string for Message.content. Sorted keys keep the output stable.
    func encodedContent() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var date: Date? { ISO8601DateFormatter().date(from: eventDate) }
}
