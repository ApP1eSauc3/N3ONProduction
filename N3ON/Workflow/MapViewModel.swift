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
    /// Where the map starts before a location fix (Brisbane CBD).
    let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    /// A one-off instruction to move the map. The map applies each request once
    /// (by `id`) and otherwise leaves the camera wherever the user panned it —
    /// a continuously bound region snapped the map back to the user's location
    /// on every location update.
    struct CameraRequest: Equatable {
        let id = UUID()
        let region: MKCoordinateRegion
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    }
    @Published private(set) var cameraRequest: CameraRequest?
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
    private var lastGeocodedLocation: CLLocation?
    /// Reverse-geocode again only after moving this far (Apple rate-limits
    /// the geocoder per app; a moving phone reports constantly).
    static let geocodeDistance: CLLocationDistance = 1_000
    /// The map needs neighbourhood precision, not GPS-grade (MASVS-PRIVACY).
    static let locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
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
        // DJ status lives on the User record (isDJ), not in a Cognito group —
        // reading the group alone hid chat and Create Event from new DJs.
        let me = try? await AuthService.getCurrentUserModel()
        role = await AccessControlService.role(for: me)
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

    /// The Maps destination for a venue, or nil for invalid coordinates (a
    /// corrupt record must not send someone to the middle of the ocean).
    static func directionsItem(for venue: Venue) -> MKMapItem? {
        let coordinate = CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
        guard CLLocationCoordinate2DIsValid(coordinate), venue.latitude != 0 || venue.longitude != 0 else { return nil }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = String(venue.name.prefix(VenueService.maxNameLength))
        return mapItem
    }

    func openDirections(to venue: Venue) {
        guard let mapItem = Self.directionsItem(for: venue) else { return }
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - Location helpers

    /// Moves the map once. Called on the first location fix and by the
    /// locate-me button — never on routine location updates.
    func zoomToLocation(_ coordinate: CLLocationCoordinate2D) {
        cameraRequest = CameraRequest(region: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    func zoomToUserLocation() {
        guard let userLocation else { return }
        zoomToLocation(userLocation.coordinate)
    }

    // MARK: - Private: role-specific loaders

    /// Venue role: only the owner's registered venue(s) and their upcoming events.
    func loadVenueRoleData() async throws {
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
    func loadDJRoleData() async throws {
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

        let venueByID = Dictionary(approvedVenues.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let eventByID = Dictionary(upcomingEvents.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var users: [String: User?] = [:]   // one read per DJ, not per link
        var pins: [DJMapPin] = []
        for link in activeLinks {
            guard !Task.isCancelled else { return }
            guard let eventID = link.event?.id,
                  let event = eventByID[eventID],
                  let venue = venueByID[event.venueID] else { continue }
            if users[link.djID] == nil { users[link.djID] = try? await MapService.user(byId: link.djID) }
            if let user = users[link.djID] ?? nil {
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
    func loadRegularRoleData() async throws {
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

        let venueByID = Dictionary(venues.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let eventByID = Dictionary(upcomingEvents.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var users: [String: User?] = [:]
        var pins: [DJMapPin] = []
        for link in activeLinks {
            guard !Task.isCancelled else { return }
            guard followedDJIDs.contains(link.djID),
                  let eid = link.event?.id,
                  let event = eventByID[eid],
                  let venue = venueByID[event.venueID] else { continue }
            if users[link.djID] == nil { users[link.djID] = try? await MapService.user(byId: link.djID) }
            if let user = users[link.djID] ?? nil {
                pins.append(DJMapPin(
                    coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                    djName: user.username,
                    glowColor: .systemPurple
                ))
            }
        }
        djPins = pins
    }

    /// What the location manager is configured with (tests assert it).
    var configuredAccuracy: CLLocationAccuracy { locationManager.desiredAccuracy }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = Self.locationAccuracy
        locationManager.distanceFilter = 100
        locationManager.requestWhenInUseAuthorization()
    }

    /// True for the first valid fix, then only after moving `geocodeDistance`.
    func shouldReverseGeocode(_ location: CLLocation) -> Bool {
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return false }
        guard let last = lastGeocodedLocation else { return true }
        return location.distance(from: last) >= Self.geocodeDistance
    }

    func reverseGeocode(location: CLLocation) async {
        guard shouldReverseGeocode(location) else { return }
        lastGeocodedLocation = location
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
