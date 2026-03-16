// StorageUploader.swift
// N3ON
//
// CHANGES FROM ORIGINAL:
// 1. uploadFile now uses Amplify.Storage.uploadFile (disk streaming) instead of
//    Data(contentsOf:) which loads entire file into RAM — crashes on large videos.
//    Source: https://docs.amplify.aws/swift/build-a-backend/storage/upload/
//
// 2. signedURL now uses native async/await API instead of callback wrapped in
//    withCheckedContinuation. The callback-style getURL is deprecated in Amplify v2.
//    Source: https://docs.amplify.aws/swift/build-a-backend/storage/download/#generate-a-download-url
//
// 3. All methods are now consistently async throws — no silent swallowing.

import Foundation
import Amplify

enum MediaKind {
    case avatar(userID: String)
    case eventPoster(eventID: String)
    case venueImage(venueID: String)
    case feedImage(userID: String)
    case feedVideo(userID: String)
    case feedAudio(userID: String)

    func makeKey(extension ext: String) -> String {
        switch self {
        case .avatar(let uid):      return "avatars/\(uid).\(ext)"
        case .eventPoster(let eid): return "events/\(eid)/poster-\(UUID().uuidString).\(ext)"
        case .venueImage(let vid):  return "venues/\(vid)/img-\(UUID().uuidString).\(ext)"
        case .feedImage(let uid):   return "feed/\(uid)/img-\(UUID().uuidString).\(ext)"
        case .feedVideo(let uid):   return "feed/\(uid)/vid-\(UUID().uuidString).\(ext)"
        case .feedAudio(let uid):   return "feed/\(uid)/aud-\(UUID().uuidString).\(ext)"
        }
    }
}

struct StorageUploader {

    static func uploadJPEG(
        _ data: Data,
        key: String,
        access: StorageAccessLevel = .protected
    ) async throws -> String {
        let result = try await Amplify.Storage
            .uploadData(
                key: key,
                data: data,
                options: .init(accessLevel: access, contentType: "image/jpeg")
            )
            .value
        return result
    }

    // ✅ FIXED: uses uploadFile (streaming from disk) not uploadData (full RAM load)
    // Critical for video — a 200MB video with the old approach caused memory crashes
    static func uploadFile(
        url: URL,
        key: String,
        contentType: String,
        access: StorageAccessLevel = .protected
    ) async throws -> String {
        let result = try await Amplify.Storage
            .uploadFile(
                key: key,
                local: url,
                options: .init(accessLevel: access, contentType: contentType)
            )
            .value
        return result
    }

    // ✅ FIXED: native async/await — callback wrapper removed, deprecated API gone
    static func signedURL(
        for key: String,
        access: StorageAccessLevel = .protected
    ) async throws -> URL {
        try await Amplify.Storage.getURL(
            key: key,
            options: .init(accessLevel: access)
        )
    }
}
