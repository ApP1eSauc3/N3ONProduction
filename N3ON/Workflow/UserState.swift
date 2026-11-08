//
//  UserState.swift
//  N3ON
//
//  Created by liam howe on 16/6/2024.

import Foundation

@MainActor
class UserState: ObservableObject {
    @Published var userId: String = ""
    @Published var username: String = ""
    @Published var avatarState: AvatarState = .remote(avatarKey: "default-avatar")
    
    func updateAvatarState(_ newState: AvatarState) {
        avatarState = newState
    }

    func reset() {
        userId = ""
        username = ""
        avatarState = .remote(avatarKey: "default-avatar")
    }
    func updateFromUser(_ user: User) {
            userId = user.id
            username = user.username
            // Same rule as everywhere else: a stored signed URL is not a key.
            if user.avatarKey != nil {
                avatarState = AvatarState.fromUser(user)
            }
        }
}
