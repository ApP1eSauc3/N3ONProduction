//
//  Data/DJ.swift
//  N3ON
//

import Foundation

struct DJLocation: Codable {
    let latitude: Double
    let longitude: Double
}

struct DJ: Codable, Identifiable {
    let id: String
    let name: String
    let genre: String?
    let profileImageKey: String?
    let currentLocation: DJLocation?
    var isFollowedByCurrentUser: Bool
}
