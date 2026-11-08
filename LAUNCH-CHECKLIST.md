# N3ON — Ordered Work Checklist

**Last touched: 2026-10-11 (deployed).** Read this first at the start of any session — it is the
handover doc. Tick items as they land and add a dated line under "Changelog".

Order is by dependency. 👤 = human-only (console, CLI login, phone, legal, human-owned
file). 🤖 = Claude can do it. ✅ = done and verified. ~~struck~~ = no longer applies (reason given).

Sources: project memory, `FINANCIAL-FORMAT.md` §12–16, `docs/schema-auth-hardening.md`
(gitignored — see Phase 0), `amplify/backend/amplify-meta.json`, compiled resolvers in
`amplify/backend/api/n3on/build/`.

---

## What is actually deployed (verified 2026-10-07/10)

**Live backend = Amplify project N3ON, env `dev`, app `d1oif2gjomnlld`** (from `amplifyconfiguration.json`). `n3onv2`/staging and the other Amplify apps are older iterations; the app does not use them.


| Thing | State | Evidence |
|---|---|---|
| Cognito groups `UserGroup`, `DJUser`, `VenueOwnerUser`, `AdminUser` | ✅ exist | `aws cognito-idp list-groups` |
| `n3onAPI` REST API + `/tickets/purchase`, `/events/join` | ✅ deployed 2026-06-02 | `amplify-meta.json` |
| `joinEvent`, `purchaseTicket`, `rankPromotion` Lambdas | deployed **as stubs**; real code committed, not pushed | `amplify-meta.json`, `e72668d` |
| GSIs `EventDJLink.byEvent`, `EndorsementRequest.byToUser` | ✅ already in schema | `schema.graphql` |
| EndorsementRequest DynamoDB stream | ✅ `NEW_AND_OLD_IMAGES` (transformer default) | `build/stacks/EndorsementRequest.json` |
| Group IAM roles / identity-pool role mapping | ✅ **dormant** (verified 2026-10-09) — app pool `2d4be7fc…` has no `RoleMappings`, classic flow off; every user gets `amplify-n3on-dev-4ad86-authRole`. But the roles still carry DynamoDB-full + S3-full (DJ/Venue) and DynamoDB-read (Customer), and trust a **different** pool `eec3d948…` with no `amr` condition | Liam's CLI output |
| Total Cognito users | 1 (you; in `DJUser` + `AdminUser`) | `list-users` |

---

## Phase 0 — Clean the workbench

- [x] ✅ 🤖 Profile header fix + MainView preview split onto `fix/profile-header-height` (`2a6e5f7`). Builds, 33/33 tests passed at the time.
- [x] ✅ 👤 `project.pbxproj` change (exclude `CLAUDE.md` files from the target) + dead-code commit `c0ebe2b` — PR #27 squash-merged to `main` 2026-10-11 (`63b34aa`). #28 still merges cleanly on top.
- [x] ✅ 👤 Merge `docs/financial-format` → `main` — PR #29, merged 2026-10-10.
- [x] ✅ 👤 `fix/profile-header-height` merged to `main` — PR #30, 2026-10-10.
- [ ] 👤 `fix/launch-phase-1-2` pushed, **PR #28 open** (#30 was **squash**-merged, so #28's 10 commits still include the original header-fix commit `2a6e5f7`; the two files it touches are identical on `main` and this branch, so they add nothing to #28's diff).
- [ ] 👤 Decide whether `docs/` stays gitignored. `docs/schema-auth-hardening.md` is the Phase 1 spec, revised 2026-10-08, and has **no version history**. Recommended: add `!docs/schema-auth-hardening.md` to `.gitignore` and commit it.
- [ ] 👤 Decide the ticket floor: **$1** (memory) vs **$0.50, $0 on free events** (FINANCIAL-FORMAT §4).

## Phase 1 — Security foundation

