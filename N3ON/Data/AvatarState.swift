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
        if let key = user.avatarKey, isStorageKey(key) {
            return .remote(avatarKey: key)
        }
        return .remote(avatarKey: "default-avatar")
    }

    /// An S3 key, not a URL. Signed URLs must never be stored (they expire and
    /// leak a credential); a stored one is treated as no avatar.
    /// S3's hard limit on key length — anything longer cannot be a real key,
    /// and rejecting it first keeps this check O(1) on hostile input.
    static let maxKeyBytes = 1_024

    static func isStorageKey(_ key: String) -> Bool {
        let bytes = key.utf8.count
        guard bytes > 0, bytes <= maxKeyBytes else { return false }
        return !key.contains("://") && !key.contains("X-Amz-")
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
