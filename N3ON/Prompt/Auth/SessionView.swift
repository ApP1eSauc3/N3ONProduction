// SessionView.swift
// N3ON
//
// CHANGES FROM ORIGINAL:
// 1. isSignedIn is now only set to true AFTER getCurrentSession() completes —
//    original set it immediately on the Hub event, before userState was populated.
//    This caused a race where MainView rendered with empty userId on slow networks.
//    Source: https://docs.amplify.aws/swift/build-a-backend/auth/sign-in/#observe-auth-events
//
// 2. Added isLoading state to show a spinner during initial session check,
//    preventing the LoginView flashing briefly on every cold launch for signed-in users.
//
// 3. observeSession() sign-in case now waits for full session load before
//    setting isSignedIn — same fix applied consistently.

import Amplify
import Combine
import SwiftUI

@MainActor
struct SessionView: View {
    @StateObject var userState: UserState = .init()
    @State private var isSignedIn: Bool = false
    @State private var isLoading: Bool = true        // NEW: prevents login flash on launch
    @State private var tokens: Set<AnyCancellable> = []

    var body: some View {
        Group {
            if isLoading {
                ProgressView()                        // brief spinner while session resolves
                    .progressViewStyle(.circular)
            } else if isSignedIn {
                MainView()
                    .environmentObject(userState)
            } else {
                LoginView()
                    .environmentObject(userState)
            }
        }
        .onAppear {
            Task { await getCurrentSession() }
            observeSession()
        }
    }

    func getCurrentSession() async {
        defer { isLoading = false }                  // always clear loading on exit

        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard session.isSignedIn else { return } // isSignedIn stays false

            let authUser = try await Amplify.Auth.getCurrentUser()
            userState.userId = authUser.userId
            userState.username = authUser.username

            if let user = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                userState.avatarState = .remote(avatarKey: user.avatarKey ?? "defaultAvatarKey")
            }

            // ✅ FIXED: only set isSignedIn = true once ALL state is ready
            // Original set this at the top before any of the above ran
            isSignedIn = true

        } catch {
            print("Session load error: \(error)")
            // isSignedIn remains false → shows LoginView
        }
    }

    func observeSession() {
        Amplify.Hub.publisher(for: .auth)
            .receive(on: DispatchQueue.main)
            .sink { payload in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    // ✅ FIXED: don't set isSignedIn = true here — wait for full load
                    Task { await getCurrentSession() }

                case HubPayload.EventName.Auth.signedOut,
                     HubPayload.EventName.Auth.sessionExpired:
                    isSignedIn = false
                    userState.userId = ""
                    userState.username = ""
                    userState.avatarState = .remote(avatarKey: "default-avatar")

                default:
                    break
                }
            }
            .store(in: &tokens)
    }
}
