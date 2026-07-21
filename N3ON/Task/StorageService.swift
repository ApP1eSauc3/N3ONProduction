//
//  StorageService.swift
//  N3ON
//
//  Created by liam howe on 8/3/2025.
//
// ACCESS LEVEL CONVENTION (mirrored in StorageUploader.swift)
//   • .guest     — anything displayed to OTHER users: avatars, DJ audio,
//                  event posters, venue imagery. Set `isPublished = true`
//                  on uploadImage() to select this.
//   • .protected — owner-writable. ⚠️ NOT cross-user readable in practice:
//                  keys resolve to protected/{identityId}/… using the CALLER's
//                  identityId, so another user signing the same key gets a URL
//                  into their own (empty) prefix → silent 403. Cross-user reads
//                  require targetIdentityId, which this app does not plumb.
//   • .private   — only the uploader can read it.
// NEVER mix access levels between the upload call and the matching
// signedURL(for:access:) call — permission mismatches produce silent 403s.

import Foundation
import Amplify
import AWSPluginsCore
import UIKit

enum StorageError: Error {
    case invalidImage
    case authenticationError
}

struct StorageService {
    static let shared = StorageService()

    // Publicly accessible path
    static func publishedPath(_ fileName: String) -> StringStoragePath {
        return StringStoragePath.fromString("public/\(fileName)")
    }

    // Private content (only owner can access)
    static func privatePath(_ fileName: String, identityId: String) -> StringStoragePath {
        return StringStoragePath.fromString("private/\(identityId)/\(fileName)")
    }

    // Protected content (readable by all, writable by owner)
    static func protectedPath(_ fileName: String, identityId: String) -> StringStoragePath {
        return StringStoragePath.fromString("protected/\(identityId)/\(fileName)")
    }

    static func uploadImage(_ image: UIImage, isPublished: Bool = false) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let fileName = "\(UUID().uuidString).jpg"
        let path: StringStoragePath

        if isPublished {
            path = publishedPath(fileName)
        } else {
            let identityId = try await getCurrentIdentityId()
            path = privatePath(fileName, identityId: identityId)
        }

        let uploadTask = Amplify.Storage.uploadData(
            path: path,
            data: imageData,
            options: StorageUploadDataRequest.Options(
                accessLevel: isPublished ? .guest : .protected,
                metadata: nil,
                contentType: "image/jpeg"
            )
        )

        return try await uploadTask.value
    }

    private static func getCurrentIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        if let identityProvider = session as? AuthCognitoIdentityProvider {
            return try identityProvider.getIdentityId().get()
        }
        throw StorageError.authenticationError
    }
}
