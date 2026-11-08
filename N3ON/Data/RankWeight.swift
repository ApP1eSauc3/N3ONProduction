// RankWeight.swift
// N3ON — Data layer
//
// Client mirror of the DJ rank → coin-weight table.
//
// The canonical weights are the `WEIGHTS` constant in the joinEvent Lambda
// (amplify/backend/function/joinEvent/src/index.js), which stamps
// `coinContribution` on every EventDJLink it creates. There is no config table
// and no env-var override — an override let the server drift from this copy
// (LEAN-RESEARCH.md F10). Both tables are pinned to the same cases by
// RankWeightTests and lambda-tests/join.test.js; change them together.

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
