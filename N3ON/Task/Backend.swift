// Backend.swift
// N3ON — Task layer
//
// The one place the app touches the Amplify categories. Every Task service
// and the two Hub-observing ViewModels call `Backend.dataStore`, `.auth`,
// `.storage`, `.rest`, `.graphQL` or `.hub` instead of `Amplify.*`, so unit
// tests can swap in an in-memory backend (N3ONTests/Support/FakeBackend.swift)
// and exercise the real service logic without AWS.
//
// Pattern: protocol-based dependency injection with a production default —
// the "live / test" split used by pointfree's swift-dependencies and by
// Apple's own sample code. The protocols mirror Amplify's method names and
// labels, so a call site only changes its prefix (`Amplify.DataStore.` →
// `Backend.dataStore.`). The `Amplify…` conformances below forward 1:1 and
// add no behaviour, except where noted.
//
// Never set these outside tests. Production code reads them only.

import Foundation
import Combine
import Amplify
import AWSAPIPlugin
import AWSPluginsCore
import UserNotifications

// MARK: - Registry

enum Backend {
    nonisolated(unsafe) static var dataStore: DataStoreClient = AmplifyDataStoreClient()
    nonisolated(unsafe) static var auth: AuthClient = AmplifyAuthClient()
    nonisolated(unsafe) static var storage: StorageClient = AmplifyStorageClient()
    nonisolated(unsafe) static var rest: RESTTransport = AmplifyRESTTransport()
    nonisolated(unsafe) static var graphQL: GraphQLClient = AmplifyGraphQLClient()
    nonisolated(unsafe) static var hub: HubClient = AmplifyHubClient()
    nonisolated(unsafe) static var notifications: NotificationClient = SystemNotificationClient()

    /// Restores every live client — tests call this in tearDown.
    static func useLive() {
        dataStore = AmplifyDataStoreClient()
        auth = AmplifyAuthClient()
        storage = AmplifyStorageClient()
        rest = AmplifyRESTTransport()
        graphQL = AmplifyGraphQLClient()
        hub = AmplifyHubClient()
        notifications = SystemNotificationClient()
    }
}

// MARK: - DataStore

protocol DataStoreClient {
    func query<M: Model>(_ modelType: M.Type, where predicate: QueryPredicate?) async throws -> [M]
    func query<M: Model>(_ modelType: M.Type, byId id: String) async throws -> M?
    @discardableResult func save<M: Model>(_ model: M) async throws -> M
    func delete<M: Model>(_ model: M) async throws
    func observe<M: Model>(_ modelType: M.Type) -> AmplifyAsyncThrowingSequence<MutationEvent>
    func clear() async throws
}

extension DataStoreClient {
    /// `query(T.self)` — every row, like `Amplify.DataStore.query(T.self)`.
    func query<M: Model>(_ modelType: M.Type) async throws -> [M] {
        try await query(modelType, where: nil)
    }
}

struct AmplifyDataStoreClient: DataStoreClient {
    func query<M: Model>(_ modelType: M.Type, where predicate: QueryPredicate?) async throws -> [M] {
        try await Amplify.DataStore.query(modelType, where: predicate)
    }
    func query<M: Model>(_ modelType: M.Type, byId id: String) async throws -> M? {
        try await Amplify.DataStore.query(modelType, byId: id)
    }
    @discardableResult func save<M: Model>(_ model: M) async throws -> M {
        try await Amplify.DataStore.save(model)
    }
    func delete<M: Model>(_ model: M) async throws {
        try await Amplify.DataStore.delete(model)
    }
    func observe<M: Model>(_ modelType: M.Type) -> AmplifyAsyncThrowingSequence<MutationEvent> {
        Amplify.DataStore.observe(modelType)
    }
    func clear() async throws {
        try await Amplify.DataStore.clear()
    }
}

// MARK: - Auth

protocol AuthClient {
    func getCurrentUser() async throws -> AuthUser
    func fetchAuthSession() async throws -> AuthSession
    func fetchUserAttributes() async throws -> [AuthUserAttribute]
    func signIn(username: String, password: String) async throws -> AuthSignInResult
    func signUp(username: String, password: String, options: AuthSignUpRequest.Options) async throws -> AuthSignUpResult
    func confirmSignUp(for username: String, confirmationCode: String) async throws -> AuthSignUpResult
    func resendSignUpCode(for username: String) async throws -> AuthCodeDeliveryDetails
    func resetPassword(for username: String) async throws -> AuthResetPasswordResult
    func confirmResetPassword(for username: String, with newPassword: String, confirmationCode: String) async throws
    func signOut() async -> AuthSignOutResult
    func deleteUser() async throws
}

