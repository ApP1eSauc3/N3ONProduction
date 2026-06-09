// LoginView.swift
// N3ON — Prompt layer
// Sign-in screen. All auth logic delegated to AuthViewModel via @EnvironmentObject.
// No Amplify import — Task layer boundary enforced.
// Design: §5.1 purple hero zone → neon dock line → black form card.

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var vm: AuthViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case username, password }

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
            Text("N3ON")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                // DESIGN §3.1 — two-layer neon glow on wordmark only
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            fieldGroup(label: "USERNAME") {
                TextField("", text: $username, prompt:
                    Text("Enter your username").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            fieldGroup(label: "PASSWORD") {
                SecureField("", text: $password, prompt:
                    Text("Enter your password").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { submitLogin() }
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

            signInButton
                .padding(.top, 4)

            HStack {
                Spacer()
                Button("Forgot password?") { vm.showResetPassword() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.top, 4)

            HStack {
                Spacer()
                Button("Create an account") { vm.showSignUp() }
                    .font(.subheadline)
                    .foregroundStyle(Color("neonPurpleBackground"))
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: — Sign in button

    private var signInButton: some View {
        Button(action: submitLogin) {
            if vm.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Sign In")
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

    // MARK: — Helpers

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    private func submitLogin() {
        guard canSubmit else { return }
        focusedField = nil
        Task { await vm.signIn(username: username.trimmingCharacters(in: .whitespaces),
                               password: password) }
    }

    private func fieldGroup<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)
            content()
        }
    }
}
