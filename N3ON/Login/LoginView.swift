import Amplify
import SwiftUI
struct LoginView: View {
    // 1
    @State var username: String = ""
    @State var password: String = ""
    // 2
    @State var shouldShowSignUp: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                // 3
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
                
                Button("Log In") {
                    Task { await login() }
                }
                Spacer()
                Button("Don't have an account? Sign up.", action: { shouldShowSignUp = true })
            }
            // 4
            .navigationDestination(isPresented: $shouldShowSignUp) {
                SignUpView(showLogin: { shouldShowSignUp = false })
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
        func login() async {
            do {
                // 1
                let result = try await Amplify.Auth.signIn(
                    username: username,
                    password: password
                )
                switch result.nextStep {
                    // 2
                case .done:
                    print("login is done")
                default:
                    print(result.nextStep)
                }
            } catch {
                print(error)
            
        }
        

    }
}
