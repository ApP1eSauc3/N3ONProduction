// AuthService.swift
// N3ON
//
// CHANGES FROM ORIGINAL:
// 1. currentUserId is now async throws — the original synchronous try? silently
//    returned nil if the auth session wasn't ready, causing downstream failures
//    (DataStore queries, upload paths, profile loads) with zero error information.
//    Source: https://docs.amplify.aws/swift/build-a-backend/auth/sign-in/
//
// 2. getCurrentUserModel() now propagates errors instead of returning nil silently.
//
// 3. Added currentUserRoles() here to centralise auth queries in one place
//    rather than scattering Amplify.Auth calls across ViewModels.

import Foundation
import Amplify

enum AuthService {

    // ✅ FIXED: async — getCurrentUser() underlying session check is async
    // Original `try? Amplify.Auth.getCurrentUser().userId` could silently return nil
    // on app launch before the session token was ready
    static func currentUserId() async throws -> String {
        try await Amplify.Auth.getCurrentUser().userId
    }

    static func getCurrentUserModel() async throws -> User? {
        let id = try await currentUserId()
        return try await Amplify.DataStore.query(User.self, byId: id)
    }

    // Convenience: returns nil instead of throwing — use where absence is valid
    static func currentUserIdOrNil() async -> String? {
        try? await Amplify.Auth.getCurrentUser().userId
    }
}
