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
    
    // 1
    @StateObject var userState: UserState = .init()
    @State var isSignedIn: Bool = false
    @State var tokens: Set<AnyCancellable> = []
    
    var body: some View {
        StartingView()
            .environmentObject(userState)
            .onAppear {
                Task { await getCurrentSession() }
                observeSession()
            }
    }
        
        
        @ViewBuilder
        func StartingView() -> some View {
            // 3
            if isSignedIn {
                Text("Signed in")
            } else {
                LoginView()
            }
        }
        
        func getCurrentSession() async {
            do {
                // 1
                let session = try await Amplify.Auth.fetchAuthSession()
                DispatchQueue.main.async {
                    self.isSignedIn = session.isSignedIn
                }
                guard session.isSignedIn else { return }
                
                // 2
                let authUser = try await Amplify.Auth.getCurrentUser()
                self.userState.userId = authUser.userId
                self.userState.username = authUser.username
                
                // 3
                let user = try await Amplify.DataStore.query(
                    User.self,
                    byId: authUser.userId
                )
                
                // 4
                if let existingUser = user {
                    print("Existing user: \(existingUser)")
                } else {
                    let newUser = User(
                        id: authUser.userId,
                        username: authUser.username
                    )
                    let savedUser = try await Amplify.DataStore.save(newUser)
                    print("Created user: \(savedUser)")
                }
            } catch {
                print(error)
            }
        }
        func observeSession() {
            // 1
            Amplify.Hub.publisher(for: .auth)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveValue: { payload in
                        
                        switch payload.eventName {
                        case HubPayload.EventName.Auth.signedIn:
                            self.isSignedIn = true
                            Task { await getCurrentSession() }
                        case HubPayload.EventName.Auth.signedOut, HubPayload.EventName.Auth.sessionExpired:
                            self.isSignedIn = false
                        default:
                            break
                        }
                    }
                )
                .store(in: &tokens)
        }
    }

