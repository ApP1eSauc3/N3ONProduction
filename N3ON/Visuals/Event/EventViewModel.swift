//
//  EventViewModel.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation

class EventViewModel: ObservableObject {
    @Published var event: Event
    @Published var isLoading = false
    @Published var error: Error?
    
    init(event: Event) {
        self.event = event
    }
    
    func handlePurchase() {
        isLoading = true
        TicketService.purchaseTicket(eventID: event.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let ticket):
                    self?.event.isSoldOut = ticket.remainingStock == 0
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: event.eventDate.foundationDate)
    }
}
