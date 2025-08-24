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

        let key = MediaKind.avatar(userId: auth.userId).makeKey(extension: "jpg")
        _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .protected)
        me.avatarKey = key
        try await Amplify.DataStore.save(me)
        return .remote(avatarKey: key)
    }
}
