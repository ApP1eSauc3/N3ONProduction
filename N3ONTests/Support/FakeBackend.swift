// FakeBackend.swift
// N3ONTests
//
// In-memory stand-ins for the Backend seams (N3ON/Task/Backend.swift), so the
// real Task services and ViewModels run in unit tests without AWS.
//
// - InMemoryDataStore evaluates the app's real QueryPredicates against stored
//   models (associations compare by identifier, like DataStore's foreign key),
//   emits MutationEvents to observe() streams, and counts calls so
//   performance tests can assert query budgets.
// - FakeAuth / FakeStorage / FakeREST / FakeGraphQL / FakeHub record every
//   call so security tests can assert what was (and was not) sent.
//
// Every fake is thread-safe (NSLock): services hop executors freely.

import Foundation
import Amplify
import AWSAPIPlugin
import AWSPluginsCore
import XCTest
import UserNotifications
@testable import N3ON

struct FakeError: Error, Equatable { let tag: String }

// MARK: - Install

enum FakeBackend {
    struct Handles {
        let dataStore: InMemoryDataStore
        let auth: FakeAuth
        let storage: FakeStorage
        let rest: FakeREST
        let graphQL: FakeGraphQL
        let hub: FakeHub
        let notifications: FakeNotifications
    }

    /// Installs a fresh fake backend. Pair with `Backend.useLive()` in tearDown.
    @discardableResult
    static func install(signedInAs userID: String? = "me") -> Handles {
        let h = Handles(dataStore: InMemoryDataStore(), auth: FakeAuth(userID: userID),
                        storage: FakeStorage(), rest: FakeREST(), graphQL: FakeGraphQL(), hub: FakeHub(),
                        notifications: FakeNotifications())
        Backend.dataStore = h.dataStore
        Backend.auth = h.auth
        Backend.storage = h.storage
        Backend.rest = h.rest
        Backend.graphQL = h.graphQL
        Backend.hub = h.hub
        Backend.notifications = h.notifications
        return h
    }
}

/// Base class for tests that use the fake backend.
class BackendTestCase: XCTestCase {
    var backend: FakeBackend.Handles!
    var db: InMemoryDataStore { backend.dataStore }

    override func setUp() {
        super.setUp()
        backend = FakeBackend.install()
    }

    override func tearDown() {
        Backend.useLive()
        backend = nil
        super.tearDown()
    }

    /// Wall-clock seconds for `block`, run `iterations` times.
    func elapsed(iterations: Int = 1, _ block: () async throws -> Void) async rethrows -> Double {
        let clock = ContinuousClock()
        let start = clock.now
        for _ in 0..<iterations { try await block() }
        let d = clock.now - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }

    func elapsedSync(iterations: Int = 1, _ block: () throws -> Void) rethrows -> Double {
        let clock = ContinuousClock()
        let start = clock.now
        for _ in 0..<iterations { try block() }
        let d = clock.now - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }
}

// MARK: - DataStore

final class InMemoryDataStore: DataStoreClient {
    private let lock = NSLock()
    private var rows: [String: [String: Model]] = [:]           // modelName → id → model
    private var order: [String: [String]] = [:]                  // insertion order per model
    /// Field values per stored model, reflected once on write — predicate
    /// evaluation reads this instead of Mirror-ing the model per comparison
    /// (keeps the fake's cost out of the app's performance budgets).
    private var fields: [String: [String: [String: Any?]]] = [:]
    private var streams: [String: [AmplifyAsyncThrowingSequence<MutationEvent>]] = [:]

    private(set) var queryCount = 0
    /// Queries with no predicate — whole-table scans (by-id reads excluded).
    private(set) var unfilteredQueryCount = 0
    private(set) var saveCount = 0
    private(set) var deleteCount = 0
    private(set) var clearCount = 0
    /// Next call of any kind throws this, once.
    var failNext: Error?

    // Seeding

    func seed<M: Model>(_ models: [M]) {
        lock.lock(); defer { lock.unlock() }
        for m in models { put(m) }
    }

    func all<M: Model>(_ type: M.Type) -> [M] {
        lock.lock(); defer { lock.unlock() }
        return (order[M.modelName] ?? []).compactMap { rows[M.modelName]?[$0] as? M }
    }

    func resetCounters() {
        lock.lock(); defer { lock.unlock() }
        queryCount = 0; unfilteredQueryCount = 0; saveCount = 0; deleteCount = 0; clearCount = 0
    }

