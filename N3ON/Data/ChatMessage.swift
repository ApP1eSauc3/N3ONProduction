// ChatMessage.swift
// N3ON — Data layer
// View-model DTO for a single chat message. No async, no SwiftUI.

import Foundation

struct ChatMessage: Identifiable {

    enum DeliveryStatus {
        case sending    // optimistic insert — not yet confirmed by DataStore
        case sent       // saved to DataStore
        case delivered  // received by the other side (reserved for future read receipts)
        case read       // recipient has opened the thread
        case failed     // DataStore save failed — user can retry
    }

    let id: String
    let sender: String
    let content: String
    let timestamp: Date
    let isCurrentUser: Bool
    var deliveryStatus: DeliveryStatus

    init(
        id: String = UUID().uuidString,
        sender: String,
        content: String,
        timestamp: Date,
        isCurrentUser: Bool,
        deliveryStatus: DeliveryStatus = .sent
    ) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isCurrentUser = isCurrentUser
        self.deliveryStatus = deliveryStatus
    }
}
