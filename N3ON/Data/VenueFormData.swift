// VenueFormData.swift
// N3ON — Data layer
// Domain enums for the venue application form.
// Extracted from Prompt layer where they were incorrectly defined.

import Foundation

enum VenueType: String, Codable, CaseIterable {
    case club, bar, restaurant, hotel, rooftop, warehouse, other

    var displayName: String {
        switch self {
        case .club:      return "Nightclub"
        case .bar:       return "Bar"
        case .restaurant: return "Restaurant"
        case .hotel:     return "Hotel"
        case .rooftop:   return "Rooftop"
        case .warehouse: return "Warehouse"
        case .other:     return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .club:      return "music.note.house.fill"
        case .bar:       return "wineglass.fill"
        case .restaurant: return "fork.knife"
        case .hotel:     return "building.2.fill"
        case .rooftop:   return "building.fill"
        case .warehouse: return "shippingbox.fill"
        case .other:     return "mappin.circle.fill"
        }
    }
}

enum Amenity: String, Codable, CaseIterable {
    case wifi, parking, outdoor, liveMusic, danceFloor, pool, smokingArea, vipArea

    var displayName: String { rawValue.capitalized }

    var iconName: String {
        switch self {
        case .wifi:        return "wifi"
        case .parking:     return "parkingsign"
        case .outdoor:     return "sun.max.fill"
        case .liveMusic:   return "music.mic"
        case .danceFloor:  return "figure.dance"
        case .pool:        return "water.waves"
        case .smokingArea: return "smoke.fill"
        case .vipArea:     return "star.fill"
        }
    }
}
