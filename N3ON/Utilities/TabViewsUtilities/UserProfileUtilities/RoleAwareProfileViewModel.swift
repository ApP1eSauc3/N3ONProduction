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
    @Published var avatarState: AvatarState = .remote(avatarKey: "default-avatar-key")

    private(set) var me: User?

    init() {
        Task { await bootstrap() }
    }

    private func bootstrap() async {
        roles = await AccessControlService.currentUserRoles()
        if let u = try? await AuthService.getCurrentUserModel() {
            me = u
            username = u.username
            if let key = u.avatarKey { avatarState = .remote(avatarKey: key) }
        }
        isDJMode = roles.contains(.dj)
    }
}
