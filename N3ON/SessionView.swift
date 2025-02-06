//
//  SessionView.swift
//  N3ON
//
//  Created by liam howe on 16/6/2024.
//

import Amplify
import Combine
import SwiftUI

struct SessionView: View {
    
    @StateObject var userState: UserState = .init() // Observable object for user state
    @State var isSignedIn: Bool = false // User sign-in state
    @State var tokens: Set<AnyCancellable> = [] // Set of cancellables for Combine

    var body: some View {
        StartingView()
            .environmentObject(userState) // Pass userState to the view hierarchy
            .onAppear {
                Task { await getCurrentSession() } // Fetch current session on appear
                observeSession() // Observe session changes
            }
    }

    @ViewBuilder
    func StartingView() -> some View {
        if isSignedIn {
            MainView() // Show main view if signed in
        } else {
            LoginView() // Show login view if not signed in
        }
    }
    
    func getCurrentSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession() // Fetch auth session
            DispatchQueue.main.async {
                self.isSignedIn = session.isSignedIn // Update sign-in state
            }
            guard session.isSignedIn else { return }
            
            let authUser = try await Amplify.Auth.getCurrentUser() // Get current user
            DispatchQueue.main.async {
                self.userState.userId = authUser.userId
                self.userState.username = authUser.username // Update user state
            }

            let user = try await Amplify.DataStore.query(User.self, byId: authUser.userId) // Query user data

            if let existingUser = user {
                print("Existing user: \(existingUser)")
            } else {
                let newUser = User(id: authUser.userId, username: authUser.username)
                let savedUser = try await Amplify.DataStore.save(newUser) // Save new user data
                print("Created user: \(savedUser)")
            }
        } catch {
            print(error) // Handle errors
        }
    }

    func observeSession() {
        Amplify.Hub.publisher(for: .auth)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { payload in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    self.isSignedIn = true
                    Task { await getCurrentSession() }
                case HubPayload.EventName.Auth.signedOut, HubPayload.EventName.Auth.sessionExpired:
                    self.isSignedIn = false
                default:
                    break
                }
            })
            .store(in: &tokens) // Store the cancellable
    }
}
