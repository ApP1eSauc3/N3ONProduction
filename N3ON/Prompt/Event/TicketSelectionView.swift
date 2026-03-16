// TicketSelectionView.swift
// N3ON
//
// CHANGES FROM ORIGINAL:
// 1. selectedTicketID changed from local @State to @Binding — lifted to
//    EventDetailView so the purchase button can read which ticket is selected.
//    Original kept selectedTicketID internal, making it invisible to the
//    purchase action which lived in the parent view.
//
// NOTE: TicketType is a client-side UI struct (Codable, Identifiable).
// It is NOT a DataStore model. remainingStock on TicketType is client-supplied
// and not server-validated. For production, ticket stock must come from the server.
// Schema Event currently has ticketPrice: Float! (single price only).
// To support multiple ticket tiers, add TicketType @model to schema.graphql.

import SwiftUI

struct TicketSelectionView: View {
    let ticketTypes: [TicketType]
    @Binding var selectedTicketID: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tickets").font(.headline)

            if ticketTypes.isEmpty {
                Text("General Admission")
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            } else {
                ForEach(ticketTypes) { ticket in
                    TicketRow(
                        ticket: ticket,
                        isSelected: selectedTicketID == ticket.id
                    ) {
                        selectedTicketID = ticket.id
                    }
                }
            }
        }
    }
}
