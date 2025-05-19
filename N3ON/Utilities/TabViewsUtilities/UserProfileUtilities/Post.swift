//
//  Post.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//

import Foundation
import Amplify
import MapKit
import AVKit

struct Post: Identifiable, Hashable {
    let id: UUID
    let urls: [URL]
    let types: [MediaType]
    let timestamp: Date
    let caption: String
}

enum MediaType: String, Codable, CaseIterable {
    case image, audio, video
}
    
    
