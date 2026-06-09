// ConfirmationSignupView.swift
// N3ON — Prompt layer
// Email verification screen shown after sign-up. Accepts the 6-digit Cognito code.
// All auth logic delegated to AuthViewModel via @EnvironmentObject.
// No Amplify import — Task layer boundary enforced.
// Design: §5.1 purple hero zone → neon dock line → black form card.

import SwiftUI

struct ConfirmationSignupView: View {
    let username: String
    @EnvironmentObject private var vm: AuthViewModel

    @State private var code: String = ""
    @State private var resendSent: Bool = false
    @FocusState private var isCodeFocused: Bool

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

                VStack {
                    Spacer()
                    Color.black
                        .frame(height: geo.size.height * 0.68)
                        .ignoresSafeArea(edges: .bottom)
                }

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
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color("neonPurpleBackground"))
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

            Text("Check your email")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)

            Text("We sent a verification code to the\nemail linked to \(username)")
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
                Text("VERIFICATION CODE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)

                codeField
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

            confirmButton
                .padding(.top, 4)

            HStack(spacing: 0) {
                Spacer()
                Button(resendSent ? "Code sent" : "Resend code") {
                    Task { await sendResend() }
                }
                .font(.subheadline)
                .foregroundStyle(resendSent
                                 ? .white.opacity(0.3)
                                 : Color("neonPurpleBackground"))
                .disabled(resendSent || vm.isLoading)

                Spacer()
            }
            .padding(.top, 4)

            HStack {
                Spacer()
                Button("Back to sign up") { vm.showSignUp() }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
            }
        }
    }

    // MARK: — Code entry field

    private var codeField: some View {
        TextField("", text: $code, prompt:
            Text("6-digit code").foregroundColor(.white.opacity(0.3))
        )
        .font(.system(.title3, design: .monospaced, weight: .semibold))
        .foregroundStyle(.white)
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)
        .focused($isCodeFocused)
        .onSubmit { submitCode() }
        .onChangeCompat(of: code) { _, new in
            // Enforce 6-character limit and digits only
            let filtered = new.filter(\.isNumber)
            if filtered != new || new.count > 6 {
                code = String(filtered.prefix(6))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(code.count == 6
                        ? Color("neonPurpleBackground").opacity(0.5)
                        : .clear,
                        lineWidth: 1)
        )
    }

    // MARK: — Confirm button

    private var confirmButton: some View {
        Button(action: submitCode) {
            if vm.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Verify")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(canSubmit ? Color("neonPurpleBackground") : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.85 : 0), radius: 5)
        .disabled(!canSubmit || vm.isLoading)
    }

    // MARK: — Helpers

    private var canSubmit: Bool { code.count == 6 }

    private func submitCode() {
        guard canSubmit else { return }
        isCodeFocused = false
        Task { await vm.confirmCode(username: username, code: code) }
    }

    private func sendResend() async {
        await vm.resendCode(for: username)
        resendSent = true
        // Reset after 30s so they can request again if needed
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        resendSent = false
    }
}
