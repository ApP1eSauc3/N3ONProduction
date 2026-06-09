// AccessControlService.swift
// N3ON
// Task layer — calls Amplify.Auth to resolve the current user's Cognito groups.

import Foundation
import Amplify
import AWSPluginsCore

struct AccessControlService {
    /// Returns the single role for the current signed-in user.
    /// Roles are mutually exclusive — a user holds exactly one Cognito group at a time.
    /// Priority: .venue → .dj → .regular. Falls back to .regular on any failure.
    static func currentUserRole() async -> AppRole {
        let resolved = await currentGroups().compactMap(AppRole.init(rawValue:))
        if resolved.contains(.venue) { return .venue }
        if resolved.contains(.dj)    { return .dj }
        return .regular
    }

    /// True when the signed-in user belongs to the `AdminUser` Cognito group.
    /// Admin is an **orthogonal capability**, not an `AppRole` — an admin who is
    /// also a DJ/regular keeps their normal role and UI. Bootstrap/curation gates
    /// read this via `CurationService`. Falls back to `false` on any failure.
    static func isAdmin() async -> Bool {
        await currentGroups().contains("AdminUser")
    }

    /// Decodes the `cognito:groups` claim from the current id token.
    /// Returns `[]` on any failure (no session, malformed token, missing claim).
    /// Shared by `currentUserRole()` and `isAdmin()` so JWT decoding lives in one place.
    private static func currentGroups() async -> [String] {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let provider = session as? AuthCognitoTokensProvider else { return [] }
            let idToken: String
            do { idToken = try provider.getCognitoTokens().get().idToken }
            catch { return [] }
            guard let payload = decodeJWT(idToken),
                  let groups = payload["cognito:groups"] as? [String]
            else { return [] }
            return groups
        } catch { return [] }
    }

    /// Returns true when the given userID holds at least one ticket for the event.
    /// Called by TicketScannerView after reading the attendee's QR code.
    static func validateTicket(userID: String, eventID: String) async -> Bool {
        let tickets = (try? await Amplify.DataStore.query(
            Ticket.self,
            where: Ticket.keys.eventID == eventID
        )) ?? []
        return tickets.contains { $0.userID == userID }
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
