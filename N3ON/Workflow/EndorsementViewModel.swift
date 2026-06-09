// EndorsementViewModel.swift
// N3ON — Workflow layer
// Drives EndorsementProgressView (candidate view) and EndorsementInboxView (senior DJ view).

import Foundation
import Amplify

@MainActor
final class EndorsementViewModel: ObservableObject {

    // MARK: — Candidate state (requesting endorsements)
    @Published var sentRequests: [EndorsementRequest] = []
    @Published var eligibleEndorsers: [User] = []
    @Published var isLoadingProgress = false
    @Published var isLoadingEndorsers = false
    @Published var isSending = false
    @Published var sendError: String?
    @Published var didSend = false

    // MARK: — Senior DJ state (incoming requests)
    @Published var incomingRequests: [EndorsementRequest] = []
    @Published var isLoadingInbox = false
    @Published var actionError: String?

    // MARK: — Rank context (set by caller)
    var currentRank: Int = 0

    var targetRank: Int { currentRank + 1 }
    var required: Int { EndorsementService.requiredEndorsements(forTargetRank: targetRank) }

    var approvedCount: Int {
        sentRequests.filter { $0.status == "approved" && $0.targetRank == targetRank }.count
    }

    var pendingCount: Int {
        sentRequests.filter { $0.status == "pending" && $0.targetRank == targetRank }.count
    }

    var progressFraction: Double {
        guard required > 0 else { return 0 }
        return min(Double(approvedCount) / Double(required), 1.0)
    }

    var isEligibleToPromote: Bool { approvedCount >= required }

    // MARK: — Load candidate progress

    func loadProgress(userID: String) async {
        isLoadingProgress = true
        defer { isLoadingProgress = false }
        sentRequests = (try? await EndorsementService.sentRequests(by: userID, targetRank: targetRank)) ?? []
    }

    // MARK: — Load eligible endorsers (lazy — only when user taps "Request")

    func loadEligibleEndorsers(userID: String) async {
        isLoadingEndorsers = true
        defer { isLoadingEndorsers = false }
        eligibleEndorsers = await EndorsementService.eligibleEndorsers(for: userID, targetRank: targetRank)
    }

    // MARK: — Send request

    func sendRequest(toUserID: String, message: String) async {
        isSending = true
        sendError = nil
        defer { isSending = false }
        do {
            try await EndorsementService.requestEndorsement(
                toUserID: toUserID,
                targetRank: targetRank,
                message: message
            )
            didSend = true
            // Refresh sent list
            if let myID = await AuthService.currentUserIdOrNil() {
                sentRequests = (try? await EndorsementService.sentRequests(by: myID, targetRank: targetRank)) ?? []
            }
        } catch {
            sendError = error.localizedDescription
        }
    }

    // MARK: — Load inbox (senior DJ)

    func loadInbox(userID: String) async {
        isLoadingInbox = true
        defer { isLoadingInbox = false }
        incomingRequests = (try? await EndorsementService.pendingIncoming(for: userID)) ?? []
    }

    // MARK: — Accept / Decline

    func accept(request: EndorsementRequest) async {
        actionError = nil
        do {
            try await EndorsementService.acceptRequest(id: request.id)
            incomingRequests.removeAll { $0.id == request.id }
        } catch {
            actionError = error.localizedDescription
        }
    }

    func decline(request: EndorsementRequest) async {
        actionError = nil
        do {
            try await EndorsementService.declineRequest(id: request.id)
            incomingRequests.removeAll { $0.id == request.id }
        } catch {
            actionError = error.localizedDescription
        }
    }
}
