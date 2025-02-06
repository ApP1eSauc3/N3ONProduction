//
//  MapViewModel.swift
//  N3ON
//
//  Created by liam howe on 10/10/2024.
//

import Foundation
import MapKit
import Combine

class MapViewModel: ObservableObject{
    
    @Published var searchText = "" // Search query
    @Published var mapItems: [MKMapItem] = [] // Search results (bars, nightclubs, etc.)
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
    @Published var isLoading = false
    private var locationManager = LocationManager() //instance of LocationManager
    
    init() {
            // Observe changes to userCity from LocationManager
            locationManager.$userCity
                .sink { [weak self] city in
                    guard let city = city, !city.isEmpty else { return }
                    self?.performInitialSearch(in: city)
                }
                .store(in: &cancellables)
        }
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchForPlaces() {
        guard let city = locationManager.userCity, !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(searchText) \(city) nightclubs and bars"
        request.region = mapRegion
        
        let search = MKLocalSearch(request: request)
        isLoading = true
        search.start { [weak self] (response, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error searching for places: \(error.localizedDescription)")
                    return
                }
                
                    self?.mapItems = response?.mapItems ?? [] // Store search results in mapItems
                }
        }
    }
    
    private func performInitialSearch(in city: String) {
        searchText = "nightclubs bars \(city)"
        searchForPlaces()
    }

    func setMapRegion(for location: CLLocationCoordinate2D) {
            mapRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
