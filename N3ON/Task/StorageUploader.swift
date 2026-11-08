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
//
// ACCESS LEVEL CONVENTION
//   • .guest     — anything displayed to OTHER users: avatars, DJ audio,
//                  event posters, venue imagery. (Upload still requires auth;
//                  "guest" only means the read path is not identity-scoped.)
//   • .protected — owner-writable. ⚠️ Keys resolve to protected/{identityId}/…
//                  using the CALLER's identityId — so another user signing this
//                  key gets a URL into their OWN (empty) prefix → silent 403.
//                  Cross-user reads need targetIdentityId, which this app does
//                  not plumb. Only use .protected for content the uploader alone
//                  will ever view.
//   • .private   — only the uploader can read.
// `access:` has no default — every call site states its intent explicitly.
// The same access level MUST be used for the matching signedURL(for:access:)
// read — mismatches are silent 403s.

import Foundation
import Amplify

enum MediaKind {
    case avatar(userID: String)
    case profileAudio(userID: String)
    case eventPoster(eventID: String)
    case venueImage(venueID: String)
    case feedImage(userID: String)
    case feedVideo(userID: String)

    func makeKey(extension rawExt: String) -> String {
        let ext = Self.component(rawExt)
        switch self {
        case .avatar(let uid):        return "avatars/\(Self.component(uid)).\(ext)"
        case .profileAudio(let uid):  return "profile-audio/\(Self.component(uid)).\(ext)"
        case .eventPoster(let eid):   return "events/\(Self.component(eid))/poster-\(UUID().uuidString).\(ext)"
        case .venueImage(let vid):    return "venues/\(Self.component(vid))/img-\(UUID().uuidString).\(ext)"
        case .feedImage(let uid):     return "feed/\(Self.component(uid))/img-\(UUID().uuidString).\(ext)"
        case .feedVideo(let uid):     return "feed/\(Self.component(uid))/vid-\(UUID().uuidString).\(ext)"
        }
    }

    /// One S3 path component: letters, digits, `-` and `_` only (everything
    /// else becomes `_`), never empty, at most 128 characters. IDs reach here
    /// from client-written records, so "../avatars/victim" must not be able to
    /// address another user's media. Cognito subs and UUIDs pass unchanged.
    static func component(_ raw: String) -> String {
        let cleaned = String(raw.unicodeScalars.prefix(128).map { scalar -> Character in
            let ok = (scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar))) || scalar == "-" || scalar == "_"
            return ok ? Character(scalar) : "_"
        })
        return cleaned.isEmpty ? "_" : cleaned
    }
}

struct StorageUploader {

    static func uploadJPEG(
        _ data: Data,
        key: String,
        access: StorageAccessLevel
    ) async throws -> String {
        try await Backend.storage.uploadData(key: key, data: data, accessLevel: access, contentType: "image/jpeg")
    }

    // ✅ FIXED: uses uploadFile (streaming from disk) not uploadData (full RAM load)
    // Critical for video — a 200MB video with the old approach caused memory crashes
    static func uploadFile(
        url: URL,
        key: String,
        contentType: String,
        access: StorageAccessLevel
    ) async throws -> String {
        try await Backend.storage.uploadFile(key: key, local: url, accessLevel: access, contentType: contentType)
    }

    // ✅ FIXED: native async/await — callback wrapper removed, deprecated API gone
    static func signedURL(
        for key: String,
        access: StorageAccessLevel
    ) async throws -> URL {
        try await Backend.storage.getURL(key: key, accessLevel: access)
    }
}
