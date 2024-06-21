//
//  SignupView.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//

import Amplify
import SwiftUI

struct SignUpView: View {
    // 1
    let showLogin: () -> Void
    
    @State var username: String = ""
    // 2
    @State var email: String = ""
    @State var password: String = ""
    @State var shouldShowConfirmSignUp: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            TextField("Username", text: $username)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            Button("Sign Up") {
                Task { await signUp() }
            }
            
            Spacer()
            Button("Already have an account? Login.", action: showLogin)
        }
        // 3
        .navigationDestination(isPresented: .constant(shouldShowConfirmSignUp)) {
            ConfirmSignUpView(username: username)
        }
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
