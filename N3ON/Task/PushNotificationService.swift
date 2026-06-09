// PushNotificationService.swift
// N3ON — Task layer
//
// Manages notification permissions and local event-reminder scheduling.
// Remote push (APNs via Amplify Pinpoint) requires `amplify add notifications` — see AGENTS.md.
// Until Pinpoint is configured, all push surfaces use local UNUserNotificationCenter.
//
// Remote push setup checklist:
//   1. amplify add notifications → configure Pinpoint channel
//   2. Add AWSPinpointPushNotificationsPlugin to Podfile
//   3. Register plugin in N3ONApp.configureAmplify()
//   4. Call Amplify.Notifications.Push.registerDevice(apnsToken:) in AppDelegate.didRegisterForRemoteNotifications

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
