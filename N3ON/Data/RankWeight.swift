// RankWeight.swift
// N3ON — Data layer
//
// BOOTSTRAP-ONLY mirror of the DJ rank → coin-weight table.
//
// The canonical weights live in the Lambda's DynamoDB config (RankWeights
// table), NOT in the app — see Prompt/Event/AGENTS.md. This local copy exists
// only so admin lineup curation can stamp a plausible `coinContribution` on the
// EventDJLink records it creates during the bootstrap phase. It mirrors the
// same precedent already set by `EventDraftViewModel.requiredTally`, which
// hardcodes capacity tiers for a client-side estimate.
//
// Remove this once the join/tally Lambda owns EventDJLink creation.

import Foundation

enum RankWeight {
    /// Coin contribution for a DJ of the given rank, mirroring the documented
    /// 0 / 5 / 7 / 10 / 25 table. Rank 1 (or unranked) contributes nothing;
    /// Rank 5 is the host weight.
    static func coins(forRank rank: Int) -> Int {
        switch rank {
        case ..<2:  return 0
        case 2:     return 5
        case 3:     return 7
        case 4:     return 10
        default:    return 25
        }
    }
}
