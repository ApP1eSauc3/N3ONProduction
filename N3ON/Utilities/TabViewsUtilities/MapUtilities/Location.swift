//
//  Location.swift
//  N3ON
//
//  Created by liam howe on 5/11/2024.
//

import Foundation
import CoreLocation

struct Location: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
}

