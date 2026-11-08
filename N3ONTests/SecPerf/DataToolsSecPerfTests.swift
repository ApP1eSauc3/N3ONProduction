// DataToolsSecPerfTests.swift
// N3ONTests
//
// One security and one performance test per function in Data/ and Tools/
// (scripts/check-function-tests.py enforces the pairing).
//
// Security tests feed hostile or malformed input (OWASP MASVS-CODE: input
// validation; MASVS-STORAGE: no credentials persisted) and assert the function
// fails closed. Performance tests run a bulk workload under a wall-clock budget
// with ~10–50x headroom — loose enough not to flake on CI, tight enough to
// catch an accidental O(n²) or per-call allocation of an expensive resource.

import XCTest
import UIKit
import SwiftUI
@testable import N3ON

final class DataToolsSecPerfTests: BackendTestCase {

    private func user(avatarKey: String?) -> User {
        User(id: "u", username: "u", avatarKey: avatarKey, isDJ: false, isCurated: false,
             isSharingLocation: false, coinBalance: 0)
    }

    // MARK: - AvatarState

    func test_AvatarState_fromUser_security() {
        // A stored signed URL (never allowed) must not be used as a key.
        let signed = "https://bucket.s3.amazonaws.com/public/avatars/u.jpg?X-Amz-Signature=abc"
        XCTAssertEqual(AvatarState.fromUser(user(avatarKey: signed)), .remote(avatarKey: "default-avatar"))
        XCTAssertEqual(AvatarState.fromUser(user(avatarKey: "")), .remote(avatarKey: "default-avatar"))
        XCTAssertEqual(AvatarState.fromUser(user(avatarKey: nil)), .remote(avatarKey: "default-avatar"))
        XCTAssertEqual(AvatarState.fromUser(user(avatarKey: "avatars/u.jpg")), .remote(avatarKey: "avatars/u.jpg"))
    }

    func test_AvatarState_fromUser_performance() {
        let u = user(avatarKey: "avatars/u.jpg")
        let t = elapsedSync(iterations: 100_000) { _ = AvatarState.fromUser(u) }
        XCTAssertLessThan(t, 1.0, "100k avatar resolutions: \(t)s")
    }

    func test_AvatarState_isStorageKey_security() {
        for bad in ["", "https://x/y", "s3://bucket/key", "avatars/u.jpg?X-Amz-Credential=AKIA", "file:///etc/passwd"] {
            XCTAssertFalse(AvatarState.isStorageKey(bad), bad)
        }
        XCTAssertTrue(AvatarState.isStorageKey("avatars/7f3c.jpg"))
    }

    func test_AvatarState_isStorageKey_performance() {
        // Found by this test: an unbounded key made each check ~0.6ms (bridged
        // String.contains over 10k chars). Over-long keys now fail in O(1).
        let hostile = String(repeating: "a", count: 10_000)
        let real = "avatars/" + UUID().uuidString + ".jpg"
        let t = elapsedSync(iterations: 10_000) {
            _ = AvatarState.isStorageKey(hostile)
            _ = AvatarState.isStorageKey(real)
        }
        XCTAssertLessThan(t, 1.0, "10k hostile + 10k real keys: \(t)s")
        XCTAssertFalse(AvatarState.isStorageKey(hostile), "longer than S3 allows")
    }

    func test_AvatarState_toAmplifyValue_security() {
        // A local (unsaved) image must never be written as a key.
        XCTAssertNil(AvatarState.local(image: UIImage()).toAmplifyValue())
        XCTAssertEqual(AvatarState.remote(avatarKey: "avatars/u.jpg").toAmplifyValue(), "avatars/u.jpg")
    }

