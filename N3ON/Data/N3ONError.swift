//
//  N3ONError.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//

import Foundation

enum N3ONError: Error {
    case amplify(Error) // Wraps any Amplify error without importing Amplify in Data
}
