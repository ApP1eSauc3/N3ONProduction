// PushNotificationService.swift
// N3ON — Task layer
//
// Manages notification permissions and local event-reminder scheduling.
// All notifications today are LOCAL (UNUserNotificationCenter). Remote push is
// not built.
//
// Do NOT build remote push on Amplify's push category: it is Pinpoint-backed
// (AWSPinpointPushNotificationsPlugin is the only provider, verified up to
// amplify-swift 2.62.0), and Amazon Pinpoint reaches end of support on
// 2026-10-30 — its endpoints/segments/campaigns go away. Amplify's migration
// guide points at Amazon Connect Customer Profiles, which has no Swift push
// plugin yet. Provider decision is open (LAUNCH-CHECKLIST.md, Phase 5):
//   • direct APNs from a Lambda (device tokens stored per user) — fewest moving parts
//   • Amazon SNS mobile push
//   • AWS End User Messaging push APIs (the retained, non-endpoint part of Pinpoint)
// Any option needs an APNs .p8 key and a server-side token store.

import Foundation
import UserNotifications
import Amplify

enum PushNotificationService {

    // MARK: — Permission

    /// Requests APNs permission. Call once after the user signs in.
    /// Safe to call repeatedly — iOS debounces the system prompt after the first ask.
    @discardableResult
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: — Local event reminders

    /// Schedules a local notification 24 hours before `event.eventDate`.
    /// Uses the event ID as the notification identifier so it can be cancelled.
    static func scheduleEventReminder(for event: Event) async {
        let center = UNUserNotificationCenter.current()
        guard await requestPermission() else { return }

        let triggerDate = event.eventDate.foundationDate.addingTimeInterval(-86_400)
        guard triggerDate > Date() else { return }  // Skip if less than 24h away

        let content = UNMutableNotificationContent()
        content.title = "Event tomorrow 🎶"
        content.body = "\(event.eventName) starts in 24 hours. Don't miss it."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event-reminder-\(event.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Non-fatal — reminder is a nice-to-have
        }
    }

    /// Cancels a previously scheduled event reminder.
    static func cancelEventReminder(for eventID: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["event-reminder-\(eventID)"])
    }

    // MARK: — Badge

    /// Resets the app badge count to zero.
    static func clearBadge() async {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
