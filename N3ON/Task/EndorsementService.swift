// EndorsementService.swift
// N3ON — Task layer
//
// Manages DJ-to-DJ endorsement requests for rank promotion.
//
// Flow:
//   1. Candidate DJ (rank N) calls eligibleEndorsers(targetRank: N+1)
//      → Returns DJs of rank N+1 who shared an event with the candidate via EventDJLink.
//   2. Candidate sends one request per endorser via requestEndorsement(toUserID:targetRank:message:).
//   3. Senior DJ sees incoming requests via pendingIncoming(for:) and calls accept/decline.
//   4. Once approvedCount(for:targetRank:) == requiredEndorsements(forTargetRank:),
//      a Lambda (rankPromotion) detects the threshold and updates User.djRank.
//   5. Demotion is also Lambda-driven: after an event, if the event underperforms,
//      the Lambda demotes the DJ and resets endorsements for that rank.
//
// NOTE: EndorsementRequest.targetRank requires schema.graphql to include:
//   targetRank: Int!
// followed by `amplify push && amplify codegen models` before this file compiles.

import Foundation
import Amplify

enum EndorsementService {

    // MARK: — Constants

    /// Minimum accepted endorsements required to promote from (targetRank - 1) → targetRank.
    static func requiredEndorsements(forTargetRank rank: Int) -> Int {
        rank >= 4 ? 3 : 2
    }

    // MARK: — Eligible endorsers

    /// Returns DJs who (a) hold `targetRank` and (b) have shared at least one event with `userID`
    /// via EventDJLink. These are the only DJs whose endorsement counts toward promotion.
    static func eligibleEndorsers(for userID: String, targetRank: Int) async -> [User] {
        // Step 1: event IDs the candidate has participated in
        let myLinks = (try? await Amplify.DataStore.query(
            EventDJLink.self,
            where: EventDJLink.keys.djID == userID
        )) ?? []
        let myEventIDs = Set(myLinks.compactMap { $0.event?.id })
        guard !myEventIDs.isEmpty else { return [] }

        // Step 2: all EventDJLinks across the entire platform, filtered to shared events
        let allLinks = (try? await Amplify.DataStore.query(EventDJLink.self)) ?? []
        let sharedDJIDs = Set(
            allLinks
                .filter { myEventIDs.contains($0.event?.id ?? "") && $0.djID != userID }
                .map { $0.djID }
        )
        guard !sharedDJIDs.isEmpty else { return [] }

        // Step 3: resolve User records and filter to targetRank
        let allUsers = (try? await Amplify.DataStore.query(User.self)) ?? []
        return allUsers.filter { sharedDJIDs.contains($0.id) && ($0.djRank ?? 0) == targetRank }
    }

    // MARK: — Send request

    /// Creates an endorsement request from the current user to a senior DJ.
    /// Validates that the recipient actually holds `targetRank` before saving.
    static func requestEndorsement(
        toUserID: String,
        targetRank: Int,
        message: String
    ) async throws {
        let fromUser = try await AuthService.getCurrentUserModel()
        guard let from = fromUser else { throw EndorsementError.senderNotFound }
        guard let toUser = try await Amplify.DataStore.query(User.self, byId: toUserID)
        else { throw EndorsementError.recipientNotFound }
        guard (toUser.djRank ?? 0) == targetRank
        else { throw EndorsementError.rankMismatch }

        let request = EndorsementRequest(
            fromUser: from,
            toUser: toUser,
            targetRank: targetRank,
            message: message,
            status: "pending",
            timestamp: Temporal.DateTime(Date(), timeZone: .current)
        )
        try await Amplify.DataStore.save(request)
    }

    // MARK: — Accept / Decline (called by the senior DJ)

    static func acceptRequest(id: String) async throws {
        guard var req = try await Amplify.DataStore.query(EndorsementRequest.self, byId: id)
        else { throw EndorsementError.notFound }
        req.status = "approved"
        try await Amplify.DataStore.save(req)
    }

    static func declineRequest(id: String) async throws {
        guard var req = try await Amplify.DataStore.query(EndorsementRequest.self, byId: id)
        else { throw EndorsementError.notFound }
        req.status = "rejected"
        try await Amplify.DataStore.save(req)
    }

    // MARK: — Queries

    /// Incoming pending requests for a senior DJ to review.
    static func pendingIncoming(for userID: String) async throws ->
      [EndorsementRequest] {
          let all = try await Amplify.DataStore.query(
              EndorsementRequest.self,
              where: EndorsementRequest.keys.toUser == userID
          )
          print("🔍 pendingIncoming — userID: \(userID), total fetched: \(all.count)")
          return all
              .filter { $0.status == "pending" }
              .sorted { $0.timestamp.foundationDate > $1.timestamp.foundationDate }
      }

    /// All requests sent by `userID` for a specific target rank, sorted newest first.
    static func sentRequests(by userID: String, targetRank: Int) async throws -> [EndorsementRequest] {
        let all = try await Amplify.DataStore.query(
            EndorsementRequest.self,
            where: EndorsementRequest.keys.fromUser == userID
        )
        return all
            .filter { $0.targetRank == targetRank }
            .sorted { $0.timestamp.foundationDate > $1.timestamp.foundationDate }
    }

    /// Count of approved endorsements the candidate has for a specific target rank.
    static func approvedCount(for userID: String, targetRank: Int) async -> Int {
        let sent = (try? await Amplify.DataStore.query(
            EndorsementRequest.self,
            where: EndorsementRequest.keys.fromUser == userID
        )) ?? []
        return sent.filter { $0.status == "approved" && $0.targetRank == targetRank }.count
    }
}

// MARK: — Errors

enum EndorsementError: LocalizedError {
    case senderNotFound
    case recipientNotFound
    case rankMismatch
    case notFound

    var errorDescription: String? {
        switch self {
        case .senderNotFound:    return "Could not identify your account."
        case .recipientNotFound: return "The DJ you selected could not be found."
        case .rankMismatch:      return "This DJ is not the right rank to endorse your promotion."
        case .notFound:          return "Endorsement request not found."
        }
    }
}
