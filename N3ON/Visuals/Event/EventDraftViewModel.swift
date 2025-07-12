//
//  EventDraftViewModel.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import Foundation
import SwiftUI
import Combine
import MapKit
import Amplify

@MainActor
class EventDraftViewModel: ObservableObject {
    enum Package: String, CaseIterable, Identifiable {
            case basic, medium, extreme
            var id: String { rawValue }
        }
   
    
        @Published var eventPosterImage: UIImage?
        @Published var eventPosterKey: String?

        @Published var venue: Venue?
        @Published var package: Package = .basic
        @Published var specialRequest: String = ""

        @Published var invitedDJUsernames: [String] = []
        @Published var vjUsername: String? = nil
        @Published var eventDate: Date = Date()

        @Published var searchQuery: String = ""
        @Published var djSuggestions: [String] = []
        @Published var vjSuggestions: [String] = []

        func reset() {
            venue = nil
            package = .basic
            specialRequest = ""
            invitedDJUsernames = []
            vjUsername = nil
            eventDate = Date()
            searchQuery = ""
            djSuggestions = []
            vjSuggestions = []
        }

        func addDJ(_ username: String) {
            guard !invitedDJUsernames.contains(username) else { return }
            invitedDJUsernames.append(username)
        }

        func removeDJ(_ username: String) {
            invitedDJUsernames.removeAll { $0 == username }
        }

        func setVJ(_ username: String) {
            vjUsername = username
        }

        func isReadyToSubmit() -> Bool {
            return venue != nil && !invitedDJUsernames.isEmpty
        }

        func submitEvent() async {
            guard let venue = venue else { return }
            do {
                let currentUser = try await Amplify.Auth.getCurrentUser()
                let event = Event(
                    id: UUID().uuidString,
                    venueID: venue.id,
                    hostDJID: currentUser.userId,
                    djUsernames: invitedDJUsernames,
                    vjUsername: vjUsername,
                    package: package.rawValue,
                    requestNote: specialRequest,
                    eventDate: Temporal.DateTime(eventDate)
                )
                try await Amplify.DataStore.save(event)
                print("✅ Event submitted successfully")
            } catch {
                print("❌ Event submission failed: \(error)")
            }
        }

        // DJ's venue glow intensity logic
        func glowStrength(for venue: Venue, allEvents: [Event]) -> Double {
            let calendar = Calendar.current
            let today = Date()
            let thisWeekend = calendar.date(byAdding: .day, value: 3 - calendar.component(.weekday, from: today), to: today) ?? today
            let weekendRange = 0..<7

            let venueEvents = allEvents.filter { $0.venueID == venue.id }

            var glow: Double = 0.0
            for event in venueEvents {
                let daysFromNow = calendar.dateComponents([.day], from: today, to: event.eventDate.foundationDate).day ?? 30

                switch daysFromNow {
                case weekendRange:
                    glow += 1.0
                case 8..<15:
                    glow += 0.6
                case 15..<30:
                    glow += 0.3
                default:
                    glow += 0.1
                }
            }

            return min(glow, 1.0) // max glow capped at 1.0
        }
    }

    #Preview {
        Text("EventDraftViewModel")
            .environmentObject(EventDraftViewModel())
    }