    func test_AvatarState_toAmplifyValue_performance() {
        let s = AvatarState.remote(avatarKey: "avatars/u.jpg")
        let t = elapsedSync(iterations: 200_000) { _ = s.toAmplifyValue() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - EventInvitePayload

    func test_EventInvitePayload_parse_security() {
        // Not an invite, wrong type, empty event, malformed, oversized: all nil.
        XCTAssertNil(EventInvitePayload.parse("hello"))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"other","eventID":"e","eventName":"","venueName":"","eventDate":""}"#))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"event_invite","eventID":"","eventName":"","venueName":"","eventDate":""}"#))
        XCTAssertNil(EventInvitePayload.parse(#"{"type":"event_invite","eventID":"#))
        let padding = String(repeating: "x", count: EventInvitePayload.maxEncodedBytes)
        let huge = #"{"type":"event_invite","eventID":"e","eventName":"\#(padding)","venueName":"v","eventDate":"2027-01-01T00:00:00Z"}"#
        XCTAssertNil(EventInvitePayload.parse(huge), "oversized content is not decoded")
        // A genuine invite still parses.
        let ok = EventInvitePayload(eventID: "e1", eventName: "N", venueName: "V", eventDate: Date())
        XCTAssertEqual(EventInvitePayload.parse(ok.encodedContent()!), ok)
    }

    func test_EventInvitePayload_parse_performance() {
        // Chat rows call parse on every message: plain text must short-circuit.
        let text = String(repeating: "hey ", count: 200)
        let invite = EventInvitePayload(eventID: "e1", eventName: "N", venueName: "V", eventDate: Date()).encodedContent()!
        let t = elapsedSync(iterations: 20_000) {
            _ = EventInvitePayload.parse(text)
            _ = EventInvitePayload.parse(invite)
        }
        XCTAssertLessThan(t, 2.0, "20k text + 20k invite parses: \(t)s")
    }

    func test_EventInvitePayload_encodedContent_security() {
        // Hostile names stay inside JSON strings — no breaking out into new keys.
        let p = EventInvitePayload(eventID: "e1", eventName: #"","type":"pwn"#, venueName: "\u{0}\n", eventDate: Date())
        let json = p.encodedContent()!
        XCTAssertEqual(EventInvitePayload.parse(json)?.eventName, #"","type":"pwn"#)
        XCTAssertEqual(EventInvitePayload.parse(json)?.type, EventInvitePayload.messageType)
    }

    func test_EventInvitePayload_encodedContent_performance() {
        let p = EventInvitePayload(eventID: "e1", eventName: "Warehouse", venueName: "Benga Box", eventDate: Date())
        let t = elapsedSync(iterations: 20_000) { _ = p.encodedContent() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - RankWeight

    func test_RankWeight_coins_security() {
        // Out-of-range ranks (corrupt data) can't mint extra tally weight.
        XCTAssertEqual(RankWeight.coins(forRank: Int.max), 25)
        XCTAssertEqual(RankWeight.coins(forRank: Int.min), 0)
        XCTAssertTrue((-1_000...1_000).allSatisfy { (0...25).contains(RankWeight.coins(forRank: $0)) })
    }

    func test_RankWeight_coins_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = RankWeight.coins(forRank: 3) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - Motion

    func test_Motion_exitDuration_security() {
        XCTAssertEqual(Motion.exitDuration(for: -5), 0)
        XCTAssertEqual(Motion.exitDuration(for: .nan), 0)
        XCTAssertEqual(Motion.exitDuration(for: .infinity), 0)
    }

    func test_Motion_exitDuration_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.exitDuration(for: 0.25) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_safeDuration_security() {
        XCTAssertEqual(Motion.safeDuration(.nan), 0)
        XCTAssertEqual(Motion.safeDuration(-.infinity), 0)
        XCTAssertEqual(Motion.safeDuration(-1), 0)
        XCTAssertEqual(Motion.safeDuration(0.2), 0.2)
    }

    func test_Motion_safeDuration_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.safeDuration(0.2) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_staggerDelay_security() {
        // A huge list can't make a row wait forever (UI lock-out), nor negative.
        XCTAssertEqual(Motion.staggerDelay(for: Int.max), Motion.staggerDelay(for: Motion.staggerCap))
        XCTAssertEqual(Motion.staggerDelay(for: Int.min), 0)
    }

    func test_Motion_staggerDelay_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.staggerDelay(for: 7) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_enter_security() {
        // Non-finite durations are sanitised before reaching CoreAnimation.
        XCTAssertEqual(Motion.enter(.nan), Motion.enter(0))
        XCTAssertEqual(Motion.enter(-3), Motion.enter(0))
    }

    func test_Motion_enter_performance() {
        let t = elapsedSync(iterations: 200_000) { _ = Motion.enter() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_exit_security() {
        XCTAssertEqual(Motion.exit(.nan), Motion.exit(0))
        XCTAssertEqual(Motion.exit(-1), Motion.exit(0))
    }

    func test_Motion_exit_performance() {
        let t = elapsedSync(iterations: 200_000) { _ = Motion.exit() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_move_security() {
        XCTAssertEqual(Motion.move(.infinity), Motion.move(0))
        XCTAssertEqual(Motion.move(-0.3), Motion.move(0))
    }

    func test_Motion_move_performance() {
        let t = elapsedSync(iterations: 200_000) { _ = Motion.move() }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_Motion_rubberBand_security() {
        XCTAssertEqual(Motion.rubberBand(.nan, dimension: 300), 0, "NaN never reaches layout")
        XCTAssertEqual(Motion.rubberBand(.infinity, dimension: 300), 300)
        XCTAssertEqual(Motion.rubberBand(-.infinity, dimension: 300), -300)
        XCTAssertEqual(Motion.rubberBand(50, dimension: .nan), 0)
        XCTAssertEqual(Motion.rubberBand(50, dimension: -10), 0)
    }

    func test_Motion_rubberBand_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.rubberBand(123, dimension: 390) }
        XCTAssertLessThan(t, 1.0, "per-frame drag maths ×1M: \(t)s")
    }

    func test_Motion_rubberBanded_security() {
        XCTAssertEqual(Motion.rubberBanded(.nan, in: -300...0, dimension: 300), 0)
        XCTAssertEqual(Motion.rubberBanded(.nan, in: 10...20, dimension: 300), 10)
        XCTAssertTrue(Motion.rubberBanded(.infinity, in: 0...390, dimension: 390).isFinite)
    }

    func test_Motion_rubberBanded_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.rubberBanded(-420, in: -390...0, dimension: 390) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - StretchEffect

    func test_StretchEffect_scale_security() {
        // Any progress value keeps the stretch within [1, 1 + amount].
        for p in [-1e9, -0.5, 0.25, 1e9, Double.greatestFiniteMagnitude] {
            let s = StretchEffect.scale(progress: p, amount: 0.12)
            XCTAssertTrue((1.0...1.12 + 1e-9).contains(Double(s)), "\(p) → \(s)")
        }
    }

    func test_StretchEffect_scale_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = StretchEffect.scale(progress: 3.3, amount: 0.12) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    func test_StretchEffect_effectValue_security() {
        // Zero-size and huge sizes produce finite transforms.
        let e = StretchEffect(progress: 0.5, amount: 0.12)
        for size in [CGSize.zero, CGSize(width: 1e9, height: 1e9)] {
            let t = e.effectValue(size: size)
            XCTAssertTrue([t.m11, t.m31, t.m22].allSatisfy(\.isFinite))
        }
        XCTAssertEqual(e.effectValue(size: CGSize(width: 100, height: 2)).m22, 1, "never stretches vertically")
    }

    func test_StretchEffect_effectValue_performance() {
        let e = StretchEffect(progress: 0.5, amount: 0.12)
        let t = elapsedSync(iterations: 200_000) { _ = e.effectValue(size: CGSize(width: 120, height: 2)) }
        XCTAssertLessThan(t, 1.0, "\(t)s")
    }

    // MARK: - QRCodeGenerator

    func test_QRCodeGenerator_make_security() {
        // A hostile size can't allocate a gigapixel bitmap.
        let huge = QRCodeGenerator.make(from: "user-id", size: 1_000_000)
        XCTAssertNotNil(huge)
        XCTAssertLessThanOrEqual(huge!.size.width, QRCodeGenerator.sizeRange.upperBound + 1)
        XCTAssertNotNil(QRCodeGenerator.make(from: "x", size: .nan))
        XCTAssertNil(QRCodeGenerator.make(from: "émoji 🎧"), "non-ASCII is refused, not mangled")
    }

    func test_QRCodeGenerator_make_performance() {
        // Shared CIContext: 50 codes well under a second.
        let t = elapsedSync(iterations: 50) { _ = QRCodeGenerator.make(from: UUID().uuidString) }
        XCTAssertLessThan(t, 3.0, "50 QR codes: \(t)s")
    }
}
