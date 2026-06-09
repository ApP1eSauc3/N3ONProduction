//
//  RoleAwareProfileViewModel.swift
//  N3ON
//
import Foundation
import UIKit
import Amplify

@MainActor
final class RoleAwareProfileViewModel: ObservableObject {
    @Published var role: AppRole = .regular
    @Published var username = "Username"
    @Published var followers = 0
    @Published var following = 0
    @Published var avatarState: AvatarState = .remote(avatarKey: "default-avatar")
    @Published var currentUser: User?
    @Published var isSwitchingRole = false
    @Published var roleSwitchError: String?

    /// Orthogonal admin capability (AdminUser Cognito group) — drives bootstrap curation UI.
    @Published var isAdmin = false

    /// Whether this user may create/host an event. Routed through the capability
    /// layer so bootstrap curation (admin / curated roster) supersedes the rank gate.
    var canCreateEvent: Bool {
        guard let user = currentUser else { return false }
        return CurationService.canCreateEvent(user: user, isAdmin: isAdmin)
    }

    func load() async {
        // Venue role has no DataStore field — derive it from the Cognito group only
        let cognitoRole = await AccessControlService.currentUserRole()
        isAdmin = await AccessControlService.isAdmin()
        do {
            if let model = try await AuthService.getCurrentUserModel() {
                username = model.username
                avatarState = .remote(avatarKey: model.avatarKey ?? "default-avatar")
                currentUser = model
                // Venue is Cognito-only; DJ vs Regular is authoritative in User.isDJ
                role = cognitoRole == .venue ? .venue : (model.isDJ ? .dj : .regular)
            }
        } catch {
            role = cognitoRole
            avatarState = .remote(avatarKey: "default-avatar")
        }
    }

    func uploadAvatar(image: UIImage) async {
        do {
            avatarState = try await AvatarUploadService.uploadUIImage(image)
        } catch {
            // keep existing avatarState on failure
        }
    }

    /// Writes the new role to DataStore and updates published state.
    /// Venue role cannot be set from the client — this is a no-op for `.venue`.
    func switchRole(to newRole: AppRole) async {
        guard newRole != .venue else { return }
        guard !isSwitchingRole, let user = currentUser else { return }
        isSwitchingRole = true
        defer { isSwitchingRole = false }
        roleSwitchError = nil
        do {
            let updated = try await RoleService.setDJStatus(newRole == .dj, for: user)
            currentUser = updated
            role = newRole
        } catch {
            roleSwitchError = error.localizedDescription
        }
    }
}
