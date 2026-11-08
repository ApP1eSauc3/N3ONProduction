// TaskRestSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for EndorsementService, ImageCache /
// ImageLoader, PushNotificationService, the DataStoreClient default query,
// the motion transitions and the chat-panel gesture rules.

import XCTest
import UIKit
import SwiftUI
import UserNotifications
import Amplify
@testable import N3ON

final class TaskRestSecPerfTests: BackendTestCase {

    private func request(_ id: String, from: User, to: User, rank: Int = 2, status: String = "pending",
                         touched: Bool = true) -> EndorsementRequest {
        let created = Date(timeIntervalSince1970: 1_800_000_000)
        return EndorsementRequest(id: id, fromUser: from, toUser: to, targetRank: rank, message: "", status: status,
                                  timestamp: Temporal.DateTime(created, timeZone: .current),
                                  createdAt: Temporal.DateTime(created, timeZone: .current),
                                  updatedAt: Temporal.DateTime(created.addingTimeInterval(touched ? 60 : 0), timeZone: .current))
    }

    private func jpeg(_ w: Int, _ h: Int) -> Data {
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { c in
            UIColor.orange.setFill(); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }.jpegData(compressionQuality: 0.8)!
    }

    // MARK: - EndorsementService

    func test_EndorsementService_requiredEndorsements_security() {
        // A corrupt target can't lower the bar below 2.
        for r in [Int.min, -1, 0, 1, 2, 3] { XCTAssertGreaterThanOrEqual(EndorsementService.requiredEndorsements(forTargetRank: r), 2) }
        XCTAssertEqual(EndorsementService.requiredEndorsements(forTargetRank: Int.max), 3)
    }

    func test_EndorsementService_requiredEndorsements_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = EndorsementService.requiredEndorsements(forTargetRank: 4) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_EndorsementService_canEndorse_security() {
        XCTAssertFalse(EndorsementService.canEndorse(Make.user("x", rank: 9, isDJ: false), targetRank: 2), "ex-DJs can't endorse")
        XCTAssertFalse(EndorsementService.canEndorse(Make.user("x", rank: nil), targetRank: 1))
    }

