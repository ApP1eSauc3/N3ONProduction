//
//  SessionView.swift
//  N3ON
//
//  Created by liam howe on 16/6/2024.
//

import Amplify
import Combine
import SwiftUI

@MainActor
struct SessionView: View {
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
        if isSignedIn {
            MainView()
        } else {
            LoginView()
        }
    }
    
    func getCurrentSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            await MainActor.run {
                self.isSignedIn = session.isSignedIn
            }
            
            if session.isSignedIn {
                let authUser = try await Amplify.Auth.getCurrentUser()
                await MainActor.run {
                    self.userState.userId = authUser.userId
                    self.userState.username = authUser.username
                }
                
                let user = try await Amplify.DataStore.query(User.self, byId: authUser.userId)
                if let existingUser = user {
                    await MainActor.run {
                        self.userState.avatarState = .remote(avatarKey: existingUser.avatarKey ?? "defaultAvatarKey")
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func observeSession() {
        Amplify.Hub.publisher(for: .auth)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { payload in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    self.isSignedIn = true
                    Task {
                        await getCurrentSession() // Move async call here
                    }
                case HubPayload.EventName.Auth.signedOut, HubPayload.EventName.Auth.sessionExpired:
                    self.isSignedIn = false
                default:
                    break
                }
            })
            .store(in: &tokens)

    }
}
