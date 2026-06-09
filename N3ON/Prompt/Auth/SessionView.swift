// SessionView.swift
// N3ON — Prompt layer
// Root auth gate — owns AuthViewModel (single source of truth for all auth state).
// Switches on vm.flowState to render the correct screen with a cross-fade transition.
// UserState flows downward to MainView via @EnvironmentObject.
//
// Architecture derived from Kilo-Loco's SessionView pattern, rewritten to:
//   — own AuthViewModel (not SessionManager) to comply with N3ON's Workflow layer rules
//   — use .task instead of .onAppear + Combine for Hub observation
//   — remove @MainActor from struct (redundant — View body always runs on main actor)
//   — use ZStack + @ViewBuilder rather than Group (Group is ambiguous in Swift 6)

import SwiftUI

struct SessionView: View {
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            currentScreen
        }
        .animation(.easeInOut(duration: 0.25), value: vm.flowState)
        .task { await vm.load() }
    }

    // MARK: — Screen routing

    @ViewBuilder
    private var currentScreen: some View {
        switch vm.flowState {
        case .loading:
            loadingView
        case .login:
            LoginView()
                .environmentObject(vm)
        case .signUp:
            SignUpView()
                .environmentObject(vm)
        case .confirmCode(let username):
            ConfirmationSignupView(username: username)
                .environmentObject(vm)
        case .resetPassword:
            ResetPasswordView()
                .environmentObject(vm)
        case .confirmReset(let username):
            ConfirmResetView(username: username)
                .environmentObject(vm)
        case .roleSelection(let username):
            RoleSelectionView(username: username)
                .environmentObject(vm)
        case .authenticated:
            MainView()
                .environmentObject(vm.userState)
                .environmentObject(vm)
        }
    }

    // MARK: — Loading state (cold launch session check)

    private var loadingView: some View {
        VStack(spacing: 16) {
            // N3ON wordmark with neon glow — §3.1 two-layer shadow
            Text("N3ON")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

            ProgressView()
                .tint(Color("neonPurpleBackground"))
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
