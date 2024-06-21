//
//  N3ONApp.swift
//  N3ON
//
//  Created by liam howe on 21/5/2024.
//
import SwiftUI
import AWSDataStorePlugin
import AWSCognitoAuthPlugin
import Amplify

@main
struct NNApp: App {
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            SessionView()
                
        }
    }
   
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let models = AmplifyModels()
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.configure()
            
            
           print("Successfully configured Amplify")
    
        } catch {
            print("Failed to initialize Amplify", error)
        }
    }
}
