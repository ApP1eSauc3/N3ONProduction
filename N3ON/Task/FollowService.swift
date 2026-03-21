// FollowService.swift
// N3ON
//
// Only DJs can be followed. The followeeID stored here is always a DJ's userID.
// The DJ constraint is enforced at the call site (DJViewModel) — this service
// stores and queries raw IDs without re-fetching the User to check isDJ.

import Foundation
import Amplify

enum FollowService {

    // MARK: - Write

    /// Records that the current user is following a DJ.
    static func follow(djID: String) async throws {
        let followerID = try await AuthService.currentUserId()
        guard try await !isFollowing(djID: djID) else { return }

        let link = UserFollows(
            followerID: followerID,
            followeeID: djID,
            createdAt: Temporal.DateTime.now()
        )
        try await Amplify.DataStore.save(link)
    }

    /// Removes the current user's follow on a DJ.
    static func unfollow(djID: String) async throws {
        let followerID = try await AuthService.currentUserId()
        let matches = try await Amplify.DataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followerID == followerID
        )
        if let link = matches.first(where: { $0.followeeID == djID }) {
            try await Amplify.DataStore.delete(link)
        }
    }

    // MARK: - Read

    /// Returns true if the current user follows the given DJ.
    static func isFollowing(djID: String) async throws -> Bool {
        let followerID = try await AuthService.currentUserId()
        let matches = try await Amplify.DataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followerID == followerID
        )
        return matches.contains { $0.followeeID == djID }
    }

    /// Returns the djIDs of everyone the current user follows.
    static func followedDJIDs() async throws -> [String] {
        let followerID = try await AuthService.currentUserId()
        let matches = try await Amplify.DataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followerID == followerID
        )
        return matches.map { $0.followeeID }
    }

    /// Returns the follower count for a given DJ.
    static func followerCount(for djID: String) async -> Int {
        let matches = (try? await Amplify.DataStore.query(
            UserFollows.self,
            where: UserFollows.keys.followeeID == djID
        )) ?? []
        return matches.count
    }
}
