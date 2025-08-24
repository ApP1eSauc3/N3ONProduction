//
//  UploadError.swift
//  N3ON
//
//  Created by liam howe on 24/8/2025.
//

import Foundation

enum UploadError: Error, LocalizedError {
    case invalidSelection
    case imageDecodeFailed
    case encodingFailed
    case uploadFailed(String)
    case userNotFound
    case eventNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidSelection: return "no media selected"
        case .imageDecodeFailed: return "failed to decode image"
        case .encodingFailed: return "failed to encode media"
        case .uploadFailed(let reason): return "upload failed: \(reason)"
        }
    }
}
            
