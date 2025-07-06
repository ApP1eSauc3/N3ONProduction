//
//  AvatarState.swift
//  N3ON
//
//  Created by liam howe on 7/7/2025.
//

import SwiftUI
import Amplify
import UIKit

enum AvatarState: Equatable {
    case remote(avatarKey: String)
    case local(image: UIImage)
    
    // Computed property to get image key
    var key: String? {
        switch self {
        case .remote(let key): return key
        case .local: return nil
        }
    }
    
    // Helper to get UIImage representation
    var image: UIImage? {
        switch self {
        case .local(let img): return img
        default: return nil
        }
    }
}

// MARK: - Convenience Methods
extension AvatarState {
    static func fromUser(_ user: User) -> AvatarState {
        if let key = user.avatarKey {
            return .remote(avatarKey: key)
        }
        return .remote(avatarKey: "default-avatar")
    }
    
    func toAmplifyValue() -> String? {
        switch self {
        case .remote(let key): return key
        case .local: return nil  // Local images need upload first
        }
    }
}

// MARK: - Equatable Conformance
extension AvatarState {
    static func == (lhs: AvatarState, rhs: AvatarState) -> Bool {
        switch (lhs, rhs) {
        case (.remote(let lhsKey), (.remote(let rhsKey)):
            return lhsKey == rhsKey
        case (.local(let lhsImage), (.local(let rhsImage)):
            return lhsImage.pngData() == rhsImage.pngData()
        default:
            return false
        }
    }
}
