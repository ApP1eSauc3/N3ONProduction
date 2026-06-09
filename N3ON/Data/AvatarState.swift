///
//  AvatarState.swift
//  N3ON
//

import UIKit

enum AvatarState: Equatable {
    case remote(avatarKey: String)
    case local(image: UIImage)

    var key: String? {
        switch self {
        case .remote(let key): return key
        case .local: return nil
        }
    }

    var image: UIImage? {
        switch self {
        case .local(let img): return img
        case .remote: return nil
        }
    }
}

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
        case .local: return nil
        }
    }

    // Equatable — UIImage doesn't conform by default so we implement manually.
    // .local compares by reference identity only — pngData() would run a full
    // PNG encode on every SwiftUI equality check, which is O(pixels).
    static func == (lhs: AvatarState, rhs: AvatarState) -> Bool {
        switch (lhs, rhs) {
        case (.remote(let lKey), .remote(let rKey)):
            return lKey == rKey
        case (.local(let lImg), .local(let rImg)):
            return lImg === rImg
        default:
            return false
        }
    }
}