    private func put(_ m: Model) {
        let name = m.modelName
        if rows[name]?[m.identifier] == nil { order[name, default: []].append(m.identifier) }
        rows[name, default: [:]][m.identifier] = m
        var values: [String: Any?] = [:]
        for child in Mirror(reflecting: m).children {
            guard let label = child.label else { continue }
            var v: Any? = child.value
            if case Optional<Any>.none = child.value { v = nil }
            if let related = v as? Model { v = related.identifier }   // FK semantics
            values[label] = v
        }
        fields[name, default: [:]][m.identifier] = values
    }

    private func takeFailure() throws {
        if let e = failNext { failNext = nil; throw e }
    }

    // DataStoreClient

    func query<M: Model>(_ modelType: M.Type, where predicate: QueryPredicate?) async throws -> [M] {
        lock.lock(); defer { lock.unlock() }
        queryCount += 1
        if predicate == nil { unfilteredQueryCount += 1 }
        try takeFailure()
        let models = (order[M.modelName] ?? []).compactMap { rows[M.modelName]?[$0] as? M }
        guard let predicate else { return models }
        let table = fields[M.modelName] ?? [:]
        return models.filter { m in
            Self.matches(predicate, m) { field in table[m.identifier]?[field] ?? nil }
        }
    }

    func query<M: Model>(_ modelType: M.Type, byId id: String) async throws -> M? {
        lock.lock(); defer { lock.unlock() }
        queryCount += 1
        try takeFailure()
        return rows[M.modelName]?[id] as? M
    }

    @discardableResult
    func save<M: Model>(_ model: M) async throws -> M {
        let observers: [AmplifyAsyncThrowingSequence<MutationEvent>]
        let isUpdate: Bool
        do {
            lock.lock(); defer { lock.unlock() }
            saveCount += 1
            try takeFailure()
            isUpdate = rows[M.modelName]?[model.identifier] != nil
            put(model)
            observers = streams[M.modelName] ?? []
        }
        if !observers.isEmpty {
            let event = try MutationEvent(model: model, mutationType: isUpdate ? .update : .create)
            observers.forEach { $0.send(event) }
        }
        return model
    }

    func delete<M: Model>(_ model: M) async throws {
        let observers: [AmplifyAsyncThrowingSequence<MutationEvent>]
        do {
            lock.lock(); defer { lock.unlock() }
            deleteCount += 1
            try takeFailure()
            rows[M.modelName]?[model.identifier] = nil
            fields[M.modelName]?[model.identifier] = nil
            order[M.modelName]?.removeAll { $0 == model.identifier }
            observers = streams[M.modelName] ?? []
        }
        if !observers.isEmpty {
            let event = try MutationEvent(model: model, mutationType: .delete)
            observers.forEach { $0.send(event) }
        }
    }

    func observe<M: Model>(_ modelType: M.Type) -> AmplifyAsyncThrowingSequence<MutationEvent> {
        lock.lock(); defer { lock.unlock() }
        let seq = AmplifyAsyncThrowingSequence<MutationEvent>()
        streams[M.modelName, default: []].append(seq)
        return seq
    }

    func clear() async throws {
        lock.lock(); defer { lock.unlock() }
        clearCount += 1
        try takeFailure()
        rows = [:]; order = [:]; fields = [:]
    }

    /// Ends every observe() stream (lets `for try await` loops finish).
    func finishStreams() {
        lock.lock(); let all = streams.values.flatMap { $0 }; streams = [:]; lock.unlock()
        all.forEach { $0.finish() }
    }

    // Predicate evaluation — the app's real predicates, in memory.

    static func matches(_ predicate: QueryPredicate, _ model: Model,
                        value: (String) -> Any? = { _ in nil }) -> Bool {
        switch predicate {
        case let group as QueryPredicateGroup:
            switch group.type {
            case .and: return group.predicates.allSatisfy { matches($0, model, value: value) }
            case .or:  return group.predicates.contains { matches($0, model, value: value) }
            case .not: return !(group.predicates.first.map { matches($0, model, value: value) } ?? false)
            }
        case let op as QueryPredicateOperation:
            let actual = value(op.field)
            // Fast path for equality on plain values (most of the app's
            // predicates). Amplify's generic Persistable comparison is ~µs per
            // row, which would make the FAKE, not the app, dominate budgets.
            if case .equals(let expected) = op.operator {
                switch (actual, expected) {
                case let (a as String, b as String): return a == b
                case let (a as Bool, b as Bool):     return a == b
                case let (a as Int, b as Int):       return a == b
                default: break
                }
            }
            return op.operator.evaluate(target: actual)
        case is QueryPredicateConstant:
            return true
        default:
            return predicate.evaluate(target: model)
        }
    }
}

