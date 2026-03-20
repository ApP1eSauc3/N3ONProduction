// AccessControlService.swift
// N3ON
// Task layer — calls Amplify.Auth to resolve the current user's Cognito groups.

import Foundation
import Amplify
import AWSPluginsCore

struct AccessControlService {
    /// Returns the set of roles the current signed-in user belongs to.
    /// Returns an empty set if the session is absent or the token cannot be decoded.
    static func currentUserRoles() async -> Set<AppRole> {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let provider = session as? AuthCognitoTokensProvider else { return [] }
            // Result.get() avoids existential pattern-match ambiguity (see Task/CLAUDE.md)
            let idToken: String
            do { idToken = try provider.getCognitoTokens().get().idToken }
            catch { return [] }
            guard let payload = decodeJWT(idToken),
                  let groups = payload["cognito:groups"] as? [String]
            else { return [] }
            return Set(groups.compactMap(AppRole.init(rawValue:)))
        } catch { return [] }
    }

    // AuthCognitoTokens.idToken is a raw JWT string — no structured payload API in AWSPluginsCore.
    private static func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = base64.count % 4
        if pad > 0 { base64 += String(repeating: "=", count: 4 - pad) }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
