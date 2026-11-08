// RoleService.swift
// N3ON — Task layer
// Persists role changes to the DataStore User record.
// Venue role is Cognito-managed (admin only) and cannot be changed here.

import Foundation
import Amplify

enum RoleService {
    /// Sets the DJ flag on the User record and returns the saved model.
    /// The caller is responsible for updating AppRole in the ViewModel after this succeeds.
    /// Only the signed-in user's own record: a client never changes someone
    /// else's DJ status (server @auth agrees; this keeps the client honest).
    static func setDJStatus(_ isDJ: Bool, for user: User) async throws -> User {
        guard try await AuthService.currentUserId() == user.id else { throw RoleError.notCurrentUser }
        var updated = user
        updated.isDJ = isDJ
        try await Backend.dataStore.save(updated)
        return updated
    }
}

enum RoleError: LocalizedError {
    case notCurrentUser
    var errorDescription: String? { "You can only change your own profile." }
}
