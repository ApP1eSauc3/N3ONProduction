// AuthServiceSignUpTests.swift
// N3ONTests
//
// The user pool signs in by email (UsernameAttributes: [email]) and requires the
// `name` attribute. Sending the handle as the Cognito username, or omitting
// `name`, makes Cognito reject every sign-up — so the request shape is pinned here.

import XCTest
import Amplify
@testable import N3ON

final class AuthServiceSignUpTests: XCTestCase {

    func testUsernameIsTheEmailNotTheHandle() {
        let request = AuthService.signUpRequest(handle: "djA", email: "a@example.com")
        XCTAssertEqual(request.username, "a@example.com")
    }

    func testSendsEmailAndRequiredNameAttribute() {
        let request = AuthService.signUpRequest(handle: " djA ", email: "a@example.com")
        let values = Dictionary(uniqueKeysWithValues: request.attributes.map { ($0.key, $0.value) })
        XCTAssertEqual(values[.email], "a@example.com")
        XCTAssertEqual(values[.name], "djA")
        XCTAssertEqual(request.attributes.count, 2)
    }

    func testEmailIsNormalisedSoOneAddressMapsToOneAccount() {
        XCTAssertEqual(AuthService.cognitoUsername("  Liam+N3ON-A@Gmail.com \n"), "liam+n3on-a@gmail.com")
        let request = AuthService.signUpRequest(handle: "djA", email: " A@Example.com ")
        XCTAssertEqual(request.username, "a@example.com")
        XCTAssertEqual(request.attributes.first { $0.key == .email }?.value, "a@example.com")
    }
}
