// WorkflowASecPerfTests.swift
// N3ONTests
//
// Security + performance tests for the auth, admin, profile, search, invite,
// endorsement, event, DJ and unread-badge ViewModels. They run the real
// ViewModels on the main actor against FakeBackend.

import XCTest
import Amplify
import AWSCognitoAuthPlugin
@testable import N3ON

@MainActor
final class WorkflowASecPerfTests: BackendTestCase {

    private let pendingKeys = ["pendingUsername", "pendingIsDJ", AuthViewModel.pendingEmailKey]

    override func setUp() {
        super.setUp()
        pendingKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        pendingKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    private var userNotFound: AuthError {
        .service("User does not exist.", "", AWSCognitoAuthError.userNotFound)
    }

    // MARK: - AuthViewModel

    func test_AuthViewModel_load_security() async {
        backend.auth.userID = nil
        let vm = AuthViewModel()
        await vm.load()
        XCTAssertEqual(vm.flowState, .login, "no session → login, never authenticated")
    }

    func test_AuthViewModel_load_performance() async {
        db.seed([Make.user("me")])
        let t = await elapsed(iterations: 200) { let vm = AuthViewModel(); await vm.load() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_AuthViewModel_loadSession_security() async {
        // A pending role choice saved by ANOTHER account on this device is not
        // applied to whoever signs in next.
        UserDefaults.standard.set("victimHandle", forKey: "pendingUsername")
        UserDefaults.standard.set(true, forKey: "pendingIsDJ")
        UserDefaults.standard.set("victim@x.co", forKey: AuthViewModel.pendingEmailKey)
        backend.auth.attributes = [AuthUserAttribute(.email, value: "Attacker@x.co")]
        let vm = AuthViewModel()
        await vm.loadSession()
        XCTAssertTrue(db.all(User.self).isEmpty, "no profile created from someone else's choice")
        XCTAssertNil(UserDefaults.standard.string(forKey: "pendingUsername"), "the foreign choice is discarded")
        // The right account does get its own choice.
        UserDefaults.standard.set("luna", forKey: "pendingUsername")
        UserDefaults.standard.set("me@x.co", forKey: AuthViewModel.pendingEmailKey)
        backend.auth.attributes = [AuthUserAttribute(.email, value: "ME@x.co")]
        await vm.loadSession()
        XCTAssertEqual(db.all(User.self).first?.username, "luna")
        XCTAssertEqual(vm.flowState, .authenticated)
    }

    func test_AuthViewModel_loadSession_performance() async {
        db.seed(Make.many(5_000) { Make.user("u\($0)") } + [Make.user("me")])
        let vm = AuthViewModel()
        db.resetCounters()
        let t = await elapsed(iterations: 200) { await vm.loadSession() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_AuthViewModel_startHubObservation_security() async {
        db.seed([Make.user("me")])
        let vm = AuthViewModel()
        await vm.load()
        XCTAssertEqual(vm.flowState, .authenticated)
        vm.userState.username = "me"
        // The ViewModel subscribes inside a Task, so its listener can attach a
        // moment later; re-send the (idempotent) event until it's handled.
        let loggedOut = await eventually {
            self.backend.hub.send(HubPayload(eventName: HubPayload.EventName.Auth.sessionExpired), on: .auth)
            return vm.flowState == .login && vm.userState.username.isEmpty
        }
        XCTAssertTrue(loggedOut, "an expired session drops to login and clears user state")
    }

    func test_AuthViewModel_startHubObservation_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed { for _ in 0..<500 { vm.startHubObservation() } }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertLessThanOrEqual(backend.hub.listenerCount, 500)
    }

    func test_AuthViewModel_showSignUp_security() {
        let vm = AuthViewModel(); vm.errorMessage = "Incorrect email or password."
        vm.showSignUp()
        XCTAssertNil(vm.errorMessage, "no error leaks onto the next screen")
        XCTAssertEqual(vm.flowState, .signUp)
    }

    func test_AuthViewModel_showSignUp_performance() {
        let vm = AuthViewModel()
        let t = elapsedSync(iterations: 50_000) { vm.showSignUp() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_showLogin_security() {
        let vm = AuthViewModel(); vm.errorMessage = "x"
        vm.showLogin()
        XCTAssertNil(vm.errorMessage); XCTAssertEqual(vm.flowState, .login)
    }

    func test_AuthViewModel_showLogin_performance() {
        let vm = AuthViewModel()
        let t = elapsedSync(iterations: 50_000) { vm.showLogin() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_showResetPassword_security() {
        let vm = AuthViewModel(); vm.errorMessage = "x"
        vm.showResetPassword()
        XCTAssertNil(vm.errorMessage); XCTAssertEqual(vm.flowState, .resetPassword)
    }

    func test_AuthViewModel_showResetPassword_performance() {
        let vm = AuthViewModel()
        let t = elapsedSync(iterations: 50_000) { vm.showResetPassword() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_signIn_security() async {
        // Unknown account and wrong password are indistinguishable (no
        // account enumeration through the login form).
        let vm = AuthViewModel()
        backend.auth.failNext = userNotFound
        await vm.signIn(email: "nobody@x.co", password: "password1")
        let unknown = vm.errorMessage
        backend.auth.failNext = AuthError.notAuthorized("Incorrect username or password.", "", nil)
        await vm.signIn(email: "real@x.co", password: "wrongpass")
        XCTAssertEqual(unknown, vm.errorMessage)
        XCTAssertEqual(vm.errorMessage, "Incorrect email or password.")
    }

    func test_AuthViewModel_signIn_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.signIn(email: "a@b.co", password: "password1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_signUp_security() async {
        let vm = AuthViewModel()
        await vm.signUp(handle: "luna", email: "a@b.co", password: "short")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(backend.auth.calls.contains("signUp"), "a weak password never leaves the device")
        await vm.signUp(handle: "luna", email: " A@B.CO ", password: "password1")
        XCTAssertEqual(vm.flowState, .confirmCode(email: "a@b.co", handle: "luna"))
    }

    func test_AuthViewModel_signUp_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.signUp(handle: "h", email: "a@b.co", password: "password1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_confirmCode_security() async {
        let vm = AuthViewModel()
        await vm.confirmCode(email: " Me@X.co ", handle: "luna", code: "123456")
        XCTAssertEqual(UserDefaults.standard.string(forKey: AuthViewModel.pendingEmailKey), "me@x.co",
                       "the next role choice is bound to this account")
        XCTAssertEqual(vm.flowState, .roleSelection(username: "luna"))
    }

    func test_AuthViewModel_confirmCode_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.confirmCode(email: "a@b.co", handle: "h", code: "1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_completeRoleSelection_security() async {
        // Signed out: the choice is only stored, never applied to an account.
        backend.auth.userID = nil
        let vm = AuthViewModel()
        await vm.completeRoleSelection(username: "luna", isDJ: true)
        XCTAssertEqual(vm.flowState, .login)
        XCTAssertTrue(db.all(User.self).isEmpty)
        // Signed in: the record is the session user's.
        backend.auth.userID = "me"
        await vm.completeRoleSelection(username: "luna", isDJ: true)
        XCTAssertEqual(db.all(User.self).first?.id, "me")
        XCTAssertFalse(db.all(User.self).first?.isCurated ?? true)
    }

    func test_AuthViewModel_completeRoleSelection_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 500) { await vm.completeRoleSelection(username: "u", isDJ: false) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_requestReset_security() async {
        // An unknown email looks exactly like a known one (no enumeration).
        let vm = AuthViewModel()
        backend.auth.failNext = userNotFound
        await vm.requestReset(email: "nobody@x.co")
        XCTAssertEqual(vm.flowState, .confirmReset(email: "nobody@x.co"))
        XCTAssertNil(vm.errorMessage)
    }

    func test_AuthViewModel_requestReset_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.requestReset(email: "a@b.co") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_confirmReset_security() async {
        let vm = AuthViewModel()
        backend.auth.failNext = AuthError.service("Invalid verification code provided, please try again.", "", nil)
        await vm.confirmReset(email: "a@b.co", newPassword: "password1", code: "000000")
        XCTAssertNotEqual(vm.flowState, .login, "a wrong code never completes the reset")
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_AuthViewModel_confirmReset_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.confirmReset(email: "a@b.co", newPassword: "password1", code: "1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_resendCode_security() async {
        let vm = AuthViewModel()
        vm.isLoading = true
        await vm.resendCode(email: "a@b.co")
        XCTAssertFalse(backend.auth.calls.contains("resendSignUpCode"), "no double-send while a request is in flight")
    }

    func test_AuthViewModel_resendCode_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.resendCode(email: "a@b.co") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_signOut_security() async {
        let vm = AuthViewModel()
        await vm.signOut()
        let after = await AuthService.currentUserIdOrNil()
        XCTAssertNil(after)
    }

    func test_AuthViewModel_signOut_performance() async {
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.signOut(); self.backend.auth.userID = "me" }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_deleteAccount_security() async {
        db.seed([Make.user("me"), Make.user("other")])
        let vm = AuthViewModel()
        await vm.deleteAccount()
        XCTAssertEqual(backend.auth.calls.last, "deleteUser")
        XCTAssertEqual(db.clearCount, 1)
    }

    func test_AuthViewModel_deleteAccount_performance() async {
        db.seed(Make.many(2_000) { Make.user("u\($0)") } + [Make.user("me")])
        let vm = AuthViewModel()
        let t = await elapsed { await vm.deleteAccount() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_AuthViewModel_authErrorMessage_security() {
        let vm = AuthViewModel()
        XCTAssertEqual(vm.authErrorMessage(from: userNotFound, context: .signIn), "Incorrect email or password.")
        let raw = AuthError.validation("password", "Value at 'password' failed to satisfy constraint: Member must satisfy regular expression pattern", "", nil)
        XCTAssertEqual(vm.authErrorMessage(from: raw), "Your password can't start or end with a space.", "no raw AWS text")
    }

    func test_AuthViewModel_authErrorMessage_performance() {
        let vm = AuthViewModel()
        let e = AuthError.notAuthorized("x", "", nil)
        let t = elapsedSync(iterations: 50_000) { _ = vm.authErrorMessage(from: e, context: .signIn) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_isUserNotFound_security() {
        XCTAssertTrue(AuthViewModel.isUserNotFound(userNotFound))
        XCTAssertFalse(AuthViewModel.isUserNotFound(AuthError.notAuthorized("User does not exist.", "", nil)),
                       "decided by the typed error, not by matching text")
        XCTAssertFalse(AuthViewModel.isUserNotFound(FakeError(tag: "x")))
    }

    func test_AuthViewModel_isUserNotFound_performance() {
        let e = userNotFound
        let t = elapsedSync(iterations: 200_000) { _ = AuthViewModel.isUserNotFound(e) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthViewModel_pendingChoiceBelongsToCurrentAccount_security() async {
        UserDefaults.standard.set("a@x.co", forKey: AuthViewModel.pendingEmailKey)
        backend.auth.attributes = []   // email unknown → not trusted
        let vm = AuthViewModel()
        let ok = await vm.pendingChoiceBelongsToCurrentAccount()
        XCTAssertFalse(ok)
    }

    func test_AuthViewModel_pendingChoiceBelongsToCurrentAccount_performance() async {
        backend.auth.attributes = [AuthUserAttribute(.email, value: "a@x.co")]
        let vm = AuthViewModel()
        let t = await elapsed(iterations: 2_000) {
            UserDefaults.standard.set("a@x.co", forKey: AuthViewModel.pendingEmailKey)
            _ = await vm.pendingChoiceBelongsToCurrentAccount()
        }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - AdminCurationViewModel

    private func admin() { backend.auth.idToken = FakeAuth.token(groups: ["AdminUser"]) }

    func test_AdminCurationViewModel_load_security() async {
        db.failNext = FakeError(tag: "x")
        let vm = AdminCurationViewModel()
        await vm.load()
        XCTAssertNotNil(vm.errorMessage, "a failed load says so — it doesn't show an empty, 'clean' console")
    }

    func test_AdminCurationViewModel_load_performance() async {
        db.seed(Make.many(3_000) { Make.user("u\($0)") }); db.seed(Make.many(3_000) { Make.event("e\($0)") })
        let vm = AdminCurationViewModel()
        let t = await elapsed { await vm.load() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminCurationViewModel_seedRank_security() async {
        let dj = Make.user("d", rank: 1); db.seed([dj])
        let vm = AdminCurationViewModel(); vm.djs = [dj]
        await vm.seedRank(5, for: dj)
        XCTAssertNotNil(vm.errorMessage, "non-admin refused")
        XCTAssertEqual(vm.djs.first?.djRank, 1)
    }

    func test_AdminCurationViewModel_seedRank_performance() async {
        admin()
        let djs = Make.many(200) { Make.user("d\($0)", rank: 1) }; db.seed(djs)
        let vm = AdminCurationViewModel(); vm.djs = djs
        let t = await elapsed { for d in djs { await vm.seedRank(3, for: d) } }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminCurationViewModel_toggleCurated_security() async {
        let dj = Make.user("d"); db.seed([dj])
        let vm = AdminCurationViewModel(); vm.djs = [dj]
        await vm.toggleCurated(dj)
        XCTAssertEqual(vm.djs.first?.isCurated, false)
    }

    func test_AdminCurationViewModel_toggleCurated_performance() async {
        admin(); let dj = Make.user("d"); db.seed([dj])
        let vm = AdminCurationViewModel(); vm.djs = [dj]
        let t = await elapsed(iterations: 200) { await vm.toggleCurated(dj) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminCurationViewModel_toggleFeatured_security() async {
        let e = Make.event("e"); db.seed([e])
        let vm = AdminCurationViewModel(); vm.events = [e]
        await vm.toggleFeatured(e)
        XCTAssertEqual(vm.events.first?.isFeatured, false)
    }

    func test_AdminCurationViewModel_toggleFeatured_performance() async {
        admin(); let e = Make.event("e"); db.seed([e])
        let vm = AdminCurationViewModel(); vm.events = [e]
        let t = await elapsed(iterations: 200) { await vm.toggleFeatured(e) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminCurationViewModel_forcePublish_security() async {
        let e = Make.event("e", status: "pending"); db.seed([e])
        let vm = AdminCurationViewModel()
        await vm.forcePublish(e)
        XCTAssertEqual(db.all(Event.self).first?.status, "pending")
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_AdminCurationViewModel_forcePublish_performance() async {
        admin(); db.seed(Make.many(1_000) { Make.event("e\($0)", status: "pending") })
        let vm = AdminCurationViewModel()
        let t = await elapsed(iterations: 20) { await vm.forcePublish(Make.event("e1")) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_AdminCurationViewModel_attachDJ_security() async {
        let e = Make.event("e"); db.seed([e])
        let vm = AdminCurationViewModel()
        await vm.attachDJ(Make.user("d"), to: e)
        XCTAssertTrue(db.all(EventDJLink.self).isEmpty, "non-admin can't build lineups")
    }

    func test_AdminCurationViewModel_attachDJ_performance() async {
        admin(); let e = Make.event("e"); db.seed([e])
        let vm = AdminCurationViewModel()
        let t = await elapsed { for i in 0..<100 { await vm.attachDJ(Make.user("d\(i)"), to: e) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_AdminCurationViewModel_replaceDJ_security() {
        let vm = AdminCurationViewModel(); vm.djs = [Make.user("a")]
        vm.replaceDJ(Make.user("intruder"))
        XCTAssertEqual(vm.djs.map(\.id), ["a"], "replace never inserts a new row")
    }

    func test_AdminCurationViewModel_replaceDJ_performance() {
        let vm = AdminCurationViewModel(); vm.djs = Make.many(2_000) { Make.user("u\($0)") }
        let t = elapsedSync(iterations: 500) { vm.replaceDJ(Make.user("u1999", rank: 2)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AdminCurationViewModel_replaceEvent_security() {
        let vm = AdminCurationViewModel(); vm.events = [Make.event("a")]
        vm.replaceEvent(Make.event("intruder"))
        XCTAssertEqual(vm.events.map(\.id), ["a"])
    }

    func test_AdminCurationViewModel_replaceEvent_performance() {
        let vm = AdminCurationViewModel(); vm.events = Make.many(2_000) { Make.event("e\($0)") }
        let t = elapsedSync(iterations: 500) { vm.replaceEvent(Make.event("e1999", featured: true)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - RoleAwareProfileViewModel

    func test_RoleAwareProfileViewModel_load_security() async {
        db.seed([Make.user("me", isDJ: false, avatarKey: "https://evil/x.jpg?X-Amz-Signature=1")])
        backend.auth.idToken = FakeAuth.token(groups: ["UserGroup"])
        let vm = RoleAwareProfileViewModel()
        await vm.load()
        XCTAssertEqual(vm.role, .regular)
        XCTAssertFalse(vm.isAdmin)
        XCTAssertFalse(vm.canCreateEvent)
    }

    func test_RoleAwareProfileViewModel_load_performance() async {
        db.seed([Make.user("me")] + Make.many(5_000) { Make.user("u\($0)") })
        let vm = RoleAwareProfileViewModel()
        let t = await elapsed(iterations: 200) { await vm.load() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_RoleAwareProfileViewModel_uploadAvatar_security() async {
        db.seed([Make.user("me")])
        let vm = RoleAwareProfileViewModel()
        await vm.uploadAvatar(image: UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in })
        XCTAssertEqual(backend.storage.uploads.last?.key, "avatars/me.jpg", "always the caller's own avatar path")
    }

    func test_RoleAwareProfileViewModel_uploadAvatar_performance() async {
        db.seed([Make.user("me")])
        let vm = RoleAwareProfileViewModel()
        let img = UIGraphicsImageRenderer(size: CGSize(width: 1_000, height: 1_000)).image { _ in }
        let t = await elapsed(iterations: 5) { await vm.uploadAvatar(image: img) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_RoleAwareProfileViewModel_switchRole_security() async {
        let vm = RoleAwareProfileViewModel()
        vm.currentUser = Make.user("me", isDJ: false)
        await vm.switchRole(to: .venue)
        XCTAssertEqual(db.saveCount, 0, "venue is admin-assigned — never self-switched")
        vm.currentUser = Make.user("someoneElse", isDJ: false)
        await vm.switchRole(to: .dj)
        XCTAssertNotNil(vm.roleSwitchError, "can't flip another user's role")
    }

    func test_RoleAwareProfileViewModel_switchRole_performance() async {
        let vm = RoleAwareProfileViewModel(); vm.currentUser = Make.user("me", isDJ: false)
        let t = await elapsed(iterations: 500) { await vm.switchRole(to: .dj); await vm.switchRole(to: .regular) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - SearchViewModel

    func test_SearchViewModel_queryChanged_security() {
        let vm = SearchViewModel()
        vm.queryChanged("   ")
        XCTAssertFalse(vm.isSearching, "blank input never searches")
        XCTAssertTrue(vm.results.djs.isEmpty)
    }

    func test_SearchViewModel_queryChanged_performance() {
        // Debounced: a burst of keystrokes cancels down to one search.
        let vm = SearchViewModel()
        let t = elapsedSync(iterations: 10_000) { vm.queryChanged("dj") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_SearchViewModel_performSearch_security() async {
        db.seed([Make.user("fan", isDJ: false, username: "luna")])
        let vm = SearchViewModel()
        await vm.performSearch(query: "luna")
        XCTAssertTrue(vm.results.djs.isEmpty, "fans aren't searchable as DJs")
        XCTAssertFalse(vm.isSearching)
    }

    func test_SearchViewModel_performSearch_performance() async {
        db.seed(Make.many(5_000) { Make.user("u\($0)", username: "dj\($0)") })
        let vm = SearchViewModel()
        let t = await elapsed(iterations: 10) { await vm.performSearch(query: "dj4") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_SearchViewModel_commitSearch_security() {
        let vm = SearchViewModel()
        vm.commitSearch(String(repeating: "x", count: 100_000))
        XCTAssertLessThanOrEqual(vm.recentSearches.first?.count ?? 0, SearchService.maxQueryLength, "bounded recents")
        for i in 0..<50 { vm.commitSearch("q\(i)") }
        XCTAssertLessThanOrEqual(vm.recentSearches.count, 8)
    }

    func test_SearchViewModel_commitSearch_performance() {
        let vm = SearchViewModel()
        let t = elapsedSync(iterations: 20_000) { vm.commitSearch("night \(Int.random(in: 0..<30))") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_SearchViewModel_removeRecent_security() {
        let vm = SearchViewModel(); vm.commitSearch("a"); vm.commitSearch("b")
        vm.removeRecent("A")
        XCTAssertEqual(vm.recentSearches, ["b", "a"], "exact match only")
    }

    func test_SearchViewModel_removeRecent_performance() {
        let vm = SearchViewModel()
        let t = elapsedSync(iterations: 100_000) { vm.removeRecent("absent") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_SearchViewModel_clearRecents_security() {
        let vm = SearchViewModel(); vm.commitSearch("ex's flat")
        vm.clearRecents()
        XCTAssertTrue(vm.recentSearches.isEmpty, "nothing left behind for the next person holding the phone")
    }

    func test_SearchViewModel_clearRecents_performance() {
        let vm = SearchViewModel()
        let t = elapsedSync(iterations: 100_000) { vm.clearRecents() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - UserState

    func test_UserState_updateAvatarState_security() {
        let s = UserState()
        s.updateAvatarState(.remote(avatarKey: "avatars/me.jpg"))
        XCTAssertEqual(s.avatarState.key, "avatars/me.jpg")
    }

    func test_UserState_updateAvatarState_performance() {
        let s = UserState()
        let t = elapsedSync(iterations: 100_000) { s.updateAvatarState(.remote(avatarKey: "k")) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_UserState_reset_security() {
        let s = UserState(); s.userId = "me"; s.username = "luna"
        s.reset()
        XCTAssertEqual([s.userId, s.username], ["", ""], "sign-out leaves no identity behind")
        XCTAssertEqual(s.avatarState, .remote(avatarKey: "default-avatar"))
    }

    func test_UserState_reset_performance() {
        let s = UserState()
        let t = elapsedSync(iterations: 100_000) { s.reset() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_UserState_updateFromUser_security() {
        let s = UserState()
        s.updateFromUser(Make.user("me", avatarKey: "https://b/x.jpg?X-Amz-Signature=s"))
        XCTAssertEqual(s.avatarState, .remote(avatarKey: "default-avatar"), "a stored signed URL is not used")
    }

    func test_UserState_updateFromUser_performance() {
        let s = UserState(); let u = Make.user("me", avatarKey: "avatars/me.jpg")
        let t = elapsedSync(iterations: 100_000) { s.updateFromUser(u) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - InviteSearchBarViewModel

    func test_InviteSearchBarViewModel_performSearch_security() async {
        db.seed([Make.user("dj", username: "luna"), Make.user("fan", isDJ: false, username: "lunafan"), Make.user("me", username: "lunaMe")])
        let vm = InviteSearchBarViewModel()
        vm.performSearch(term: "")
        XCTAssertTrue(vm.results.isEmpty, "an empty search lists nobody (it used to list everyone)")
        vm.performSearch(term: "luna")
        let found = await eventually { !vm.results.isEmpty }
        XCTAssertTrue(found)
        XCTAssertEqual(vm.results.map(\.id), ["dj"], "DJs only, never yourself, never fans")
    }

    func test_InviteSearchBarViewModel_performSearch_performance() async {
        db.seed(Make.many(5_000) { Make.user("u\($0)", username: "dj\($0)") })
        let vm = InviteSearchBarViewModel()
        db.resetCounters()
        vm.performSearch(term: "dj")
        _ = await eventually { !vm.results.isEmpty }
        XCTAssertLessThanOrEqual(vm.results.count, InviteSearchBarViewModel.resultLimit)
        XCTAssertEqual(db.unfilteredQueryCount, 0, "DJs filtered by DataStore, not all users loaded")
    }

    func test_InviteSearchBarViewModel_debounceSearch_security() async {
        let vm = InviteSearchBarViewModel()
        vm.searchText = String(repeating: "a", count: 10_000)   // triggers debounceSearch
        try? await Task.sleep(nanoseconds: 450_000_000)
        XCTAssertTrue(vm.results.isEmpty)
    }

    func test_InviteSearchBarViewModel_debounceSearch_performance() async {
        db.seed(Make.many(1_000) { Make.user("u\($0)", username: "dj\($0)") })
        let vm = InviteSearchBarViewModel()
        db.resetCounters()
        for c in "djdjdjdjdj" { vm.searchText += String(c) }   // 10 keystrokes
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertLessThanOrEqual(db.queryCount, 2, "10 keystrokes debounce to ~1 query")
    }

    func test_InviteSearchBarViewModel_load_security() async {
        backend.auth.userID = nil
        let vm = InviteSearchBarViewModel()
        await vm.load()
        XCTAssertTrue(vm.followedIDs.isEmpty)
    }

    func test_InviteSearchBarViewModel_load_performance() async {
        db.seed([Make.user("me")]); db.seed(Make.many(2_000) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let vm = InviteSearchBarViewModel()
        let t = await elapsed { await vm.load() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_InviteSearchBarViewModel_follow_security() async {
        let vm = InviteSearchBarViewModel()
        await vm.follow(UserSummary(id: "me", username: "me", avatarKey: nil, isDJ: true))
        XCTAssertTrue(db.all(UserFollows.self).isEmpty, "no self-follow")
    }

    func test_InviteSearchBarViewModel_follow_performance() async {
        let vm = InviteSearchBarViewModel()
        let t = await elapsed { for i in 0..<200 { await vm.follow(UserSummary(id: "d\(i)", username: "d", avatarKey: nil, isDJ: true)) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_InviteSearchBarViewModel_message_security() async {
        db.seed([Make.user("me"), Make.user("fan", isDJ: false)])
        let vm = InviteSearchBarViewModel()
        await vm.message(UserSummary(id: "fan", username: "fan", avatarKey: nil, isDJ: false))
        XCTAssertNil(vm.openChat, "DJs can't open DMs with fans")
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_InviteSearchBarViewModel_message_performance() async {
        db.seed([Make.user("me"), Make.user("dj")])
        let vm = InviteSearchBarViewModel()
        let t = await elapsed(iterations: 50) { await vm.message(UserSummary(id: "dj", username: "dj", avatarKey: nil, isDJ: true)) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.all(ChatRoom.self).count, 1, "one DM room however often opened")
    }

    // MARK: - EndorsementViewModel

    func test_EndorsementViewModel_loadProgress_security() async {
        let vm = EndorsementViewModel(); vm.currentRank = 1
        XCTAssertEqual(vm.approvedCount, 0, "no candidate yet → nothing counted")
        await vm.loadProgress(userID: "me")
        XCTAssertTrue(vm.sentRequests.isEmpty)
    }

    func test_EndorsementViewModel_loadProgress_performance() async {
        let me = Make.user("me", rank: 1)
        db.seed(Make.many(2_000) { EndorsementRequest(fromUser: me, toUser: Make.user("s\($0)", rank: 2), targetRank: 2, message: "",
                                                      status: "approved", timestamp: Make.now()) })
        let vm = EndorsementViewModel(); vm.currentRank = 1
        let t = await elapsed { await vm.loadProgress(userID: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementViewModel_loadEligibleEndorsers_security() async {
        let vm = EndorsementViewModel(); vm.currentRank = 1
        await vm.loadEligibleEndorsers(userID: "me")
        XCTAssertTrue(vm.eligibleEndorsers.isEmpty, "no shared events → nobody offered")
    }

    func test_EndorsementViewModel_loadEligibleEndorsers_performance() async {
        let vm = EndorsementViewModel(); vm.currentRank = 1
        db.seed(Make.many(3_000) { Make.user("u\($0)", rank: 3) })
        let t = await elapsed(iterations: 20) { await vm.loadEligibleEndorsers(userID: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementViewModel_sendRequest_security() async {
        db.seed([Make.user("me", rank: 1), Make.user("junior", rank: 1)])
        let vm = EndorsementViewModel(); vm.currentRank = 1
        await vm.sendRequest(toUserID: "junior", message: "pls")
        XCTAssertNotNil(vm.sendError)
        XCTAssertFalse(vm.didSend)
    }

    func test_EndorsementViewModel_sendRequest_performance() async {
        db.seed([Make.user("me", rank: 1)] + Make.many(100) { Make.user("s\($0)", rank: 2) })
        let vm = EndorsementViewModel(); vm.currentRank = 1
        let t = await elapsed { for i in 0..<100 { await vm.sendRequest(toUserID: "s\(i)", message: "") } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EndorsementViewModel_loadInbox_security() async {
        let cand = Make.user("c", rank: 1)
        db.seed([EndorsementRequest(fromUser: cand, toUser: Make.user("other", rank: 2), targetRank: 2, message: "", status: "pending", timestamp: Make.now())])
        let vm = EndorsementViewModel()
        await vm.loadInbox(userID: "me")
        XCTAssertTrue(vm.incomingRequests.isEmpty, "other people's inbox stays theirs")
    }

    func test_EndorsementViewModel_loadInbox_performance() async {
        let cand = Make.user("c", rank: 1)
        db.seed(Make.many(3_000) { i in EndorsementRequest(id: "r\(i)", fromUser: cand, toUser: Make.user("me", rank: 2), targetRank: 2, message: "", status: "pending", timestamp: Make.now()) })
        let vm = EndorsementViewModel()
        let t = await elapsed { await vm.loadInbox(userID: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementViewModel_accept_security() async {
        let req = EndorsementRequest(fromUser: Make.user("c"), toUser: Make.user("other", rank: 2), targetRank: 2, message: "", status: "pending", timestamp: Make.now())
        db.seed([req])
        let vm = EndorsementViewModel(); vm.incomingRequests = [req]
        await vm.accept(request: req)
        XCTAssertNotNil(vm.actionError, "can't approve someone else's request")
        XCTAssertEqual(db.all(EndorsementRequest.self).first?.status, "pending")
    }

    func test_EndorsementViewModel_accept_performance() async {
        let reqs = Make.many(300) { EndorsementRequest(id: "r\($0)", fromUser: Make.user("c\($0)"), toUser: Make.user("me", rank: 2), targetRank: 2,
                                                       message: "", status: "pending", timestamp: Make.now()) }
        db.seed(reqs)
        let vm = EndorsementViewModel(); vm.incomingRequests = reqs
        let t = await elapsed { for r in reqs { await vm.accept(request: r) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertTrue(vm.incomingRequests.isEmpty)
    }

    func test_EndorsementViewModel_decline_security() async {
        let req = EndorsementRequest(fromUser: Make.user("c"), toUser: Make.user("other", rank: 2), targetRank: 2, message: "", status: "pending", timestamp: Make.now())
        db.seed([req])
        let vm = EndorsementViewModel(); vm.incomingRequests = [req]
        await vm.decline(request: req)
        XCTAssertNotNil(vm.actionError)
        XCTAssertEqual(vm.incomingRequests.count, 1, "not removed from the list on failure")
    }

    func test_EndorsementViewModel_decline_performance() async {
        let reqs = Make.many(300) { EndorsementRequest(id: "r\($0)", fromUser: Make.user("c\($0)"), toUser: Make.user("me", rank: 2), targetRank: 2,
                                                       message: "", status: "pending", timestamp: Make.now()) }
        db.seed(reqs)
        let vm = EndorsementViewModel(); vm.incomingRequests = reqs
        let t = await elapsed { for r in reqs { await vm.decline(request: r) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - EventViewModel

    func test_EventViewModel_loadDJProfiles_security() async {
        let e = Make.event("e", host: "host"); db.seed([e]); db.seed([Make.user("host"), Make.user("guest")])
        db.seed([Make.link(event: e, dj: "guest"), Make.link(event: Make.event("other"), dj: "intruder")])
        let vm = EventViewModel(event: e)
        await vm.loadDJProfiles()
        XCTAssertEqual(vm.djProfiles.map(\.id), ["host", "guest"], "host first, then this event's lineup — no one else")
    }

    func test_EventViewModel_loadDJProfiles_performance() async {
        let e = Make.event("e", host: "host"); db.seed([e])
        db.seed(Make.many(30) { Make.user("d\($0)") } + [Make.user("host")]); db.seed(Make.many(30) { Make.link(event: e, dj: "d\($0)") })
        let vm = EventViewModel(event: e)
        let t = await elapsed { await vm.loadDJProfiles() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(vm.djProfiles.count, 31)
    }

    func test_EventViewModel_handlePurchase_security() async {
        backend.rest.responses["/tickets/purchase"] = Data(#"{"success":false,"errorCode":"LIMIT_REACHED"}"#.utf8)
        let vm = EventViewModel(event: Make.event("e"))
        vm.ticketQuantity = 50
        await vm.handlePurchase()
        XCTAssertEqual(vm.completedPurchases, 0, "a refused purchase is never confirmed")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(backend.rest.requests.last?.body["quantity"] as? Int, TicketService.maxPerRequest)
    }

    func test_EventViewModel_handlePurchase_performance() async {
        db.seed([Make.event("e")])
        backend.notifications.granted = false
        let vm = EventViewModel(event: Make.event("e"))
        let t = await elapsed(iterations: 300) { await vm.handlePurchase() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(vm.completedPurchases, 300)
    }

    func test_EventViewModel_shareText_security() {
        let text = EventViewModel.shareText(name: "Rave\nwin a prize: http://evil", date: "1 Jan")
        XCTAssertFalse(text.contains("\n"), "one line — host text can't add fake lines to a share")
    }

    func test_EventViewModel_shareText_performance() {
        let long = String(repeating: "x", count: 100_000)
        let t = elapsedSync(iterations: 20) { _ = EventViewModel.shareText(name: long, date: "d") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - DJViewModel

    func test_DJViewModel_loadUpcomingEvents_security() async {
        let dj = Make.user("dj")
        db.seed([Make.event("mine", host: "dj", days: 5), Make.event("notMine", host: "x", days: 5),
                 Make.event("pastMine", host: "dj", days: -5)])
        let vm = DJViewModel(user: dj)
        await vm.loadUpcomingEvents()
        XCTAssertEqual(vm.upcomingEvents.map(\.id), ["mine"], "this DJ's upcoming events only (it used to show every event)")
    }

    func test_DJViewModel_loadUpcomingEvents_performance() async {
        db.seed(Make.many(5_000) { Make.event("e\($0)", host: $0 % 50 == 0 ? "dj" : "x", days: 5) })
        let vm = DJViewModel(user: Make.user("dj"))
        let t = await elapsed { await vm.loadUpcomingEvents() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_DJViewModel_toggleFollow_security() async {
        let vm = DJViewModel(user: Make.user("fan", isDJ: false))
        await vm.initialLoad?.value   // its queries would otherwise eat failNext below
        await vm.toggleFollow()
        XCTAssertTrue(db.all(UserFollows.self).isEmpty, "only DJs can be followed")
        let djVM = DJViewModel(user: Make.user("dj"))
        await djVM.initialLoad?.value   // or it races the injected failure
        db.failNext = FakeError(tag: "x")
        let before = djVM.followerCount
        await djVM.toggleFollow()
        XCTAssertEqual(djVM.followerCount, before, "optimistic count rolls back on failure")
    }

    func test_DJViewModel_loadFollowState_doesNotOverwriteATap() async {
        db.seed([Make.user("dj")])
        let vm = DJViewModel(user: Make.user("dj"))
        await vm.initialLoad?.value
        let load = Task { await vm.loadFollowState() }   // starts with generation N
        await vm.toggleFollow()                          // tap → generation N+1, count 1
        await load.value
        XCTAssertTrue(vm.isFollowing, "a load that overlapped the tap never undoes it")
        XCTAssertEqual(vm.followerCount, 1)
    }

    func test_DJViewModel_toggleFollow_performance() async {
        let vm = DJViewModel(user: Make.user("dj"))
        let t = await elapsed(iterations: 200) { await vm.toggleFollow() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_DJViewModel_loadFollowState_security() async {
        db.seed([UserFollows(followerID: "other", followeeID: "dj", createdAt: Make.now())])
        let vm = DJViewModel(user: Make.user("dj"))
        await vm.loadFollowState()
        XCTAssertFalse(vm.isFollowing, "someone else's follow isn't mine")
        XCTAssertEqual(vm.followerCount, 1)
    }

    func test_DJViewModel_loadFollowState_performance() async {
        db.seed(Make.many(5_000) { UserFollows(followerID: "f\($0)", followeeID: "dj", createdAt: Make.now()) })
        let vm = DJViewModel(user: Make.user("dj"))
        let t = await elapsed(iterations: 5) { await vm.loadFollowState() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_DJViewModel_openChatRoomID_security() {
        let vm = DJViewModel(user: Make.user("b"))
        XCTAssertEqual(vm.openChatRoomID(with: "a"), ChatRoomService.dmRoomName("a", "b"), "same room whichever side opens")
    }

    func test_DJViewModel_openChatRoomID_performance() {
        let vm = DJViewModel(user: Make.user(UUID().uuidString))
        let other = UUID().uuidString
        let t = elapsedSync(iterations: 100_000) { _ = vm.openChatRoomID(with: other) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_DJViewModel_subscribeToUserUpdates_security() async throws {
        let vm = DJViewModel(user: Make.user("dj", rank: 1))
        try await Task.sleep(nanoseconds: 50_000_000)
        try await Backend.dataStore.save(Make.user("dj"))                 // create, not update
        try await Backend.dataStore.save(Make.user("other", rank: 5))     // someone else's update
        let stayed = await eventually(timeout: 0.3) { vm.user.djRank != 1 }
        XCTAssertFalse(stayed, "another user's update never replaces this profile")
        try await Backend.dataStore.save(Make.user("dj", rank: 3))
        let updated = await eventually { vm.user.djRank == 3 }
        XCTAssertTrue(updated)
    }

    func test_DJViewModel_subscribeToUserUpdates_performance() async throws {
        let vm = DJViewModel(user: Make.user("dj", rank: 1))
        try await Task.sleep(nanoseconds: 50_000_000)
        db.seed(Make.many(2_000) { Make.user("u\($0)") })
        let t = try await elapsed { for i in 0..<2_000 { try await Backend.dataStore.save(Make.user("u\(i)", rank: 2)) } }
        XCTAssertLessThan(t, 4.0, "2k unrelated updates skipped by id, not decoded: \(t)s")
        _ = vm
    }

    // MARK: - UnreadCounterVM

    func test_UnreadCounterVM_start_security() async {
        backend.auth.userID = nil
        let vm = UnreadCounterVM()
        await vm.start()
        XCTAssertEqual(vm.count, 0, "signed out shows no unread count")
    }

    func test_UnreadCounterVM_start_performance() async {
        let t = await elapsed(iterations: 200) { let vm = UnreadCounterVM(); await vm.start() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_UnreadCounterVM_reset_security() {
        let vm = UnreadCounterVM(); vm.count = 9
        vm.reset()
        XCTAssertEqual(vm.count, 0)
    }

    func test_UnreadCounterVM_reset_performance() {
        let vm = UnreadCounterVM()
        let t = elapsedSync(iterations: 100_000) { vm.reset() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_UnreadCounterVM_refresh_security() async {
        let r1 = ChatRoom(id: "r1", name: "r1", createdAt: Make.now(), updatedAt: Make.now())
        let r2 = ChatRoom(id: "r2", name: "r2", createdAt: Make.now(), updatedAt: Make.now())
        db.seed([r1, r2]); db.seed([UserChatRooms(user: Make.user("me"), chatRoom: r1)])
        db.seed([Message(sender: Make.user("x"), chatRoomID: "r1", content: "hi", timestamp: Make.now(), isRead: false),
                 Message(sender: Make.user("x"), chatRoomID: "r2", content: "not mine", timestamp: Make.now(), isRead: false),
                 Message(sender: Make.user("me"), chatRoomID: "r1", content: "mine", timestamp: Make.now(), isRead: false)])
        let vm = UnreadCounterVM()
        await vm.refresh()
        XCTAssertEqual(vm.count, 1, "only rooms I'm in, only others' messages")
    }

    func test_UnreadCounterVM_refresh_performance() async {
        let rooms = Make.many(100) { ChatRoom(id: "r\($0)", name: "r\($0)", createdAt: Make.now(), updatedAt: Make.now()) }
        db.seed(rooms); db.seed(rooms.map { UserChatRooms(user: Make.user("me"), chatRoom: $0) })
        db.seed(Make.many(2_000) { Message(sender: Make.user("x"), chatRoomID: "r\($0 % 100)", content: "m", timestamp: Make.now(), isRead: false) })
        let vm = UnreadCounterVM()
        let t = await elapsed { await vm.refresh() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(vm.count, 2_000)
    }
}
