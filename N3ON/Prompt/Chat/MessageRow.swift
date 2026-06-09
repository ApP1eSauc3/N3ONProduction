//
//  MessageRow.swift
//  N3ON
//
// ChatMessage is defined in Data/ChatMessage.swift.

import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    @State private var showTimestamp = false

    var body: some View {
        VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
            if !message.isCurrentUser {
                Text(message.sender)
                    .font(.caption)
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .padding(.leading, 12)
            }

            HStack(alignment: .bottom, spacing: 6) {
                if !message.isCurrentUser { profileIndicator }
                messageContent
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) { showTimestamp.toggle() }
                    }
                if message.isCurrentUser { deliveryStatusIndicator }
            }

            if showTimestamp {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .id(message.id)
    }

    // MARK: - Subviews

    private var profileIndicator: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color("dullPurple"), Color("neonPurpleBackground")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 24, height: 24)
            .overlay(
                Text(message.sender.prefix(1).uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
            )
    }

    @ViewBuilder private var messageContent: some View {
        if message.content.hasPrefix("{\"type\":\"event_invite\"") {
            EventInviteCard(content: message.content)
        } else {
            textBubble
        }
    }

    private var textBubble: some View {
        Text(message.content)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                message.isCurrentUser
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color("neonPurpleBackground"), Color("dullPurple")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                      )
                    : AnyShapeStyle(Color.white.opacity(0.08))
            )
            .clipShape(
                // DESIGN §1.6 — asymmetric corners indicate message direction
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: message.isCurrentUser ? 16 : 4,
                    bottomTrailingRadius: message.isCurrentUser ? 4 : 16,
                    topTrailingRadius: 16,
                    style: .continuous
                )
            )
            .contextMenu {
                Button("Copy") { UIPasteboard.general.string = message.content }
            }
    }

    // MARK: - Event invite card

    /// Rendered in place of the text bubble when content is a JSON event invitation.
    private struct EventInviteCard: View {
        let content: String

        private var decoded: [String: String] {
            guard let data = content.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            else { return [:] }
            return dict
        }

        private var eventName: String { decoded["eventName"] ?? "Event Invitation" }
        private var venueName: String { decoded["venueName"] ?? "" }
        private var eventDate: String {
            guard let iso = decoded["eventDate"],
                  let date = ISO8601DateFormatter().date(from: iso)
            else { return "" }
            return date.formatted(date: .abbreviated, time: .omitted)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("neonPurpleBackground"))
                    Text("Event Invitation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("neonPurpleBackground"))
                }

                Text(eventName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)

                if !venueName.isEmpty {
                    Label(venueName, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if !eventDate.isEmpty {
                    Label(eventDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.15),
                             Color("dullPurple").opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color("neonPurpleBackground").opacity(0.3), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var deliveryStatusIndicator: some View {
        Group {
            switch message.deliveryStatus {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(.white.opacity(0.5))
            case .sent, .delivered:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color("neonPurpleBackground"))
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.bottom, 4)
    }
}
