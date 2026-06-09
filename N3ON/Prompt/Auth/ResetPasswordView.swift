// ResetPasswordView.swift
// N3ON — Prompt layer
// Step 1 of password reset: user enters their username to receive a code.
// Design follows the LoginView pattern: purple hero zone → neon dock line → black form.

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var vm: AuthViewModel

    @State private var username: String = ""
    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // DESIGN §5.1 — purple hero zone
                Color("dullPurple").ignoresSafeArea()
                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.45), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.87
                )
                .frame(height: geo.size.height * 0.35)
                .ignoresSafeArea(edges: .top)

                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        // DESIGN §3.5 — neon dock line
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.clear, Color("neonPurpleBackground"),
                                         Color("neonPurpleBackground"), .clear],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .shadow(color: Color("neonPurpleBackground"), radius: 10, y: 4)
                            .shadow(color: Color("neonPurpleBackground").opacity(0.3), radius: 4, y: 2)

                        formSection
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }

    // MARK: — Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Reset Password")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Enter your username and we'll send a code to your email.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("USERNAME")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)
                TextField("", text: $username, prompt:
                    Text("Enter your username").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .submitLabel(.go)
                .onSubmit { submit() }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            sendCodeButton
                .padding(.top, 4)

            HStack {
                Spacer()
                Button("Back to sign in") { vm.showLogin() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: — Send code button

    private var sendCodeButton: some View {
        Button(action: submit) {
            if vm.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Send Code")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(canSubmit ? Color("neonPurpleBackground") : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        // DESIGN §3.1 — two-layer neon glow on primary CTA
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.85 : 0), radius: 5)
        .disabled(!canSubmit || vm.isLoading)
    }

    // MARK: — Actions

    private func submit() {
        guard canSubmit else { return }
        isFocused = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { await vm.requestReset(username: username.trimmingCharacters(in: .whitespaces)) }
    }
}
