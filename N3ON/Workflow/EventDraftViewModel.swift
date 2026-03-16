// EventDraftViewModel.swift
// N3ON
//

import Foundation
import SwiftUI
import Combine
import MapKit
import Amplify

struct RevenueBreakdown {
    let totalCoins: Int
    let venueCoins: Int
    let hostDJCoins: Int
    let djPayouts: [DJPayout]
}

struct DJPayout {
    let username: String
    let coins: Int
}

@MainActor
class EventDraftViewModel: ObservableObject {
    enum Package: String, CaseIterable, Identifiable {
        case basic, medium, extreme
        var id: String { rawValue }
    }

    @Published var posterImage: UIImage?
    @Published var posterKey: String?
    @Published var eventPosterImage: UIImage?
    @Published var eventPosterKey: String?
    @Published var venue: Venue?
    @Published var package: Package = .basic
    @Published var specialRequest: String = ""
    @Published var invitedDJs: [InvitedDJ] = []
    @Published var invitedDJUsernames: [String] = []
    @Published var vjUsername: String? = nil
    @Published var eventDate: Date = Date()
    @Published var eventTime: Date = Date()
    @Published var searchQuery: String = ""
    @Published var djSuggestions: [String] = []
    @Published var vjSuggestions: [String] = []
    @Published var eventName: String = ""
    @Published var eventDescription: String = ""
    @Published var availableTickets: Int = 100
    @Published var ticketPrice: Double = 0
    @Published var estimatedAttendance: Double = 100
    @Published var djSharePercentage: Double = 50
    @Published var hostDJRank: Int = 0
    @Published var submissionError: String?
    @Published var didSubmitSuccessfully = false

    let venueShareRatio: Double = 0.4
    let djPoolRatio: Double = 0.6

    var revenueBreakdown: RevenueBreakdown {
        let total = ticketPrice * estimatedAttendance
        let venueCoins = Int(total * venueShareRatio)
        let djPool = total * djPoolRatio
        let hostDJCut = hostDJRank == 5 ? djPool * (djSharePercentage / 100) : 0
        let remainingDJPool = djPool - hostDJCut
        let payouts = computePayouts(from: remainingDJPool)
        return RevenueBreakdown(
            totalCoins: Int(total),
            venueCoins: venueCoins,
            hostDJCoins: Int(hostDJCut),
            djPayouts: payouts
        )
    }

    func computePayouts(from pool: Double) -> [DJPayout] {
        let totalRank = invitedDJs.map(\.rank).reduce(0, +)
        guard totalRank > 0 else { return [] }
        return invitedDJs.map { dj in
            let share = (Double(dj.rank) / Double(totalRank)) * pool
            return DJPayout(username: dj.username, coins: Int(share))
        }
    }

    func addDJ(_ username: String) {
        guard !invitedDJUsernames.contains(username) else { return }
        invitedDJUsernames.append(username)
    }

    func removeDJ(_ username: String) {
        invitedDJUsernames.removeAll { $0 == username }
        invitedDJs.removeAll { $0.username == username }
    }

    func setVJ(_ username: String) { vjUsername = username }

    func meetsRankRequirements() -> Bool {
        let rank5Count = invitedDJs.filter { $0.rank == 5 }.count
        let rank4Count = invitedDJs.filter { $0.rank == 4 }.count
        return rank5Count >= 1 || rank4Count >= 3
    }

    func isReadyToSubmit() -> Bool {
        venue != nil && !invitedDJUsernames.isEmpty
    }

    func submitEvent() async {
        guard let venue = venue else { return }
        guard !eventName.trimmingCharacters(in: .whitespaces).isEmpty else {
            submissionError = "Event name is required."
            return
        }
        submissionError = nil

        do {
            let currentUser = try await Amplify.Auth.getCurrentUser()
            let event = Event(
                id: UUID().uuidString,
                venueID: venue.id,
                hostDJID: currentUser.userId,
                vjUsername: vjUsername,
                package: package.rawValue,
                requestNote: specialRequest,
                eventDate: Temporal.DateTime(eventDate, timeZone: .current),
                posterKey: posterKey,
                eventName: eventName,
                description: eventDescription,
                ticketPrice: ticketPrice,
                availableTickets: availableTickets
            )
            try await Amplify.DataStore.save(event)
            didSubmitSuccessfully = true
        } catch {
            submissionError = "Event submission failed: \(error.localizedDescription)"
        }
    }

    func glowStrength(for venue: Venue, allEvents: [Event]) -> Double {
        let calendar = Calendar.current
        let today = Date()
        let venueEvents = allEvents.filter { $0.venueID == venue.id }
        var glow: Double = 0.0

        for event in venueEvents {
            let daysFromNow = calendar.dateComponents([.day], from: today, to: event.eventDate.foundationDate).day ?? 30
            switch daysFromNow {
            case 0..<7:    glow += 1.0
            case 7..<15:   glow += 0.6
            case 15..<30:  glow += 0.3
            default:       glow += 0.1
            }
        }
        return min(glow, 1.0)
    }

    func reset() {
        venue = nil
        package = .basic
        specialRequest = ""
        invitedDJUsernames = []
        invitedDJs = []
        vjUsername = nil
        eventDate = Date()
        eventTime = Date()
        searchQuery = ""
        djSuggestions = []
        vjSuggestions = []
        ticketPrice = 0
        djSharePercentage = 50
        eventName = ""
        eventDescription = ""
        availableTickets = 100
        submissionError = nil
        didSubmitSuccessfully = false
    }
}

struct InvitedDJ: Identifiable {
    let id = UUID()
    let username: String
    let rank: Int
}
