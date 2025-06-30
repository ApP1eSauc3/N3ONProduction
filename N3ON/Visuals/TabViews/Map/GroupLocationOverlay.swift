//
//  GroupLocationOverlay.swift
//  N3ON
//
//  Created by liam howe on 30/6/2025.
//

import SwiftUI
import MapKit
import Combine

struct GroupLocationOverlay: UIViewRepresentable {
    @ObservedObject var viewModel: GroupLocationViewModel
    let mapView: MKMapView

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        updateAnnotations()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        updateAnnotations()
    }

    private func updateAnnotations() {
        mapView.removeAnnotations(mapView.annotations.filter { $0 is GroupMemberAnnotation })

        for member in viewModel.members {
            let annotation = GroupMemberAnnotation(member: member)
            mapView.addAnnotation(annotation)
        }
    }
}


struct GroupMemberLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class GroupMemberAnnotation: NSObject, MKAnnotation {
    let member: GroupMemberLocation
    var coordinate: CLLocationCoordinate2D { member.coordinate }
    var title: String? { member.name }

    init(member: GroupMemberLocation) {
        self.member = member
    }
}

