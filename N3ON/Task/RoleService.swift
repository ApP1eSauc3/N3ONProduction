// RoleService.swift
// N3ON — Task layer
// Persists role changes to the DataStore User record.
// Venue role is Cognito-managed (admin only) and cannot be changed here.

import Foundation
import Amplify

enum RoleService {
    /// Sets the DJ flag on the User record and returns the saved model.
    /// The caller is responsible for updating AppRole in the ViewModel after this succeeds.
    static func setDJStatus(_ isDJ: Bool, for user: User) async throws -> User {
        var updated = user
        updated.isDJ = isDJ
        try await Amplify.DataStore.save(updated)
        return updated
    }
}
