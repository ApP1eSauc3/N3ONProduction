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
    // Populated by the caller for each returned DJ — not in the GraphQL
    // response, so excluded from decoding.
    var isFollowedByCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, name, genre, profileImageKey, currentLocation
    }
}
