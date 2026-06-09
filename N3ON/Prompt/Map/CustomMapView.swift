//
//  CustomMapView.swift
//  N3ON
//

import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    // Annotation sources
    var venues: [Venue]
    var visibleDJPins: [DJMapPin]
    var groupLocations: [GroupMemberLocation]
    var allEvents: [Event]
    var role: AppRole

    // Event handlers
    var onDoubleTap: (CLLocationCoordinate2D) -> Void
    var onVenueTap: (Venue) -> Void
    /// Called when a venue pin is tapped in the `.regular` role —
    /// receives the first upcoming event at that venue for ticket purchase.
    var onEventTap: ((Event) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark

        let doubleTapRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap)
        )
        doubleTapRecognizer.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapRecognizer)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region only when it has actually changed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude ||
           mapView.region.span.latitudeDelta != region.span.latitudeDelta ||
           mapView.region.span.longitudeDelta != region.span.longitudeDelta {
            mapView.setRegion(region, animated: true)
        }

        // Preserve group member annotations — remove everything else
        let nonGroupAnnotations = mapView.annotations.filter {
            !($0 is GroupMemberAnnotation) && !($0 is MKUserLocation)
        }
        mapView.removeAnnotations(nonGroupAnnotations)

        // Venue annotations
        let venueAnnotations = venues.map { venue -> VenueAnnotation in
            VenueAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                venue: venue,
                glowLevel: glowStrength(for: venue.id),
                upcomingDates: upcomingEvents(for: venue.id),
                isAvailableForHosting: role == .dj && glowStrength(for: venue.id) == 0.0
            )
        }

        // DJ pins
        let djAnnotations = visibleDJPins.map { dj -> DJPinAnnotation in
            DJPinAnnotation(coordinate: dj.coordinate, djName: dj.djName, glowColor: dj.glowColor)
        }

        // Group member annotations
        let groupAnnotations = groupLocations.map { GroupMemberAnnotation(member: $0) }

        let allAnnotations: [any MKAnnotation] = venueAnnotations + djAnnotations + groupAnnotations
        mapView.addAnnotations(allAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Helpers

    private func glowStrength(for venueID: String) -> CGFloat {
        guard let nextEvent = allEvents
            .filter({ $0.venueID == venueID && $0.eventDate.foundationDate > Date() })
            .sorted(by: { $0.eventDate.foundationDate < $1.eventDate.foundationDate })
            .first else { return 0.0 }

        let daysUntil = nextEvent.eventDate.foundationDate.timeIntervalSinceNow / 86400
        switch daysUntil {
        case ..<3:  return 1.0
        case ..<7:  return 0.7
        case ..<14: return 0.4
        default:    return 0.0
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

    private func firstUpcomingEvent(for venueID: String) -> Event? {
        allEvents
            .filter { $0.venueID == venueID && $0.eventDate.foundationDate > Date() }
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
            .first
    }

    // MARK: - Coordinator

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
            guard let venueAnnotation = view.annotation as? VenueAnnotation else { return }

            // Regular users: route to ticket purchase for the first upcoming event
            if parent.role == .regular,
               let event = parent.firstUpcomingEvent(for: venueAnnotation.venue.id),
               let handler = parent.onEventTap {
                handler(event)
            } else {
                parent.onVenueTap(venueAnnotation.venue)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let venueAnnotation = annotation as? VenueAnnotation {
                let identifier = "VenuePin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.glyphText = "🎶"
                view.canShowCallout = true

                if venueAnnotation.isAvailableForHosting {
                    // DJ role — neon accent: venue available for hosting (no active event).
                    // DESIGN §3.1 — uses asset colour so it tracks any future palette update.
                    view.markerTintColor = UIColor(named: "neonPurpleBackground")
                } else {
                    view.markerTintColor = UIColor.systemPurple.withAlphaComponent(
                        max(venueAnnotation.glowLevel, 0.35)
                    )
                }
                return view
            }

            if let djAnnotation = annotation as? DJPinAnnotation {
                let identifier = "DJPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.glyphText = "🎧"
                view.canShowCallout = true
                view.markerTintColor = djAnnotation.glowColor
                return view
            }

            if let groupAnnotation = annotation as? GroupMemberAnnotation {
                let identifier = "GroupMemberPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = true
                view.markerTintColor = .systemGreen
                view.glyphText = "📍"
                return view
            }

            // Default fallback (search results etc.)
            let identifier = "PlaceAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = .purple
            return view
        }
    }
}

// MARK: - Annotations

/// Venue map pin — carries availability flag for DJ role neon rendering.
class VenueAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let venue: Venue
    let glowLevel: CGFloat
    let upcomingDates: [String]
    /// True when this venue has no upcoming events and the current role is `.dj` —
    /// rendered with full neon purple to signal "available for hosting".
    let isAvailableForHosting: Bool

    init(coordinate: CLLocationCoordinate2D,
         venue: Venue,
         glowLevel: CGFloat,
         upcomingDates: [String],
         isAvailableForHosting: Bool = false) {
        self.coordinate = coordinate
        self.venue = venue
        self.glowLevel = glowLevel
        self.upcomingDates = upcomingDates
        self.isAvailableForHosting = isAvailableForHosting
    }
}

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

// DJMapPin is defined in Data/DJMapPin.swift
