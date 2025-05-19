//
//  N3ONError.swift
//  N3ON
//
//  Created by liam howe on 22/5/2024.
//

import Amplify
import Foundation

enum N3ONError: Error {
    case amplify(AmplifyError) // Custom error type for Amplify errors
}
