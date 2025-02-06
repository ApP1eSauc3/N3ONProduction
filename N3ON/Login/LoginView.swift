

import Amplify
import SwiftUI

struct LoginView: View {
    
    @State var username: String = ""
    @State var password: String = ""
    @State var shouldShowSignUp: Bool = false
    @State var showAlert = false
    @State var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .foregroundColor(.gray)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .foregroundColor(.gray)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
   
                Button("Log In") {
                    Task { await login() }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()

                Button("Don't have an account? Sign up.", action: { shouldShowSignUp = true })
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color("neonPurpleBackground"))
            .navigationTitle("Log in")
            .foregroundColor(.white)
            
            // Attach .alert to the VStack or any other direct parent view
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Login Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(isPresented: $shouldShowSignUp) {
                SignUpView(showLogin: { shouldShowSignUp = false })
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    func login() async {
        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password
            )
            if result.isSignedIn {
                print("Sign in successful")
                // Perform navigation or state update after successful sign-in
            } else {
                errorMessage = "Sign in unsuccessful. Please try again."
                showAlert = true
            }
        } catch let error as AuthError {
            switch error {
            case .notAuthorized(let message, _, _):
                errorMessage = "Sign in failed: \(message)"
            case .service(let serviceError, _, _):
                errorMessage = "Service error: \(serviceError)"
            default:
                errorMessage = "Sign in failed: \(error)"
            }
            showAlert = true
        } catch {
            errorMessage = "Unexpected error: \(error)"
            showAlert = true
        }
    }
}
