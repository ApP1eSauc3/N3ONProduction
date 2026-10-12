// JoinLineupError.swift
// N3ON — Data layer
//
// Failure cases of POST /events/join (amplify/backend/function/joinEvent).
// `init(errorCode:)` maps the Lambda's machine-readable `errorCode` field.

import Foundation

enum JoinLineupError: LocalizedError, Equatable {
    case eventNotFound
    case eventNotOpen
    case notADJ
    case notInvited
    case serverError(String)

    init(errorCode: String?) {
        switch errorCode {
        case "EVENT_NOT_FOUND": self = .eventNotFound
        case "EVENT_NOT_OPEN":  self = .eventNotOpen
        case "NOT_A_DJ":        self = .notADJ
        case "NOT_INVITED":     self = .notInvited
        default:                self = .serverError(errorCode ?? "Unknown")
        }
    }

    var errorDescription: String? {
        switch self {
        case .eventNotFound:       return "This event no longer exists."
        case .eventNotOpen:        return "This lineup is closed."
        case .notADJ:              return "Only DJs can join a lineup."
        case .notInvited:          return "You need an invite from the host to join."
        case .serverError(let m):  return "Couldn't join the lineup: \(m)"
        }
    }
}
