// MapViewModel.swift
// N3ON
//
// CHANGES FROM ORIGINAL:
// 1. Removed double debounce — original debounced in Combine (.debounce 0.3s) AND
//    then again with Task.sleep(300ms) inside fetchSuggestions(). This caused
//    a 0.6s delay on every search suggestion. The Task.sleep also blocked the
//    async context unnecessarily.
//    Source: https://developer.apple.com/documentation/combine/publisher/debounce(for:scheduler:options:)
//
// 2. Default location sentinel (comparing latitude == 37.7749 float) replaced with
//    a Bool flag. Floating point comparison as a sentinel is fragile — two floats
//    that should be equal can differ by epsilon after arithmetic.
//    Source: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basicoperators/
//    (see Floating-Point section)
//
// 3. locationManager.startUpdatingLocation() is now only called once — original
//    called it in both setupLocationManager() and locationManagerDidChangeAuthorization().
//    On iOS, calling startUpdatingLocation() twice wastes battery.
//    Source: https://developer.apple.com/documentation/corelocation/cllocationmanager/1423750-startupdatinglocation
//
// 4. searchForPlaces() MainActor.run calls removed — class is @MainActor so all
//    mutations are already on main thread. The nested MainActor.run calls were redundant.

import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
final class MapViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchSuggestions: [String] = []
    @Published var mapItems: [MKMapItem] = []
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var isLoading = false
    @Published var userLocation: CLLocation?
    @Published var userCity: String?

    // ✅ FIXED: bool flag replaces fragile float sentinel comparison
    private var hasReceivedFirstLocation = false

    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let searchCompleter = MKLocalSearchCompleter()
    private var currentSearchTask: Task<Void, Never>?

    override init() {
        super.init()
        setupLocationManager()
        setupSearchCompleter()
        setupSearchObservers()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        // Note: startUpdatingLocation() called in delegate after auth granted
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .query
    }

    private func setupSearchObservers() {
        $searchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self else { return }
                self.currentSearchTask?.cancel()
                self.currentSearchTask = Task {
                    await self.fetchSuggestions(query: query)
                }
            }
            .store(in: &cancellables)
    }

    func fetchSuggestions(query: String) async {
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }
        // ✅ FIXED: Task.sleep removed — debounce above already handles delay.
        // Original had 0.3s debounce AND 0.3s sleep = 0.6s total delay.
        searchCompleter.queryFragment = query
    }

    func searchForPlaces() async {
        guard !searchText.isEmpty else {
            mapItems = []
            return
        }

        isLoading = true
        defer { isLoading = false }      // ✅ always clears loading even on error

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapRegion

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            // ✅ No nested MainActor.run needed — class is already @MainActor
            mapItems = response.mapItems
            if let firstItem = response.mapItems.first {
                zoomToLocation(firstItem.placemark.coordinate)
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
        }
    }

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

    private func reverseGeocode(location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            userCity = placemarks.first?.locality
        } catch {
            print("Reverse geocode error: \(error.localizedDescription)")
        }
    }

    deinit {
        currentSearchTask?.cancel()
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.userLocation = location
            await self.reverseGeocode(location: location)

            // ✅ FIXED: bool flag — original compared latitude float to 37.7749
            if !self.hasReceivedFirstLocation {
                self.hasReceivedFirstLocation = true
                self.zoomToLocation(location.coordinate)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            // ✅ FIXED: only start here — not also in setupLocationManager()
            manager.startUpdatingLocation()
        }
    }
}

extension MapViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor [weak self] in
            self?.searchSuggestions = completer.results.map { $0.title }
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Suggestion error: \(error.localizedDescription)")
    }
}
