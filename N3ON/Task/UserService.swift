// UserService.swift
// N3ON — Task layer
// Generic User DataStore access shared across features that don't own the
// user relationship themselves (chat, event lineups, invite search).

import Foundation
import Amplify
import AWSPluginsCore

enum UserService {

    static func fetch(byId id: String) async throws -> User? {
        try await Amplify.DataStore.query(User.self, byId: id)
    }

    /// The local copy if DataStore has synced it, else one GraphQL read. Used
    /// for display names (chat senders) where a not-yet-synced profile used to
    /// show as "Unknown".
    static func fetchAnywhere(byId id: String) async -> User? {
        if let local = try? await Amplify.DataStore.query(User.self, byId: id) { return local }
        guard let response = try? await Amplify.API.query(request: .get(User.self, byId: id)),
              case .success(let user) = response else { return nil }
        return user
    }

    static func fetchAll() async throws -> [User] {
        try await Amplify.DataStore.query(User.self)
    }
}
