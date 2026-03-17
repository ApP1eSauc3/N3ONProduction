// TicketRow.swift
// N3ON

import SwiftUI

struct TicketRow: View {
    let ticket: TicketType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.name)
                        .font(.headline)
                    if let desc = ticket.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(ticket.remainingStock) remaining")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text("$\(Int(ticket.price))")
                    .font(.headline)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
            .padding(12)
            .background(isSelected ? Color.purple.opacity(0.15) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
