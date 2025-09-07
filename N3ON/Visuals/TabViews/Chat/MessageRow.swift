//
//  MessageRow.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

// ===============================================
// File: Chat/MessageRow.swift
// WHY: Stable ChatMessage.id; tiny, readable bubble.
// ===============================================
import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    @State private var showTimestamp = false
    
    var body: some View {
        VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
            if !message.isCurrentUser {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(Color("neonPurpleBackground"))
                    .padding(.leading, 12)
            }
            HStack(alignment: .bottom) {
                if !message.isCurrentUser { profileIndicator }
                messageContent
                    .onTapGesture { withAnimation { showTimestamp.toggle() } }
                if message.isCurrentUser { deliveryStatusIndicator }
            }
            if showTimestamp {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .id(message.id)
    }
    
    private var profileIndicator: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color("dullPurple"), Color("neonPurpleBackground")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 24, height: 24)
            .overlay(
                Text(message.sender.prefix(1).uppercased())
                    .font(.caption)
                    .foregroundColor(.white)
            )
    }
    
    private var messageContent: some View {
        Text(message.content)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.isCurrentUser
                        ? LinearGradient(colors: [Color("neonPurpleBackground"), Color("dullPurple")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : Color(.systemGray5))
            .foregroundColor(message.isCurrentUser ? .white : .primary)
            .cornerRadius(18, corners: message.isCurrentUser
                          ? [.topLeft, .topRight, .bottomLeft]
                          : [.topLeft, .topRight, .bottomRight])
            .contextMenu {
                Button("Copy") { UIPasteboard.general.string = message.content }
            }
    }
    
    private var deliveryStatusIndicator: some View {
        Group {
            switch message.deliveryStatus {
            case .sending:   ProgressView().scaleEffect(0.5)
            case .sent:      Image(systemName: "checkmark").font(.caption2).foregroundColor(.gray)
            case .delivered: Image(systemName: "checkmark").font(.caption2).foregroundColor(.gray)
            case .read:      Image(systemName: "checkmark").font(.caption2).foregroundColor(Color("neonPurpleBackground"))
            case .failed:    Image(systemName: "exclamationmark.circle").font(.caption2).foregroundColor(.red)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - View Model DTO (stable id)
struct ChatMessage: Identifiable {
    enum DeliveryStatus { case sending, sent, delivered, read, failed }
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
    let isCurrentUser: Bool
    var deliveryStatus: DeliveryStatus = .sent
    
    init(id: String = UUID().uuidString,
         sender: String,
         content: String,
         timestamp: Date,
         isCurrentUser: Bool) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isCurrentUser = isCurrentUser
    }
}