    func test_EndorsementService_canEndorse_performance() {
        let u = Make.user("x", rank: 3)
        let t = elapsedSync(iterations: 1_000_000) { _ = EndorsementService.canEndorse(u, targetRank: 2) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_EndorsementService_approvedByUpdate_security() {
        let me = Make.user("me"), s = Make.user("s", rank: 2)
        XCTAssertFalse(EndorsementService.approvedByUpdate(request("f", from: me, to: s, touched: false)), "forged: never updated")
        var unsynced = request("u", from: me, to: s); unsynced.createdAt = nil
        XCTAssertFalse(EndorsementService.approvedByUpdate(unsynced))
        XCTAssertTrue(EndorsementService.approvedByUpdate(request("g", from: me, to: s)))
    }

    func test_EndorsementService_approvedByUpdate_performance() {
        let r = request("g", from: Make.user("me"), to: Make.user("s", rank: 2))
        let t = elapsedSync(iterations: 200_000) { _ = EndorsementService.approvedByUpdate(r) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementService_countedEndorsers_security() {
        let me = Make.user("me", rank: 1), a = Make.user("a", rank: 2)
        let rows = [request("1", from: me, to: a, status: "approved"), request("2", from: me, to: a, status: "approved"),
                    request("3", from: me, to: me, status: "approved"), request("4", from: me, to: Make.user("b", rank: 2), status: "approved", touched: false)]
        XCTAssertEqual(EndorsementService.countedEndorsers(in: rows, candidateID: "me", targetRank: 2), 1)
    }

    func test_EndorsementService_countedEndorsers_performance() {
        let me = Make.user("me", rank: 1)
        let rows = Make.many(10_000) { request("r\($0)", from: me, to: Make.user("s\($0 % 500)", rank: 3), status: "approved") }
        let t = elapsedSync(iterations: 10) { _ = EndorsementService.countedEndorsers(in: rows, candidateID: "me", targetRank: 2) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementService_eligibleEndorsers_security() async {
        let shared = Make.event("shared"), other = Make.event("other")
        db.seed([Make.user("me", rank: 1), Make.user("senior", rank: 3), Make.user("junior", rank: 1), Make.user("stranger", rank: 5)])
        db.seed([shared, other])
        db.seed([Make.link(event: shared, dj: "me"), Make.link(event: shared, dj: "senior"),
                 Make.link(event: shared, dj: "junior"), Make.link(event: other, dj: "stranger")])
        let e = await EndorsementService.eligibleEndorsers(for: "me", targetRank: 2)
        XCTAssertEqual(e.map(\.id), ["senior"], "shared an event AND senior enough; never yourself or a stranger")
    }

    func test_EndorsementService_eligibleEndorsers_performance() async {
        let events = Make.many(1_000) { Make.event("e\($0)") }
        db.seed(events)
        db.seed(Make.many(1_000) { Make.user("u\($0)", rank: 3) } + [Make.user("me", rank: 1)])
        db.seed(Make.many(5_000) { Make.link(event: events[$0 % 1_000], dj: "u\($0 % 1_000)") }
                + Make.many(5) { Make.link(event: events[$0], dj: "me") })
        db.resetCounters()
        let t = await elapsed { _ = await EndorsementService.eligibleEndorsers(for: "me", targetRank: 2) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0, "used to load every link and every user")
    }

    func test_EndorsementService_requestEndorsement_security() async throws {
        db.seed([Make.user("me", rank: 1), Make.user("senior", rank: 2), Make.user("junior", rank: 1)])
        do { try await EndorsementService.requestEndorsement(toUserID: "junior", targetRank: 2, message: ""); XCTFail() }
        catch { XCTAssertEqual(error as? EndorsementError, .rankMismatch) }
        do { try await EndorsementService.requestEndorsement(toUserID: "me", targetRank: 2, message: ""); XCTFail("self-endorsement") } catch {}
        do { try await EndorsementService.requestEndorsement(toUserID: "senior", targetRank: 2,
                                                              message: String(repeating: "x", count: 501)); XCTFail() }
        catch { XCTAssertEqual(error as? EndorsementError, .messageTooLong) }
        try await EndorsementService.requestEndorsement(toUserID: "senior", targetRank: 2, message: "hi")
        do { try await EndorsementService.requestEndorsement(toUserID: "senior", targetRank: 2, message: "again"); XCTFail("spam") }
        catch { XCTAssertEqual(error as? EndorsementError, .alreadyRequested) }
        let saved = try XCTUnwrap(db.all(EndorsementRequest.self).first)
        XCTAssertEqual(saved.fromUser?.id, "me", "from the session user")
        XCTAssertEqual(saved.status, "pending", "a request is never created approved")
    }

    func test_EndorsementService_requestEndorsement_performance() async throws {
        db.seed([Make.user("me", rank: 1)] + Make.many(200) { Make.user("s\($0)", rank: 2) })
        let t = try await elapsed { for i in 0..<200 { try await EndorsementService.requestEndorsement(toUserID: "s\(i)", targetRank: 2, message: "") } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EndorsementService_incomingPending_security() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed([request("toMe", from: cand, to: Make.user("me", rank: 2)), request("toOther", from: cand, to: Make.user("o", rank: 2)),
                 request("done", from: cand, to: Make.user("me", rank: 2), status: "approved")])
        let ok = try await EndorsementService.incomingPending(id: "toMe")
        XCTAssertEqual(ok.id, "toMe")
        for id in ["toOther", "done", "nope"] {
            do { _ = try await EndorsementService.incomingPending(id: id); XCTFail(id) }
            catch { XCTAssertEqual(error as? EndorsementError, .notFound) }
        }
    }

    func test_EndorsementService_incomingPending_performance() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed(Make.many(3_000) { request("r\($0)", from: cand, to: Make.user("me", rank: 2)) })
        let t = try await elapsed(iterations: 1_000) { _ = try await EndorsementService.incomingPending(id: "r9") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementService_acceptRequest_security() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed([request("toOther", from: cand, to: Make.user("o", rank: 2)), request("toMe", from: cand, to: Make.user("me", rank: 2))])
        do { try await EndorsementService.acceptRequest(id: "toOther"); XCTFail("approved someone else's request") } catch {}
        XCTAssertEqual(db.all(EndorsementRequest.self).first { $0.id == "toOther" }?.status, "pending")
        try await EndorsementService.acceptRequest(id: "toMe")
        do { try await EndorsementService.acceptRequest(id: "toMe"); XCTFail("decided twice") } catch {}
    }

    func test_EndorsementService_acceptRequest_performance() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed(Make.many(500) { request("r\($0)", from: cand, to: Make.user("me", rank: 2)) })
        let t = try await elapsed { for i in 0..<500 { try await EndorsementService.acceptRequest(id: "r\(i)") } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EndorsementService_declineRequest_security() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed([request("toOther", from: cand, to: Make.user("o", rank: 2))])
        do { try await EndorsementService.declineRequest(id: "toOther"); XCTFail("declined someone else's request") } catch {}
    }

    func test_EndorsementService_declineRequest_performance() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed(Make.many(500) { request("r\($0)", from: cand, to: Make.user("me", rank: 2)) })
        let t = try await elapsed { for i in 0..<500 { try await EndorsementService.declineRequest(id: "r\(i)") } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EndorsementService_pendingIncoming_security() async throws {
        let cand = Make.user("cand", rank: 1), me = Make.user("me", rank: 2)
        db.seed([request("a", from: cand, to: me), request("b", from: cand, to: Make.user("o", rank: 2)),
                 request("c", from: cand, to: me, status: "approved")])
        let inbox = try await EndorsementService.pendingIncoming(for: "me")
        XCTAssertEqual(inbox.map(\.id), ["a"], "only mine, only undecided")
    }

    func test_EndorsementService_pendingIncoming_performance() async throws {
        let cand = Make.user("cand", rank: 1)
        db.seed(Make.many(5_000) { request("r\($0)", from: cand, to: Make.user($0 % 10 == 0 ? "me" : "o\($0)", rank: 2)) })
        let t = try await elapsed { _ = try await EndorsementService.pendingIncoming(for: "me") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementService_sentRequests_security() async throws {
        let me = Make.user("me", rank: 1), other = Make.user("other", rank: 1), s = Make.user("s", rank: 2)
        db.seed([request("mine", from: me, to: s), request("theirs", from: other, to: s)])
        let sent = try await EndorsementService.sentRequests(by: "me", targetRank: 2)
        XCTAssertEqual(sent.map(\.id), ["mine"])
    }

    func test_EndorsementService_sentRequests_performance() async throws {
        let me = Make.user("me", rank: 1)
        db.seed(Make.many(5_000) { request("r\($0)", from: $0 % 5 == 0 ? me : Make.user("x\($0)"), to: Make.user("s", rank: 2)) })
        let t = try await elapsed { _ = try await EndorsementService.sentRequests(by: "me", targetRank: 2) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EndorsementService_approvedCount_security() async {
        let me = Make.user("me", rank: 1), a = Make.user("a", rank: 2)
        db.seed([request("1", from: me, to: a, status: "approved"), request("2", from: me, to: a, status: "approved"),
                 request("3", from: me, to: Make.user("b", rank: 2), status: "approved", touched: false)])
        let n = await EndorsementService.approvedCount(for: "me", targetRank: 2)
        XCTAssertEqual(n, 1, "duplicates and forgeries don't count")
    }

    func test_EndorsementService_approvedCount_performance() async {
        let me = Make.user("me", rank: 1)
        db.seed(Make.many(5_000) { request("r\($0)", from: me, to: Make.user("s\($0 % 100)", rank: 2), status: "approved") })
        let t = await elapsed { _ = await EndorsementService.approvedCount(for: "me", targetRank: 2) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - ImageCache / ImageLoader

    func test_ImageCache_image_security() {
        // A miss is nil — never another key's image.
        ImageCache.shared.insert(UIImage(), forKey: "a-\(#function)")
        XCTAssertNil(ImageCache.shared.image(forKey: "b-\(#function)"))
    }

    func test_ImageCache_image_performance() {
        ImageCache.shared.insert(UIImage(), forKey: #function)
        let t = elapsedSync(iterations: 200_000) { _ = ImageCache.shared.image(forKey: #function) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageCache_insert_security() {
        // Memory is bounded: a byte cost limit, so hostile images can't grow
        // the cache without limit (NSCache evicts beyond it).
        XCTAssertGreaterThan(ImageCache.shared.costLimit, 0)
        XCTAssertLessThanOrEqual(ImageCache.shared.costLimit, 128 * 1_024 * 1_024)
        let img = UIImage(data: jpeg(200, 200))!
        ImageCache.shared.insert(img, forKey: #function)
        XCTAssertTrue(ImageCache.shared.image(forKey: #function) === img)
    }

    func test_ImageCache_insert_performance() {
        let img = UIImage(data: jpeg(64, 64))!
        let t = elapsedSync(iterations: 50_000) { ImageCache.shared.insert(img, forKey: "k\(Int.random(in: 0..<500))") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageCache_remove_security() {
        ImageCache.shared.insert(UIImage(), forKey: #function)
        ImageCache.shared.remove(forKey: #function)
        XCTAssertNil(ImageCache.shared.image(forKey: #function), "a replaced avatar can't be served stale")
    }

    func test_ImageCache_remove_performance() {
        let t = elapsedSync(iterations: 100_000) { ImageCache.shared.remove(forKey: "absent") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageCache_loadImage_security() async {
        // Not-an-image bytes from storage are rejected, not displayed or cached.
        let key = "bad-\(UUID().uuidString)"
        backend.storage.objects[key] = Data("<script>alert(1)</script>".utf8)
        do { _ = try await ImageCache.loadImage(forKey: key, access: .guest); XCTFail("decoded junk") } catch {}
        XCTAssertNil(ImageCache.shared.image(forKey: key))
    }

    func test_ImageCache_loadImage_performance() async throws {
        let key = "p-\(UUID().uuidString)"
        backend.storage.objects[key] = jpeg(400, 400)
        _ = try await ImageCache.loadImage(forKey: key, access: .guest)
        let t = try await elapsed(iterations: 2_000) { _ = try await ImageCache.loadImage(forKey: key, access: .guest) }
        XCTAssertLessThan(t, 1.0, "memory hits: \(t)s")
        XCTAssertEqual(backend.storage.downloads.filter { $0 == key }.count, 1, "downloaded once, then cached")
        await ImageCache.invalidate(key)
    }

    func test_ImageCache_store_security() async {
        let key = "s-\(UUID().uuidString)"
        let junk = await ImageCache.store(data: Data([0, 1, 2]), forKey: key)
        XCTAssertNil(junk, "undecodable data is not stored as an image")
        XCTAssertNil(ImageCache.shared.image(forKey: key))
        await ImageCache.invalidate(key)
    }

    func test_ImageCache_store_performance() async {
        let data = jpeg(512, 512)
        let t = await elapsed(iterations: 30) { _ = await ImageCache.store(data: data, forKey: "st-\(Int.random(in: 0..<5))") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        for i in 0..<5 { await ImageCache.invalidate("st-\(i)") }
    }

    func test_ImageCache_invalidate_security() async {
        let key = "i-\(UUID().uuidString)"
        await ImageCache.store(data: jpeg(20, 20), forKey: key)
        await ImageCache.invalidate(key)
        XCTAssertNil(ImageCache.shared.image(forKey: key))
        XCTAssertFalse(FileManager.default.fileExists(atPath: ImageLoader.fileURL(for: key).path), "disk copy removed too")
    }

    func test_ImageCache_invalidate_performance() async {
        let t = await elapsed(iterations: 2_000) { await ImageCache.invalidate("absent-key") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageLoader_load_security() async {
        do { _ = try await ImageLoader.shared.load(key: "missing-\(UUID().uuidString)", access: .guest); XCTFail() } catch {}
    }

    func test_ImageLoader_load_performance() async throws {
        // Concurrent loads of one key share one download (in-flight dedupe).
        let key = "c-\(UUID().uuidString)"
        backend.storage.objects[key] = jpeg(300, 300)
        let t = try await elapsed {
            try await withThrowingTaskGroup(of: Void.self) { g in
                for _ in 0..<20 { g.addTask { _ = try await ImageLoader.shared.load(key: key, access: .guest) } }
                try await g.waitForAll()
            }
        }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertLessThanOrEqual(backend.storage.downloads.filter { $0 == key }.count, 2, "deduped")
        await ImageCache.invalidate(key)
    }

    func test_ImageLoader_store_security() async {
        let img = await ImageLoader.shared.store(data: Data(), key: "e-\(#function)")
        XCTAssertNil(img)
    }

    func test_ImageLoader_store_performance() async {
        let data = jpeg(256, 256)
        let t = await elapsed(iterations: 50) { _ = await ImageLoader.shared.store(data: data, key: "ls") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        await ImageCache.invalidate("ls")
    }

    func test_ImageLoader_invalidate_security() async {
        await ImageLoader.shared.store(data: jpeg(10, 10), key: #function)
        await ImageLoader.shared.invalidate(key: #function)
        XCTAssertNil(ImageCache.shared.image(forKey: #function))
    }

    func test_ImageLoader_invalidate_performance() async {
        let t = await elapsed(iterations: 2_000) { await ImageLoader.shared.invalidate(key: "nothing") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageLoader_decodeDownsampled_security() {
        // Decompression-bomb shape: a huge image is decoded at most 1200px.
        let big = UIGraphicsImageRenderer(size: CGSize(width: 6_000, height: 6_000), format: {
            let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }()).image { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 6_000, height: 6_000)) }.jpegData(compressionQuality: 0.5)!
        let img = ImageLoader.decodeDownsampled(big)
        XCTAssertNotNil(img)
        XCTAssertLessThanOrEqual(max(img!.size.width, img!.size.height) * img!.scale, 1_200)
        XCTAssertNil(ImageLoader.decodeDownsampled(Data("GIF89a-not-really".utf8)))
    }

    func test_ImageLoader_decodeDownsampled_performance() {
        let data = jpeg(2_000, 2_000)
        let t = elapsedSync(iterations: 10) { _ = ImageLoader.decodeDownsampled(data) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_ImageLoader_fileURL_security() {
        // Keys are hashed: "../" in a key can't escape the cache directory.
        let url = ImageLoader.fileURL(for: "../../../../etc/passwd")
        XCTAssertFalse(url.path.contains(".."))
        XCTAssertTrue(url.path.contains("/ImageCache/"))
        XCTAssertEqual(url.lastPathComponent.count, 64, "SHA-256 hex")
    }

    func test_ImageLoader_fileURL_performance() {
        let t = elapsedSync(iterations: 50_000) { _ = ImageLoader.fileURL(for: "avatars/abc.jpg") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ImageLoader_trimDiskIfNeeded_security() async {
        // Runs once per launch (guarded) — repeated calls can't storm the disk.
        await ImageLoader.shared.trimDiskIfNeeded()
        let trimmed = await ImageLoader.shared.didTrimDisk
        XCTAssertTrue(trimmed, "guard set after the first pass; later calls return immediately")
    }

    func test_ImageLoader_trimDiskIfNeeded_performance() async {
        let t = await elapsed(iterations: 10_000) { await ImageLoader.shared.trimDiskIfNeeded() }
        XCTAssertLessThan(t, 2.0, "guarded no-op after the first: \(t)s")
    }

    // MARK: - PushNotificationService

    func test_PushNotificationService_requestPermission_security() async {
        backend.notifications.granted = false
        let granted = await PushNotificationService.requestPermission()
        XCTAssertFalse(granted)
    }

    func test_PushNotificationService_requestPermission_performance() async {
        let t = await elapsed(iterations: 5_000) { _ = await PushNotificationService.requestPermission() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_PushNotificationService_notificationSafe_security() {
        XCTAssertEqual(PushNotificationService.notificationSafe("Rave\nBank: tap to verify"), "Rave Bank: tap to verify", "one line")
        XCTAssertEqual(PushNotificationService.notificationSafe("   "), "Your event")
        XCTAssertEqual(PushNotificationService.notificationSafe(String(repeating: "x", count: 500)).count, PushNotificationService.maxNameInNotification)
        XCTAssertFalse(PushNotificationService.notificationSafe("a\u{0}b\u{7}c").contains("\u{0}"))
    }

    func test_PushNotificationService_notificationSafe_performance() {
        let long = String(repeating: "Night ", count: 10_000)
        let t = elapsedSync(iterations: 50) { _ = PushNotificationService.notificationSafe(long) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_PushNotificationService_scheduleEventReminder_security() async throws {
        await PushNotificationService.scheduleEventReminder(for: Make.event("e", days: 3, name: "Rave\nFREE MONEY tap here"))
        let req = try XCTUnwrap(backend.notifications.added.last)
        XCTAssertFalse(req.content.body.contains("\n"), "host text can't add lines to the lock screen")
        XCTAssertEqual(req.identifier, "event-reminder-e")
        backend.notifications.granted = false
        await PushNotificationService.scheduleEventReminder(for: Make.event("e2", days: 3))
        XCTAssertEqual(backend.notifications.added.count, 1, "no permission → nothing scheduled")
        backend.notifications.granted = true
        await PushNotificationService.scheduleEventReminder(for: Make.event("soon", days: 0))
        XCTAssertEqual(backend.notifications.added.count, 1, "no reminder in the past")
    }

    func test_PushNotificationService_scheduleEventReminder_performance() async {
        let events = Make.many(500) { Make.event("e\($0)", days: 5) }
        let t = await elapsed { for e in events { await PushNotificationService.scheduleEventReminder(for: e) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_PushNotificationService_cancelEventReminder_security() {
        PushNotificationService.cancelEventReminder(for: "e1")
        XCTAssertEqual(backend.notifications.removed, ["event-reminder-e1"], "only that event's reminder")
    }

    func test_PushNotificationService_cancelEventReminder_performance() {
        let t = elapsedSync(iterations: 50_000) { PushNotificationService.cancelEventReminder(for: "e") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_PushNotificationService_clearBadge_security() async {
        await PushNotificationService.clearBadge()
        XCTAssertEqual(backend.notifications.badge, 0)
    }

    func test_PushNotificationService_clearBadge_performance() async {
        let t = await elapsed(iterations: 10_000) { await PushNotificationService.clearBadge() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - DataStoreClient default query

    func test_DataStoreClient_query_security() async throws {
        // `query(T.self)` is an unfiltered read of THAT type only.
        db.seed([Make.user("u")]); db.seed([Make.event("e")])
        let users: [User] = try await Backend.dataStore.query(User.self)
        XCTAssertEqual(users.map(\.id), ["u"])
    }

    func test_DataStoreClient_query_performance() async throws {
        db.seed(Make.many(10_000) { Make.user("u\($0)") })
        let t = try await elapsed { _ = try await Backend.dataStore.query(User.self) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - Transitions

    func test_AnyTransition_popover_security() {
        // Non-finite anchors are replaced, never put into a transform.
        XCTAssertEqual(Motion.sanitizedAnchor(UnitPoint(x: .nan, y: 0.5)), .center)
        XCTAssertEqual(Motion.sanitizedAnchor(UnitPoint(x: 0, y: .infinity)), .center)
        XCTAssertEqual(Motion.sanitizedAnchor(.bottomLeading), .bottomLeading)
        _ = AnyTransition.popover(anchor: UnitPoint(x: .nan, y: .infinity))   // and it builds
    }

    func test_AnyTransition_popover_performance() {
        let t = elapsedSync(iterations: 100_000) { _ = AnyTransition.popover(anchor: .topTrailing) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_AnyTransition_edgeReveal_security() {
        // Exits never linger longer than entrances (a panel the user dismissed
        // must get out of the way), and timings are sane.
        let d = Motion.edgeRevealDurations
        XCTAssertLessThan(d.exit, d.enter)
        XCTAssertTrue(d.enter > 0 && d.enter < 0.3)
        for edge in Edge.allCases { _ = AnyTransition.edgeReveal(edge) }
    }

    func test_AnyTransition_edgeReveal_performance() {
        let t = elapsedSync(iterations: 100_000) { _ = AnyTransition.edgeReveal(.bottom) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - ChatPanelView gesture rules

    func test_ChatPanelView_axis_security() {
        // The left 30pt belong to the system back-swipe: never captured.
        XCTAssertEqual(ChatPanelView.axis(start: CGPoint(x: 29, y: 0), translation: CGSize(width: 300, height: 0)), .vertical)
        XCTAssertEqual(ChatPanelView.axis(start: CGPoint(x: 200, y: 0), translation: CGSize(width: CGFloat.nan, height: 0)), .vertical, "NaN never locks horizontal")
    }

    func test_ChatPanelView_axis_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = ChatPanelView.axis(start: CGPoint(x: 200, y: 0), translation: CGSize(width: 40, height: 3)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatPanelView_track_security() {
        let d = ChatPanelView.track(.init(), start: CGPoint(x: 200, y: 0), translation: CGSize(width: 1e12, height: 0), panelWidth: 390)
        XCTAssertTrue(d.offset.isFinite)
        XCTAssertLessThanOrEqual(d.offset, 390 * 2, "a wild drag stays near the panel, rubber-banded")
    }

    func test_ChatPanelView_track_performance() {
        var d = ChatPanelView.CloseDrag()
        let t = elapsedSync(iterations: 1_000_000) {
            d = ChatPanelView.track(d, start: CGPoint(x: 200, y: 0), translation: CGSize(width: 120, height: 4), panelWidth: 390)
        }
        XCTAssertLessThan(t, 2.0, "per-frame tracking ×1M: \(t)s")
    }

    func test_ChatPanelView_closes_security() {
        XCTAssertFalse(ChatPanelView.closes(start: CGPoint(x: 200, y: 0), translation: CGSize(width: CGFloat.nan, height: 0),
                                            predicted: CGSize(width: CGFloat.nan, height: 0), panelWidth: 390), "garbage input never closes")
    }

    func test_ChatPanelView_closes_performance() {
        let t = elapsedSync(iterations: 1_000_000) {
            _ = ChatPanelView.closes(start: CGPoint(x: 200, y: 0), translation: CGSize(width: 90, height: 2),
                                     predicted: CGSize(width: 200, height: 2), panelWidth: 390)
        }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }
}
