//
//  AppRole.swift
//  N3ON
//
//  Created by liam howe on 21/8/2025.
//

import Foundation
import Amplify
import AWSPluginsCore


enum AppRole: String {
    case dj = "DJUser"
    case venue = "VenueOwnerUser"
    case regular = "UserGroup"
}

struct AccessControlService {
    // why: single source of truth for roles; used by VM
    static func currentUserRoles() async -> Set<AppRole> {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let provider = session as? AuthCognitoTokensProvider else { return [] }
            // Split into own guard — multi-condition guard can't resolve associated value type
            guard case .success(let tokens) = provider.getCognitoTokens() else { return [] }
            guard let payload = Self.decodeJWT(tokens.idToken),
                  let groups = payload["cognito:groups"] as? [String]
            else { return [] }
            return Set(groups.compactMap(AppRole.init(rawValue:)))
        } catch { return [] }
    }

    // why: AuthCognitoTokens.idToken is a raw JWT string — no structured payload API in AWSPluginsCore
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
