//
//  confirmationView.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//

import Amplify
import SwiftUI

struct ConfirmSignUpView: View {
    // 1
    let username: String
    
    @State var confirmationCode: String = ""
    @State var shouldShowLogin: Bool = false
    
    var body: some View {
        VStack {
            TextField("Verification Code", text: $confirmationCode)
            
            Button("Submit") {
                Task { await confirmSignUp() }
            }
            
        }
        // 2
        .navigationDestination(isPresented: .constant(shouldShowLogin)) {
            LoginView()
        }
    }
        func confirmSignUp() async {
            do {
                // 1
                let result = try await Amplify.Auth.confirmSignUp(
                    for: username,
                    confirmationCode: confirmationCode
                )
                switch result.nextStep {
                // 2
                case .done:
                    DispatchQueue.main.async {
                        self.shouldShowLogin = true
                    }
                default:
                    print(result.nextStep)
                }
            } catch {
                print(error)
            }
        }
    }

