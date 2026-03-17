// VenueEventSheet.swift
// N3ON
//
// Shown when a user taps a venue pin on the map.
// Lists upcoming events at the venue and provides GPS directions.

import SwiftUI
import Amplify

extension Event: Identifiable {}

struct VenueEventSheet: View {
    let venue: Venue
    let events: [Event]

    @EnvironmentObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: Event?

    private var upcomingEvents: [Event] {
        events
            .filter { $0.eventDate.foundationDate >= Date() }
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Venue header
                    VStack(spacing: 8) {
                        Text(venue.name)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(venue.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // GPS directions button
                        Button {
                            viewModel.openDirections(to: venue)
                        } label: {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("neonPurpleBackground"))
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.black)

                    // Events list
                    VStack(alignment: .leading, spacing: 12) {
                        if upcomingEvents.isEmpty {
                            Text("No upcoming events")
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            Text("Upcoming Events")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                                .padding(.top, 16)

                            ForEach(upcomingEvents) { event in
                                EventListRow(event: event)
                                    .onTapGesture { selectedEvent = event }
                            }
                        }
                    }
                    .background(Color.black)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(vm: EventViewModel(event: event))
        }
    }
}

// MARK: - EventListRow

private struct EventListRow: View {
    let event: Event

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            // Poster or placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("neonPurpleBackground").opacity(0.3))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(Color("neonPurpleBackground"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Text(Self.dateFormatter.string(from: event.eventDate.foundationDate))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 8) {
                    if event.ticketPrice > 0 {
                        Text("$\(Int(event.ticketPrice)) / ticket")
                            .font(.caption2)
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                    if event.availableTickets > 0 {
                        Text("\(event.availableTickets) left")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
