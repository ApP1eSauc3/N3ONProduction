//
//  SignupView.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//

import Amplify
import SwiftUI

struct SignUpView: View {
    let showLogin: () -> Void // Callback to show login view

    @State var username: String = "" // Username input
    @State var email: String = "" // Email input
    @State var password: String = "" // Password input
    @State var shouldShowConfirmSignUp: Bool = false // Flag to show confirmation view

    
    var body: some View {
        VStack {
            Spacer()
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .foregroundColor(.gray)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .foregroundColor(.gray)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .foregroundColor(.gray)

            Button("Sign Up") {
                Task { await signUp() }
            }
            .padding()
            .background(.white)
            .foregroundColor(.gray)
            .cornerRadius(8)
            
            Spacer()
            Button("Already have an account? Login.", action: showLogin)
                .foregroundColor(.white)
        }
        // 3
        .navigationDestination(isPresented: $shouldShowConfirmSignUp) {
            ConfirmSignUpView(username: username)
        }
        .padding()
        .background(Color("neonPurpleBackground"))
    }

    func signUp() async {
        // 1
        let options = AuthSignUpRequest.Options(
            userAttributes: [.init(.email, value: email)]
        )
        do {
            // 2
            let result = try await Amplify.Auth.signUp(
                username: username,
                password: password,
                options: options
            )
            
            switch result.nextStep {
            // 3
            case .confirmUser:
                DispatchQueue.main.async {
                    self.shouldShowConfirmSignUp = true
                }
            default:
                print(result)
            }
        } catch {
            print(error)
        }
    }
}
