// SignupView.swift
// N3ON — Prompt layer
// Account creation screen. All auth logic delegated to AuthViewModel via @EnvironmentObject.
// No Amplify import — Task layer boundary enforced.
// Design: §5.1 purple hero zone → neon dock line → black form card.

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var vm: AuthViewModel

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case username, email, password }

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
            Text("N3ON")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

            Text("Create your account")
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
                    Text("Choose a username").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .email }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            fieldGroup(label: "EMAIL") {
                TextField("", text: $email, prompt:
                    Text("Your email address").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            fieldGroup(label: "PASSWORD") {
                SecureField("", text: $password, prompt:
                    Text("Create a password").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .textContentType(.newPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { submitSignUp() }
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

            signUpButton
                .padding(.top, 4)

            HStack {
                Spacer()
                Button("Already have an account? Sign in.") { vm.showLogin() }
                    .font(.subheadline)
                    .foregroundStyle(Color("neonPurpleBackground"))
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: — Sign up button

    private var signUpButton: some View {
        Button(action: submitSignUp) {
            if vm.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Create Account")
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

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 8
    }

    private func submitSignUp() {
        guard canSubmit else { return }
        focusedField = nil
        Task {
            await vm.signUp(
                username: username.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
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
