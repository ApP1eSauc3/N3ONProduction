//
//  Event.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import Foundation
import Amplify



public struct DJParticipant: Codable {
    public var id: String
    public var username: String
    public var rank: Int // 1–5
    
    public init(id: String, username: String, rank: Int) {
        self.id = id
        self.username = username
        self.rank = rank
    }
}