// MARK: - Auth

struct FakeAuthUser: AuthUser {
    var username: String
    var userId: String
}

struct FakeTokens: AuthCognitoTokens {
    var idToken: String
    var accessToken: String = "access"
    var refreshToken: String = "refresh"
}

struct FakeSession: AuthSession, AuthCognitoTokensProvider {
    var isSignedIn: Bool
    var idToken: String?
    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        guard let idToken else { return .failure(.signedOut("no session", "sign in", nil)) }
        return .success(FakeTokens(idToken: idToken))
    }
}

final class FakeAuth: AuthClient {
    private let lock = NSLock()
    var userID: String?
    var attributes: [AuthUserAttribute] = []
    /// Raw id token returned by fetchAuthSession (see `token(groups:)`).
    var idToken: String?
    var signInResult = AuthSignInResult(nextStep: .done)
    var signUpResult = AuthSignUpResult(.confirmUser(nil, nil, "me"), userID: "me")
    var confirmResult = AuthSignUpResult(.done, userID: "me")
    var failNext: Error?
    private(set) var calls: [String] = []
    private(set) var usernames: [String] = []
    private(set) var passwords: [String] = []
    private(set) var signUpAttributes: [AuthUserAttribute] = []

    init(userID: String?) { self.userID = userID }

    /// A JWT whose payload carries `cognito:groups` (signature not checked by the app).
    static func token(groups: [String]?, extra: [String: Any] = [:]) -> String {
        var payload = extra
        if let groups { payload["cognito:groups"] = groups }
        let json = try! JSONSerialization.data(withJSONObject: payload)
        let b64 = json.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "eyJhbGciOiJIUzI1NiJ9.\(b64).sig"
    }

    private func record(_ call: String, username: String? = nil, password: String? = nil) throws {
        lock.lock(); defer { lock.unlock() }
        calls.append(call)
        if let username { usernames.append(username) }
        if let password { passwords.append(password) }
        if let e = failNext { failNext = nil; throw e }
    }

    func getCurrentUser() async throws -> AuthUser {
        try record("getCurrentUser")
        guard let userID else { throw AuthError.signedOut("signed out", "sign in", nil) }
        return FakeAuthUser(username: userID, userId: userID)
    }
    func fetchAuthSession() async throws -> AuthSession {
        try record("fetchAuthSession")
        return FakeSession(isSignedIn: userID != nil, idToken: idToken)
    }
    func fetchUserAttributes() async throws -> [AuthUserAttribute] {
        try record("fetchUserAttributes"); return attributes
    }
    func signIn(username: String, password: String) async throws -> AuthSignInResult {
        try record("signIn", username: username, password: password); return signInResult
    }
    func signUp(username: String, password: String, options: AuthSignUpRequest.Options) async throws -> AuthSignUpResult {
        try record("signUp", username: username, password: password)
        lock.lock(); signUpAttributes = options.userAttributes ?? []; lock.unlock()
        return signUpResult
    }
    func confirmSignUp(for username: String, confirmationCode: String) async throws -> AuthSignUpResult {
        try record("confirmSignUp", username: username); return confirmResult
    }
    func resendSignUpCode(for username: String) async throws -> AuthCodeDeliveryDetails {
        try record("resendSignUpCode", username: username)
        return AuthCodeDeliveryDetails(destination: .email(username))
    }
    func resetPassword(for username: String) async throws -> AuthResetPasswordResult {
        try record("resetPassword", username: username)
        return AuthResetPasswordResult(isPasswordReset: false, nextStep: .done)
    }
    func confirmResetPassword(for username: String, with newPassword: String, confirmationCode: String) async throws {
        try record("confirmResetPassword", username: username, password: newPassword)
    }
    func signOut() async -> AuthSignOutResult {
        try? record("signOut"); userID = nil
        return FakeSignOutResult()
    }
    func deleteUser() async throws { try record("deleteUser"); userID = nil }
}

struct FakeSignOutResult: AuthSignOutResult {}

