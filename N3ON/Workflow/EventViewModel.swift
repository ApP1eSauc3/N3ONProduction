// EventViewModel.swift
// N3ON

import Foundation
import Amplify

@MainActor
final class EventViewModel: ObservableObject {
    @Published var event: Event
    @Published var isLoading = false
    @Published var errorMessage: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    init(event: Event) {
        self.event = event
    }

    func handlePurchase(ticketID: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await TicketService.purchaseTicket(eventID: event.id)
            if let refreshed = try await Amplify.DataStore.query(Event.self, byId: event.id) {
                event = refreshed
            }
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
