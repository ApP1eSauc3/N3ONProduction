// MapViewModel.swift
// N3ON

import Foundation
import MapKit
import CoreLocation
import Amplify

@MainActor
final class MapViewModel: NSObject, ObservableObject {
    @Published var venues: [Venue] = []
    @Published var events: [Event] = []
    @Published var djPins: [DJMapPin] = []
    @Published var role: AppRole = .regular
    @Published var djRank: Int? = nil
    @Published var currentUser: User?
    @Published var isAdmin = false
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var isLoading = false
    @Published var userLocation: CLLocation?
    @Published var userCity: String?

    /// Whether the signed-in DJ may create/host an event (capability layer —
    /// bootstrap curation supersedes the rank gate).
    var canCreateEvent: Bool {
        guard let user = currentUser else { return false }
        return CurationService.canCreateEvent(user: user, isAdmin: isAdmin)
    }

    private var currentUserID: String?
    private var hasReceivedFirstLocation = false
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Data loading

    func loadMapData() async {
        isLoading = true
        defer { isLoading = false }

        currentUserID = await AuthService.currentUserIdOrNil()
        role = await AccessControlService.currentUserRole()
        isAdmin = await AccessControlService.isAdmin()
        guard !Task.isCancelled else { return }

        do {
            switch role {
            case .venue:   try await loadVenueRoleData()
            case .dj:      try await loadDJRoleData()
            case .regular: try await loadRegularRoleData()
            }
        } catch {
            // Silently degrade — map remains functional with empty collections
        }
    }

    // MARK: - Navigation

    func openDirections(to venue: Venue) {
        let coordinate = CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - Location helpers

    func zoomToLocation(_ coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func zoomToUserLocation() {
        guard let userLocation else { return }
        zoomToLocation(userLocation.coordinate)
    }

    // MARK: - Private: role-specific loaders

    /// Venue role: only the owner's registered venue(s) and their upcoming events.
    private func loadVenueRoleData() async throws {
        guard let ownerID = currentUserID else { return }
        let myVenues = try await MapService.venues(ownedBy: ownerID)
        guard !Task.isCancelled else { return }
        let myVenueIDs = Set(myVenues.map { $0.id })
        let myEvents = try await MapService.upcomingEvents(atVenueIDs: myVenueIDs)
        guard !Task.isCancelled else { return }
        venues = myVenues
        events = myEvents
        djPins = []
    }

    /// DJ role: all approved venues (neon-highlighted when available for hosting),
    /// upcoming events for glow levels, and DJ pins for performers at those events.
    private func loadDJRoleData() async throws {
        if let uid = currentUserID,
           let user = try? await MapService.user(byId: uid) {
            djRank = user.djRank
            currentUser = user
        }
        guard !Task.isCancelled else { return }

        let approvedVenues = try await MapService.approvedVenues()
        guard !Task.isCancelled else { return }
        let upcomingEvents = try await MapService.allUpcomingEvents()
        guard !Task.isCancelled else { return }

        venues = approvedVenues
        events = upcomingEvents

        let upcomingEventIDs = Set(upcomingEvents.map { $0.id })
        let activeLinks = try await MapService.djLinks(forEventIDs: upcomingEventIDs)
        guard !Task.isCancelled else { return }

        let venueByID = Dictionary(uniqueKeysWithValues: approvedVenues.map { ($0.id, $0) })
        var pins: [DJMapPin] = []
        for link in activeLinks {
            guard !Task.isCancelled else { return }
            guard let eventID = link.event?.id,
                  let event = upcomingEvents.first(where: { $0.id == eventID }),
                  let venue = venueByID[event.venueID] else { continue }
            if let user = try? await MapService.user(byId: link.djID) {
                pins.append(DJMapPin(
                    coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                    djName: user.username,
                    glowColor: .cyan
                ))
            }
        }
        djPins = pins
    }

    /// Regular role: only venues with a live N3ON event, plus followed DJs
    /// pinned to the venue where they are performing.
    private func loadRegularRoleData() async throws {
        let upcomingEvents = try await MapService.allUpcomingEvents()
        guard !Task.isCancelled else { return }
        let eventVenueIDs = Set(upcomingEvents.map { $0.venueID })
        let approvedVenues = try await MapService.approvedVenues()
        guard !Task.isCancelled else { return }

        venues = approvedVenues.filter { eventVenueIDs.contains($0.id) }
        events = upcomingEvents

        guard let userID = currentUserID else { djPins = []; return }
        let followedDJIDs = try await MapService.followedUserIDs(for: userID)
        guard !Task.isCancelled else { return }
        guard !followedDJIDs.isEmpty else { djPins = []; return }

        let upcomingEventIDs = Set(upcomingEvents.map { $0.id })
        let activeLinks = try await MapService.djLinks(forEventIDs: upcomingEventIDs)
        guard !Task.isCancelled else { return }

        let venueByID = Dictionary(uniqueKeysWithValues: venues.map { ($0.id, $0) })
        var pins: [DJMapPin] = []
        for link in activeLinks {
            guard !Task.isCancelled else { return }
            guard followedDJIDs.contains(link.djID),
                  let eid = link.event?.id,
                  upcomingEventIDs.contains(eid),
                  let event = upcomingEvents.first(where: { $0.id == eid }),
                  let venue = venueByID[event.venueID] else { continue }
            if let user = try? await MapService.user(byId: link.djID) {
                pins.append(DJMapPin(
                    coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                    djName: user.username,
                    glowColor: .systemPurple
                ))
            }
        }
        djPins = pins
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    private func reverseGeocode(location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            userCity = placemarks.first?.locality
        } catch { }
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.userLocation = location
            await self.reverseGeocode(location: location)
            if !self.hasReceivedFirstLocation {
                self.hasReceivedFirstLocation = true
                self.zoomToLocation(location.coordinate)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
