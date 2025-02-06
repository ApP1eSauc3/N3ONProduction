//
//  confirmationView.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//
import Amplify
import SwiftUI

struct ConfirmSignUpView: View {
    let username: String // Username for confirmation

    @State var confirmationCode: String = "" // Confirmation code input
    @State var shouldShowLogin: Bool = false // Flag to show login view

    var body: some View {
        VStack {
            TextField("Verification Code", text: $confirmationCode) // Input for verification code
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .foregroundColor(.gray)
            
            Button("Submit") { // Button to submit verification code
                Task { await confirmSignUp() }
            }
            .padding()
            .background(.white)
            .foregroundColor(.gray)
            .cornerRadius(8)
            
        }
        .navigationDestination(isPresented: $shouldShowLogin) {
            LoginView() // Show login view if verification is successful
        }
    }

    func confirmSignUp() async {
        do {
            let result = try await Amplify.Auth.confirmSignUp(for: username, confirmationCode: confirmationCode) // Confirm sign-up
            switch result.nextStep {
            case .done:
                DispatchQueue.main.async {
                    self.shouldShowLogin = true // Navigate to login view
                }
            default:
                print(result.nextStep)
            }
        } catch {
            print(error) // Handle errors
        }
    }
}
