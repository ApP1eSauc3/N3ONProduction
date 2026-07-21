// MapView.swift
// N3ON

import SwiftUI
import MapKit
import CoreLocation

// Venue needs Identifiable for sheet(item:)
extension Venue: Identifiable {}

struct MapView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @StateObject private var unreadVM = UnreadCounterVM()
    @State private var showChatPanel = false
    @State private var showSearch = false
    @State private var selectedVenue: Venue?
    /// User role: holds the event to purchase tickets for.
    @State private var ticketEvent: Event?

    var body: some View {
        ZStack(alignment: .trailing) {
            // Black fallback prevents any white flash behind the map
            // during load or in safe-area regions the map doesn't cover.
            Color.black.ignoresSafeArea()

            CustomMapView(
                region: $viewModel.mapRegion,
                venues: viewModel.venues,
                visibleDJPins: viewModel.djPins,
                groupLocations: [],
                allEvents: viewModel.events,
                role: viewModel.role,
                onDoubleTap: handleDoubleTap,
                onVenueTap: { venue in selectedVenue = venue },
                onEventTap: { event in ticketEvent = event }
            )
            .ignoresSafeArea(.container, edges: [.top])
            // Swipe left anywhere on the map to open the chat panel.
            // Swipe right while panel is open to close it.
            .gesture(
                DragGesture(minimumDistance: 40, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical   = abs(value.translation.height)
                        guard vertical < 80 else { return } // ignore diagonal
                        if !showChatPanel && horizontal < -50 {
                            showChatPanel = true
                            unreadVM.reset()
                        } else if showChatPanel && horizontal > 50 {
                            showChatPanel = false
                        }
                    }
            )

            // Floating controls
            VStack {
                // Chat button — neon glow active when unread messages exist
                // Chat is only accessible for DJ and Venue roles
                if viewModel.role != .regular {
                    Button {
                        showChatPanel.toggle()
                        if showChatPanel { unreadVM.reset() }
                    } label: {
                        Image(systemName: "message.badge.filled.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background {
                                Circle()
                                    .fill(Color("neonPurpleBackground"))
                                    // Two-layer neon glow (design system) — only when unread
                                    .shadow(
                                        color: unreadVM.count > 0
                                            ? Color("neonPurpleBackground").opacity(0.55)
                                            : .clear,
                                        radius: 18
                                    )
                                    .shadow(
                                        color: unreadVM.count > 0
                                            ? Color("neonPurpleBackground").opacity(0.85)
                                            : .clear,
                                        radius: 5
                                    )
                            }
                            .overlay(alignment: .topTrailing) {
                                if unreadVM.count > 0 {
                                    Text("\(unreadVM.count)")
                                        .font(.caption2).bold()
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(Color("neonPurpleBackground"))
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                    }
                    .animation(.easeInOut(duration: 0.25), value: unreadVM.count > 0)
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }

                // DJ event creation — Rank ≥ 4, OR an admin-curated DJ during
                // bootstrap (capability layer; see CurationService.canCreateEvent)
                if viewModel.role == .dj, viewModel.canCreateEvent {
                    NavigationLink(destination: EventCreationFlowView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .padding(12)
                            .background {
                                Circle()
                                    .fill(Color("neonPurpleBackground").opacity(0.85))
                                    .shadow(color: .black.opacity(0.3), radius: 5)
                            }
                    }
                    .padding(.top, viewModel.role != .regular ? 12 : 60)
                    .padding(.trailing, 20)
                }

                // Search button — all roles can search
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(Color("neonPurpleBackground").opacity(0.85))
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                }
                .padding(.top, viewModel.role == .regular ? 60 : 12)
                .padding(.trailing, 20)

                // Locate me button
                Button {
                    viewModel.zoomToUserLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(Color("neonPurpleBackground").opacity(0.85))
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                }
                .padding(.top, 12)
                .padding(.trailing, 20)

                Spacer()
            }

            // Chat panel slides in from the right edge.
            // Only rendered when the role has chat access.
            if viewModel.role != .regular {
                ChatPanelView()
                    .offset(x: showChatPanel ? 0 : UIScreen.main.bounds.width)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showChatPanel)
            }
        }
        .task {
            await unreadVM.start()
            await viewModel.loadMapData()
        }
        .sheet(isPresented: $showSearch) {
            MapSearchView()
        }
        // Venue / DJ roles: show venue sheet
        .sheet(item: $selectedVenue) { venue in
            VenueEventSheet(
                venue: venue,
                events: viewModel.events.filter { $0.venueID == venue.id }
            )
            .environmentObject(viewModel)
        }
        // Regular role: show event detail for ticket purchase
        .sheet(item: $ticketEvent) { event in
            EventDetailView(vm: EventViewModel(event: event))
        }
    }

    private func handleDoubleTap(_ coordinate: CLLocationCoordinate2D) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: viewModel.mapRegion.span.latitudeDelta * 0.5,
            longitudeDelta: viewModel.mapRegion.span.longitudeDelta * 0.5
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.mapRegion = MKCoordinateRegion(center: coordinate, span: newSpan)
        }
    }
}