struct AmplifyAuthClient: AuthClient {
    func getCurrentUser() async throws -> AuthUser { try await Amplify.Auth.getCurrentUser() }
    func fetchAuthSession() async throws -> AuthSession { try await Amplify.Auth.fetchAuthSession() }
    func fetchUserAttributes() async throws -> [AuthUserAttribute] { try await Amplify.Auth.fetchUserAttributes() }
    func signIn(username: String, password: String) async throws -> AuthSignInResult {
        try await Amplify.Auth.signIn(username: username, password: password)
    }
    func signUp(username: String, password: String, options: AuthSignUpRequest.Options) async throws -> AuthSignUpResult {
        try await Amplify.Auth.signUp(username: username, password: password, options: options)
    }
    func confirmSignUp(for username: String, confirmationCode: String) async throws -> AuthSignUpResult {
        try await Amplify.Auth.confirmSignUp(for: username, confirmationCode: confirmationCode)
    }
    func resendSignUpCode(for username: String) async throws -> AuthCodeDeliveryDetails {
        try await Amplify.Auth.resendSignUpCode(for: username)
    }
    func resetPassword(for username: String) async throws -> AuthResetPasswordResult {
        try await Amplify.Auth.resetPassword(for: username)
    }
    func confirmResetPassword(for username: String, with newPassword: String, confirmationCode: String) async throws {
        try await Amplify.Auth.confirmResetPassword(for: username, with: newPassword, confirmationCode: confirmationCode)
    }
    func signOut() async -> AuthSignOutResult { await Amplify.Auth.signOut() }
    func deleteUser() async throws { try await Amplify.Auth.deleteUser() }
}

// MARK: - Storage

protocol StorageClient {
    /// Uploads bytes; returns the stored key.
    func uploadData(key: String, data: Data, accessLevel: StorageAccessLevel, contentType: String) async throws -> String
    /// Uploads a local file; returns the stored key.
    func uploadFile(key: String, local: URL, accessLevel: StorageAccessLevel, contentType: String) async throws -> String
    func getURL(key: String, accessLevel: StorageAccessLevel) async throws -> URL
    func downloadData(key: String, accessLevel: StorageAccessLevel) async throws -> Data
}

struct AmplifyStorageClient: StorageClient {
    func uploadData(key: String, data: Data, accessLevel: StorageAccessLevel, contentType: String) async throws -> String {
        try await Amplify.Storage
            .uploadData(key: key, data: data, options: .init(accessLevel: accessLevel, contentType: contentType))
            .value
    }
    func uploadFile(key: String, local: URL, accessLevel: StorageAccessLevel, contentType: String) async throws -> String {
        try await Amplify.Storage
            .uploadFile(key: key, local: local, options: .init(accessLevel: accessLevel, contentType: contentType))
            .value
    }
    func getURL(key: String, accessLevel: StorageAccessLevel) async throws -> URL {
        try await Amplify.Storage.getURL(key: key, options: .init(accessLevel: accessLevel))
    }
    func downloadData(key: String, accessLevel: StorageAccessLevel) async throws -> Data {
        try await Amplify.Storage.downloadData(key: key, options: .init(accessLevel: accessLevel)).value
    }
}

// MARK: - REST (n3onAPI Lambdas)

protocol RESTTransport {
    /// Returns the response body for ANY HTTP response — the Lambdas put a
    /// JSON `errorCode` in their 4xx/5xx bodies, which callers decode. Throws
    /// only when there is no response (network, signing, configuration).
    func post(_ request: RESTRequest) async throws -> Data
}

struct AmplifyRESTTransport: RESTTransport {
    func post(_ request: RESTRequest) async throws -> Data {
        do {
            return try await Amplify.API.post(request: request)
        } catch {
            if let data = Self.lambdaBody(from: error) { return data }
            throw error
        }
    }

    /// The Lambdas' JSON reply is ~100 bytes; anything this large is not one.
    static let maxErrorBodyBytes = 64 * 1024

    /// Amplify throws on non-2xx, but the body is still the Lambda's answer
    /// (its `errorCode`). Only an HTTP status error with a body of plausible
    /// size counts; network, signing and other errors stay errors.
    static func lambdaBody(from error: Error) -> Data? {
        guard let apiError = error as? APIError,
              case let .httpStatusError(_, response) = apiError,
              let data = (response as? AWSHTTPURLResponse)?.body,
              !data.isEmpty, data.count <= maxErrorBodyBytes
        else { return nil }
        return data
    }
}

// MARK: - GraphQL (reads DataStore has not synced yet)

protocol GraphQLClient {
    func getUser(byId id: String) async throws -> User?
}

struct AmplifyGraphQLClient: GraphQLClient {
    func getUser(byId id: String) async throws -> User? {
        let response = try await Amplify.API.query(request: .get(User.self, byId: id))
        guard case .success(let user) = response else { return nil }
        return user
    }
}

// MARK: - Hub

protocol HubClient {
    func events(on channel: HubChannel) -> AsyncStream<HubPayload>
}

struct AmplifyHubClient: HubClient {
    /// Same mechanism the ViewModels used directly: the Hub publisher's
    /// AsyncPublisher, relayed. Cancelling the consumer cancels the relay.
    func events(on channel: HubChannel) -> AsyncStream<HubPayload> {
        AsyncStream { continuation in
            let relay = Task {
                for await payload in Amplify.Hub.publisher(for: channel).values {
                    continuation.yield(payload)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in relay.cancel() }
        }
    }
}

// MARK: - Local notifications (not Amplify, same seam pattern)

protocol NotificationClient {
    func requestAuthorization() async -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePending(withIdentifiers ids: [String])
    func setBadgeCount(_ count: Int)
}

struct SystemNotificationClient: NotificationClient {
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
    func removePending(withIdentifiers ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    func setBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
    }
}
