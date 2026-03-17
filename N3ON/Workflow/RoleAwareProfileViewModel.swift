//
//  RoleAwareProfileViewModel.swift
//  N3ON
//
import Foundation
import UIKit
import Amplify

@MainActor
final class RoleAwareProfileViewModel: ObservableObject {
    @Published var roles: Set<AppRole> = []
    @Published var isDJMode = false
    @Published var username = "Username"
    @Published var followers = 0
    @Published var following = 0
    @Published var avatarState: AvatarState = .remote(avatarKey: "default-avatar")

    // true while a mode-switch save is in flight
    @Published var isSwitching = false

    func load() async {
        roles = await AccessControlService.currentUserRoles()
        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            if let model = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                username = model.username
                avatarState = .remote(avatarKey: model.avatarKey ?? "default-avatar")
                // isDJ in DataStore is the persisted mode preference
                isDJMode = model.isDJ
            }
        } catch {
            avatarState = .remote(avatarKey: "default-avatar")
        }
    }

    /// Toggles between DJ and fan mode, persists to DataStore.
    /// Only callable when the user holds the DJ Cognito role.
    func toggleDJMode() async {
        guard !isSwitching else { return }
        isSwitching = true
        defer { isSwitching = false }

        let newMode = !isDJMode
        // Optimistic update
        isDJMode = newMode

        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            if var user = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                user.isDJ = newMode
                try await Amplify.DataStore.save(user)
            }
        } catch {
            // Revert on failure
            isDJMode = !newMode
        }
    }

    func uploadAvatar(image: UIImage) async {
        do {
            avatarState = try await AvatarUploadService.uploadUIImage(image)
        } catch {
            // keep existing avatarState on failure
        }
    }
}
