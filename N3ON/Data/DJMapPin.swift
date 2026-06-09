// DJMapPin.swift
// N3ON — Data layer
// Value type representing a DJ pin on the map.
// Coordinate is set to the venue where the DJ is performing.

import Foundation
import UIKit
import CoreLocation

struct DJMapPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let djName: String
    let glowColor: UIColor

    init(coordinate: CLLocationCoordinate2D, djName: String, glowColor: UIColor) {
        self.id = UUID()
        self.coordinate = coordinate
        self.djName = djName
        self.glowColor = glowColor
    }
}
