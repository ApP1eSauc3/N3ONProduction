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
import UserNotifications

// MARK: — AppDelegate

final class N3ONAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when APNs issues a device token after `registerForRemoteNotifications`
    // (not yet called anywhere — remote push is not built; see the provider
    // decision in Task/PushNotificationService.swift). The token is a delivery
    // credential for this device: never log it.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        _ = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[N3ON] APNs registration failed: \(error.localizedDescription)")
    }

    // Foreground notification: show banner even while app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: — App

@main
struct N3ONApp: App {

    @UIApplicationDelegateAdaptor(N3ONAppDelegate.self) private var appDelegate

    init() {
        configureAmplify()
    }

    var body: some Scene {
        WindowGroup {
            // SessionView owns AuthViewModel which owns UserState.
            // UserState flows to MainView via .environmentObject(vm.userState) inside SessionView.
            SessionView()
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
