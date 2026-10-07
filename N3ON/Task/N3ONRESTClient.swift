// N3ONRESTClient.swift
// N3ON — Task layer
//
// Single entry point for the n3onAPI REST endpoints (API Gateway → Lambda,
// IAM-signed with the signed-in user's identity-pool credentials). The caller's
// identity is derived server-side from that signature — never send a userID.
//
// Every n3onAPI Lambda replies with a JSON envelope `{ "success": Bool,
// "errorCode": String?, ... }` and uses real HTTP status codes (402/403/409…).
// Amplify throws `APIError.httpStatusError` for non-2xx responses but keeps the
// body on `AWSHTTPURLResponse.body`, so this client returns the body for both
// outcomes and lets the caller decode `errorCode`.

import Foundation
import Amplify
import AWSAPIPlugin

enum N3ONRESTClient {
    static let apiName = "n3onAPI"

    /// POSTs `json` to `path` and returns the response body, including for
    /// non-2xx replies that carry an error envelope. Throws only for transport
    /// failures or error responses without a body.
    static func post(path: String, json: [String: Any]) async throws -> Data {
        let body = try JSONSerialization.data(withJSONObject: json)
        let request = RESTRequest(
            apiName: apiName,
            path: path,
            headers: ["Content-Type": "application/json"],
            body: body
        )
        do {
            return try await Amplify.API.post(request: request)
        } catch let error as APIError {
            if case let .httpStatusError(_, response) = error,
               let awsResponse = response as? AWSHTTPURLResponse,
               let data = awsResponse.body {
                return data
            }
            throw error
        }
    }
}

/// The shared response envelope. Endpoint-specific fields are decoded by the
/// caller's own `Decodable` type.
struct N3ONAPIEnvelope: Decodable {
    let success: Bool
    let errorCode: String?
}
