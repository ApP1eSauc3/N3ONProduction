# N3ON — Ordered Work Checklist

**Last touched: 2026-10-08.** Read this first at the start of any session — it is the
handover doc. Tick items as they land and add a dated line under "Changelog".

Order is by dependency. 👤 = human-only (console, CLI login, phone, legal, human-owned
file). 🤖 = Claude can do it. ✅ = done and verified. ~~struck~~ = no longer applies (reason given).

Sources: project memory, `FINANCIAL-FORMAT.md` §12–16, `docs/schema-auth-hardening.md`
(gitignored — see Phase 0), `amplify/backend/amplify-meta.json`, compiled resolvers in
`amplify/backend/api/n3on/build/`.

---

## What is actually deployed (verified 2026-10-07/08)

| Thing | State | Evidence |
|---|---|---|
| Cognito groups `UserGroup`, `DJUser`, `VenueOwnerUser`, `AdminUser` | ✅ exist | `aws cognito-idp list-groups` |
| `n3onAPI` REST API + `/tickets/purchase`, `/events/join` | ✅ deployed 2026-06-02 | `amplify-meta.json` |
| `joinEvent`, `purchaseTicket`, `rankPromotion` Lambdas | deployed **as stubs**; real code committed, not pushed | `amplify-meta.json`, `e72668d` |
| GSIs `EventDJLink.byEvent`, `EndorsementRequest.byToUser` | ✅ already in schema | `schema.graphql` |
| EndorsementRequest DynamoDB stream | ✅ `NEW_AND_OLD_IMAGES` (transformer default) | `build/stacks/EndorsementRequest.json` |
| Group IAM roles / identity-pool role mapping | ❓ **unverified** — read was blocked in-session | run the commands in Phase 1 |
| Total Cognito users | 1 (you; in `DJUser` + `AdminUser`) | `list-users` |

---

## Phase 0 — Clean the workbench

- [x] ✅ 🤖 Profile header fix + MainView preview split onto `fix/profile-header-height` (`2a6e5f7`). Builds, 33/33 tests passed at the time.
- [ ] 👤 `project.pbxproj` change (exclude `CLAUDE.md` files from the target) is still **uncommitted in the working tree** — human-owned file, needs your approval to commit.
- [ ] 👤 Merge `docs/financial-format` → `main` (PR).
- [ ] 👤 Push / PR `fix/profile-header-height` and `fix/launch-phase-1-2` (stacked: phase branch contains the header fix).
- [ ] 👤 Decide whether `docs/` stays gitignored. `docs/schema-auth-hardening.md` is the Phase 1 spec, revised 2026-10-08, and has **no version history**. Recommended: add `!docs/schema-auth-hardening.md` to `.gitignore` and commit it.
- [ ] 👤 Decide the ticket floor: **$1** (memory) vs **$0.50, $0 on free events** (FINANCIAL-FORMAT §4).

## Phase 1 — Security foundation

- [ ] 👤 **Verify the group IAM roles first** — if `DJUserRole`/`VenueOwnerUserRole` really hold DynamoDB-full and users can assume them via the identity pool, every `@auth` rule is bypassable:
  ```bash
  aws iam list-attached-role-policies --role-name DJUserRole
  aws iam list-role-policies          --role-name DJUserRole
  aws iam list-attached-role-policies --role-name VenueOwnerUserRole
  aws cognito-identity get-identity-pool-roles --identity-pool-id "$(jq -r '.auth.n3on3dbadbe4.output.IdentityPoolId' amplify/backend/amplify-meta.json)"
  ```
