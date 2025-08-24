//
//  PosterUploadService.swift
//  N3ON
//
//  Created by liam howe on 24/8/2025.
//

import Foundation
import Amplify
import PhotosUI
import UIKit
import _PhotosUI_SwiftUI

@MainActor

enum PosterUploadService {
    static func uploadFromPickerItem(_ item: PhotosPickerItem, eventId: String,
                                     access: StorageAccessLevel = .protected) async throws -> String {
        guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { throw UploadError.imageDecodeFailed }
                return try await uploadUIImage(image, eventId: eventId, access: access)
            }

            static func uploadUIImage(_ image: UIImage, eventId: String,
                                      access: StorageAccessLevel = .protected) async throws -> String {
                guard var event = try await Amplify.DataStore.query(Event.self, byId: eventId)
                else { throw UploadError.eventNotFound }

                guard let jpeg = ImagePipeline.makeJPEGData(from: image, config: .poster)
                else { throw UploadError.encodingFailed }

                let key = MediaKind.eventPoster(eventID: eventId).makeKey(extension: "jpg")
                _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: access)
                event.posterKey = key
                try await Amplify.DataStore.save(event)
                return key
            }
        }
