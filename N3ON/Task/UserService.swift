// UserService.swift
// N3ON — Task layer
// Generic User DataStore access shared across features that don't own the
// user relationship themselves (chat, event lineups, invite search).

import Foundation
import Amplify

enum UserService {

    static func fetch(byId id: String) async throws -> User? {
        try await Amplify.DataStore.query(User.self, byId: id)
    }

    static func fetchAll() async throws -> [User] {
        try await Amplify.DataStore.query(User.self)
    }
}
