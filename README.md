# N3ON

iOS nightlife/events app — DJs, venues, and fans on a live map. SwiftUI (iOS 16+) with an AWS Amplify backend.

## What it does

- **Map-first discovery** — venues and live events on a MapKit map; venue glow scales with upcoming event proximity
- **Three roles** — DJ, Venue owner, Regular (fan); one `AppRole` per user, admin as an orthogonal capability (Cognito group)
- **Event creation** — DJ-hosted three-stage flow: date → limbo (DJ lineup tally) → pricing/poster → live
- **DJ ranking & endorsements** — rank 1–5 ladder with endorsement requests; suspended behind a curation flag during bootstrap (`Data/CurationConfig.swift`)
- **Real-time chat** — DataStore `observe()` streams, role-gated eligibility (DJ↔DJ, DJ↔Venue around an event), optimistic sends
- **Tickets** — purchase, QR codes, venue-side scanner
- **Profiles** — pulsing avatar with DJ audio intro, stats, event history, follow system (DJ-only)

## Architecture

Five layers with strict import rules (see `CLAUDE.md`):

```
Data → Task → Workflow → Prompt   (Tools standalone)
```

| Layer | Path | Contains |
|---|---|---|
| Data | `N3ON/Data/` | Models, enums, errors — no async, no SwiftUI |
| Task | `N3ON/Task/` | Async services — the only layer that calls Amplify |
| Workflow | `N3ON/Workflow/` | `ObservableObject` ViewModels |
| Tools | `N3ON/Tools/` | Utilities, pickers, view modifiers |
| Prompt | `N3ON/Prompt/` | SwiftUI views — the only layer that imports SwiftUI |

## Stack

- **Language** — Swift, SwiftUI, async/await (`@MainActor` ViewModels, no Combine in views)
- **Frameworks** — MapKit, AVFoundation, PhotosUI
- **Cloud** — AWS Amplify v2: Cognito (auth + user groups), DataStore/AppSync (offline-first GraphQL), S3 (media — keys stored, URLs signed at display time)

## Development

Schema changes require `amplify push` then `amplify codegen models` before building. Generated models in `amplify/generated/models/` are never hand-edited. Full contributor rules: `CLAUDE.md`.