- [x] ✅ 🤖 Schema proposal revised — **the old `User`/`Ticket` rules would have broken production** (implicit `owner` is null on existing User rows and on Lambda-minted tickets). Now `ownerField: "id"` / `ownerField: "userID"`; `Message`/`ChatRoom` participant scoping added. Verified against the compiled resolvers.
- [ ] 👤 Apply the proposal to `schema.graphql` — in the **same push** as the Lambdas (Phase 2 runbook).
- [x] ✅ 🤖 ~~Remove client-side rank write in `DJProfileStatsService`~~ — it had **no callers** (dead code, not "every login"); deleted.
- [x] ✅ 🤖 `AdminService.swift` header corrected (Event writes enforced; User writes not).
- [x] ✅ 🤖 DataStore truncation **verified real** in amplify-swift 2.54.1 source (records past 10,000 are never fetched later). ~~Client `syncExpressions`~~ rejected: a time window drops permanent DJ↔DJ history; a room predicate has a membership bootstrap problem. Fix is server-side (`Message`/`ChatRoom` scoping in the proposal).
- [ ] 🤖 After the Message/ChatRoom schema change + codegen: populate `participantIDs` in `ChatRoomService` (`getOrCreate`, `send`) and backfill existing rows.
- [ ] 👤 Multi-account smoke test (list in the proposal's deploy checklist + Phase 2 runbook step 6).

## Phase 2 — Backend pipeline

- [x] ✅ ~~Add GSIs~~ — already in the schema.
- [x] ✅ ~~DynamoDB config tables~~ — superseded: rank weights live in `joinEvent` with a `RANK_WEIGHTS` env-var override (no table, no extra IAM). Capacity tiers are client display only.
- [x] ✅ ~~`custom:role` attribute~~ — **dropped deliberately**: DJ vs Regular is `User.isDJ` (DataStore), not a Cognito group, and a client-writable role attribute is a known privilege-escalation pattern.
- [x] ✅ 🤖 PostConfirmation: always `UserGroup`, never creates groups, ignores password-reset confirmations. **Fixed a live bug:** `GROUP` was `"Users"`, a group no `@auth` rule references (local `team-provider-info.json` updated to `UserGroup`).
- [x] ✅ 🤖 `rankPromotion`, `joinEvent`, `purchaseTicket` implemented — IAM-signed AppSync (DataStore-safe), server-derived identity, idempotent. 41 Node tests in `lambda-tests/` (real SigV4, GraphQL validated against the compiled schema).
- [x] ✅ 🤖 Deprecated `nodejs18.x` → `nodejs22.x` (CustomMessage, PostConfirmation, S3 trigger).
- [x] ✅ 🤖 Client wired: `N3ONRESTClient`, `TicketService` (no client `userID`), `EventService.joinLineup`, host auto-joins own lineup, invite card **Join lineup** button. Fixed invite detection (prefix match broke on JSON key order).
- [x] ✅ ~~Replace `EventInviteSheet` direct `EventDJLink` creation~~ — it never created links; joining didn't exist until now.
- [ ] 👤 `approveVenue` Lambda — not created (new function needs `amplify add function`; ask Claude to write the handler after).
- [ ] 👤 **Deploy** — see runbook below.
- [x] ✅ 🤖 Server-side tally gate on **ticket sales**: `purchaseTicket` refuses with `TALLY_NOT_MET` when `TALLY_ENFORCED=true` (off by default = curated mode). Mirrors the client's `requiredTally` formula (tested). Set the env var on purchaseTicket when flipping to `.community`.
- [ ] 🤖 Remaining gap: an event *owner* can still set `Event.status = "live"` client-side before the tally (the sale is gated, the listing isn't). Close with a publish Lambda if it matters for `.community`.

### Phase 2 deploy runbook (👤, in this order)

1. `cd lambda-tests && npm install && npm test` — must be all green.
2. Grant API access to each function (adds `API_N3ON_GRAPHQLAPIENDPOINTOUTPUT`, `appsync:GraphQL`, and the resolvers' `adminRoles` allow-listing the code relies on):
   ```bash
   amplify update function   # rankPromotion → Resource access permissions → api → n3on → Query, Mutation
   amplify update function   # joinEvent     → same
   amplify update function   # purchaseTicket → same; also REMOVE its unused storage/DynamoDB table access (least privilege)
   ```
3. Confirm `rankPromotion-cloudformation-template.json` now has the `apin3onGraphQLAPIIdOutput` parameter, then merge `deploy/rankPromotion-stream-trigger.json` into its `Resources` (validated with cfn-lint; filter only delivers `status = approved` records).
4. Apply `docs/schema-auth-hardening.md` to `schema.graphql` — at minimum `EventDJLink` owner → `[read]` and `Ticket` → `ownerField: "userID"` must ship **with** this push.
   4b. `amplify api gql-compile && (cd lambda-tests && npm test)` — **must be green before pushing.** The tests validate every Lambda GraphQL document against the *edited* schema (a selection of a field the edit removed fails here instead of failing every request in production).
5. `amplify push` → `amplify codegen models` → clean build (⇧⌘K) → ⌘U.
6. Smoke test with two accounts: host creates event → host link with rank weight appears in limbo tally; host invites DJ → DJ taps **Join lineup** → tally rises; uninvited DJ gets "You need an invite"; free event ticket purchase works and shows in the buyer's tickets; paid event → "Paid tickets aren't available"; two approved endorsements from senior DJs who shared an event → rank +1.

## Phase 3 — Business & legal **(parallel — start now)**

Unchanged — FINANCIAL-FORMAT §15: venue calls (incl. ticketing exclusivity), Benga Box inclusions (**load-bearing**), certifier quote, Stripe charge type (lawyer), super exposure (accountant), Arts Queensland, payout-curve host premium, Cognito threat protection cost.

## Phase 4 — Payments & tickets

- [x] ✅ 🤖 `purchaseTicket` safe subset: free events end-to-end; paid events hard-refused (402) — no free-ticket hole.
- [ ] 🤖 Stripe Connect on the charge type the lawyer picks (blocked on Phase 3).
- [ ] 🤖 Signed, expiring, single-use ticket QR + `validateTicket` burn — needs a server signing key and a redemption field (schema), so it lands with Stripe.
- [ ] 🤖 Payout curve + commission/floor in pricing UI (blocked on Phase 3 decisions).

## Phase 5 — Push notifications

- [x] ✅ 🤖 Verified: amplify-swift (through 2.62.0) has **only** the Pinpoint push plugin; Pinpoint ends 2026-10-30; Amplify's migration target (Connect Customer Profiles) has no Swift push plugin. Push is local-only today, so nothing breaks on that date. Stale Pinpoint/Podfile instructions replaced; APNs token no longer logged.
- [ ] 👤 Pick a provider (direct APNs from Lambda / SNS / End User Messaging push API) + APNs `.p8` key; then 🤖 builds it.

## Phase 6 — Launch hardening

- [ ] 🤖 `launch-security` 40-item pass (after Phase 2 deploy, so it audits real behaviour).
- [ ] 🤖 Re-run a full-tree audit.
- [ ] 👤 Re-upload media from before 2026-06-12.
- [ ] 👤 TestFlight with ≥2 accounts per role.

## Phase 7 — After launch traction

- [ ] 👤 Flip `CurationConfig.platformMode` to `.community` — only after Phases 1–2 are live **and** the server-side tally gate exists.
- [ ] Group chat (`Message.readBy` already reserved).

---

## Changelog

- **2026-10-08 (later)** — Review fix: `CREATE_TICKET` no longer selects `owner` (the planned `ownerField: "userID"` removes it; new test validates against the reshaped schema). Added runbook step 4b, `TALLY_NOT_MET` gate. Lambda suite 45/45.
- **2026-10-08** — Phases 0–2 client/Lambda work done on `fix/launch-phase-1-2` (`e72668d` + follow-up). Verified: Xcode suite 41/41, Lambda suite 41/41, no new compiler warnings (66 before and after). Corrected stale memory (deployed state, dead stats service, GROUP bug). Nothing deployed — runbook above.
- **2026-10-07** — Checklist created from memory, FINANCIAL-FORMAT.md and docs/schema-auth-hardening.md.
