//
//  DJProfileStat.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import Foundation
import Amplify
import SwiftUI

class DJProfileStatsService {
    static func evaluateAndUpgradeDJLevel(for user: User) async {
        guard user.endorsementLevel < 5 else { return }

        do {
            let djEvents = try await Amplify.DataStore.query(Event.self, where: Event.keys.djUsernames.contains(user.username))
            let hostedEvents = djEvents.filter { $0.hostDJID == user.id }

            let currentDate = Date()
            let accountAgeMonths = Calendar.current.dateComponents([.month], from: user.createdAt ?? currentDate, to: currentDate).month ?? 0
            let attendanceCount = djEvents.count
            let headlinedCount = hostedEvents.count

            let avgCapacity = try await calculateAverageCapacity(for: djEvents)

            let newLevel: Int
            switch user.endorsementLevel {
            case 0, 1:
                newLevel = (accountAgeMonths >= 6 && attendanceCount >= 26 && avgCapacity >= 65) ? 2 : user.endorsementLevel
            case 2:
                newLevel = (accountAgeMonths >= 12 && attendanceCount >= 50 && avgCapacity >= 65) ? 3 : user.endorsementLevel
            case 3:
                newLevel = (accountAgeMonths >= 12 && headlinedCount >= 1 && avgCapacity >= 75) ? 4 : user.endorsementLevel
            case 4:
                let endorsements = try await Amplify.DataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.toUserID == user.id && EndorsementRequest.keys.status == "approved")
                newLevel = (accountAgeMonths >= 12 && headlinedCount >= 4 && avgCapacity >= 75 && endorsements.contains(where: { $0.fromUserID != nil })) ? 5 : user.endorsementLevel
            default:
                newLevel = user.endorsementLevel
            }

            if newLevel != user.endorsementLevel {
                var updatedUser = user
                updatedUser.endorsementLevel = newLevel
                try await Amplify.DataStore.save(updatedUser)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .djLevelUpgraded, object: nil, userInfo: ["newLevel": newLevel])
                }

                print("🎉 Upgraded DJ \(user.username) to level \(newLevel)")
            }

        } catch {
            print("❌ Error evaluating DJ level: \(error)")
        }
    }

    private static func calculateAverageCapacity(for events: [Event]) async throws -> Double {
        let venueIDs = Set(events.map { $0.venueID })
        var capacityRatios: [Double] = []

        for venueID in venueIDs {
            guard let venue = try await Amplify.DataStore.query(Venue.self, byId: venueID),
                  venue.maxCapacity > 0 else { continue }

            let daily = try await Amplify.DataStore.query(DailyUserCount.self, where: DailyUserCount.keys.venueID == venueID)
            let totalUsers = daily.reduce(0) { $0 + $1.userCount }
            let ratio = Double(totalUsers) / (Double(venue.maxCapacity) * Double(daily.count))
            capacityRatios.append(ratio * 100)
        }

        return capacityRatios.isEmpty ? 0 : capacityRatios.reduce(0, +) / Double(capacityRatios.count)
    }

    static func runOnLogin() {
        Task {
            do {
                let authUser = try await Amplify.Auth.getCurrentUser()
                if let user = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                    await evaluateAndUpgradeDJLevel(for: user)
                }
            } catch {
                print("❌ Failed to run DJ level check on login: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let djLevelUpgraded = Notification.Name("DJLevelUpgraded")
}
