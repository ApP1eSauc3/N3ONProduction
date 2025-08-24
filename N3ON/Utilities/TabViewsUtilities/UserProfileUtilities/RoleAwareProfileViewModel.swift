//
//  RoleAwareProfileViewModel.swift
//  N3ON
//
//  Created by liam howe on 21/8/2025.
//
import SwiftUI
import Amplify

@MainActor
final class RoleAwareProfileViewModel: ObservableObject {
    @Published var roles: Set<AppRole> = []
    @Published var isDJMode = false
    @Published var username = "Username"
    @Published var followers = 0
    @Published var following = 0

    // ✅ Use your pre-existing AvatarState
    @Published var avatarState: AvatarState = .placeholder

    func load() async {
        roles = await AccessControlService.currentUserRoles()
        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            if let model = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                username = model.username
                if let key = model.avatarKey {
                    avatarState = .remote(avatarKey: key)  // why: reuse your caching + effects
                } else {
                    avatarState = .placeholder
                }
                // TODO: wire followers/following to real fields when available
            }
        } catch {
            avatarState = .placeholder
        }
        isDJMode = roles.contains(.dj)
    }
}
