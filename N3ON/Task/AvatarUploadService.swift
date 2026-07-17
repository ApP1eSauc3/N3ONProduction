//
//  AvatarUploadService.swift
//  N3ON
//
//  Created by liam howe on 24/8/2025.
//

import Foundation
import Amplify
import UIKit
import PhotosUI
import _PhotosUI_SwiftUI

@MainActor
enum AvatarUploadService {
    static func uploadFromPickerItem(_ item: PhotosPickerItem) async throws -> AvatarState {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { throw UploadError.imageDecodeFailed }
        return try await uploadUIImage(image)
    }

    static func uploadUIImage(_ image: UIImage) async throws -> AvatarState {
        guard let auth = try? await Amplify.Auth.getCurrentUser(),
              var me = try await Amplify.DataStore.query(User.self, byId: auth.userId)
        else { throw UploadError.userNotFound }

        guard let jpeg = ImagePipeline.makeJPEGData(from: image, config: .avatar)
        else { throw UploadError.encodingFailed }

        let key = MediaKind.avatar(userID: auth.userId).makeKey(extension: "jpg")
        _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .guest)
        // The avatar key is deterministic (avatars/{uid}.jpg) — replace the
        // cache entry or every open view serves the old photo until relaunch.
        await ImageCache.store(data: jpeg, forKey: key)
        me.avatarKey = key
        try await Amplify.DataStore.save(me)
        return .remote(avatarKey: key)
    }

    /// Uploads an audio file from a local URL and saves the S3 key to the user's profile.
    /// - Returns: The S3 key of the uploaded audio.
    @discardableResult
    static func uploadProfileAudio(from url: URL) async throws -> String {
        guard let auth = try? await Amplify.Auth.getCurrentUser(),
              var me = try await Amplify.DataStore.query(User.self, byId: auth.userId)
        else { throw UploadError.userNotFound }

        let key = MediaKind.profileAudio(userID: auth.userId).makeKey(extension: "m4a")
        _ = try await StorageUploader.uploadFile(url: url, key: key, contentType: "audio/m4a", access: .guest)
        me.profileAudioKey = key
        try await Amplify.DataStore.save(me)
        return key
    }
}
