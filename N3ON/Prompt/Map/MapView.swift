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
    @State private var selectedVenue: Venue?

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
                onDoubleTap: handleDoubleTap,
                onVenueTap: { venue in selectedVenue = venue }
            )
            .ignoresSafeArea(.container, edges: [.top])

            // Chat button
            VStack {
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
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                        .overlay(alignment: .topTrailing) {
                            if unreadVM.count > 0 {
                                Text("\(unreadVM.count)")
                                    .font(.caption2).bold()
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                }
                .padding(.top, 60)
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

            ChatPanelView()
                .offset(x: showChatPanel ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(), value: showChatPanel)
        }
        .task {
            await unreadVM.start()
            await viewModel.loadMapData()
        }
        .sheet(item: $selectedVenue) { venue in
            VenueEventSheet(
                venue: venue,
                events: viewModel.events.filter { $0.venueID == venue.id }
            )
            .environmentObject(viewModel)
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
