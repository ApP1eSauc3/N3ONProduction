//
//  CustomMapView.swift
//  N3ON
//
//  Created by liam howe on 5/9/2024.
//
import SwiftUI
import MapKit
import Combine


struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
//    @Environment(\.colorScheme) var colorScheme//detects the current colour scheme
    
    func makeUIView(context: Context) -> MKMapView{
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        
        if #available(iOS 16.0, *){
            
            mapView.mapType = .mutedStandard // Dark map
            
        }else{
            mapView.mapType = .hybrid
            
        }
        
        
        return mapView
    }
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
        if #available(iOS 16.0, *){
            mapView.mapType = .mutedStandard
        }else{
            mapView.mapType = .hybrid
        }
        
        mapView.setRegion(region, animated: true)
    }
    
    
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
    }
}

