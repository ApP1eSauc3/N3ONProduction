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
        // Parse, never prefix-match — JSON key order is not guaranteed.
        if let invite = EventInvitePayload.parse(message.content) {
            EventInviteCard(invite: invite, isRecipient: !message.isCurrentUser)
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

    /// Rendered in place of the text bubble when content is an event invitation.
    /// The recipient can accept, which joins them to the lineup via the
    /// joinEvent Lambda (it verifies the invite server-side).
    private struct EventInviteCard: View {
        let invite: EventInvitePayload
        let isRecipient: Bool

        private enum JoinState: Equatable { case idle, joining, joined, failed(String) }
        @State private var joinState: JoinState = .idle

        private var eventDate: String {
            invite.date?.formatted(date: .abbreviated, time: .omitted) ?? ""
        }
        private var eventName: String { invite.eventName.isEmpty ? "Event Invitation" : invite.eventName }
        private var venueName: String { invite.venueName }

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

                if isRecipient { acceptControl }
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

        @ViewBuilder private var acceptControl: some View {
            switch joinState {
            case .joined:
                Label("You're on the lineup", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
            case .idle, .joining, .failed:
                VStack(alignment: .leading, spacing: 4) {   // DESIGN §1.3 space1
                    Button {
                        Task { await accept() }
                    } label: {
                        HStack(spacing: 8) {               // DESIGN §1.3 space2
                            if joinState == .joining {
                                ProgressView().tint(Color("neonPurpleBackground"))
                            }
                            Text("Join lineup")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color("neonPurpleBackground"))
                        .padding(.horizontal, 16)          // DESIGN §1.3 space4
                        .padding(.vertical, 8)             // DESIGN §1.3 space2
                        .background(Color("neonPurpleBackground").opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color("neonPurpleBackground").opacity(0.4), lineWidth: 1))
                        .frame(minHeight: 44)              // HIG minimum tap target
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(joinState == .joining)

                    if case .failed(let message) = joinState {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }

        private func accept() async {
            guard joinState != .joining else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()   // DESIGN §4 primary CTA
            joinState = .joining
            do {
                try await EventService.joinLineup(eventID: invite.eventID)
                withAnimation(.easeInOut(duration: 0.25)) { joinState = .joined }   // DESIGN §4 state transition
            } catch {
                joinState = .failed(error.localizedDescription)
            }
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
