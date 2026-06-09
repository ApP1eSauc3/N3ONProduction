// EventPopupPreview.swift
// N3ON — Prompt layer
// Draft event preview — shown from TicketPricingStepView so the DJ sees exactly
// what attendees will see before going live.
//
// Design reference: Resident Advisor and Dice both show a card preview at the final
// step of event creation. RA uses full-bleed artwork + gradient scrim + event meta below.
// Dice shows the poster as an app-card with rounded corners + venue/date in a dark bar.
// N3ON follows the RA pattern: poster fills the top 40%, gradient bleeds the event name,
// event meta (date, price) lives in the black zone below.

import SwiftUI

struct EventPopupPreview: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @Environment(\.dismiss) private var dismiss

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMM · HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        posterZone
                        metaZone
                    }
                }
                .safeAreaInset(edge: .bottom) { attendeeFooter }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }

    // MARK: — Poster (full-bleed, 40% of screen height)

    private var posterZone: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let image = draft.posterImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width * 0.9)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color("dullPurple"))
                        .frame(width: geo.size.width, height: geo.size.width * 0.9)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(Color("neonPurpleBackground").opacity(0.4))
                                Text("No poster selected")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        )
                }

                // Gradient scrim — same pattern as EventDetailView
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: UnitPoint(x: 0.5, y: 0.25),
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.width * 0.9)

                // Event name over scrim
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.eventName.isEmpty ? "Untitled Event" : draft.eventName)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text(Self.dateFormatter.string(from: draft.eventDate))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .aspectRatio(1.0 / 0.9, contentMode: .fit)
    }

    // MARK: — Meta (description, lineup stub)

    private var metaZone: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Notice banner — this is a draft preview
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.caption)
                    .foregroundStyle(Color("neonPurpleBackground"))
                Text("Draft preview — visible only to you until you go live.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("neonPurpleBackground").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Lineup placeholder
            VStack(alignment: .leading, spacing: 12) {
                Text("LINEUP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)

                Text("Your DJ profile will appear here once the event goes live.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }

            // Description
            if !draft.eventDescription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("neonPurpleBackground"))
                        .tracking(1.5)

                    Text(draft.eventDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .padding(.top, 20)
    }

    // MARK: — Attendee-style ticket footer

    private var attendeeFooter: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: 32)
                .allowsHitTesting(false)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if draft.ticketPrice > 0 {
                        Text("$\(Int(draft.ticketPrice))")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("per ticket")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        Text("Free")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                }

                Spacer()

                // Simulated buy button — non-interactive in preview
                Text("Buy Tickets")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 136, height: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.black.ignoresSafeArea(.all, edges: .bottom))
        }
    }
}
