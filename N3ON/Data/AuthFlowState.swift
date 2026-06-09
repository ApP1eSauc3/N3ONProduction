// AuthFlowState.swift
// N3ON — Data layer
// Finite states of the auth flow — SessionView switches on this value to decide
// which screen to render. Derived from Kilo-Loco's AuthState enum pattern.

import Foundation

enum AuthFlowState: Equatable {
    /// Initial state — checking for an existing session on cold launch.
    case loading
    /// No active session — show the sign-in screen.
    case login
    /// User has chosen to create a new account.
    case signUp
    /// Sign-up completed — waiting for the Cognito email confirmation code.
    /// Carries the username so the confirmation screen can pass it back to the service.
    case confirmCode(username: String)
    /// User tapped "Forgot password?" — show email/username entry for reset.
    case resetPassword
    /// Reset code sent — waiting for the code + new password to be submitted.
    /// Carries the username so the confirmation screen can pass it back to the service.
    case confirmReset(username: String)
    /// Email confirmed — first-time user picks their role (DJ or music fan).
    /// Carries the username for downstream User record creation.
    case roleSelection(username: String)
    /// Valid session confirmed — show the main app.
    case authenticated
}