// MARK: - Storage

final class FakeStorage: StorageClient {
    struct Upload: Equatable { let key: String; let bytes: Int; let access: String; let contentType: String }
    private let lock = NSLock()
    private(set) var uploads: [Upload] = []
    private(set) var downloads: [String] = []
    private(set) var urlRequests: [String] = []
    var objects: [String: Data] = [:]
    var failNext: Error?

    private func take() throws { if let e = failNext { failNext = nil; throw e } }

    func uploadData(key: String, data: Data, accessLevel: StorageAccessLevel, contentType: String) async throws -> String {
        lock.lock(); defer { lock.unlock() }
        try take()
        uploads.append(Upload(key: key, bytes: data.count, access: accessLevel.rawValue, contentType: contentType))
        objects[key] = data
        return key
    }
    func uploadFile(key: String, local: URL, accessLevel: StorageAccessLevel, contentType: String) async throws -> String {
        let data = (try? Data(contentsOf: local)) ?? Data()
        lock.lock(); defer { lock.unlock() }
        try take()
        uploads.append(Upload(key: key, bytes: data.count, access: accessLevel.rawValue, contentType: contentType))
        objects[key] = data
        return key
    }
    func getURL(key: String, accessLevel: StorageAccessLevel) async throws -> URL {
        lock.lock(); defer { lock.unlock() }
        try take()
        urlRequests.append(key)
        return URL(string: "https://fake-bucket.s3.amazonaws.com/\(accessLevel.rawValue)/\(key)?X-Amz-Signature=fake")!
    }
    func downloadData(key: String, accessLevel: StorageAccessLevel) async throws -> Data {
        lock.lock(); defer { lock.unlock() }
        try take()
        downloads.append(key)
        guard let data = objects[key] else { throw StorageError.keyNotFound(key, "missing", "", nil) }
        return data
    }
}

// MARK: - REST / GraphQL / Hub

final class FakeREST: RESTTransport {
    private let lock = NSLock()
    private(set) var requests: [(path: String?, body: [String: Any])] = []
    /// Body returned for a path (default: `{"success":true}`).
    var responses: [String: Data] = [:]
    var failNext: Error?

    func post(_ request: RESTRequest) async throws -> Data {
        lock.lock(); defer { lock.unlock() }
        let body = request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        requests.append((request.path, body))
        if let e = failNext { failNext = nil; throw e }
        return responses[request.path ?? ""] ?? Data(#"{"success":true}"#.utf8)
    }
}

final class FakeGraphQL: GraphQLClient {
    var users: [String: User] = [:]
    private(set) var reads: [String] = []
    func getUser(byId id: String) async throws -> User? { reads.append(id); return users[id] }
}

final class FakeHub: HubClient {
    private let lock = NSLock()
    private var continuations: [String: [AsyncStream<HubPayload>.Continuation]] = [:]

    func events(on channel: HubChannel) -> AsyncStream<HubPayload> {
        AsyncStream { c in
            lock.lock(); continuations[String(describing: channel), default: []].append(c); lock.unlock()
        }
    }

    func send(_ payload: HubPayload, on channel: HubChannel) {
        lock.lock(); let cs = continuations[String(describing: channel)] ?? []; lock.unlock()
        cs.forEach { $0.yield(payload) }
    }

    var listenerCount: Int {
        lock.lock(); defer { lock.unlock() }
        return continuations.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Async helpers

/// Polls `condition` (main actor) until true or `timeout` passes.
@MainActor
func eventually(timeout: Double = 2, _ condition: @MainActor () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return condition()
}

final class FakeNotifications: NotificationClient {
    private let lock = NSLock()
    var granted = true
    private(set) var authorizationRequests = 0
    private(set) var added: [UNNotificationRequest] = []
    private(set) var removed: [String] = []
    private(set) var badge: Int?

    func requestAuthorization() async -> Bool {
        lock.lock(); defer { lock.unlock() }
        authorizationRequests += 1; return granted
    }
    func add(_ request: UNNotificationRequest) async throws {
        lock.lock(); defer { lock.unlock() }
        added.append(request)
    }
    func removePending(withIdentifiers ids: [String]) {
        lock.lock(); defer { lock.unlock() }
        removed += ids
    }
    func setBadgeCount(_ count: Int) {
        lock.lock(); defer { lock.unlock() }
        badge = count
    }
}
