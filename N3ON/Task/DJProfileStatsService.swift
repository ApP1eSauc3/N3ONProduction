// DJProfileStatsService.swift
// N3ON — Task layer
// Evaluates a DJ's metrics against rank-promotion thresholds and upgrades
// djRank in DataStore when criteria are met. Called once on login.

import Foundation
import Amplify

extension Notification.Name {
    static let djLevelUpgraded = Notification.Name("DJLevelUpgraded")
}

class DJProfileStatsService {
    static func evaluateAndUpgradeDJLevel(for user: User) async {
        guard (user.djRank ?? 0) < 5 else { return }

        do {
            let links = try await Amplify.DataStore.query(EventDJLink.self,
                where: EventDJLink.keys.djID.eq(user.id))
            // EventDJLink.event is a belongsTo association — access ID via .event?.id
            let eventIDs = Set(links.compactMap { $0.event?.id })
            let djEvents = try await Amplify.DataStore.query(Event.self)
                .filter { eventIDs.contains($0.id) }
            let hostedEvents = djEvents.filter { $0.hostDJID == user.id }

            let currentDate = Date()
            let accountAgeMonths = Calendar.current.dateComponents([.month], from: user.createdAt?.foundationDate ?? currentDate, to: currentDate).month ?? 0
            let attendanceCount = djEvents.count
            let headlinedCount = hostedEvents.count

            let avgCapacity = try await calculateAverageCapacity(for: djEvents)

            let currentRank = user.djRank ?? 0
            let newLevel: Int
            switch currentRank {
            case 0, 1:
                newLevel = (accountAgeMonths >= 6 && attendanceCount >= 26 && avgCapacity >= 65) ? 2 : currentRank
            case 2:
                newLevel = (accountAgeMonths >= 12 && attendanceCount >= 50 && avgCapacity >= 65) ? 3 : currentRank
            case 3:
                newLevel = (accountAgeMonths >= 12 && headlinedCount >= 1 && avgCapacity >= 75) ? 4 : currentRank
            case 4:
                // EndorsementRequest.toUser is a belongsTo association — use .toUser key, not .toUserID
                let endorsements = try await Amplify.DataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.toUser == user.id && EndorsementRequest.keys.status == "approved")
                newLevel = (accountAgeMonths >= 12 && headlinedCount >= 4 && avgCapacity >= 75 && endorsements.contains(where: { $0.fromUser != nil })) ? 5 : currentRank
            default:
                newLevel = currentRank
            }

            if newLevel != currentRank {
                var updatedUser = user
                updatedUser.djRank = newLevel
                try await Amplify.DataStore.save(updatedUser)

                await MainActor.run {
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

            // DailyUserCount.venue is a belongsTo — key is .venue not .venueID
            let daily = try await Amplify.DataStore.query(DailyUserCount.self, where: DailyUserCount.keys.venue == venueID)
            let totalUsers = daily.reduce(0) { $0 + ($1.userCount ?? 0) }
            let ratio = Double(totalUsers) / (Double(venue.maxCapacity) * Double(daily.count))
            capacityRatios.append(ratio * 100)
        }

        return capacityRatios.isEmpty ? 0 : capacityRatios.reduce(0, +) / Double(capacityRatios.count)
    }

    static func runOnLogin() {
        Task {
            do {
                if let user = try await AuthService.getCurrentUserModel() {
                    await evaluateAndUpgradeDJLevel(for: user)
                }
            } catch {
                print("❌ Failed to run DJ level check on login: \(error)")
            }
        }
    }
}
