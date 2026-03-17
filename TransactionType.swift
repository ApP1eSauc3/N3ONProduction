// TransactionType.swift
// N3ON

import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case ticketPurchase     = "ticket_purchase"
    case djPayout           = "dj_payout"
    case venuePayout        = "venue_payout"
    case refund             = "refund"
    case endorsementReward  = "endorsement_reward"
    case topUp              = "top_up"
    case withdrawal         = "withdrawal"
}
