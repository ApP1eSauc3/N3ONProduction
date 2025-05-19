//
//  MapViewModel.swift
//  N3ON
//
//  Created by liam howe on 10/10/2024.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
final class MapViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
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
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let searchCompleter = MKLocalSearchCompleter()
    private var currentSearchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        setupSearchCompleter()
        setupSearchObservers()
    }
    
    // MARK: - Setup Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .query
    }
    
    private func setupSearchObservers() {
        $searchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                self.currentSearchTask?.cancel()
                self.currentSearchTask = Task {
                    await self.fetchSuggestions(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search Methods
    func fetchSuggestions(query: String) async {
        guard !query.isEmpty else {
                searchSuggestions = []
            return
        }
        
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second debounce
            
            searchCompleter.queryFragment = query
        } catch {
            // Task was cancelled or failed
            print("Suggestions fetch cancelled or failed: \(error)")
        }
    }
    
    func searchForPlaces() async {
        guard !searchText.isEmpty else {
            await MainActor.run {
                mapItems = []
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapRegion
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            await MainActor.run {
                mapItems = response.mapItems
                isLoading = false
                
                if let firstItem = response.mapItems.first {
                    zoomToLocation(firstItem.placemark.coordinate)
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Search error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Map Methods
    func zoomToLocation(_ coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func zoomToUserLocation() {
        guard let userLocation = userLocation else { return }
        zoomToLocation(userLocation.coordinate)
    }
    
    // MARK: - Private Methods
    private func reverseGeocode(location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            await MainActor.run {
                userCity = placemarks.first?.locality
            }
        } catch {
            print("Reverse geocode error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    deinit {
        currentSearchTask?.cancel()
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task {
            await MainActor.run {
                userLocation = location
            }
            await reverseGeocode(location: location)
            
            if mapRegion.center.latitude == 37.7749 { // Default location check
                zoomToLocation(location.coordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
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


