# N3ON — Company Setup Research Brief

**Last touched:** 2026-10-12 · **Status:** not started. This is a research brief for a later session, not advice and not a decision record.

**Task for the next session:** research how Liam should set up N3ON's company (an Australian Pty Ltd), then produce a recommended structure, a step-by-step setup order, and a costed list of what to file and when. **Verify every fee, threshold and rule against a current official source** (ASIC, ATO, business.gov.au, IP Australia) and cite it. Nothing in this brief has been checked; it records what the session of 2026-10-12 established and what is still open.

Method (Liam's standing preference): research real-world and industry-standard examples first, read the relevant repo files, then complete each part and check it for errors and invented facts before moving on.

---

## Why now

- **The lawyer needs it.** Papillon Lawyers (Matthew Hodgkinson, Director) sent a costs agreement on 2026-10-12 and asked for an ABN. Liam's reply, drafted in Gmail and **not yet sent**, says the ABN will follow once the company is registered and asks for the agreement to be made out in the company's name.
  - Costs agreement: `~/Downloads/Costs Disclosure and Costs Agreement N3ON.pdf` ($550/hr incl GST, 6-minute units, NSW law, accepted by continuing to instruct, **excludes tax and financial advice**).
- **It caps Liam's personal liability.** He currently acts as an individual. Events, ticketing and user content all carry liability that a company keeps away from personal assets (subject to directors' duties and personal guarantees, which the research should explain).
- **Stripe needs it.** Stripe Connect and the platform account should be in the company's name from day one, so the ABN and company details must exist before Phase 4 (payments).

## What's already decided or recommended

- **One Pty Ltd now, not two.** Advice from a separate planning chat: a platform with no outside organisers has nothing to ring-fence yet. Split off a second entity only when third parties start selling through the platform.
- **The intended legal model** (from the call with Matt, 2026-10-12, not yet formal advice):
  - The **organiser** (a venue, promoter, or possibly a DJ) owns each event and is the merchant of record.
  - **N3ON is the ticketing agent** for the organiser, taking an application fee on Stripe Connect **direct charges**.
  - The DJ directory has **no relationship with the talent**: booking contracts sit between the DJ and the organiser.
- **N3ON may also run its own nights** at licensed venues, through the company acting as organiser. That makes the company the engager of those DJs and **probably liable for their super** (performers can count as employees under the super guarantee rules even when they're contractors). See FINANCIAL-FORMAT.md §10.
- **Revenue:** a 12% buyer-paid booking fee (minimum $1 per ticket), plus 15% of sponsorship deals N3ON brokers. No subscriptions, no investor money, no user wallet. See FINANCIAL-FORMAT.md §3, §8 and §11.
- **Location:** Liam is in West End, QLD 4101. The market is Brisbane.

## Questions to research

### 1. Structure
- **Pty Ltd options:** sole director and sole shareholder, versus a holding company or discretionary trust as shareholder. Which suits a first-time solo founder? What does each add in cost and complexity, and what's the real asset-protection or tax benefit at this stage?
- **Share structure:** how to leave room for a future co-founder or staff equity (share classes, vesting, a shareholders' agreement).
- **Rules:** the replaceable rules versus a custom constitution.
- **The future second entity:** when should it be split off, and what makes the separation hold? Arm's-length fees between the entities, separate accounts, intercompany agreements. The platform must charge N3ON's own events the same fee as everyone else.

### 2. Registration steps and costs (verify current fees)
- **Director ID:** confirm whether it's needed before registering the company, and how to get one.
- **ASIC company registration:** the fee, the annual review fee, and the company name. Is "N3ON Pty Ltd" available? Can a company name contain a digit like that?
- **ABN and TFN:** for the company.
- **Business name:** if trading under a name other than the company name.
- **GST registration:** the $75,000 GST-exclusive turnover threshold. As ticketing agent, turnover is commission only (~10–27 events/month to reach it; see FINANCIAL-FORMAT.md §13). Should we register voluntarily from the start, given input-tax credits and Stripe fees?
- **PAYG withholding and super:** registration is needed once the company engages DJs for its own nights.
- **Trademark:** "N3ON" with IP Australia (classes 9, 41 and 42 at least). Search for conflicts first.

### 3. Moving existing assets into the company
- **IP assignment:** the app code (repo `ApP1eSauc3/N3ONProduction`), the brand and any designs, from Liam personally to the company.
- **Accounts to transfer or recreate in the company's name:**
  - The Apple Developer account. An organisation enrolment needs a D-U-N-S number, so check the lead time.
  - The AWS account, which currently runs in us-east-1.
  - GitHub, the n30n.org domain, and Supabase.
- **Contracts:** the costs agreement with Papillon in the company's name.

### 4. Running costs and duties
- **Ongoing obligations:** the annual ASIC review, company tax return, BAS if registered for GST, bookkeeping, and the accountant's annual cost.
- **Directors' duties:** insolvent trading, and when personal liability survives despite the company (personal guarantees, director penalty notices for unpaid super and PAYG). **This matters if the company engages DJs and owes super.**
- **Insurance in the company's name:** professional indemnity and platform cover for N3ON itself. Organisers carry their own $10–20M public liability, which is a listing condition. Get indicative quotes.
- **Banking:** a business bank account, needed for Stripe payouts.

### 5. Support for early-stage companies (check eligibility; don't assume)
- **R&D Tax Incentive:** app development may qualify, but registration rules and timing are strict.
- **Early Stage Innovation Company (ESIC) status:** probably irrelevant under the no-investor-money rule; confirm.
- **Queensland and federal grants:** Arts Queensland's Growing Gigs is already on the Phase 3 call list.

## What to produce
1. A recommended structure, with reasons and trade-offs.
2. A setup checklist in order, with costs, lead times and who does each step: Liam, an accountant, or the lawyer.
3. A list of who should be consulted for what:
   - **Accountant:** tax structure, GST timing, super, R&D Tax Incentive.
   - **Matt at Papillon:** constitution, IP assignment, shareholders' agreement.

   The costs agreement excludes tax advice, so the accountant is required, not optional.
4. Updates to `LAUNCH-CHECKLIST.md` Phase 3 and a dated Changelog entry.

## Sources in this repo
- `FINANCIAL-FORMAT.md`:
  - §3 who pays
  - §7 liquor and occupancy
  - §10 super and the creator-DJ trap
  - §11 coins
  - §12 money flow
  - §13 GST thresholds
  - §15 human tasks
- `LAUNCH-CHECKLIST.md` Phase 3 for business and legal tasks.
- Gmail thread "Matt from LawConnect/Papillon Lawyers introduction" (thread `1a128126cc10abc8`), which holds Matt's four threshold questions and Liam's draft reply.
