// Sections.swift
// N3ON

import SwiftUI

// MARK: - RegularUserSection

struct RegularUserSection: View {
    @State private var myTickets: [(ticket: Ticket, eventName: String)] = []
    @State private var isLoadingTickets = false
    @State private var selectedTicket: (ticket: Ticket, eventName: String)?
    @State private var currentUserID: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeader(title: "My Tickets")

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
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedTicket = entry
                    } label: {
                        TicketSummaryRow(ticket: entry.ticket, eventName: entry.eventName)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task { await loadTickets() }
        .sheet(item: Binding(
            get: { selectedTicket.map { TicketSheetItem(ticket: $0.ticket, eventName: $0.eventName) } },
            set: { if $0 == nil { selectedTicket = nil } }
        )) { item in
            TicketDetailView(ticket: item.ticket, eventName: item.eventName, userID: currentUserID)
        }
    }

    private func loadTickets() async {
        isLoadingTickets = true
        defer { isLoadingTickets = false }
        currentUserID = await AuthService.currentUserIdOrNil() ?? ""
        guard let tickets = try? await TicketService.myTickets() else { return }
        var result: [(Ticket, String)] = []
        for ticket in tickets {
            let name = (try? await EventService.fetchEvent(byId: ticket.eventID))?.eventName
            result.append((ticket, name ?? "Unknown Event"))
        }
        myTickets = result
    }
}

// Identifiable wrapper so sheet(item:) can use the tuple
private struct TicketSheetItem: Identifiable {
    let id: String
    let ticket: Ticket
    let eventName: String
    init(ticket: Ticket, eventName: String) {
        self.id = ticket.id
        self.ticket = ticket
        self.eventName = eventName
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
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - DJSection

struct DJSection: View {
    let rank: Int
    let userID: String
    /// Capability-layer result (Rank ≥ 4 OR admin-curated during bootstrap). Drives the Create Event tool.
    let canCreateEvent: Bool

    @State private var showAudioPicker = false
    @State private var isUploadingAudio = false
    @State private var audioUploadError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: "DJ Tools")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    EventCreationFlowView()
                        .environmentObject(EventDraftViewModel())
                } label: {
                    toolLabel("Create Event", "calendar.badge.plus", locked: !canCreateEvent)
                }
                .buttonStyle(ToolGridButtonStyle())
                .disabled(!canCreateEvent)

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

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAudioPicker = true
                } label: {
                    toolLabel(
                        isUploadingAudio ? "Uploading…" : "Audio Clip",
                        isUploadingAudio ? "arrow.up.circle" : "waveform",
                        locked: false
                    )
                }
                .buttonStyle(ToolGridButtonStyle())
                .disabled(isUploadingAudio)
            }

            if let err = audioUploadError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 4)
            }

            // MARK: — Rank progression
            if rank > 0 && rank < 5 {
                rankProgressionSection
            }
        }
        .sheet(isPresented: $showAudioPicker) {
            AudioPicker(selectedAudio: Binding(
                get: { nil },
                set: { url in
                    guard let url else { return }
                    Task { await uploadAudio(url: url) }
                }
            ))
        }
    }

    // MARK: — Rank progression section

    private var rankProgressionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeader(title: "Rank Progression")

            NavigationLink {
                EndorsementProgressView(userID: userID, currentRank: rank)
            } label: {
                rankNavRow(
                    icon: "arrow.up.circle",
                    title: "Rank \(rank) → \(rank + 1)",
                    subtitle: "Track endorsements toward your next rank"
                )
            }

            NavigationLink {
                EndorsementInboxView(userID: userID, currentRank: rank)
            } label: {
                rankNavRow(
                    icon: "checkmark.seal",
                    title: "Endorsement Inbox",
                    subtitle: "Review requests from DJs seeking your endorsement"
                )
            }
        }
    }

    private func rankNavRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color("neonPurpleBackground"))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func uploadAudio(url: URL) async {
        isUploadingAudio = true
        audioUploadError = nil
        defer { isUploadingAudio = false }
        do {
            try await AvatarUploadService.uploadProfileAudio(from: url)
        } catch {
            audioUploadError = "Upload failed — try again"
        }
    }

    private func toolLabel(_ title: String, _ system: String, locked: Bool = false) -> some View {
        HStack {
            Image(systemName: locked ? "lock" : system)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.customDarkGray)
        .foregroundStyle(locked ? .white.opacity(0.3) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            ProfileSectionHeader(title: "Venue Tools")

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

                NavigationLink {
                    TicketScannerView()
                } label: {
                    rowLabel("Scan Tickets", "qrcode.viewfinder")
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
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            venues = (try? await VenueService.fetchApproved()) ?? []
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
              let venue = try? await VenueService.fetchOwned(by: ownerID).first
        else { return }
        events = (try? await EventService.fetchEvents(forVenueID: venue.id)) ?? []
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
              let venue = try? await VenueService.fetchOwned(by: ownerID).first
        else { return }
        venueID = venue.id
    }
}
