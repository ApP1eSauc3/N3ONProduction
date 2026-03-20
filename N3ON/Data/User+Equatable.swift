//
//  User+Equatable.swift
//  N3ON
//
//  Created by liam howe on 4/5/2025.
//

// User is an Amplify-generated model in the same module — no import needed.
extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
