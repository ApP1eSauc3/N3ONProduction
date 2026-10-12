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
                // Signed in but no User record yet — first sign-in after role
                // selection, or a recovery case (reinstall / second device /
                // interrupted first run).
                let id = try await AuthService.currentUserId()
                userState.userId = id
                if let pendingUsername = UserDefaults.standard.string(forKey: "pendingUsername") {
                    let isDJ = UserDefaults.standard.bool(forKey: "pendingIsDJ")
                    do {
                        let created = try await AuthService.createInitialUserRecord(
                            username: pendingUsername, isDJ: isDJ
                        )
                        userState.updateFromUser(created)
                        // Clear pending data only on success — keep it for retry.
                        UserDefaults.standard.removeObject(forKey: "pendingUsername")
                        UserDefaults.standard.removeObject(forKey: "pendingIsDJ")
                        flowState = .authenticated
                    } catch {
                        // Never land the user in the app with no User record.
                        // Role selection retries creation via completeRoleSelection.
                        errorMessage = "Could not finish setting up your profile — please try again."
                        flowState = .roleSelection(username: pendingUsername)
                    }
                } else {
                    // No pending role data on this device — re-ask instead of
                    // authenticating a user who has no profile record.
                    let handle = try? await AuthService.currentHandle()
                    flowState = .roleSelection(username: handle ?? "")
                }
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

    func signIn(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.signIn(email: email, password: password)
            // Hub .signedIn event will trigger loadSession() → flowState = .authenticated
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    /// `handle` is the public @username (stored on the User record); `email` is
    /// what the account signs in with.
    func signUp(handle: String, email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let needsConfirmation = try await AuthService.signUp(
                handle: handle,
                email: email,
                password: password
            )
            flowState = needsConfirmation
                ? .confirmCode(email: AuthService.cognitoUsername(email), handle: handle)
                : .roleSelection(username: handle)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func confirmCode(email: String, handle: String, code: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.confirmSignUp(email: email, code: code)
            // First-time user — let them pick their role before signing in.
            flowState = .roleSelection(username: handle)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    /// Called by RoleSelectionView.
    /// Normal sign-up flow (no session yet): persists the choice so loadSession()
    /// can create the User record after the user signs in for the first time.
    /// Recovery flow (already signed in, no User record): creates the record
    /// immediately — bouncing a signed-in user back to the login screen would
    /// be both confusing and unnecessary.
    func completeRoleSelection(username: String, isDJ: Bool) async {
        errorMessage = nil
        guard await AuthService.currentUserIdOrNil() != nil else {
            UserDefaults.standard.set(username, forKey: "pendingUsername")
            UserDefaults.standard.set(isDJ, forKey: "pendingIsDJ")
            flowState = .login
            return
        }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let created = try await AuthService.createInitialUserRecord(username: username, isDJ: isDJ)
            userState.updateFromUser(created)
            UserDefaults.standard.removeObject(forKey: "pendingUsername")
            UserDefaults.standard.removeObject(forKey: "pendingIsDJ")
            flowState = .authenticated
        } catch {
            errorMessage = "Could not save your role: \(authErrorMessage(from: error))"
        }
    }

    func requestReset(email: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.resetPassword(email: email)
            flowState = .confirmReset(email: email)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func confirmReset(email: String, newPassword: String, code: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.confirmReset(email: email, newPassword: newPassword, code: code)
            flowState = .login
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func resendCode(email: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.resendSignUpCode(email: email)
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
