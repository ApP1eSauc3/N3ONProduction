//
//  User+Equatable.swift
//  N3ON
//
//  Created by liam howe on 4/5/2025.
//

import Amplify

extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
