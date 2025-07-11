//
//  TicketSelectionView.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct TicketSelectionView: View {
    var ticketTypes: [TicketType]
    @State private var selectedTicketID: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tickets")
                .font(.headline)
            
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
