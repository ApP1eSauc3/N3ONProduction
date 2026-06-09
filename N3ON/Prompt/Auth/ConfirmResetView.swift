// ConfirmResetView.swift
// N3ON — Prompt layer
// Step 2 of password reset: user enters the verification code + new password.
// Design follows the ConfirmationSignupView pattern.

import SwiftUI

struct ConfirmResetView: View {
    let username: String
    @EnvironmentObject private var vm: AuthViewModel

    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case code, password, confirm }

    private var passwordsMatch: Bool { newPassword == confirmPassword }
    private var canSubmit: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty &&
        newPassword.count >= 8 &&
        passwordsMatch
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
            Text("New Password")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Check your email for the code we sent to\nyour account.")
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
            fieldGroup(label: "VERIFICATION CODE") {
                TextField("", text: $code, prompt:
                    Text("6-digit code").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .code)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            fieldGroup(label: "NEW PASSWORD") {
                SecureField("", text: $newPassword, prompt:
                    Text("At least 8 characters").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .textContentType(.newPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(.next)
                .onSubmit { focusedField = .confirm }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            fieldGroup(label: "CONFIRM PASSWORD") {
                SecureField("", text: $confirmPassword, prompt:
                    Text("Re-enter new password").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .textContentType(.newPassword)
                .focused($focusedField, equals: .confirm)
                .submitLabel(.go)
                .onSubmit { submit() }
                .padding(12)
                .background(
                    confirmPassword.isEmpty ? Color.white.opacity(0.06)
                    : passwordsMatch ? Color.white.opacity(0.06)
                    : Color.white.opacity(0.06)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            !confirmPassword.isEmpty && !passwordsMatch
                                ? Color.white.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
            }

            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
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

            resetButton
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

    // MARK: — Reset button

    private var resetButton: some View {
        Button(action: submit) {
            if vm.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Reset Password")
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
        focusedField = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            await vm.confirmReset(
                username: username,
                newPassword: newPassword,
                code: code.trimmingCharacters(in: .whitespaces)
            )
        }
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
