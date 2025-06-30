//
//  GroupLocationViewModel.swift
//  N3ON
//
//  Created by liam howe on 3/6/2025.
//

import SwiftUI
import MapKit
import Combine

class GroupLocationViewModel: ObservableObject {
    @Published var memberLocations: [UserLocation] = []
    private var timer: Timer?

    init() {
        startTracking()
    }

    func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.fetchGroupLocations()
        }
    }

    func stopTracking() {
        timer?.invalidate()
    }

    private func fetchGroupLocations() {
        // Simulated fetch; in production, query your backend here
        let mockData = [
            UserLocation(id: "u1", name: "Alex", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), avatarKey: nil),
            UserLocation(id: "u2", name: "Jordan", coordinate: CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4202), avatarKey: nil)
        ]
        self.memberLocations = mockData
    }
}

struct UserLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let avatarKey: String?
}

class GroupAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let user: UserLocation

    init(user: UserLocation) {
        self.user = user
        self.coordinate = user.coordinate
    }
}

class GroupAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let groupAnnotation = newValue as? GroupAnnotation else { return }

            canShowCallout = true
            image = UIImage(systemName: "person.circle")

            let label = UILabel()
            label.text = groupAnnotation.user.name
            label.font = .systemFont(ofSize: 10)
            label.textColor = .white
            label.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
            label.textAlignment = .center
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            label.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
            detailCalloutAccessoryView = label
        }
    }
}

struct GroupLocationOverlay {
    let viewModel: GroupLocationViewModel
    let mapView: MKMapView

    func updateAnnotations() {
        let existing = mapView.annotations.compactMap { $0 as? GroupAnnotation }
        mapView.removeAnnotations(existing)

        let newAnnotations: [MKAnnotation] = [
                searchResults.map { ... },
                venues.map { ... },
                visibleDJPins.map { ... },
                groupLocations.map { ... }
            ].flatMap { $0 }
            
            // Calculate diffs
            let oldAnnotations = mapView.annotations
            let toRemove = oldAnnotations.filter { !newAnnotations.contains($0) }
            let toAdd = newAnnotations.filter { !oldAnnotations.contains($0) }
            

    static func setup(for mapView: MKMapView) {
        mapView.register(GroupAnnotationView.self, forAnnotationViewWithReuseIdentifier: "GroupAnnotation")
    }
}
    mapView.removeAnnotations(toRemove)
        mapView.addAnnotations(toAdd)
        
        // Update existing venue annotations
        mapView.annotations.forEach { annotation in
            guard let venueAnnotation = annotation as? VenueAnnotation,
                  let view = mapView.view(for: venueAnnotation) as? MKMarkerAnnotationView else { return }
            
            venueAnnotation.glowLevel = glowStrength(for: venueAnnotation.venue.id)
            venueAnnotation.upcomingDates = upcomingEvents(for: venueAnnotation.venue.id)
            view.markerTintColor = UIColor.systemPurple.withAlphaComponent(venueAnnotation.glowLevel)
        }
    }
