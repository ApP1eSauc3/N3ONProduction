// RESTTransportSecPerfTests.swift
// N3ONTests
//
// AmplifyRESTTransport.lambdaBody: which thrown errors carry a Lambda reply.

import XCTest
import Amplify
@testable import AWSAPIPlugin
@testable import N3ON

final class RESTTransportSecPerfTests: XCTestCase {

    private func statusError(_ code: Int, body: Data?) -> APIError {
        let http = HTTPURLResponse(url: URL(string: "https://api.example/x")!, statusCode: code, httpVersion: "1.1", headerFields: nil)!
        return .httpStatusError(code, AWSHTTPURLResponse(response: http, body: body)!)
    }

    func test_AmplifyRESTTransport_lambdaBody_security() {
        let reply = Data(#"{"success":false,"errorCode":"SOLD_OUT"}"#.utf8)
        XCTAssertEqual(AmplifyRESTTransport.lambdaBody(from: statusError(409, body: reply)), reply)
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: APIError.networkError("offline", nil, URLError(.notConnectedToInternet))),
                     "network failures stay errors, never decoded as a reply")
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: statusError(403, body: nil)))
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: statusError(403, body: Data())))
        let plain = HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: APIError.httpStatusError(500, plain)), "no body, no reply")
        let huge = Data(count: AmplifyRESTTransport.maxErrorBodyBytes + 1)
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: statusError(502, body: huge)), "a proxy's HTML page is not a Lambda reply")
        XCTAssertNil(AmplifyRESTTransport.lambdaBody(from: CancellationError()))
    }

    func test_AmplifyRESTTransport_lambdaBody_performance() {
        let err = statusError(409, body: Data(#"{"success":false,"errorCode":"SOLD_OUT"}"#.utf8))
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<200_000 { _ = AmplifyRESTTransport.lambdaBody(from: err) }
        let t = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }
}
