//
//  StorageUploader.swift
//  N3ON
//
//  Created by liam howe on 24/8/2025.
//

import Foundation
import Amplify

enum MediaKind {
    case avatar(userID: String)
    case eventPoster(eventID: String)
    case venueImage(venueID: String)
    case feedImage(userID: String)
    case feedVideo(userID: String)
    case feedAudio(userID: String)
    
    func makeKey(`extension`: String) -> String {
           switch self {
           case .avatar(let uid):         return "avatars/\(uid).\(`extension`)"
           case .eventPoster(let eid):    return "events/\(eid)/poster-\(UUID().uuidString).\(`extension`)"
           case .venueImage(let vid):     return "venues/\(vid)/img-\(UUID().uuidString).\(`extension`)"
           case .feedImage(let uid):      return "feed/\(uid)/img-\(UUID().uuidString).\(`extension`)"
           case .feedVideo(let uid):      return "feed/\(uid)/vid-\(UUID().uuidString).\(`extension`)"
           case .feedAudio(let uid):      return "feed/\(uid)/aud-\(UUID().uuidString).\(`extension`)"
           }
       }
   }

struct StorageUploader {
    static func uploadJPEG(_ data: Data,
                           key: String,
                           access: StorageAccessLevel = .protected) async throws -> String {
        do {
            let result = try await Amplify.Storage
                .uploadData(key: key, data: data,
                            options: .init(accessLevel: access, contentType: "image/jpeg"))
                .value
            return result
        } catch { throw UploadError.uploadFailed(String(describing: error)) }
    }

    static func uploadFile(url: URL,
                           key: String,
                           contentType: String,
                           access: StorageAccessLevel = .protected) async throws -> String {
        do {
            let data = try Data(contentsOf: url)
            let result = try await Amplify.Storage
                .uploadData(key: key, data: data,
                            options: .init(accessLevel: access, contentType: contentType))
                .value
            return result
        } catch { throw UploadError.uploadFailed(String(describing: error)) }
    }

    static func signedURL(for key: String,
                          access: StorageAccessLevel = .protected) async -> URL? {
        await withCheckedContinuation { cont in
            Amplify.Storage.getURL(key: key, options: .init(accessLevel: access)) { result in
                switch result {
                case .success(let url): cont.resume(returning: url)
                case .failure:          cont.resume(returning: nil)
                }
            }
        }
    }
}
