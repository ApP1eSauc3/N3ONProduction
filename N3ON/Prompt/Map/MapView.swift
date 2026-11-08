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
    /// Live finger offset while the edge strip is dragged (0 at rest).
    /// @GestureState resets itself when the drag ends OR is cancelled (a call
    /// coming in, the system taking the touch) — animated by the gesture-end
    /// spring — so the panel can never be left part-way open.
    @GestureState(resetTransaction: SwiftUI.Transaction(animation: Motion.gestureEnd))
    private var edgeDrag: CGFloat = 0
    @State private var showCreateEvent = false
    @State private var showSearch = false
    @State private var selectedVenue: Venue?
    /// User role: holds the event to purchase tickets for.
    @State private var ticketEvent: Event?

    /// The panel covers the full width, so its travel is the screen width.
    private var panelWidth: CGFloat { UIScreen.main.bounds.width }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Black fallback prevents any white flash behind the map
            // during load or in safe-area regions the map doesn't cover.
            Color.black.ignoresSafeArea()

            CustomMapView(
                initialRegion: viewModel.initialRegion,
                cameraRequest: viewModel.cameraRequest,
                venues: viewModel.venues,
                visibleDJPins: viewModel.djPins,
                allEvents: viewModel.events,
                role: viewModel.role,
                onVenueTap: { venue in selectedVenue = venue },
                onEventTap: { event in ticketEvent = event }
            )
            .ignoresSafeArea(.container, edges: [.top])

            // Swipe in from the right edge to open the chat panel. A gesture on
            // the map itself never fired reliably — MKMapView's own pan
            // recogniser takes the drag — so a thin edge strip catches it
            // instead (the panel closes itself: button or swipe right).
            //
            // The panel follows the finger 1:1 while held — no animation until
            // release (DESIGN §4: don't tween while held) — and rubber-bands
            // past fully open. On release it settles open or closed by distance
            // or flick velocity.
            if viewModel.role != .regular && !showChatPanel {
                Color.clear
                    .frame(width: 24)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10, coordinateSpace: .local)
                            .updating($edgeDrag) { value, offset, _ in
                                offset = Motion.rubberBanded(
                                    value.translation.width, in: -panelWidth...0, dimension: panelWidth
                                )
                            }
                            .onEnded { value in
                                let open = value.translation.width < -panelWidth * 0.3
                                    || value.predictedEndTranslation.width < -panelWidth * 0.5
                                if open {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    unreadVM.reset()
                                }
                                // edgeDrag springs back to 0 while the resting
                                // position springs to open/closed — same curve,
                                // so their sum moves continuously from the finger.
                                withAnimation(Motion.gestureEnd) {   // DESIGN §4 gesture-end spring
                                    showChatPanel = open
                                }
                            }
                    )
                    .accessibilityHidden(true)   // the chat button is the accessible path
            }

            // Floating controls
            VStack {
                // Chat button — neon glow active when unread messages exist
                // Chat is only accessible for DJ and Venue roles
                if viewModel.role != .regular {
                    Button {
                        let opening = !showChatPanel
                        withAnimation(opening ? Motion.enter() : Motion.exit()) {   // DESIGN §4 enter / exit
                            showChatPanel = opening
                        }
                        if opening { unreadVM.reset() }
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
                                        .contentTransition(.numericText())   // DESIGN §4 digits roll
                                        .padding(4)
                                        .background(Color("neonPurpleBackground"))
                                        .clipShape(Circle())
                                        // Grows out of (and shrinks back into) the button it labels.
                                        .transition(.popover(anchor: .bottomLeading))   // DESIGN §4 popover 0.95
                                        .offset(x: 8, y: -8)
                                }
                            }
                    }
                    .buttonStyle(.pressable)   // DESIGN §4 press scale 0.97
                    .animation(Motion.state, value: unreadVM.count)
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }

                // DJ event creation — Rank ≥ 4, OR an admin-curated DJ during
                // bootstrap (capability layer; see CurationService.canCreateEvent)
                // A Button, not a NavigationLink: the map isn't inside a
                // NavigationStack, so a link here had nothing to push onto and
                // silently did nothing.
                if viewModel.role == .dj, viewModel.canCreateEvent {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showCreateEvent = true
                    } label: {
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
                    .buttonStyle(.pressable)   // DESIGN §4 press scale 0.97
                    .accessibilityLabel("Create event")
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
                .buttonStyle(.pressable)   // DESIGN §4 press scale 0.97
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
                .buttonStyle(.pressable)   // DESIGN §4 press scale 0.97
                .padding(.top, 12)
                .padding(.trailing, 20)

                Spacer()
            }

            // Chat panel slides in from the right edge.
            // Only rendered when the role has chat access.
            if viewModel.role != .regular {
                // Every change is animated explicitly by whoever makes it
                // (button: enter/exit; gesture release: gesture-end spring),
                // so nothing tweens the offset while a finger is down.
                // isActive from the first pixel of an opening drag, so the
                // inbox rows cascade in as the panel arrives, not at launch.
                ChatPanelView(panelWidth: panelWidth, isActive: showChatPanel || edgeDrag != 0) {
                    showChatPanel = false
                }
                .offset(x: (showChatPanel ? 0 : panelWidth) + edgeDrag)
            }
        }
        .task {
            await unreadVM.start()
            await viewModel.loadMapData()
        }
        .fullScreenCover(isPresented: $showCreateEvent) {
            EventCreationCover()
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
}

/// Event creation presented from the map: its own NavigationStack and draft,
/// plus a close button (the profile entry point pushes it instead).
private struct EventCreationCover: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var draft = EventDraftViewModel()

    var body: some View {
        NavigationStack {
            EventCreationFlowView()
                .environmentObject(draft)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Close")
                    }
                }
        }
    }
}
