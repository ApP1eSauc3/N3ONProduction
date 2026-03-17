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
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var isLoading = false
    @Published var userLocation: CLLocation?
    @Published var userCity: String?

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
        do {
            async let venueQuery = Amplify.DataStore.query(Venue.self)
            async let eventQuery = Amplify.DataStore.query(Event.self)
            let (fetchedVenues, fetchedEvents) = try await (venueQuery, eventQuery)
            venues = fetchedVenues
            // Only show upcoming events on the map
            let now = Date()
            events = fetchedEvents.filter { $0.eventDate.foundationDate >= now }
        } catch {
            print("Map data load error: \(error)")
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

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    private func reverseGeocode(location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            userCity = placemarks.first?.locality
        } catch {
            print("Reverse geocode error: \(error)")
        }
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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
