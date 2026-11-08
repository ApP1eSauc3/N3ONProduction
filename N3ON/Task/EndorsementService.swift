// EndorsementService.swift
// N3ON — Task layer
//
// Manages DJ-to-DJ endorsement requests for rank promotion.
//
// Flow:
//   1. Candidate DJ (rank N) calls eligibleEndorsers(targetRank: N+1)
//      → Returns DJs of rank ≥ N+1 who shared an event with the candidate via EventDJLink.
//   2. Candidate sends one request per endorser via requestEndorsement(toUserID:targetRank:message:).
//   3. Senior DJ sees incoming requests via pendingIncoming(for:) and calls accept/decline.
//   4. Once enough distinct endorsers approve (requiredEndorsements(forTargetRank:)),
//      a Lambda (rankPromotion) promotes User.djRank — as many ranks as the
//      endorsements support, one at a time. countedEndorsers mirrors its count.
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

    /// Returns DJs who (a) hold `targetRank` or higher and (b) have shared at least one event
    /// with `userID` via EventDJLink — the same rule rankPromotion applies server-side
    /// (`djRank >= target`). Offering only `== targetRank` hid senior DJs whose
    /// endorsement the server would count (LEAN-RESEARCH.md F8).
    static func eligibleEndorsers(for userID: String, targetRank: Int) async -> [User] {
        // Step 1: event IDs the candidate has participated in
        let myLinks = (try? await Backend.dataStore.query(
            EventDJLink.self,
            where: EventDJLink.keys.djID == userID
        )) ?? []
        let myEventIDs = Set(myLinks.compactMap { $0.event?.id })
        guard !myEventIDs.isEmpty else { return [] }

        // Step 2: the lineups of those events (one predicate query per event —
        // this used to load every EventDJLink on the platform)
        var sharedDJIDs = Set<String>()
        for eventID in myEventIDs {
            let lineup = (try? await Backend.dataStore.query(EventDJLink.self, where: EventDJLink.keys.event == eventID)) ?? []
            for link in lineup where link.djID != userID { sharedDJIDs.insert(link.djID) }
        }
        guard !sharedDJIDs.isEmpty else { return [] }

        // Step 3: resolve those users by id (this used to load every User)
        var endorsers: [User] = []
        for id in sharedDJIDs.sorted() {
            if let user = try? await Backend.dataStore.query(User.self, byId: id), canEndorse(user, targetRank: targetRank) {
                endorsers.append(user)
            }
        }
        return endorsers
    }

    // MARK: — Send request

    /// Creates an endorsement request from the current user to a senior DJ.
    /// Validates that the recipient actually holds `targetRank` before saving.
    static func requestEndorsement(
        toUserID: String,
        targetRank: Int,
        message: String
    ) async throws {
        guard message.count <= maxMessageLength else { throw EndorsementError.messageTooLong }
        let fromUser = try await AuthService.getCurrentUserModel()
        guard let from = fromUser else { throw EndorsementError.senderNotFound }
        guard let toUser = try await Backend.dataStore.query(User.self, byId: toUserID)
        else { throw EndorsementError.recipientNotFound }
        guard canEndorse(toUser, targetRank: targetRank), toUser.id != from.id
        else { throw EndorsementError.rankMismatch }
        // One open request per senior DJ per rank — no inbox spam.
        let mine = try await Backend.dataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.fromUser == from.id)
        guard !mine.contains(where: { $0.toUser?.id == toUserID && $0.targetRank == targetRank && $0.status != "rejected" })
        else { throw EndorsementError.alreadyRequested }

        let request = EndorsementRequest(
            fromUser: from,
            toUser: toUser,
            targetRank: targetRank,
            message: message,
            status: "pending",
            timestamp: Temporal.DateTime(Date(), timeZone: .current)
        )
        try await Backend.dataStore.save(request)
    }

    // MARK: — Accept / Decline (called by the senior DJ)

    static func acceptRequest(id: String) async throws {
        var req = try await incomingPending(id: id)
        req.status = "approved"
        try await Backend.dataStore.save(req)
    }

    static func declineRequest(id: String) async throws {
        var req = try await incomingPending(id: id)
        req.status = "rejected"
        try await Backend.dataStore.save(req)
    }

    /// A pending request addressed to the signed-in user. Anyone else's — or
    /// one already decided — reads as not found: only the recipient decides,
    /// once (the server's toUserID owner rule agrees).
    static func incomingPending(id: String) async throws -> EndorsementRequest {
        let me = try await AuthService.currentUserId()
        guard let req = try await Backend.dataStore.query(EndorsementRequest.self, byId: id),
              req.toUser?.id == me, req.status == "pending"
        else { throw EndorsementError.notFound }
        return req
    }

    /// Longest note a candidate can attach to a request.
    static let maxMessageLength = 500

    // MARK: — Queries

    /// Incoming pending requests for a senior DJ to review.
    static func pendingIncoming(for userID: String) async throws ->
      [EndorsementRequest] {
          let all = try await Backend.dataStore.query(
              EndorsementRequest.self,
              where: EndorsementRequest.keys.toUser == userID
          )
          return all
              .filter { $0.status == "pending" }
              .sorted { $0.timestamp.foundationDate > $1.timestamp.foundationDate }
      }

    /// All requests sent by `userID` for a specific target rank, sorted newest first.
    static func sentRequests(by userID: String, targetRank: Int) async throws -> [EndorsementRequest] {
        let all = try await Backend.dataStore.query(
            EndorsementRequest.self,
            where: EndorsementRequest.keys.fromUser == userID
        )
        return all
            .filter { $0.targetRank == targetRank }
            .sorted { $0.timestamp.foundationDate > $1.timestamp.foundationDate }
    }

    /// Count of approved endorsements the candidate has for a specific target rank,
    /// counted the way the server counts them (see `countedEndorsers`).
    static func approvedCount(for userID: String, targetRank: Int) async -> Int {
        let sent = (try? await Backend.dataStore.query(
            EndorsementRequest.self,
            where: EndorsementRequest.keys.fromUser == userID
        )) ?? []
        return countedEndorsers(in: sent, candidateID: userID, targetRank: targetRank)
    }

    // MARK: — Server mirror (pure)

    /// Whether `user` may endorse a promotion to `targetRank`: an active DJ at
    /// that rank or above. Mirrors rankPromotion's `isDJ` + `djRank >= target`.
    static func canEndorse(_ user: User, targetRank: Int) -> Bool {
        user.isDJ && (user.djRank ?? 0) >= targetRank
    }

    /// Distinct endorsers whose approval rankPromotion would count, as far as
    /// the client can tell. Counting raw `status == "approved"` rows overstated
    /// progress (LEAN-RESEARCH.md F8): duplicates stacked, self-endorsements
    /// counted, and a row the candidate created already approved (never
    /// touched by the recipient, so `updatedAt == createdAt`) looked genuine.
    ///
    /// The server also requires a shared event; that check needs every
    /// EventDJLink and stays server-side, so this is an upper bound on the
    /// server's count — never below it for the rows it can see.
    static func countedEndorsers(
        in requests: [EndorsementRequest],
        candidateID: String,
        targetRank: Int
    ) -> Int {
        let endorserIDs = requests.compactMap { request -> String? in
            guard request.status == "approved",
                  request.targetRank == targetRank,
                  approvedByUpdate(request),
                  let endorser = request.toUser,
                  endorser.id != candidateID,
                  canEndorse(endorser, targetRank: targetRank)
            else { return nil }
            return endorser.id
        }
        return Set(endorserIDs).count
    }

    /// Mirrors rankPromotion's `approvedByUpdate`: both timestamps are set by
    /// the AppSync resolver (absent from every input type), so a row only
    /// moves `updatedAt` past `createdAt` when someone with update rights —
    /// the recipient or an admin — writes it. Unsynced local rows have nil
    /// timestamps and do not count yet.
    static func approvedByUpdate(_ request: EndorsementRequest) -> Bool {
        guard let created = request.createdAt, let updated = request.updatedAt else { return false }
        return updated != created
    }
}

// MARK: — Errors

enum EndorsementError: LocalizedError {
    case senderNotFound
    case recipientNotFound
    case rankMismatch
    case notFound
    case messageTooLong
    case alreadyRequested

    var errorDescription: String? {
        switch self {
        case .senderNotFound:    return "Could not identify your account."
        case .recipientNotFound: return "The DJ you selected could not be found."
        case .rankMismatch:      return "This DJ is not the right rank to endorse your promotion."
        case .notFound:          return "Endorsement request not found."
        case .messageTooLong:    return "Keep your note under \(EndorsementService.maxMessageLength) characters."
        case .alreadyRequested:  return "You've already asked this DJ."
        }
    }
}
