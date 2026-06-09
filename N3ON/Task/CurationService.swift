// CurationService.swift
// N3ON — Task layer
//
// The single capability chokepoint for bootstrap / curation overrides.
//
// Every rank/tally gate in the app routes through here so the ranking system
// can be suspended (curated mode) or fully enforced (community mode) by flipping
// `CurationConfig.platformMode` — with no other code changes. See
// `Data/CurationConfig.swift` for the flag and the cold-start rationale.

import Foundation

enum CurationService {

    /// Whether a user may create/host an event.
    /// - Always allowed at Rank ≥ 4 (the earned host gate — unchanged).
    /// - In **curated** mode, also allowed for admins and admin-curated DJs
    ///   (`User.isCurated`), so the team can hand-pick the launch roster.
    /// - In **community** mode, only the Rank ≥ 4 gate applies.
    static func canCreateEvent(user: User, isAdmin: Bool) -> Bool {
        if (user.djRank ?? 0) >= 4 { return true }
        guard CurationConfig.platformMode == .curated else { return false }
        return isAdmin || user.isCurated
    }

    /// Whether the event tally is enforced as a hard gate before an event can
    /// go live. Mirrors `CurationConfig` and is centralised here so views and
    /// ViewModels have a single entry point. In curated mode the tally is off
    /// (the join/tally pipeline is dormant); flipping to community re-enforces it.
    static var tallyEnforced: Bool { CurationConfig.tallyEnforced }
}
