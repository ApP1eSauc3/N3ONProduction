// CurationConfig.swift
// N3ON — Data layer
//
// Single source of truth for the platform's bootstrap / curation phase.
//
// COLD-START CONTEXT
// The ranking system (rank gates + event tally) creates a chicken-and-egg
// deadlock at launch: no DJ has organically earned Rank 4 to host, and no
// EventDJLink is created yet so the tally never accrues. During the bootstrap
// phase the admin team curates DJs and events directly, superseding the
// ranking rules.
//
// The ranking system is NOT removed — it is suspended behind `platformMode`.
// Flipping `platformMode` to `.community` re-enforces every CLIENT rank/tally
// gate with no other code changes — but the server's tally gate is a separate
// switch (purchaseTicket env `TALLY_ENFORCED=true`). Flip both together; see
// the header of `Task/CurationService.swift`, where the gates live.

import Foundation

enum PlatformMode {
    /// Bootstrap: admins and admin-curated DJs supersede ranking rules.
    case curated
    /// Mature community: ranking rules (rank gates + tally) fully enforced.
    case community
}

enum CurationConfig {
    /// Current platform phase. Flip to `.community` to retire bootstrap overrides.
    static let platformMode: PlatformMode = .curated

    /// When false, the event tally requirement is not enforced as a hard gate.
    static var tallyEnforced: Bool { platformMode == .community }
}
