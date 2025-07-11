//
//  MessageRow.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    @State private var showTimestamp = false
    
    var body: some View {
        VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
            // Sender name (only for others)
            if !message.isCurrentUser {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(Color("neonPurpleBackground"))
                    .padding(.leading, 12)
            }
            
            // Message bubble
            HStack(alignment: .bottom) {
                if !message.isCurrentUser {
                    profileIndicator
                }
                
                messageContent
                    .onTapGesture { withAnimation { showTimestamp.toggle() } }
                
                if message.isCurrentUser {
                    deliveryStatusIndicator
                }
            }
            
            // Timestamp (conditional)
            if showTimestamp {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .id(message.id)  // For smooth transitions
    }
    
    // MARK: - Subviews
    
    private var profileIndicator: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color("dullPurple"), Color("neonPurpleBackground")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
            .background(messageBackground)
            .foregroundColor(message.isCurrentUser ? .white : .primary)
            .cornerRadius(18, corners: message.isCurrentUser ?
                [.topLeft, .topRight, .bottomLeft] :
                [.topLeft, .topRight, .bottomRight])
            .contextMenu {
                Button("Copy") {
                    UIPasteboard.general.string = message.content
                }
                Button("Reply", action: {})
            }
    }
    
    private var messageBackground: some View {
        Group {
            if message.isCurrentUser {
                LinearGradient(
                    colors: [Color("neonPurpleBackground"), Color("dullPurple")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemGray5)
            }
        }
    }
    
    private var deliveryStatusIndicator: some View {
        Group {
            switch message.deliveryStatus {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.gray)
            case .delivered:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.gray)
            case .read:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(Color("neonPurpleBackground"))
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Data Models
struct ChatMessage: Identifiable {
    enum DeliveryStatus {
        case sending, sent, delivered, read, failed
    }
    
    let id = UUID()
    let sender: String
    let content: String
    let timestamp: Date
    let isCurrentUser: Bool
    var deliveryStatus: DeliveryStatus = .sent
    
    // Example initializer for previews
    init(sender: String, content: String, timestamp: Date, isCurrentUser: Bool) {
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isCurrentUser = isCurrentUser
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}



// MARK: - Previews
struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Current user message
            MessageRow(message: ChatMessage(
                sender: "You",
                content: "Hello, this is a test message from current user.",
                timestamp: Date(),
                isCurrentUser: true
            ))
            .previewDisplayName("Current User")
            
            // Other user message
            MessageRow(message: ChatMessage(
                sender: "John Doe",
                content: "Hi there! This is a longer message that should wrap to multiple lines to demonstrate how the bubble expands properly.",
                timestamp: Date().addingTimeInterval(-300),
                isCurrentUser: false
            ))
            .previewDisplayName("Other User")
            
            // Failed message
            MessageRow(message: {
                var msg = ChatMessage(
                    sender: "You",
                    content: "This message failed to send",
                    timestamp: Date(),
                    isCurrentUser: true
                )
                msg.deliveryStatus = .failed
                return msg
            }())
            .previewDisplayName("Failed Message")
            
            // Sending status
            MessageRow(message: {
                var msg = ChatMessage(
                    sender: "You",
                    content: "Sending...",
                    timestamp: Date(),
                    isCurrentUser: true
                )
                msg.deliveryStatus = .sending
                return msg
            }())
            .previewDisplayName("Sending State")
        }
        .padding()
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}
