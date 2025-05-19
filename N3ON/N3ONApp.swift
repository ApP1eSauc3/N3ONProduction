//
//  N3ONApp.swift
//  N3ON
//
//  Created by liam howe on 21/5/2024.

import SwiftUI
import Amplify
import AWSAPIPlugin
import AWSCognitoAuthPlugin
import AWSDataStorePlugin
import AWSS3StoragePlugin

@main
struct N3ONApp: App {
    @StateObject private var userState = UserState()
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            SessionView() // The main view of the app
                .environmentObject(userState)
        }
    }
   
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin()) // Add Cognito Auth plugin
            let models = AmplifyModels()
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models)) // Add DataStore plugin with models
            try Amplify.add(plugin: AWSS3StoragePlugin())// Add S3 Storage plugin
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure() // Configure Amplify
            
            print("Successfully configured Amplify")
        } catch {
            print("Failed to initialize Amplify", error) // Handle configuration errors
        }
    }
}
