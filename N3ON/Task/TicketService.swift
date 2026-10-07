//
//  TicketService.swift
//  N3ON
//
//  Created by liam howe on 10/3/2026.
//

import Foundation
import Amplify

enum TicketPurchaseError: LocalizedError, Equatable {
    case soldOut
    case eventNotFound
    case notOnSale
    case eventEnded
    case paymentRequired
    case limitReached
    case tallyNotMet
    case serverError(String)

    /// Maps the purchaseTicket Lambda's `errorCode`
    /// (amplify/backend/function/purchaseTicket/src/index.js).
    init(errorCode: String?) {
        switch errorCode {
        case "SOLD_OUT":          self = .soldOut
        case "EVENT_NOT_FOUND":   self = .eventNotFound
        case "EVENT_NOT_ON_SALE": self = .notOnSale
        case "EVENT_ENDED":       self = .eventEnded
        case "PAYMENT_REQUIRED":  self = .paymentRequired
        case "LIMIT_REACHED":     self = .limitReached
        case "TALLY_NOT_MET":     self = .tallyNotMet
        default:                  self = .serverError(errorCode ?? "Unknown")
        }
    }

    var errorDescription: String? {
        switch self {
        case .soldOut:             return "This event is sold out."
        case .eventNotFound:       return "Event not found."
        case .notOnSale:           return "Tickets for this event aren't on sale yet."
        case .eventEnded:          return "This event has already started."
        case .paymentRequired:     return "Paid tickets aren't available in the app yet."
        case .limitReached:        return "You've reached the ticket limit for this event."
        case .tallyNotMet:         return "Ticket sales open once the DJ lineup is confirmed."
        case .serverError(let m):  return "Purchase failed: \(m)"
        }
    }
}

enum TicketService {

    /// Buys `quantity` tickets via the purchaseTicket Lambda — the only path
    /// that mints Ticket rows. The buyer is identified server-side from the
    /// request signature; price and stock come from the server's Event record.
    @discardableResult
    static func purchaseTicket(eventID: String, quantity: Int = 1) async throws -> PurchaseResult {
        let data: Data
        do {
            data = try await N3ONRESTClient.post(
                path: "/tickets/purchase",
                json: ["eventID": eventID, "quantity": max(1, quantity)]
            )
        } catch {
            throw TicketPurchaseError.serverError(error.localizedDescription)
        }
        return try decodePurchase(data)
    }

    /// Decodes the Lambda envelope. Internal for unit tests.
    static func decodePurchase(_ data: Data) throws -> PurchaseResult {
        guard let response = try? JSONDecoder().decode(PurchaseResult.self, from: data) else {
            throw TicketPurchaseError.serverError("Unexpected response")
        }
        guard response.success else { throw TicketPurchaseError(errorCode: response.errorCode) }
        return response
    }

    static func tickets(for eventID: String) async throws -> [Ticket] {
        try await Amplify.DataStore.query(
            Ticket.self,
            where: Ticket.keys.eventID == eventID
        )
    }

    static func myTickets() async throws -> [Ticket] {
        let userID = try await AuthService.currentUserId()
        return try await Amplify.DataStore.query(
            Ticket.self,
            where: Ticket.keys.userID == userID
        )
    }
}

struct PurchaseResult: Decodable, Equatable {
    let success: Bool
    let errorCode: String?
    let ticketID: String?
    let remainingStock: Int?
}
