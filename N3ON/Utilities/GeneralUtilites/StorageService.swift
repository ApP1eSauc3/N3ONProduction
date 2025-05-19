//
//  StorageService.swift
//  N3ON
//
//  Created by liam howe on 8/3/2025.
//

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
