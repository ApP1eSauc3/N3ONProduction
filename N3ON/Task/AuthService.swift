// AuthService.swift
// N3ON — Task layer
// Single entry point for all Amplify Auth operations.
// Views and ViewModels never call Amplify.Auth directly.
//
// CHANGES FROM ORIGINAL:
// 1. currentUserId is now async throws — the original synchronous try? silently
//    returned nil if the auth session wasn't ready, causing downstream failures
//    (DataStore queries, upload paths, profile loads) with zero error information.
//    Source: https://docs.amplify.aws/swift/build-a-backend/auth/sign-in/
//
// 2. getCurrentUserModel() now propagates errors instead of returning nil silently.
//
// 3. Added signIn / signUp / confirmSignUp / resendSignUpCode / signOut —
//    all Amplify.Auth calls centralised here so no view or ViewModel touches
//    the Amplify framework directly.

import Foundation
import Amplify

enum AuthService {

    // MARK: — Session

    /// Async throws — preferred. Call when absence of a session is an error.
    static func currentUserId() async throws -> String {
        try await Amplify.Auth.getCurrentUser().userId
    }

    /// Safe fallback — returns nil instead of throwing. Use when guest state is valid.
    static func currentUserIdOrNil() async -> String? {
        try? await Amplify.Auth.getCurrentUser().userId
    }

    /// Returns the DataStore User model for the currently signed-in user, or nil
    /// if the record does not yet exist (e.g. first launch after sign-up).
    static func getCurrentUserModel() async throws -> User? {
        let id = try await currentUserId()
        return try await Amplify.DataStore.query(User.self, byId: id)
    }

    // MARK: — Sign in

    /// Authenticates with Cognito. Throws AuthError on failure.
    /// On success the Hub emits `.signedIn` — callers should react to that event
    /// rather than polling after this call returns.
    static func signIn(username: String, password: String) async throws {
        let result = try await Amplify.Auth.signIn(username: username, password: password)
        guard result.isSignedIn else {
            throw AuthError.unknown("Sign in did not complete. Next step: \(result.nextStep)", nil)
        }
    }

    // MARK: — Sign up

    /// Creates a new Cognito account. Returns `true` when a confirmation code was sent
    /// (the normal Cognito flow); returns `false` if the account was immediately confirmed
    /// (atypical — admin-created accounts, etc).
    static func signUp(username: String, email: String, password: String) async throws -> Bool {
        let options = AuthSignUpRequest.Options(
            userAttributes: [AuthUserAttribute(.email, value: email)]
        )
        let result = try await Amplify.Auth.signUp(
            username: username,
            password: password,
            options: options
        )
        if case .confirmUser = result.nextStep { return true }
        return false
    }

    // MARK: — Confirmation

    /// Submits the 6-digit code from the Cognito verification email. Throws on failure
    /// or if the confirmation did not reach the `.done` step.
    static func confirmSignUp(for username: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(
            for: username,
            confirmationCode: code
        )
        guard case .done = result.nextStep else {
            throw AuthError.unknown("Confirmation did not complete. Next step: \(result.nextStep)", nil)
        }
    }

    /// Requests a new verification code. Use when the original code expires.
    static func resendSignUpCode(for username: String) async throws {
        _ = try await Amplify.Auth.resendSignUpCode(for: username)
    }

    // MARK: — Password reset

    /// Initiates Cognito's forgot-password flow. A verification code is sent to
    /// the email address associated with the given username.
    static func resetPassword(username: String) async throws {
        _ = try await Amplify.Auth.resetPassword(for: username)
    }

    /// Completes the reset: submits the code and new password.
    static func confirmReset(username: String, newPassword: String, code: String) async throws {
        try await Amplify.Auth.confirmResetPassword(
            for: username,
            with: newPassword,
            confirmationCode: code
        )
    }

    // MARK: — First-launch user record

    /// Creates the User DataStore record immediately after first sign-in.
    /// Called when `getCurrentUserModel()` returns nil — i.e. no record yet.
    /// The username and isDJ preference are forwarded from the role-selection screen.
    static func createInitialUserRecord(username: String, isDJ: Bool) async throws -> User {
        let id = try await currentUserId()
        let user = User(
            id: id,
            username: username,
            isDJ: isDJ,
            djRank: isDJ ? 1 : nil,
            isCurated:         false,
            isSharingLocation: false,
            coinBalance: 0
        )
        try await Amplify.DataStore.save(user)
        return user
    }

    // MARK: — Sign out

    /// Signs out globally. Non-throwing — the Hub emits `.signedOut` on completion.
    static func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    // MARK: — Account deletion

    /// Permanently removes the account in three ordered steps:
    ///
    /// 1. Delete the `User` DataStore record (syncs the deletion to the backend
    ///    while the Cognito session is still valid).
    /// 2. Clear all local DataStore data (SQLite cache wiped).
    /// 3. Delete the Cognito user account (`Auth.deleteUser()`).
    ///    Amplify internally signs the user out after deletion, which causes the
    ///    Hub to emit `.signedOut` — callers must **not** mutate `flowState` directly;
    ///    `AuthViewModel`'s Hub observer handles the transition to `.login`.
    ///
    /// Throws `AuthError` if the Cognito deletion fails, or an `AmplifyError`
    /// subtype if DataStore operations fail. DataStore failures are non-fatal in
    /// practice — the Cognito account is the authoritative gate.
    static func deleteAccount() async throws {
        // Step 1 — remove User record from DataStore (propagates to backend)
        if let user = try await getCurrentUserModel() {
            try await Amplify.DataStore.delete(user)
        }

        // Step 2 — wipe local SQLite cache
        try await Amplify.DataStore.clear()

        // Step 3 — delete Cognito account; triggers Hub .signedOut
        try await Amplify.Auth.deleteUser()
    }
}