- [x] ✅ 👤 Group IAM roles verified dormant for the app's identity pool (2026-10-09) — `@auth` hardening is meaningful.
- [x] ✅ Identity pool `eec3d948…` (trusted by `DJUserRole`) no longer exists — the group roles are fully inert.
- [x] ✅ Leftover pools audited (2026-10-10): `userPoolManagement` has no guest access. `testAuthIdentityPool__staging` (old **n3onv2** project) allows guests, but its guest role only reads/lists `public/` + `protected/` of `imagestorage51704-staging` (**empty, 0 objects**) and sends events to one old Pinpoint app — no access to the live app.
- [x] ✅ 👤 Guest access disabled on `testAuthIdentityPool__staging` (2026-10-10). Side effect: `update-identity-pool` replaces the full config, so its user-pool provider link was also removed — the pool now issues no credentials (fine; unused). Retire the old n3onv2 Amplify app when convenient (never `d1oif2gjomnlld`).
- [ ] 👤 Detach the unused broad policies (`AmazonDynamoDBFullAccess`, `AmazonS3FullAccess` from DJUserRole/VenueOwnerUserRole; `AmazonDynamoDBReadOnlyAccess` from CustomerUserRole) — nothing in the app is issued these roles.
- Original verification commands (note `--region us-east-1` on Cognito calls — the CLI default region isn't us-east-1):
  ```bash
  aws iam list-attached-role-policies --role-name DJUserRole
  aws iam list-role-policies          --role-name DJUserRole
  aws iam list-attached-role-policies --role-name VenueOwnerUserRole
  aws cognito-identity get-identity-pool-roles --identity-pool-id us-east-1:2d4be7fc-b7c1-4936-b0d3-9012d2d5d73a --region us-east-1
  ```
- [x] ✅ 🤖 Schema proposal revised — **the old `User`/`Ticket` rules would have broken production** (implicit `owner` is null on existing User rows and on Lambda-minted tickets). Now `ownerField: "id"` / `ownerField: "userID"`; `Message`/`ChatRoom` participant scoping added. Verified against the compiled resolvers.
- [x] ✅ 🤖 Proposal applied to `schema.graphql` (2026-10-11, with your go-ahead): User `ownerField: "id"`; Venue group-create + `ownerID` update/delete; VenueComplianceSubmission reviewer → `AdminUser`; Post locked to `ownerID` + admin (**not deleted** — deleting drops the table; check it first); ChatRoom/Message read scoped to `participantIDs`; Message create bound to `ownerField: "senderID"`. Compiled resolvers inspected (see changelog). Ships in the **same push** as the Lambdas.
- [x] ✅ 🤖 ~~Remove client-side rank write in `DJProfileStatsService`~~ — it had **no callers** (dead code, not "every login"); deleted.
- [x] ✅ 🤖 `AdminService.swift` header corrected (Event writes enforced; User writes not).
- [x] ✅ 🤖 DataStore truncation **verified real** in amplify-swift 2.54.1 source (records past 10,000 are never fetched later). ~~Client `syncExpressions`~~ rejected: a time window drops permanent DJ↔DJ history; a room predicate has a membership bootstrap problem. Fix is server-side (`Message`/`ChatRoom` scoping in the proposal).
- [x] ✅ 🤖 `ChatRoomService` writes `participantIDs` (creator always included; `send` copies the room's list onto each message; `getOrCreate` heals legacy rooms it can update). **No backfill needed:** the only Cognito user is you, you're `AdminUser`, and admin keeps read on every ChatRoom/Message — older rooms involve deleted test accounts. Revisit only if real users exist before the push.
- [x] ✅ 🤖 **Sign-up was broken for every new user** (found prepping step 6). The pool signs in by email and requires `name`; the app sent the handle as the Cognito username and no `name`, so Cognito rejected every sign-up. Fixed in the app: email is the Cognito username, handle goes as `name` and stays `User.username`; login/reset ask for email. And the verification email carried a **dead link** (empty verification bucket, no website config) instead of a code — `CustomMessage` trigger now sends the 6-digit code.
- [ ] 👤 `amplify push` (deploys only `n3on3dbadbe4CustomMessage`), rebuild, then the smoke test.
- [ ] 🤖 **Handle uniqueness is enforced nowhere** (consequence of the sign-up fix: the handle is now the `name` attribute + `User.username`, neither unique). Two users can both be `@luna`; `EventDraftViewModel` matches payouts by `username`. Check `User` by username before `createInitialUserRecord`, and match payouts by ID.
- [ ] 👤 Multi-account smoke test (list in the proposal's deploy checklist + Phase 2 runbook step 6).

## Phase 2 — Backend pipeline

- [x] ✅ ~~Add GSIs~~ — already in the schema.
- [x] ✅ ~~DynamoDB config tables~~ — superseded: rank weights are the `WEIGHTS` constant in `joinEvent`, mirrored by `RankWeight.swift` (the `RANK_WEIGHTS` env override was removed 2026-11-08, F10). Capacity tiers are client display only.
- [x] ✅ ~~`custom:role` attribute~~ — **dropped deliberately**: DJ vs Regular is `User.isDJ` (DataStore), not a Cognito group, and a client-writable role attribute is a known privilege-escalation pattern.
- [x] ✅ 🤖 PostConfirmation: always `UserGroup`, never creates groups, ignores password-reset confirmations. **Fixed a live bug:** `GROUP` was `"Users"`, a group no `@auth` rule references (local `team-provider-info.json` updated to `UserGroup`).
- [x] ✅ 🤖 `rankPromotion`, `joinEvent`, `purchaseTicket` implemented — IAM-signed AppSync (DataStore-safe), server-derived identity, idempotent. 41 Node tests in `lambda-tests/` (real SigV4, GraphQL validated against the compiled schema).
- [x] ✅ 🤖 Deprecated `nodejs18.x` → `nodejs22.x` (CustomMessage, PostConfirmation, S3 trigger).
- [x] ✅ 🤖 Client wired: `N3ONRESTClient`, `TicketService` (no client `userID`), `EventService.joinLineup`, host auto-joins own lineup, invite card **Join lineup** button. Fixed invite detection (prefix match broke on JSON key order).
- [x] ✅ ~~Replace `EventInviteSheet` direct `EventDJLink` creation~~ — it never created links; joining didn't exist until now.
- [ ] 👤 `approveVenue` Lambda — not created (new function needs `amplify add function`; ask Claude to write the handler after).
- [x] ✅ 👤 **Deployed 2026-10-11** (runbook steps 1–5): root stack `UPDATE_COMPLETE` 03:13 UTC; all three Lambdas on nodejs22.x with real code; stack-owned stream mapping `0ba7e7e5…` (5 retries, bisect); live schema has `participantIDs`. Codegen was a no-op. **Next: step 6 smoke test.**
- [x] ✅ 🤖 Server-side tally gate on **ticket sales**: `purchaseTicket` refuses with `TALLY_NOT_MET` when `TALLY_ENFORCED=true` (off by default = curated mode). Mirrors the client's `requiredTally` formula (tested). Set the env var on purchaseTicket when flipping to `.community`.
- [x] ✅ 🤖 **Endorsement forgery closed (found 2026-10-11):** a candidate could create an `EndorsementRequest` already `status: "approved"` (create input allows it; the stream filter + Lambda accepted INSERTs), and get promoted with no endorser consent — rank 4 unlocks Create Event even in curated mode. `rankPromotion` now: approves only on a recipient `MODIFY`; resets pre-approved INSERTs to `pending`; rejects approvals that re-point `fromUserID`/`toUserID`/`targetRank`; counts only rows with `updatedAt != createdAt` (resolver-set, in no input type).
- [ ] 🤖 Residual (before `.community`): a re-pointed approval could be counted by a concurrent invocation on another stream shard before it's rejected. Real fix: approve endorsements through a server endpoint (`amplify add function` 👤), not a DataStore update.
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
4. ✅ Done — full proposal applied to `schema.graphql` and models regenerated locally (`amplify codegen models`, committed). ⚠️ **Don't run the app from this branch against the live backend before step 5** — DataStore now selects `participantIDs`, which the live API doesn't have yet.
   4b. `amplify api gql-compile && (cd lambda-tests && npm test)` — **must be green before pushing.** The tests validate every Lambda GraphQL document against the *edited* schema (a selection of a field the edit removed fails here instead of failing every request in production).
5. `amplify push` → `amplify codegen models` (should be a no-op; if it re-formats `project.pbxproj`, that's Xcode integration — `git checkout` it, it's semantically identical) → clean build (⇧⌘K) → ⌘U (45 tests). First launch after this: the models' version hash changed, so DataStore **wipes its local store and does a full base sync** — a few seconds of empty screens is expected, not breakage.
6. Smoke test with two accounts. **Start by signing up a fresh second account** → it lands in `UserGroup` (PostConfirmation fix) → its User record saves (new `ownerField: "id"` create rule) → it appears in the first account's lists. Then: host creates event → host link with rank weight appears in limbo tally; host invites DJ → DJ taps **Join lineup** → tally rises; uninvited DJ gets "You need an invite"; free event ticket purchase works and shows in the buyer's tickets; paid event → "Paid tickets aren't available"; two approved endorsements from senior DJs who shared an event → rank +1. **Chat scoping (proves username == sub, which the whole design rests on):** DJ A messages DJ B → B sees it arrive **live** (subscription) and after relaunch (sync); a third non-admin account C sees neither the room nor the message; B can reply (B updates the room's `lastMessage` as a participant). **Ownership:** as a non-admin, editing your own profile and your own venue works; editing someone else's fails.

## LEAN-RESEARCH hardening (2026-11-08) — deploy steps and open items

Fixes for the findings in `LEAN-RESEARCH.md` (gitignored, local). Each fix has a regression test that failed against the old code. Nothing deployed.

### Deploy (👤, in order)

1. `cd lambda-tests && npm test` (all green), then `amplify api gql-compile`. `ticket.test.js` checks the compiled `TicketAllowance` stack is on `OPTIMISTIC_CONCURRENCY`.
2. `amplify push`. Deploys the new **`TicketAllowance`** table (F1), its per-model conflict handler (set in `cli-inputs.json` → `perModelResolutionStrategy`; Amplify CLI 13 **ignores** `transform.conf.json` `models` on its own, verified with gql-compile), and the `purchaseTicket` / `rankPromotion` / `joinEvent` code.
3. `amplify codegen models`. **A new `@model` was added**, so per root CLAUDE.md: `git checkout N3ON.xcodeproj/project.pbxproj`, then register `TicketAllowance` in Xcode (target membership; `deploy/add-generated-models.py` lives on `feat/legal-alignment`). No Swift code references the model; DataStore syncs it (owner-read, like Ticket). The model hash changes, so on first launch DataStore wipes and re-syncs.
4. Smoke test, **plain path first**: one free purchase succeeds and `remainingStock` drops by one; one endorsement approval promotes; (legal) one door scan admits. Every compare-and-swap now requires the returned row at exactly `_version + 1`. If live AppSync ever differs, these fail closed (refuse, never oversell), but **every** write would then exhaust its retries and return 500. This step proves the version arithmetic.
5. Then the race: two simultaneous 10-ticket requests for one free event from one account → one succeeds, one gets `LIMIT_REACHED`, and the buyer holds 10.

### What changed

- [x] ✅ 🤖 **F1 per-buyer cap race.** `purchaseTicket` reserves the buyer's cap on a `TicketAllowance` row (`<eventID>_<sub>`, conditional write) **before** taking stock, and releases it if the purchase then fails. Seeded from existing tickets on first use.
- [x] ✅ 🤖 **Automerge false successes (found while fixing F1; not in the research).** The project's conflict handler is AUTOMERGE. Per the AppSync docs, a write with a stale `_version` is **merged, not rejected**: server scalars kept, `_version` bumped, success returned. The docs don't say whether our custom `condition` is still enforced in that path, and it wasn't tested against live AWS, so the code now assumes the worst: a compare-and-swap could "succeed" without applying whenever anything else had touched the row. Every Lambda CAS now checks the response (our value at exactly `_version + 1`): `purchaseTicket` stock, `rankPromotion` rank (a location update between read and write silently dropped a promotion).
- [x] ✅ 🤖 **F2 rank order.** `rankPromotion` climbs from the current rank while the next rank qualifies, one guarded write per step.
- [x] ✅ 🤖 **F5 limbo price game.** Going live re-checks the tally at the price being saved (`EventDraftViewModel.canPublish(in:)`). The research marked this legal-only, but this branch has the limbo slider too.
- [x] ✅ 🤖 **F8** endorsement progress counts like the server (`EndorsementService.countedEndorsers`); endorsers offered at rank ≥ target. **F10** `RANK_WEIGHTS` env override removed. **F12** negative capacity → smallest tier on both sides. **F14** one Swift DM room-name function, code-point order on both sides. **F15** stale `rolesIncompatible` comment.
- [ ] 👤 **F7 — flipping to `.community` is two changes:** `CurationConfig.platformMode` **and** env `TALLY_ENFORCED=true` on `purchaseTicket`, in the same release.
- [ ] 🤖 **F6 — the rank gate is client-only** (Event `@auth` lets any owner create/update). Before relying on it in `.community`, route event creation / going live through a Lambda that re-checks the host's rank (same root as the "owner can set live" residual).
- [ ] 🤖 Residual: `TicketAllowance` over-counts if an admin deletes a ticket by hand (no refund flow exists). It errs towards refusing, never towards overselling.

## Security + performance test pass (2026-11-09) — gates, deploy, open items

Every function that can run in a unit test has one security test and one performance test (`54a6d6b`, plus the REST-transport follow-up). The fixes the tests found are listed in that commit message. Each fix was red-checked: the test was run against the old code and failed.

### Gates — run before every commit that touches code, and before every push (🤖/👤)

1. `python3 scripts/check-function-tests.py` must report `missing: 0`. A new function needs `test_<Type>_<func>_security` and `…_performance` (Swift), or `test('<fn>/<file>:<func> security…')` and `…performance…` (Lambda). The other option is an entry in `scripts/function-test-exclusions.txt` with a reason (only for OS callbacks, 1:1 live-AWS adapters, or view handlers that forward to tested code).
2. `cd lambda-tests && npm test`: all green.
3. Xcode ⌘U: all green. Performance budgets are wall-clock with wide headroom; if one fails on a slow machine, rerun once before changing a budget.

### Deploy (👤) — ✅ DEPLOYED 2026-11-09 (`amplify push` by Liam; `amplify status` all "No Change" afterwards). Smoke test still pending

`joinEvent`, `purchaseTicket`, `rankPromotion`, `n3on3dbadbe4PostConfirmation`, `n3on3dbadbe4CustomMessage`, `S3Triggerba3b2651`. There are no schema or IAM changes, so this rides along with the next `amplify push`, after the LEAN deploy steps above. Smoke test after the push:

- one free purchase;
- one join;
- one sign-up, including the confirmation email (the trigger loaders now refuse any `MODULES` value that isn't a plain name; `parameters.json` has `verification-link` / `add-to-group`, which pass).

### Open items

- [ ] 🤖 **Venue self-approval is client-only.** `VenueService.update` keeps the stored `approvalStatus`/`owner`, but Venue `@auth` lets the owner write any field directly through AppSync. This is the same residual as own `djRank` (field-level `@auth` breaks DataStore updates). Fix: an approval Lambda, or move `approvalStatus` to an admin-written model.
- [ ] 🤖 Event IDs sent to `joinEvent` / `purchaseTicket` must now match `^[A-Za-z0-9-]{1,64}$`. DataStore UUIDs do. If events are ever created with other IDs (an import, the admin console), widen `isValidID`, but never to allow `_`, because link and allowance IDs are `<eventID>_<sub>`.

## Phase 3 — Business & legal **(parallel — start now)**

- [ ] 👤🤖 **Register the Pty Ltd** — Papillon Lawyers needs the ABN for its costs agreement; Stripe Connect needs the company before Phase 4. Research brief for a fresh session: [`COMPANY-SETUP-BRIEF.md`](COMPANY-SETUP-BRIEF.md).
- [ ] 👤 Send the drafted reply to Matt (Gmail, Papillon thread) — sending accepts the costs agreement.

Also unchanged — FINANCIAL-FORMAT §15: venue calls (incl. ticketing exclusivity), Benga Box inclusions (**load-bearing**), certifier quote, Stripe charge type (lawyer), super exposure (accountant), Arts Queensland, payout-curve host premium, Cognito threat protection cost.

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

- [ ] 👤 Flip `CurationConfig.platformMode` to `.community` **and** set `TALLY_ENFORCED=true` on purchaseTicket in the same release (F7) — only after Phases 1–2 are live; see F6 (client-only rank gate) first.
- [ ] Group chat (`Message.readBy` already reserved).

---

## Changelog

- **2026-11-09 (security + performance tests)** — 350 functions, each with one security test and one performance test; 81 exclusions, each with a reason. New seams in `Task/Backend.swift` and an in-memory `FakeBackend`. The tests found and fixed:
  - authorisation that trusted arguments (admin writes, host-only event and chat operations, owner-only venue writes);
  - missing input limits;
  - whole-table DataStore scans;
  - an avatar downscale bug (1536 px on 3x screens);
  - in the Lambdas: unbounded request bodies, an `_` link-ID collision, a pagination loop with no exit, an overwritable response envelope, and S3 keys (user IDs) written to logs.

  Deployed the same day (all six Lambdas; PostConfirmation also dropped an unused `axios` dependency). Verified: Swift 651/651 (run twice), Lambda 203/203. Also fixed: `DJViewModel.loadFollowState` could overwrite a follow tap made while it was loading (it is now discarded if it overlapped a toggle). Found by a flaky test and confirmed with a 20× stress run. Not deployed.
- **2026-11-08 (LEAN-RESEARCH hardening)** — Fixed the findings from the Lean audit; see "LEAN-RESEARCH hardening" above. Biggest find was not in the research: under the project's AUTOMERGE conflict handler, a stale compare-and-swap can be merged and reported as success, so the per-buyer cap, stock and rank promotion were all only as safe as the test fake. Every CAS now verifies the returned `_version`, and the new `TicketAllowance` model runs on OPTIMISTIC_CONCURRENCY. Fake AppSync now clones responses like a real JSON round-trip (it handed out live references, which hid this). Not deployed.
- **2026-10-12 (legal)** — Call with Papillon Lawyers (Matthew Hodgkinson). Recommended model: the organiser (venue, promoter, or possibly a DJ — to be confirmed) is principal and merchant of record; N3ON is ticketing agent on Stripe Connect direct charges; the DJ directory has no relationship with talent. This reshapes the DJ-led event flow (host gate, `joinEvent`, tally, payout curve) — **no code changes until Liam adopts it**. Reply to Matt drafted in Gmail, not sent. Company setup is the next step: `COMPANY-SETUP-BRIEF.md`.
- **2026-10-11 (sign-up fix)** — No new account could be created: the pool has `UsernameAttributes: [email]` and requires `name`, but `AuthService.signUp` sent the handle as the username with only `email`. Now `signUpRequest(handle:email:)` sends the lower-cased email as username plus `email` + `name`; confirm/resend/sign-in/reset all address the email (`AuthFlowState.confirmCode(email:handle:)`, `.confirmReset(email:)`); role-selection recovery reads the handle from the `name` attribute (the Cognito username is the sub). `CustomMessage` replaced the code email with a link to `n3on3dbadbe4verificationbucket-dev`, which is empty with no website config — now sends the code for SignUp/ResendCode, other triggers keep the pool default. Verified: Xcode **48/48** (3 new `AuthServiceSignUpTests`), Lambda **55/55** (3 new trigger tests, which fail against the old trigger); `amplify status` shows only the trigger changing. Existing account unaffected (already signs in by email). Not verified live: the reproduction sign-up call was blocked, so the diagnosis rests on the pool config + code. Residual: `PreventUserExistenceErrors` is unset (legacy) on the app client — login/reset errors reveal whether an email exists; review in Phase 6.
- **2026-10-11 (first push failed, rolled back clean)** — `amplify push` failed on `EndorsementStreamMapping`: an **orphaned, hand-made** stream mapping `6c48cd72-c7be-45d8-aa37-44c844f2b088` (EndorsementRequest stream → `rankPromotion-dev`, created 2026-06-06 by "User action", owned by no stack, "No records processed", unlimited retries) already existed, and Lambda allows one mapping per stream+function. Root stack ended `UPDATE_ROLLBACK_COMPLETE`; every other nested stack (incl. `apin3on` schema) had updated fine before rolling back, so nothing is half-deployed and this is the only blocker. Fix (👤 — deletion is blocked for Claude): delete the orphan, re-run `amplify push`; the template's mapping replaces it (5 retries + batch bisect instead of unlimited retries). Config backed up before deletion. The push's rewrite of `backend-config.json` (drops the `parameters` block) is Amplify CLI output — commit it after a successful push.
- **2026-10-11 (hardening)** — Rest of the schema proposal applied + endorsement forgery fixed; all on `fix/launch-phase-1-2`, not deployed. Research used the exact deployed code: amplify-swift **2.54.1** (commit matches `Package.resolved`) and the installed CLI **13.0.1**'s compiled resolvers. Findings that shaped it:
  - **Field-level `@auth` can't be used with this client.** amplify-swift sends every non-read-only field on update (`Model+GraphQL.swift`), and the update resolver rejects any restricted *key present*, changed or not (`$inputFields` = all input keys). So privileged-field residuals (own `djRank`/`isCurated`/`coinBalance`, own venue `approvalStatus`) stay open until those move to server-written models — accepted for bootstrap.
  - **The "owners may reassign ownership" warning:** 10 of the 11 original entries were false positives — no `Create*/Update*Input` exposes the implicit `owner` field (checked every input type); the transformer's heuristic assumes it's writable. Real ones: `EndorsementRequest.toUserID` (fixed in `rankPromotion`), and after this change `Venue.ownerID` (owner can gift their venue — benign) and `ChatRoom.participantIDs` (a member can add/remove members — accepted). `User: [id]` / `UserChatRooms: [id]` are the primary key, which an update can't change.
  - **List-owner chat works with DataStore:** the 2.54.1 decorator drops non-String owner fields so sends no subscription argument; CLI 13.0.1 subscriptions then authorize via a runtime filter `participantIDs contains <username>`, and sync queries filter on sub/username/sub::username. Pool is email-as-username, so username == sub — smoke test step 6 must prove it.
  - **`Message.senderID` is now the owner field** (create-only): `createMessage` rejects a `senderID` that isn't the caller (read in the compiled VTL). Closes posting-as-someone-else; `joinEvent`'s invite check now uses it (implicit `owner` no longer exists on Message).
  - `UserChatRooms` (implicit join) inherits both parents' rules; it gained `owner` + scalar `participantIDs` fields. Membership rows are now owner-created only (was any group member, full CRUD); still readable by all signed-in users (who-chats-with-whom is visible — note for Phase 6).
  - Pre-existing, unchanged: `ChatRoomService.markRead` has the *recipient* update `Message.isRead`, which AppSync already rejects (it was owner-only before too) — read receipts are local-only. Proper fix is per-member read state, not a message update. `openEventRoom` has no callers; event rooms were created memberless (now creator-only).
  - Verified: Lambda suite **52/52** (6 + 46; mutation-tested the new guards), Xcode **45/45** (4 new `ChatRoomServiceTests`), no new warnings in touched files. `origin/main` merged in (brings #27's CLAUDE.md target exclusion — the branch didn't build without it). Codegen re-formatted `project.pbxproj` (semantically identical, reverted) and `Message.swift` had a local `assume-unchanged` flag hiding changes — cleared so the regenerated model is committed.
- **2026-10-11** — Runbook step 4 **minimum** applied to `schema.graphql`: `Ticket` → `ownerField: "userID"` read-only (+ `AdminUser`), `EventDJLink` owner → `[read]`. The rest of `docs/schema-auth-hardening.md` (User/Venue/Post owner scoping, Message/ChatRoom `participantIDs`) is **not** applied yet. Step 4b green against this schema: `amplify api gql-compile` OK, Lambda suite 45/45 (6 PostConfirmation + 39 AppSync). Steps 2–4 committed to `fix/launch-phase-1-2`. Still not pushed to AWS — next is step 5. PR #27 merged; #28 stays open until step 5 + the smoke test pass, so `main` only reflects what's live.
- **2026-10-10 (deploy prep)** — Runbook steps 2–3 done locally, not pushed. Step 2: all three functions have `api → n3on → [Query, Mutation]` (generated `API_N3ON_GRAPHQLAPI*` params present); `purchaseTicket` now has only logs + `appsync:GraphQL`, storage/DynamoDB access removed. Step 3: `deploy/rankPromotion-stream-trigger.json` merged into `rankPromotion-cloudformation-template.json` (insert-only; import name matches the compiled `EndorsementRequest` stack export; `cfn-lint` 1.57.2 zero errors, same 3 Amplify-generated warnings as before the merge). Don't re-run `amplify update function` on rankPromotion before the push without re-checking those two resources survive.
- **2026-10-10 (later)** — Phase 0 re-verified against git/GitHub: #29 (`docs/financial-format`) and #30 (`fix/profile-header-height`) merged; #28 (`fix/launch-phase-1-2`) open; the "uncommitted" `pbxproj` change is actually `8f464c5` in open PR #27 (which also carries dead-code commit `c0ebe2b`). Header date corrected (was stuck at 10-08).
- **2026-10-10** — Old n3onv2 guest pool audited: scoped to an empty bucket + old Pinpoint app; no live-app exposure. Guest access then disabled on `testAuthIdentityPool__staging` (also dropped its user-pool provider link — `update-identity-pool` replaces the full config).
- **2026-10-09** — Pool `eec3d948…` confirmed deleted → group roles inert. IAM verified: group roles over-broad but dormant (no role mapping, classic flow off, trust points at another pool `eec3d948…`). Detach + check that pool.
- **2026-10-08 (later)** — Review fix: `CREATE_TICKET` no longer selects `owner` (the planned `ownerField: "userID"` removes it; new test validates against the reshaped schema). Added runbook step 4b, `TALLY_NOT_MET` gate. Lambda suite 45/45.
- **2026-10-08** — Phases 0–2 client/Lambda work done on `fix/launch-phase-1-2` (`e72668d` + follow-up). Verified: Xcode suite 41/41, Lambda suite 41/41, no new compiler warnings (66 before and after). Corrected stale memory (deployed state, dead stats service, GROUP bug). Nothing deployed — runbook above.
- **2026-10-07** — Checklist created from memory, FINANCIAL-FORMAT.md and docs/schema-auth-hardening.md.
