//
//  AuthService.swift
//  N3ON
//
//  Created by liam howe on 21/8/2025.
//

import Foundation
import Amplify

enum AuthService {
    static var currentUserId: String? {
        try? Amplify.Auth.getCurrentUser().userId
    }

    static func getCurrentUserModel() async throws -> User? {
        guard let id = currentUserId else { return nil }
        return try await Amplify.DataStore.query(User.self, byId: id)
    }
}
