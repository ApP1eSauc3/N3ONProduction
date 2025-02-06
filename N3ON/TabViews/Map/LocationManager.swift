//
//  LocationManager.swift
//  N3ON
//
//  Created by liam howe on 26/6/2024.
//

import Foundation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var userCity: String? //stores the city of the user's location
    

    private let locationManager = CLLocationManager() // Core Location manager
    private let geocoder = CLGeocoder() //geocoder to find the city

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        userLocation = newLocation // Update user location
        fetchCity(from: newLocation) //fetches city when location is updated
    }
    
    private func fetchCity(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemark, error) in
            if let error = error {
                print("Failed to locate city: \(error.localizedDescription)")
                return
            }
            if let city = placemark?.first?.locality{
                self?.userCity = city //update userCity with the city name
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user's location: \(error.localizedDescription)")
    }
}

