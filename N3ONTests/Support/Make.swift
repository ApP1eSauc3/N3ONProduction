// Make.swift
// N3ONTests
//
// Compact factories for the generated Amplify models (field lists mirror
// amplify/generated/models — update with codegen).

import Foundation
import Amplify
@testable import N3ON

enum Make {
    static func now(_ days: Int = 0) -> Temporal.DateTime {
        Temporal.DateTime(Date().addingTimeInterval(Double(days) * 86_400), timeZone: .current)
    }

    static func user(_ id: String, rank: Int? = nil, isDJ: Bool = true, curated: Bool = false,
                     username: String? = nil, avatarKey: String? = nil) -> User {
        User(id: id, username: username ?? id, avatarKey: avatarKey, isDJ: isDJ, djRank: rank,
             isCurated: curated, isSharingLocation: false, coinBalance: 0)
    }

    static func venue(_ id: String, owner: User? = nil, capacity: Int = 150,
                      status: String = "approved", name: String? = nil) -> Venue {
        Venue(id: id, name: name ?? "Venue \(id)", description: "d", address: "1 St", latitude: -27.47,
              longitude: 153.02, owner: owner, maxCapacity: capacity, approvalStatus: status)
    }

    static func event(_ id: String, venueID: String = "v1", host: String = "host", days: Int = 30,
                      price: Double = 0, stock: Int = 100, status: String = "live",
                      name: String? = nil, featured: Bool = false) -> Event {
        Event(id: id, venueID: venueID, hostDJID: host, package: "basic", eventDate: now(days),
              eventName: name ?? "Event \(id)", description: "desc", ticketPrice: price,
              availableTickets: stock, status: status, isFeatured: featured)
    }

    static func link(_ id: String? = nil, event: Event, dj: String, rank: Int = 2) -> EventDJLink {
        EventDJLink(id: id ?? "\(event.id)_\(dj)", event: event, djID: dj, rankAtJoining: rank,
                    coinContribution: RankWeight.coins(forRank: rank), createdAt: now())
    }

    static func ticket(_ id: String, event: String, user: String, quantity: Int = 1) -> Ticket {
        Ticket(id: id, eventID: event, userID: user, quantity: quantity, purchaseTime: now(), pricePaid: 0)
    }

    /// `count` items built by `make(i)`.
    static func many<T>(_ count: Int, _ make: (Int) -> T) -> [T] { (0..<count).map(make) }
}
