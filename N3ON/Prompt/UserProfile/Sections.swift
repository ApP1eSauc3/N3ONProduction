// Sections.swift
// N3ON

import SwiftUI
import Amplify

// MARK: - RegularUserSection

struct RegularUserSection: View {
    @State private var myTickets: [(ticket: Ticket, eventName: String)] = []
    @State private var isLoadingTickets = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Tickets")
                .font(.headline)
                .foregroundStyle(.white)

            if isLoadingTickets {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if myTickets.isEmpty {
                VStack(spacing: 6) {
                    Text("No tickets yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Find events on the Map tab")
                        .font(.caption)
                        .foregroundStyle(Color("neonPurpleBackground").opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(myTickets, id: \.ticket.id) { entry in
                    TicketSummaryRow(ticket: entry.ticket, eventName: entry.eventName)
                }
            }
        }
        .task { await loadTickets() }
    }

    private func loadTickets() async {
        isLoadingTickets = true
        defer { isLoadingTickets = false }
        guard let tickets = try? await TicketService.myTickets() else { return }
        var result: [(Ticket, String)] = []
        for ticket in tickets {
            let name = (try? await Amplify.DataStore.query(Event.self, byId: ticket.eventID))?.eventName
            result.append((ticket, name ?? "Unknown Event"))
        }
        myTickets = result
    }
}

// MARK: - TicketSummaryRow

private struct TicketSummaryRow: View {
    let ticket: Ticket
    let eventName: String

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("neonPurpleBackground").opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "ticket")
                        .foregroundStyle(Color("neonPurpleBackground"))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(eventName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Qty: \(ticket.quantity) · \(Self.dateFormatter.string(from: ticket.purchaseTime.foundationDate))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

// MARK: - DJSection

struct DJSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color("neonPurpleBackground"))
                    .frame(width: 3, height: 16)
                Text("DJ Tools")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    EventCreationFlowView()
                        .environmentObject(EventDraftViewModel())
                } label: {
                    toolLabel("Create Event", "calendar.badge.plus")
                }
                .buttonStyle(ToolGridButtonStyle())

                NavigationLink {
                    UserEventTimelineView()
                } label: {
                    toolLabel("My Events", "calendar")
                }
                .buttonStyle(ToolGridButtonStyle())

                NavigationLink {
                    VenueListView()
                } label: {
                    toolLabel("Find Venues", "map")
                }
                .buttonStyle(ToolGridButtonStyle())

                NavigationLink {
                    MyPostsView()
                } label: {
                    toolLabel("My Posts", "square.and.arrow.up")
                }
                .buttonStyle(ToolGridButtonStyle())
            }
        }
    }

    private func toolLabel(_ title: String, _ system: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.customDarkGray)
        .foregroundStyle(.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

private struct ToolGridButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - VenueSection

struct VenueSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color("neonPurpleBackground"))
                    .frame(width: 3, height: 16)
                Text("Venue Tools")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                NavigationLink {
                    VenueProfileView()
                } label: {
                    rowLabel("My Venue Profile", "building.2")
                }

                NavigationLink {
                    VenueComplianceWrapper()
                } label: {
                    rowLabel("Compliance", "doc.text.magnifyingglass")
                }

                NavigationLink {
                    EventRequestsView()
                } label: {
                    rowLabel("Event Requests", "tray.full")
                }
            }
        }
    }

    private func rowLabel(_ title: String, _ system: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(12)
        .background(Color.customDarkGray)
        .foregroundStyle(.white)
        .cornerRadius(10)
    }
}

// MARK: - VenueListView
// Simple list of venues from DataStore — entry point for DJs finding venues to book.

struct VenueListView: View {
    @State private var venues: [Venue] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else if venues.isEmpty {
                VStack(spacing: 6) {
                    Text("No venues available")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Venues appear here once approved")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else {
                List(venues, id: \.id) { venue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(venue.address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Capacity: \(venue.maxCapacity)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.customDarkGray)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Venues")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            isLoading = true
            venues = (try? await Amplify.DataStore.query(Venue.self,
                where: Venue.keys.approvalStatus == "APPROVED")) ?? []
            isLoading = false
        }
    }
}

// MARK: - EventRequestsView
// Shows event applications submitted to the venue owner's venue.

struct EventRequestsView: View {
    @State private var events: [Event] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else if events.isEmpty {
                Text("No event requests")
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                List(events, id: \.id) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.eventName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(event.eventDate.foundationDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(event.package)
                            .font(.caption2)
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.customDarkGray)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Event Requests")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadRequests() }
    }

    private func loadRequests() async {
        isLoading = true
        defer { isLoading = false }
        guard let ownerID = await AuthService.currentUserIdOrNil(),
              let venue = try? await Amplify.DataStore.query(
                Venue.self,
                where: Venue.keys.owner == ownerID
              ).first
        else { return }
        events = (try? await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.venueID == venue.id
        )) ?? []
    }
}

// MARK: - MyPostsView
// Loads the current user's posts and renders them in the PostFeedView.

struct MyPostsView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(.white)
            } else {
                PostFeedView(posts: posts)
            }
        }
        .navigationTitle("My Posts")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadPosts() }
    }

    private func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        guard let ownerID = await AuthService.currentUserIdOrNil() else { return }
        posts = (try? await Amplify.DataStore.query(
            Post.self,
            where: Post.keys.ownerID == ownerID
        )) ?? []
    }
}

// MARK: - VenueComplianceWrapper
// Resolves the current user's venueID before presenting VenueComplianceForm.

struct VenueComplianceWrapper: View {
    @State private var venueID: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let venueID {
                VenueComplianceForm(venueID: venueID)
            } else {
                Text("No venue found. Create your venue profile first.")
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Compliance")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await resolveVenue() }
    }

    private func resolveVenue() async {
        defer { isLoading = false }
        guard let ownerID = await AuthService.currentUserIdOrNil(),
              let venue = try? await Amplify.DataStore.query(
                Venue.self,
                where: Venue.keys.owner == ownerID
              ).first
        else { return }
        venueID = venue.id
    }
}
