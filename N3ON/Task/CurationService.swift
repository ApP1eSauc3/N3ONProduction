// CurationService.swift
// N3ON — Task layer
//
// The single capability chokepoint for bootstrap / curation overrides.
//
// Every rank/tally gate in the app routes through here so the ranking system
// can be suspended (curated mode) or enforced (community mode) by flipping
// `CurationConfig.platformMode` — with no other client code changes. See
// `Data/CurationConfig.swift` for the flag and the cold-start rationale.
//
// FLIPPING TO COMMUNITY IS TWO CHANGES, not one (LEAN-RESEARCH.md F7):
//   1. `CurationConfig.platformMode = .community` (client gates), and
//   2. env `TALLY_ENFORCED=true` on the purchaseTicket Lambda (the server's
//      tally gate on ticket sales — the real one). Either alone leaves the
//      client and server disagreeing about whether sales are open.
//
// SERVER-SIDE RESIDUAL (F6): `canCreateEvent` is a client check only. Event's
// @auth lets any signed-in owner create/update an Event, so a modified client
// can skip the rank gate. Harmless in curated mode; before relying on it in
// community mode, route event creation (or going live) through a Lambda that
// re-checks the host's rank, like purchaseTicket re-checks the tally.

import Foundation

enum CurationService {

    /// Whether a user may create/host an event.
    /// - Always allowed at Rank ≥ 4 (the earned host gate — unchanged).
    /// - In **curated** mode, also allowed for admins and admin-curated DJs
    ///   (`User.isCurated`), so the team can hand-pick the launch roster.
    /// - In **community** mode, only the Rank ≥ 4 gate applies.
    /// `mode` defaults to the live config; tests inject `.curated` / `.community`
    /// to exercise both phases (the config value is a compile-time constant).
    static func canCreateEvent(
        user: User,
        isAdmin: Bool,
        mode: PlatformMode = CurationConfig.platformMode
    ) -> Bool {
        if (user.djRank ?? 0) >= 4 { return true }
        guard mode == .curated else { return false }
        return isAdmin || user.isCurated
    }

    /// Whether the event tally is enforced as a hard gate before an event can
    /// go live. Mirrors `CurationConfig` and is centralised here so views and
    /// ViewModels have a single entry point. In curated mode the tally is off
    /// (the join/tally pipeline is dormant); flipping to community re-enforces it.
    static var tallyEnforced: Bool { tallyEnforced(in: CurationConfig.platformMode) }

    /// Mode-explicit variant — the testable seam behind `tallyEnforced`.
    static func tallyEnforced(in mode: PlatformMode) -> Bool { mode == .community }
}
