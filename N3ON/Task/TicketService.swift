//
//  TicketService.swift
//  N3ON
//
//  Created by liam howe on 10/3/2026.
//

import Foundation
import Amplify

enum TicketPurchaseError: LocalizedError {
    case soldOut
    case insufficientCoins
    case eventNotFound
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .soldOut:              return "This event is sold out."
        case .insufficientCoins:   return "You don't have enough coins for this ticket."
        case .eventNotFound:       return "Event not found."
        case .serverError(let m):  return "Purchase failed: \(m)"
        }
    }
}

enum TicketService {

    static func purchaseTicket(eventID: String) async throws {
        let userID = try await AuthService.currentUserId()

        let body: [String: String] = [
            "eventID": eventID,
            "userID": userID
        ]
        let bodyData = try JSONEncoder().encode(body)

        let request = RESTRequest(
            apiName: "n3onAPI",
            path: "/tickets/purchase",
            body: bodyData
        )

        do {
            let data = try await Amplify.API.post(request: request)
            let response = try JSONDecoder().decode(PurchaseResponse.self, from: data)

            if !response.success {
                switch response.errorCode {
                case "SOLD_OUT":            throw TicketPurchaseError.soldOut
                case "INSUFFICIENT_COINS":  throw TicketPurchaseError.insufficientCoins
                case "EVENT_NOT_FOUND":     throw TicketPurchaseError.eventNotFound
                default:                   throw TicketPurchaseError.serverError(response.errorCode ?? "Unknown")
                }
            }
        } catch let error as TicketPurchaseError {
            throw error
        } catch {
            throw TicketPurchaseError.serverError(error.localizedDescription)
        }
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

private struct PurchaseResponse: Decodable {
    let success: Bool
    let errorCode: String?
    let ticketID: String?
    let remainingStock: Int?
}
