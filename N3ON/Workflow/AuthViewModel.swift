// AuthViewModel.swift
// N3ON — Workflow layer
// Auth state machine: owns AuthFlowState and orchestrates AuthService calls.
// Architecture derived from Kilo-Loco's SessionManager pattern, rewritten for:
//   — async/await (no callbacks, no DispatchQueue.main)
//   — Hub observation via AsyncPublisher (no Combine Set<AnyCancellable> in views)
//   — single UserState instance shared downward through the view hierarchy
//   — @MainActor isolation guaranteeing all @Published mutations on the main thread

import Foundation
import Amplify

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: — Published state

    @Published var flowState: AuthFlowState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Shared user state — passed to MainView as @EnvironmentObject so
    /// profile, map, and chat views all read from the same instance.
    let userState = UserState()

    // MARK: — Private

    private var hubTask: Task<Void, Never>?

    deinit {
        hubTask?.cancel()
    }

    // MARK: — Boot sequence

    /// Called once from SessionView's .task modifier.
    /// Checks for an existing session, then starts Hub observation.
    func load() async {
        await loadSession()
        startHubObservation()
    }

    private func loadSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let user = try await AuthService.getCurrentUserModel() {
                userState.updateFromUser(user)
                flowState = .authenticated
            } else {
                // First sign-in after role selection — create the User record now.
                let id = try await AuthService.currentUserId()
                userState.userId = id
                if let pendingUsername = UserDefaults.standard.string(forKey: "pendingUsername") {
                    let isDJ = UserDefaults.standard.bool(forKey: "pendingIsDJ")
                    if let created = try? await AuthService.createInitialUserRecord(
                        username: pendingUsername, isDJ: isDJ
                    ) {
                        userState.updateFromUser(created)
                    }
                    UserDefaults.standard.removeObject(forKey: "pendingUsername")
                    UserDefaults.standard.removeObject(forKey: "pendingIsDJ")
                }
                flowState = .authenticated
            }
        } catch {
            // No active session — route to login.
            flowState = .login
        }
    }

    // MARK: — Hub observation (AsyncPublisher — no Combine tokens in views)

    private func startHubObservation() {
        hubTask?.cancel()
        hubTask = Task { [weak self] in
            for await payload in Amplify.Hub.publisher(for: .auth).values {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    // Don't set flowState here — wait for loadSession to confirm user model.
                    await self.loadSession()
                    await PushNotificationService.requestPermission()
                case HubPayload.EventName.Auth.signedOut,
                     HubPayload.EventName.Auth.sessionExpired:
                    self.flowState = .login
                    self.userState.reset()
                default:
                    break
                }
            }
        }
    }

    // MARK: — Navigation (called by views to move between auth screens)

    func showSignUp() {
        errorMessage = nil
        flowState = .signUp
    }

    func showLogin() {
        errorMessage = nil
        flowState = .login
    }

    func showResetPassword() {
        errorMessage = nil
        flowState = .resetPassword
    }

    // MARK: — Auth actions

    func signIn(username: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.signIn(username: username, password: password)
            // Hub .signedIn event will trigger loadSession() → flowState = .authenticated
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func signUp(username: String, email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let needsConfirmation = try await AuthService.signUp(
                username: username,
                email: email,
                password: password
            )
            flowState = needsConfirmation ? .confirmCode(username: username) : .login
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func confirmCode(username: String, code: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.confirmSignUp(for: username, code: code)
            // First-time user — let them pick their role before signing in.
            flowState = .roleSelection(username: username)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    /// Called by RoleSelectionView. Persists the choice so loadSession() can
    /// create the User record after the user signs in for the first time.
    func completeRoleSelection(username: String, isDJ: Bool) {
        UserDefaults.standard.set(username, forKey: "pendingUsername")
        UserDefaults.standard.set(isDJ, forKey: "pendingIsDJ")
        errorMessage = nil
        flowState = .login
    }

    func requestReset(username: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.resetPassword(username: username)
            flowState = .confirmReset(username: username)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func confirmReset(username: String, newPassword: String, code: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.confirmReset(username: username, newPassword: newPassword, code: code)
            flowState = .login
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func resendCode(for username: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.resendSignUpCode(for: username)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func signOut() async {
        await AuthService.signOut()
        // Hub .signedOut event handles flowState and userState.reset()
    }

    func deleteAccount() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.deleteAccount()
            // Hub .signedOut (fired by Amplify.Auth.deleteUser internally) drives
            // flowState = .login and userState.reset() — no manual mutation needed here.
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    // MARK: — Error formatting

    private func authErrorMessage(from error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .notAuthorized(let description, _, _):
                return description
            case .validation(_, let description, _, _):
                return description
            case .service(let description, _, _):
                return description
            default:
                return authError.errorDescription
            }
        }
        return error.localizedDescription
    }
}
