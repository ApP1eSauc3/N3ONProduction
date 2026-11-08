// AuthUploadSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for AuthService, the upload services, storage,
// the REST client, UserService, RoleService, ImagePipeline and the Backend
// registry. Identity must always come from the session (MASVS-AUTH), media
// keys must stay inside their owner's path (MASVS-STORAGE), and uploads must
// not leak location metadata (MASVS-PRIVACY).

import XCTest
import UIKit
import ImageIO
import Amplify
@testable import N3ON

final class AuthUploadSecPerfTests: BackendTestCase {

    // MARK: Helpers

    private func image(width: Int, height: Int, scale: CGFloat = 1) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = scale
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: fmt).image { ctx in
            UIColor.systemPurple.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func pixelSize(ofJPEG data: Data) -> CGSize? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int, let h = props[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return CGSize(width: w, height: h)
    }

    /// A JPEG carrying GPS coordinates, like a phone photo.
    private func jpegWithGPS() -> Data {
        let cg = image(width: 40, height: 40).cgImage!
        let out = NSMutableData()
        let dest = CGImageDestinationCreateWithData(out, "public.jpeg" as CFString, 1, nil)!
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 27.47, kCGImagePropertyGPSLatitudeRef: "S",
                                    kCGImagePropertyGPSLongitude: 153.02, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(dest, cg, [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        CGImageDestinationFinalize(dest)
        return out as Data
    }

    // MARK: - AuthService

    func test_AuthService_currentUserId_security() async throws {
        backend.auth.userID = nil
        do { _ = try await AuthService.currentUserId(); XCTFail("signed out must throw") } catch {}
        backend.auth.userID = "sub-123"
        let id = try await AuthService.currentUserId()
        XCTAssertEqual(id, "sub-123", "identity is the session's, nothing cached")
    }

    func test_AuthService_currentUserId_performance() async throws {
        let t = try await elapsed(iterations: 5_000) { _ = try await AuthService.currentUserId() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_currentUserIdOrNil_security() async {
        backend.auth.failNext = FakeError(tag: "net")
        let onError = await AuthService.currentUserIdOrNil()
        XCTAssertNil(onError, "errors read as signed-out, never as someone")
        backend.auth.userID = nil
        let signedOut = await AuthService.currentUserIdOrNil()
        XCTAssertNil(signedOut)
    }

    func test_AuthService_currentUserIdOrNil_performance() async {
        let t = await elapsed(iterations: 5_000) { _ = await AuthService.currentUserIdOrNil() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_currentHandle_security() async throws {
        // Only the `name` attribute is the handle — never the email.
        backend.auth.attributes = [AuthUserAttribute(.email, value: "a@b.co")]
        let none = try await AuthService.currentHandle()
        XCTAssertNil(none)
        backend.auth.attributes = [AuthUserAttribute(.email, value: "a@b.co"), AuthUserAttribute(.name, value: "luna")]
        let handle = try await AuthService.currentHandle()
        XCTAssertEqual(handle, "luna")
    }

    func test_AuthService_currentHandle_performance() async throws {
        backend.auth.attributes = Make.many(30) { AuthUserAttribute(.custom("k\($0)"), value: "v") } + [AuthUserAttribute(.name, value: "n")]
        let t = try await elapsed(iterations: 2_000) { _ = try await AuthService.currentHandle() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_getCurrentUserModel_security() async throws {
        db.seed([Make.user("me"), Make.user("other")])
        let mine = try await AuthService.getCurrentUserModel()
        XCTAssertEqual(mine?.id, "me", "only the session user's record")
        backend.auth.userID = nil
        do { _ = try await AuthService.getCurrentUserModel(); XCTFail("signed out must throw") } catch {}
    }

    func test_AuthService_getCurrentUserModel_performance() async throws {
        db.seed(Make.many(5_000) { Make.user("u\($0)") } + [Make.user("me")])
        db.resetCounters()
        let t = try await elapsed(iterations: 500) { _ = try await AuthService.getCurrentUserModel() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0, "by-id read, not a table scan")
    }

    func test_AuthService_signIn_security() async throws {
        try await AuthService.signIn(email: "  Luna@Example.COM \n", password: " pass word ")
        XCTAssertEqual(backend.auth.usernames.last, "luna@example.com", "one account per address")
        XCTAssertEqual(backend.auth.passwords.last, " pass word ", "password sent exactly as typed")
        // An unfinished sign-in (MFA, new-password challenge) is not a session.
        backend.auth.signInResult = AuthSignInResult(nextStep: .confirmSignInWithNewPassword(nil))
        do { try await AuthService.signIn(email: "a@b.co", password: "x"); XCTFail("challenge treated as signed in") } catch {}
    }

    func test_AuthService_signIn_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { try await AuthService.signIn(email: "a@b.co", password: "password1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_signUp_security() async throws {
        _ = try await AuthService.signUp(handle: " luna ", email: "Luna@B.co", password: "password1")
        let attrs = backend.auth.signUpAttributes
        // Only email + name — never a role/group attribute (a client-writable
        // role is a known privilege-escalation pattern).
        XCTAssertEqual(Set(attrs.map { $0.key }), [.email, .name])
        XCTAssertEqual(attrs.first { $0.key == .name }?.value, "luna")
        XCTAssertEqual(backend.auth.usernames.last, "luna@b.co")
    }

    func test_AuthService_signUp_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { _ = try await AuthService.signUp(handle: "h", email: "a@b.co", password: "password1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_cognitoUsername_security() {
        XCTAssertEqual(AuthService.cognitoUsername(" A@B.CO\t\n"), "a@b.co")
        XCTAssertEqual(AuthService.cognitoUsername("a@b.co"), AuthService.cognitoUsername("A@B.CO"), "no case-twin accounts")
        XCTAssertEqual(AuthService.cognitoUsername(""), "")
    }

    func test_AuthService_cognitoUsername_performance() {
        let t = elapsedSync(iterations: 100_000) { _ = AuthService.cognitoUsername("  Someone.Long@Example.COM ") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_signUpRequest_security() {
        let r = AuthService.signUpRequest(handle: "\n dj\u{200B} ", email: "X@Y.Z")
        XCTAssertEqual(r.username, "x@y.z")
        XCTAssertEqual(r.attributes.count, 2, "exactly email + name")
        XCTAssertFalse(r.attributes.contains { $0.key == .custom("role") || $0.key == .custom("groups") })
    }

    func test_AuthService_signUpRequest_performance() {
        let t = elapsedSync(iterations: 50_000) { _ = AuthService.signUpRequest(handle: "luna", email: "l@b.co") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_confirmSignUp_security() async {
        backend.auth.confirmResult = AuthSignUpResult(.confirmUser(nil, nil, "me"), userID: "me")
        do { try await AuthService.confirmSignUp(email: "a@b.co", code: "123456"); XCTFail("unconfirmed treated as done") } catch {}
        XCTAssertEqual(backend.auth.usernames.last, "a@b.co")
    }

    func test_AuthService_confirmSignUp_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { try await AuthService.confirmSignUp(email: "a@b.co", code: "1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_resendSignUpCode_security() async throws {
        try await AuthService.resendSignUpCode(email: " VICTIM@x.co ")
        XCTAssertEqual(backend.auth.usernames.last, "victim@x.co", "normalised — same account as sign-up")
        XCTAssertEqual(backend.auth.calls.last, "resendSignUpCode")
    }

    func test_AuthService_resendSignUpCode_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { try await AuthService.resendSignUpCode(email: "a@b.co") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_passwordProblem_security() {
        XCTAssertNotNil(AuthService.passwordProblem("short"))
        XCTAssertNotNil(AuthService.passwordProblem(" leading1"))
        XCTAssertNotNil(AuthService.passwordProblem("trailing1 "))
        XCTAssertNotNil(AuthService.passwordProblem(String(repeating: "a", count: 257)), "over Cognito's 256 limit")
        XCTAssertNil(AuthService.passwordProblem(String(repeating: "a", count: 256)))
        XCTAssertNil(AuthService.passwordProblem("p@ss wörd 🎧"))
    }

    func test_AuthService_passwordProblem_performance() {
        let hostile = String(repeating: "x", count: 1_000_000)
        let t = elapsedSync(iterations: 20) { _ = AuthService.passwordProblem(hostile) }
        XCTAssertLessThan(t, 2.0, "1MB password checked 20×: \(t)s")
    }

    func test_AuthService_resetPassword_security() async throws {
        try await AuthService.resetPassword(email: " Me@X.co")
        XCTAssertEqual(backend.auth.usernames.last, "me@x.co")
    }

    func test_AuthService_resetPassword_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { try await AuthService.resetPassword(email: "a@b.co") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_confirmReset_security() async throws {
        try await AuthService.confirmReset(email: "A@b.co", newPassword: " new pass ", code: "123456")
        XCTAssertEqual(backend.auth.usernames.last, "a@b.co")
        XCTAssertEqual(backend.auth.passwords.last, " new pass ", "new password unmodified")
    }

    func test_AuthService_confirmReset_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { try await AuthService.confirmReset(email: "a@b.co", newPassword: "password1", code: "1") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_createInitialUserRecord_security() async throws {
        let u = try await AuthService.createInitialUserRecord(username: "luna", isDJ: true)
        XCTAssertEqual(u.id, "me", "id is the Cognito sub, not chosen by the client")
        XCTAssertFalse(u.isCurated, "no self-curation")
        XCTAssertEqual(u.djRank, 1, "DJs start at rank 1")
        let fan = try await AuthService.createInitialUserRecord(username: "fan", isDJ: false)
        XCTAssertNil(fan.djRank)
        backend.auth.userID = nil
        do { _ = try await AuthService.createInitialUserRecord(username: "x", isDJ: true); XCTFail() } catch {}
    }

    func test_AuthService_createInitialUserRecord_performance() async throws {
        let t = try await elapsed(iterations: 1_000) { _ = try await AuthService.createInitialUserRecord(username: "u", isDJ: false) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.saveCount, 1_000)
    }

    func test_AuthService_signOut_security() async {
        await AuthService.signOut()
        let after = await AuthService.currentUserIdOrNil()
        XCTAssertNil(after, "no session survives sign-out")
    }

    func test_AuthService_signOut_performance() async {
        let t = await elapsed(iterations: 2_000) { await AuthService.signOut(); self.backend.auth.userID = "me" }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AuthService_deleteAccount_security() async throws {
        db.seed([Make.user("me"), Make.user("other")])
        try await AuthService.deleteAccount()
        XCTAssertEqual(db.clearCount, 1, "local cache wiped")
        XCTAssertEqual(backend.auth.calls.last, "deleteUser", "Cognito account deleted last")
        let after = await AuthService.currentUserIdOrNil()
        XCTAssertNil(after)
    }

    func test_AuthService_deleteAccount_performance() async throws {
        db.seed(Make.many(5_000) { Make.user("u\($0)") } + [Make.user("me")])
        db.resetCounters()
        let t = try await elapsed { try await AuthService.deleteAccount() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
        XCTAssertEqual(db.deleteCount, 1, "deletes only the caller's record")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    // MARK: - AvatarUploadService

    func test_AvatarUploadService_uploadUIImage_security() async throws {
        db.seed([Make.user("me")])
        let state = try await AvatarUploadService.uploadUIImage(image(width: 4_000, height: 3_000))
        let upload = try XCTUnwrap(backend.storage.uploads.last)
        XCTAssertEqual(upload.key, "avatars/me.jpg", "key is the caller's own path")
        XCTAssertEqual(upload.access, "guest")
        XCTAssertEqual(state, .remote(avatarKey: "avatars/me.jpg"))
        XCTAssertEqual(db.all(User.self).first?.avatarKey, "avatars/me.jpg", "stores the KEY, never a signed URL")
        backend.auth.userID = nil
        do { _ = try await AvatarUploadService.uploadUIImage(image(width: 10, height: 10)); XCTFail() } catch {}
    }

    func test_AvatarUploadService_uploadUIImage_performance() async throws {
        db.seed([Make.user("me")])
        let big = image(width: 1_344, height: 1_008, scale: 3)   // a 12MP photo on a 3x device
        let t = try await elapsed { _ = try await AvatarUploadService.uploadUIImage(big) }
        XCTAssertLessThan(t, 3.0, "12MP photo → avatar: \(t)s")
        let uploaded = try XCTUnwrap(backend.storage.objects["avatars/me.jpg"])
        let px = try XCTUnwrap(pixelSize(ofJPEG: uploaded))
        XCTAssertLessThanOrEqual(max(px.width, px.height), 512, "a 512px avatar, not \(px)")
    }

    func test_AvatarUploadService_uploadProfileAudio_security() async throws {
        db.seed([Make.user("me")])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("clip.m4a")
        try Data(repeating: 1, count: 1_000).write(to: url)
        let key = try await AvatarUploadService.uploadProfileAudio(from: url)
        XCTAssertEqual(key, "profile-audio/me.m4a")
        XCTAssertEqual(backend.storage.uploads.last?.contentType, "audio/m4a")
        XCTAssertEqual(db.all(User.self).first?.profileAudioKey, key)
    }

    func test_AvatarUploadService_uploadProfileAudio_performance() async throws {
        db.seed([Make.user("me")])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("clip2.m4a")
        try Data(repeating: 2, count: 2_000_000).write(to: url)
        let t = try await elapsed { _ = try await AvatarUploadService.uploadProfileAudio(from: url) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - PosterUploadService

    @MainActor
    func test_PosterUploadService_uploadUIImage_security() async throws {
        db.seed([Make.event("mine", host: "me"), Make.event("theirs", host: "other")])
        do { _ = try await PosterUploadService.uploadUIImage(image(width: 50, height: 50), eventId: "theirs"); XCTFail("replaced another host's poster") }
        catch { XCTAssertEqual((error as? UploadError)?.errorDescription, UploadError.eventNotFound.errorDescription) }
        XCTAssertTrue(backend.storage.uploads.isEmpty, "nothing uploaded")
        let key = try await PosterUploadService.uploadUIImage(image(width: 50, height: 50), eventId: "mine")
        XCTAssertTrue(key.hasPrefix("events/mine/poster-"))
    }

    @MainActor
    func test_PosterUploadService_uploadUIImage_performance() async throws {
        db.seed([Make.event("mine", host: "me")])
        let big = image(width: 4_032, height: 3_024)
        let t = try await elapsed { _ = try await PosterUploadService.uploadUIImage(big, eventId: "mine") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - StorageUploader / MediaKind

    func test_StorageUploader_uploadJPEG_security() async throws {
        _ = try await StorageUploader.uploadJPEG(Data([0xFF, 0xD8]), key: "avatars/me.jpg", access: .guest)
        XCTAssertEqual(backend.storage.uploads.last?.contentType, "image/jpeg", "content type fixed, not caller-chosen")
    }

    func test_StorageUploader_uploadJPEG_performance() async throws {
        let data = Data(repeating: 0, count: 500_000)
        let t = try await elapsed(iterations: 200) { _ = try await StorageUploader.uploadJPEG(data, key: "k", access: .guest) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_StorageUploader_uploadFile_security() async {
        let missing = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)")
        backend.storage.failNext = FakeError(tag: "io")
        do { _ = try await StorageUploader.uploadFile(url: missing, key: "k", contentType: "audio/m4a", access: .guest); XCTFail() }
        catch { XCTAssertEqual(error as? FakeError, FakeError(tag: "io"), "errors propagate — no silent success") }
    }

    func test_StorageUploader_uploadFile_performance() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("f.bin")
        try Data(repeating: 3, count: 1_000_000).write(to: url)
        let t = try await elapsed(iterations: 20) { _ = try await StorageUploader.uploadFile(url: url, key: "k", contentType: "x", access: .guest) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_StorageUploader_signedURL_security() async throws {
        let url = try await StorageUploader.signedURL(for: "avatars/me.jpg", access: .guest)
        XCTAssertTrue(url.absoluteString.contains("Signature"))
        XCTAssertEqual(db.saveCount, 0, "a signed URL is never persisted")
    }

    func test_StorageUploader_signedURL_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { _ = try await StorageUploader.signedURL(for: "k", access: .guest) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MediaKind_makeKey_security() {
        // Client-written ids can't escape their folder.
        let poster = MediaKind.eventPoster(eventID: "../../avatars/victim").makeKey(extension: "jpg")
        XCTAssertFalse(poster.contains(".."))
        XCTAssertTrue(poster.hasPrefix("events/"))
        XCTAssertEqual(poster.split(separator: "/").count, 3, "no extra path segments")
        XCTAssertEqual(MediaKind.avatar(userID: "a/b").makeKey(extension: "jpg/../x"), "avatars/a_b.jpg____x")
        // Real ids are unchanged.
        let sub = "0b6e1c2a-7f9d-4a51-9c3e-2f1d8b7a6e50"
        XCTAssertEqual(MediaKind.avatar(userID: sub).makeKey(extension: "jpg"), "avatars/\(sub).jpg")
    }

    func test_MediaKind_makeKey_performance() {
        let t = elapsedSync(iterations: 50_000) { _ = MediaKind.eventPoster(eventID: "e1").makeKey(extension: "jpg") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MediaKind_component_security() {
        XCTAssertEqual(MediaKind.component(""), "_", "never an empty path segment")
        XCTAssertEqual(MediaKind.component("é/🎧"), "___")
        XCTAssertEqual(MediaKind.component(String(repeating: "a", count: 1_000)).count, 128)
    }

    func test_MediaKind_component_performance() {
        let long = String(repeating: "x", count: 100_000)
        let t = elapsedSync(iterations: 1_000) { _ = MediaKind.component(long) }
        XCTAssertLessThan(t, 1.0, "prefix-bounded: \(t)s")
    }

    // MARK: - N3ONRESTClient

    func test_N3ONRESTClient_post_security() async throws {
        _ = try await N3ONRESTClient.post(path: "/tickets/purchase", json: ["eventID": "e1", "quantity": 2])
        let sent = try XCTUnwrap(backend.rest.requests.last)
        XCTAssertEqual(sent.path, "/tickets/purchase")
        XCTAssertNil(sent.body["userID"], "identity comes from the IAM signature, never the body")
        XCTAssertEqual(sent.body["eventID"] as? String, "e1")
        backend.rest.failNext = FakeError(tag: "offline")
        do { _ = try await N3ONRESTClient.post(path: "/x", json: [:]); XCTFail() } catch {}
    }

    func test_N3ONRESTClient_post_performance() async throws {
        let t = try await elapsed(iterations: 2_000) { _ = try await N3ONRESTClient.post(path: "/x", json: ["a": 1]) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - UserService

    func test_UserService_fetch_security() async throws {
        db.seed([Make.user("a")])
        let missing = try await UserService.fetch(byId: "' OR 1=1 --")
        XCTAssertNil(missing, "an id is an id, not a query")
    }

    func test_UserService_fetch_performance() async throws {
        db.seed(Make.many(5_000) { Make.user("u\($0)") })
        db.resetCounters()
        let t = try await elapsed(iterations: 1_000) { _ = try await UserService.fetch(byId: "u42") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_UserService_fetchAnywhere_security() async {
        // Falls back to the network ONLY when the local copy is missing, and a
        // failed read is nil, not a crash or a placeholder identity.
        db.seed([Make.user("local")])
        backend.graphQL.users["remote"] = Make.user("remote")
        let local = await UserService.fetchAnywhere(byId: "local")
        XCTAssertEqual(local?.id, "local")
        let remote = await UserService.fetchAnywhere(byId: "remote")
        XCTAssertEqual(remote?.id, "remote")
        let none = await UserService.fetchAnywhere(byId: "nobody")
        XCTAssertNil(none)
        XCTAssertEqual(backend.graphQL.reads, ["remote", "nobody"])
    }

    func test_UserService_fetchAnywhere_performance() async {
        db.seed(Make.many(500) { Make.user("u\($0)") })
        let t = await elapsed(iterations: 1_000) { _ = await UserService.fetchAnywhere(byId: "u7") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertTrue(backend.graphQL.reads.isEmpty, "synced users never hit the network")
    }

    func test_UserService_fetchAll_security() async {
        db.failNext = FakeError(tag: "x")
        do { _ = try await UserService.fetchAll(); XCTFail("errors propagate") } catch {}
    }

    func test_UserService_fetchAll_performance() async throws {
        db.seed(Make.many(10_000) { Make.user("u\($0)") })
        let t = try await elapsed { _ = try await UserService.fetchAll() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - RoleService

    func test_RoleService_setDJStatus_security() async throws {
        let other = Make.user("other", isDJ: false)
        db.seed([other, Make.user("me", isDJ: false)])
        do { _ = try await RoleService.setDJStatus(true, for: other); XCTFail("changed another user's role") }
        catch { XCTAssertTrue(error is RoleError) }
        XCTAssertEqual(db.all(User.self).first { $0.id == "other" }?.isDJ, false)
        let me = try await RoleService.setDJStatus(true, for: Make.user("me", isDJ: false))
        XCTAssertTrue(me.isDJ)
    }

    func test_RoleService_setDJStatus_performance() async throws {
        let me = Make.user("me")
        let t = try await elapsed(iterations: 1_000) { _ = try await RoleService.setDJStatus(true, for: me) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - ImagePipeline

    func test_ImagePipeline_makeJPEGData_security() throws {
        // Re-encoding drops the photo's GPS location before upload.
        let source = try XCTUnwrap(UIImage(data: jpegWithGPS()))
        let out = try XCTUnwrap(ImagePipeline.makeJPEGData(from: source, config: .avatar))
        let src = try XCTUnwrap(CGImageSourceCreateWithData(out as CFData, nil))
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        XCTAssertNil(props?[kCGImagePropertyGPSDictionary], "no location in uploaded media")
    }

    func test_ImagePipeline_makeJPEGData_performance() throws {
        let photo = image(width: 4_032, height: 3_024)
        let t = elapsedSync(iterations: 3) { _ = ImagePipeline.makeJPEGData(from: photo, config: .poster) }
        XCTAssertLessThan(t, 6.0, "3 × 12MP → poster: \(t)s")
    }

    func test_ImagePipeline_downscale_security() throws {
        // maxDimension is pixels, whatever the screen scale — the bug this
        // test found uploaded 3x-sized avatars on 3x iPhones.
        let out = ImagePipeline.downscale(image(width: 2_000, height: 1_000, scale: 3), maxDimension: 512)
        XCTAssertEqual(out.size.width * out.scale, 512, accuracy: 1)
        let jpeg = try XCTUnwrap(ImagePipeline.makeJPEGData(from: image(width: 3_000, height: 3_000, scale: 3), config: .avatar))
        let px = try XCTUnwrap(pixelSize(ofJPEG: jpeg))
        XCTAssertLessThanOrEqual(max(px.width, px.height), 512)
        let tiny = image(width: 10, height: 10)
        XCTAssertTrue(ImagePipeline.downscale(tiny, maxDimension: 0) === tiny, "a bad config never produces a 0×0 image")
    }

    func test_ImagePipeline_downscale_performance() {
        let photo = image(width: 4_032, height: 3_024)
        let t = elapsedSync(iterations: 5) { _ = ImagePipeline.downscale(photo, maxDimension: 512) }
        XCTAssertLessThan(t, 5.0, "\(t)s")
    }

    func test_ImagePipeline_fixOrientation_security() throws {
        // A rotated photo is normalised (no orientation flag left for a viewer
        // to misinterpret), and an upright one is returned as-is.
        let cg = try XCTUnwrap(image(width: 40, height: 20).cgImage)
        let rotated = UIImage(cgImage: cg, scale: 1, orientation: .right)
        let fixed = ImagePipeline.fixOrientation(rotated)
        XCTAssertEqual(fixed.imageOrientation, .up)
        let upright = image(width: 5, height: 5)
        XCTAssertTrue(ImagePipeline.fixOrientation(upright) === upright)
    }

    func test_ImagePipeline_fixOrientation_performance() throws {
        let cg = try XCTUnwrap(image(width: 2_000, height: 1_500).cgImage)
        let rotated = UIImage(cgImage: cg, scale: 1, orientation: .right)
        let t = elapsedSync(iterations: 5) { _ = ImagePipeline.fixOrientation(rotated) }
        XCTAssertLessThan(t, 5.0, "\(t)s")
    }

    // MARK: - Backend

    func test_Backend_useLive_security() {
        // After a test, no fake can linger in the app's backend registry.
        Backend.useLive()
        XCTAssertTrue(Backend.dataStore is AmplifyDataStoreClient)
        XCTAssertTrue(Backend.auth is AmplifyAuthClient)
        XCTAssertTrue(Backend.storage is AmplifyStorageClient)
        XCTAssertTrue(Backend.rest is AmplifyRESTTransport)
        XCTAssertTrue(Backend.graphQL is AmplifyGraphQLClient)
        XCTAssertTrue(Backend.hub is AmplifyHubClient)
        backend = FakeBackend.install()
    }

    func test_Backend_useLive_performance() {
        let t = elapsedSync(iterations: 100_000) { Backend.useLive() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        backend = FakeBackend.install()
    }
}
