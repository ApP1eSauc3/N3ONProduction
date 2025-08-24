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
            guard let provider = session as? AuthCognitoTokensProvider,
                  case .success(let tokens) = await Result { try await provider.getCognitoTokens() },
                  let groups = tokens.idToken.payload["cognito:groups"] as? [String]
            else { return [] }
            return Set(groups.compactMap(AppRole.init(rawValue:)))
        } catch { return [] }
    }
}
