//
//  CustomMapView.swift
//  N3ON
//
//  Created by liam howe on 5/9/2024.
//
import SwiftUI
import MapKit
import CoreLocation

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @FocusState.Binding var isSearchFieldFocused: Bool 
    var places: [MKMapItem]
    var onDoubleTap: (CLLocationCoordinate2D) -> Void
    

    
    
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
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Use Equatable comparison for region
        if uiView.region.center.latitude != region.center.latitude ||
              uiView.region.center.longitude != region.center.longitude ||
                uiView.region.span.latitudeDelta != region.span.latitudeDelta ||
                uiView.region.span.longitudeDelta != region.span.longitudeDelta {
            uiView.setRegion(region, animated: true)
        }
        
        // Efficient annotation updates using Equatable coordinates
        let existingAnnotations = uiView.annotations.compactMap { $0 as? MKPointAnnotation }
        let newAnnotations = places.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotation.title = item.name
            return annotation
        }
        
        // Calculate diffs using Equatable conformance
        let annotationsToRemove = existingAnnotations.filter { existing in
            !newAnnotations.contains { $0.coordinate == existing.coordinate }
        }
        
        let annotationsToAdd = newAnnotations.filter { new in
            !existingAnnotations.contains { $0.coordinate == new.coordinate }
        }
        
        uiView.removeAnnotations(annotationsToRemove)
        uiView.addAnnotations(annotationsToAdd)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
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
            parent.isSearchFieldFocused = true // Dismiss the search field
        }
    }
}

