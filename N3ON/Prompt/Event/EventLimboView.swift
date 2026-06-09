// EventLimboView.swift
// N3ON — Prompt layer
// Stage 2: limbo. The event is saved as "pending". The host DJ invites others
// via EventInviteSheet (chat-based). The tally ring fills as DJs join.
// "Continue to Pricing" unlocks when draft.tallyMet == true.

import SwiftUI

struct EventLimboView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var showInviteSheet = false
    @State private var showCancelAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                tallySection
                pricePreviewSection
                inviteButton
                continueButton
                cancelLink
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showInviteSheet) {
            if let venue = draft.venue, let eventID = draft.createdEventID {
                EventInviteSheet(context: EventInviteContext(
                    eventID:   eventID,
                    eventName: draft.eventName,
                    venueName: venue.name,
                    eventDate: draft.eventDate
                ))
            }
        }
        .alert("Cancel Event?", isPresented: $showCancelAlert) {
            Button("Cancel Event", role: .destructive) {
                Task { await cancelEvent() }
            }
            Button("Keep", role: .cancel) { }
        } message: {
            Text("This will delete the event draft. DJs you invited won't be notified.")
        }
    }

    // MARK: — Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draft.eventName)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
            if let venue = draft.venue {
                Label(venue.name, systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Label(
                draft.eventDate.formatted(date: .abbreviated, time: .omitted),
                systemImage: "calendar"
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: — Tally ring

    private var tallySection: some View {
        VStack(spacing: 16) {
            TallyRing(current: draft.currentTally, required: draft.requiredTally)
                .frame(width: 140, height: 140)

            VStack(spacing: 4) {
                Text(draft.tallyMet ? "Lineup ready"
                     : (draft.canLeaveLimbo ? "Curated — ready to publish" : "Building lineup..."))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(draft.canLeaveLimbo ? Color("neonPurpleBackground") : .white)
                    .animation(.easeInOut(duration: 0.25), value: draft.canLeaveLimbo)
                Text("\(draft.currentTally) of \(draft.requiredTally) tally coins")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: — Price preview

    private var pricePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ticket price estimate")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(draft.ticketPrice > 0 ? "$\(Int(draft.ticketPrice))" : "Not set")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(
                        draft.ticketPrice > 0
                            ? Color("neonPurpleBackground")
                            : Color.white.opacity(0.3)
                    )
                    .animation(.easeInOut(duration: 0.2), value: draft.ticketPrice)
            }
            Slider(value: $draft.ticketPrice, in: 0...200, step: 5)
                .tint(Color("neonPurpleBackground"))
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.right.circle")
                    .font(.caption)
                    .foregroundStyle(Color("neonPurpleBackground"))
                Text(
                    draft.ticketPrice > 0
                        ? "Required tally drops to \(draft.requiredTally) coins at this price"
                        : "Set a price to see how it affects your required tally"
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            }
            if let preview = draft.breakEvenPreview {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("30% fill · \(preview.attendees) attendees · $\(preview.revenue) gross revenue")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: — Invite button

    private var inviteButton: some View {
        Button {
            showInviteSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                Text("Invite DJs")
                    .font(.headline)
            }
            .foregroundStyle(Color("neonPurpleBackground"))
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Color("neonPurpleBackground").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color("neonPurpleBackground").opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: — Continue button

    private var continueButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            draft.currentStep = .pricing
        } label: {
            Text("Continue to Pricing")
                .font(.headline)
                .foregroundStyle(draft.canLeaveLimbo ? .white : .white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            draft.canLeaveLimbo
                ? AnyShapeStyle(Color("neonPurpleBackground"))
                : AnyShapeStyle(Color.white.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(draft.canLeaveLimbo ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(draft.canLeaveLimbo ? 0.85 : 0), radius: 5)
        .disabled(!draft.canLeaveLimbo)
    }

    // MARK: — Cancel

    private var cancelLink: some View {
        Button("Cancel event") {
            showCancelAlert = true
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.3))
    }

    private func cancelEvent() async {
        if let eventID = draft.createdEventID {
            try? await EventService.cancelEvent(id: eventID)
        }
        draft.reset()
    }
}

// MARK: - Tally ring component

private struct TallyRing: View {
    let current: Int
    let required: Int

    private var progress: Double {
        guard required > 0 else { return 0 }
        return min(Double(current) / Double(required), 1.0)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 8)
            // Fill
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color("neonPurpleBackground"),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            // Label
            VStack(spacing: 2) {
                Text("\(current)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text("/ \(required)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        // Neon glow fires only when the ring is full (§3.1 — glow is earned)
        .shadow(color: Color("neonPurpleBackground").opacity(progress >= 1.0 ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(progress >= 1.0 ? 0.85 : 0), radius: 5)
    }
}
