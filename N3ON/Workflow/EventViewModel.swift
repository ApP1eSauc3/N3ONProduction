// EventViewModel.swift
// N3ON

import Foundation
import UIKit

@MainActor
final class EventViewModel: ObservableObject {
    @Published var event: Event
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var djProfiles: [User] = []
    @Published var isLoadingDJs = false
    @Published var ticketQuantity: Int = 1

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    init(event: Event) {
        self.event = event
    }

    func loadDJProfiles() async {
        isLoadingDJs = true
        defer { isLoadingDJs = false }
        do {
            let links = try await EventService.djLinks(forEventID: event.id)
            var djIDs: [String] = links.map(\.djID)
            // Host DJ may not have a link record yet — always show them first
            if !djIDs.contains(event.hostDJID) {
                djIDs.insert(event.hostDJID, at: 0)
            }
            // Independent per-DJ fetches — fan out so an 8-DJ lineup costs one
            // round-trip of latency, not eight. Order is restored afterwards.
            let fetched = await withTaskGroup(of: (Int, User?).self) { group in
                for (index, id) in djIDs.enumerated() {
                    group.addTask { (index, try? await UserService.fetch(byId: id)) }
                }
                var results = [User?](repeating: nil, count: djIDs.count)
                for await (index, user) in group { results[index] = user }
                return results
            }
            guard !Task.isCancelled else { return }
            djProfiles = fetched.compactMap { $0 }
        } catch {
            // Non-fatal — missing lineup doesn't block purchase
        }
    }

    func handlePurchase() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await TicketService.purchaseTicket(eventID: event.id, quantity: ticketQuantity)
            if let refreshed = try await EventService.fetchEvent(byId: event.id) {
                event = refreshed
            }
            // Schedule a local reminder 24h before the event
            await PushNotificationService.scheduleEventReminder(for: event)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isSoldOut: Bool {
        event.availableTickets == 0
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: event.eventDate.foundationDate)
    }

    func shareEvent() {
        let text = "\(event.eventName) — \(formattedDate)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}
