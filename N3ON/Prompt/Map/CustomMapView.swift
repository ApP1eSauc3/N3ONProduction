//
//  CustomMapView.swift
//  N3ON
//
//  Created by liam howe on 5/9/2024.
//
import SwiftUI
import MapKit
import Combine

// MARK: - OPTIMIZED CUSTOM MAP VIEW WITH GROUP MEMBERS
struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    // Annotation sources
    var searchResults: [MKMapItem]
    var venues: [Venue]
    var visibleDJPins: [DJMapPin]
    var groupLocations: [GroupMemberLocation] // ADDED BACK
    var allEvents: [Event]
    
    // Event handlers
    var onDoubleTap: (CLLocationCoordinate2D) -> Void
    var onVenueTap: (Venue) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark
        
        // Double tap gesture
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap)
        )
        doubleTapRecognizer.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapRecognizer)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if mapView.region.center.latitude != region.center.latitude ||
            mapView.region.center.longitude != region.center.longitude ||
            mapView.region.span.latitudeDelta != region.span.latitudeDelta ||
            mapView.region.span.longitudeDelta != region.span.longitudeDelta {
            mapView.setRegion(region, animated: true)
        }
        
        // Clear non-group annotations only
        let nonGroupAnnotations = mapView.annotations.filter {
            !($0 is GroupMemberAnnotation) && !($0 is MKUserLocation)
        }
        mapView.removeAnnotations(nonGroupAnnotations)
        
        // Add search result annotations
        let searchAnnotations = searchResults.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotation.title = item.name
            return annotation
        }
        
        // Add venue annotations
        let venueAnnotations = venues.map { venue -> VenueAnnotation in
            VenueAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: venue.latitude,
                    longitude: venue.longitude
                ),
                venue: venue,
                glowLevel: glowStrength(for: venue.id),
                upcomingDates: upcomingEvents(for: venue.id)
            )
        }
        
        // Add DJ pins
        let djAnnotations = visibleDJPins.map { dj -> DJPinAnnotation in
            DJPinAnnotation(
                coordinate: dj.coordinate,
                djName: dj.djName,
                glowColor: dj.glowColor // ADDED
            )
        }
        
        // ADDED: Group member annotations
        let groupAnnotations = groupLocations.map { member -> GroupMemberAnnotation in
            GroupMemberAnnotation(member: member)
        }
        
        // Combine all annotations
        let allAnnotations: [any MKAnnotation] = searchAnnotations + venueAnnotations + djAnnotations + groupAnnotations
        mapView.addAnnotations(allAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Helper Methods (UNCHANGED)
    private func glowStrength(for venueID: String) -> CGFloat {
        let venueEvents = allEvents.filter { $0.venueID == venueID }
        guard let nextEvent = venueEvents
            .filter({ $0.eventDate.foundationDate > Date() })
            .sorted(by: { $0.eventDate.foundationDate < $1.eventDate.foundationDate })
            .first else { return 0.0 }
        
        let daysUntil = nextEvent.eventDate.timeIntervalSinceNow / 86400
        
        switch daysUntil {
        case ..<3: return 1.0
        case ..<7: return 0.7
        case ..<14: return 0.4
        default: return 0.0
        }
    }
    
    private func upcomingEvents(for venueID: String) -> [String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return allEvents
            .filter { $0.venueID == venueID && $0.eventDate.foundationDate > Date() }
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
            .map { formatter.string(from: $0.eventDate.foundationDate) }
    }
    
    // MARK: - Coordinator (ENHANCED GROUP HANDLING)
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            parent.onDoubleTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let venueAnnotation = view.annotation as? VenueAnnotation {
                parent.onVenueTap(venueAnnotation.venue)
            }
            else if let groupAnnotation = view.annotation as? GroupMemberAnnotation {
                // Handle group member tap
                print("Selected group member: \(groupAnnotation.member.name)")
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // User location
            if annotation is MKUserLocation {
                return nil
            }
            
            // Venue annotation
            if let venueAnnotation = annotation as? VenueAnnotation {
                let identifier = "VenuePin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                view.annotation = annotation
                view.glyphText = "🎶"
                view.canShowCallout = true
                view.markerTintColor = UIColor.systemPurple.withAlphaComponent(venueAnnotation.glowLevel)
                return view
            }
            
            // Group member annotation (ENHANCED)
            else if let groupAnnotation = annotation as? GroupMemberAnnotation {
                let identifier = "GroupMemberPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                view.annotation = annotation
                view.canShowCallout = true
                
                view.markerTintColor = .systemGreen
                view.glyphText = "📍"
                
                return view
            }
            
            // DJ pin annotation
            else if let djAnnotation = annotation as? DJPinAnnotation {
                let identifier = "DJPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                view.annotation = annotation
                view.glyphText = "🎧"
                view.canShowCallout = true
                view.markerTintColor = djAnnotation.glowColor // ADDED
                return view
            }
            
            // Default annotation (search results)
            else {
                let identifier = "PlaceAnnotation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                    view?.markerTintColor = .purple
                } else {
                    view?.annotation = annotation
                }
                
                return view
            }
        }
    }
}



// MARK: - ADDED: DJ PIN WITH GLOW COLOR
struct DJMapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let djName: String
    let glowColor: UIColor
}

// MARK: - ADDED: VENUE ANNOTATION WITH GLOW
class VenueAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let venue: Venue
    let glowLevel: CGFloat
    let upcomingDates: [String]
    
    init(coordinate: CLLocationCoordinate2D, venue: Venue, glowLevel: CGFloat, upcomingDates: [String]) {
        self.coordinate = coordinate
        self.venue = venue
        self.glowLevel = glowLevel
        self.upcomingDates = upcomingDates
    }
}

// MARK: - ADDED: DJ PIN ANNOTATION
class DJPinAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let djName: String
    let glowColor: UIColor
    
    init(coordinate: CLLocationCoordinate2D, djName: String, glowColor: UIColor) {
        self.coordinate = coordinate
        self.djName = djName
        self.glowColor = glowColor
    }
}
