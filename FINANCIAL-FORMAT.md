# N3ON — Financial Format

**Status: draft for review, 2026-09-26.** Seven research passes complete, two
independent verification passes applied. Every figure below has been re-derived
by a verifier that did not write it.

All money AUD. Constraint honoured throughout: revenue comes only from ticket
commission, brokered sponsorship, and government aid. No subscriptions, no
investor money, no user-funded wallet.

> **Pending reconciliation against the mission statement.** Sections 5–7 assume
> a promoter-hire model inferred from conversation, not quoted from the mission
> statement. Once that document is available this needs one consistency pass.

---

## 1. The benchmark

The trigger: *DJs who main for The Beat make $1,500 for two nights.*

- **$750/night is one DJ's fee**, confirmed 2026-09-26 — not a whole-night
  budget split across a lineup. Every pass/fail line in this document uses it
  as a per-DJ target.
- No public pay data exists for The Beat or any named Brisbane venue, so the
  figure is unsourced externally. Nothing found contradicted it, and it is
  plausible as a main-room resident rate.
- **The legally enforceable floor is ~$513** for a 4-hour casual club set —
  Fair Work MA000081, "live performance employee level 9, performer category 2",
  effective 1 Jul 2026. DJs are classified as *performers*, not musicians.

Two targets, both used below: **$513 = compliance. $750 = competitive.**

---

## 2. Ticket price band

Sourced Brisbane door prices: The Beat **$14**; The MET **$15 Fri / $20 Sat**;
Prohibition **free, $10 Sat after 10pm**; Wonderland club nights **$20–30**.

**The norm is $0–20. $30 is the ceiling for a local lineup.** The existing
pricing slider runs 0–200 in $5 steps, which lets a DJ price far outside the
market. Cost, not disinterest, is the documented primary barrier to live-music
attendance in Australia.

---

## 3. Who pays the platform fee — buyer, displayed all-in

**Decision: buyer-pays, one all-in price from the first screen.**

1. **Every Australian platform that publishes a rate card defaults to
   buyer-pays** — Humanitix ("you take home 100% of the ticket sale"),
   Eventbrite AU, TryBooking's ticket fee, Tixel, and Resident Advisor
   ("completely free for promoters").
2. **Organiser-pays is a 12% DJ pay cut** against competitor organiser-side
   costs of roughly 0–2.5%. On the supply-constrained side of a cold-start
   platform that is the one place N3ON cannot be worst-in-market.
3. **GST makes organiser-pays worse.** Most DJs are under the $75,000 threshold,
   aren't GST-registered, and **cannot reclaim the input credit** — the GST
   becomes dead cost on top of the 12%.

**But buyer-pays must not mean drip pricing.** The ACCC requires the total as a
single figure including unavoidable fees; drip pricing is the conduct penalised
at Dendy Cinemas and behind the Ticketek/Ticketmaster changes. The Unfair
Trading Practices Act 2026 tightens this from 1 Jul 2027.

Adopt the **DICE pattern**: charge the buyer economically, show one all-in price
on the map pin, event card and detail view, itemise the fee only in the order
breakdown.

> **Code impact:** `EventDetailView` currently shows `$\(Int(ticketPrice * qty))`
> — the face value. The displayed figure must become the all-in charge.

---

## 4. Commission — 12% GST-inclusive, floor cut to $0.50

**The 12% is GST-inclusive** (decided 2026-09-26). Buyer-side load versus
competitors:

| Face | N3ON 12%/$1 | Humanitix | Eventbrite AU |
|---|---|---|---|
| $5 | **$1.00 (20.0%)** | $1.31 (26.2%) | $1.46 (29.2%) |
| $10 | $1.20 (12.0%) | $1.53 (15.3%) | $1.73 (17.3%) |
| $20 | $2.40 (12.0%) | $1.97 (9.8%) | $2.26 (11.3%) |
| $30 | $3.60 (12.0%) | $2.41 (8.0%) | $2.80 (9.3%) |

- **Cheaper than Eventbrite below $17.90 face; cheaper than Humanitix below
  $14.33.** At the $10–18 club-entry prices that dominate Brisbane, 12% is
  genuinely competitive — their ~$1 fixed component is brutal on cheap tickets.
  *(Because the 12% is GST-inclusive, these crossovers hold as stated.)*
- **At $25–30+ it is high** (12% vs 8–9.3%).
- Against the real nightlife comparators it is level: DICE ~10–12%, RA ~10%.
- **Cut the $1 floor to $0.50, and to zero on free events.** The floor binds
  below $8.33 and is punitive at $5 (20%). On a 200-person free event — normal
  in Brisbane before 10pm — "12% or $1, whichever is greater" charges **$200**
  for an event that generated no revenue.

**Net take is thinner than 12% looks.** On a $30 ticket the buyer pays $33.60.
The $3.60 commission is GST-inclusive, so **$3.27 is revenue**; Stripe takes
$0.87 on the gross charged, leaving **$2.40 = 8.0% of face**. At $20 it is
**7.5%**; at $10, **6.0%**. Stripe AU drops to 1.65% + $0.30 on 1 Oct 2026.

GST on Stripe's fee is reclaimable as an input credit once registered.

**The platform bears processing out of its commission** — the buyer-pays
convention every competitor uses. **The DJ pool keeps full face value.**

---

## 5. Per-DJ outcomes — established licensed venue

> **Superseded by §7 for the actual pop-up premise**, retained for comparison.

200-cap room at 70% fill = 140 tickets, buyer-pays except A:

| Format | $25 face, 4 DJs | $30 sellout | Tickets for 4×$750 at $25 |
|---|---|---|---|
| **A. Current code** (12% organiser-pays, venue 40% of door) | **$83** | $371 | 489 |
| B. 12% buyer-pays, venue 40% of door | $161 | $503 | 377 |
| C. 12% buyer-pays, venue $0 door | $511 | $1,103 | 182 |
| D. 12% buyer-pays, venue $0 door, venue absorbs costs | **$875** | $1,500 | 120 |

**Two caveats.** The "tickets needed" column silently grows the room — 489 is
impossible in a 200-cap venue, so format A's honest verdict is *unachievable at
any realistic price*. And A/B/C charge the full $1,588 of event costs to the DJ
pool, which §6 says is wrong for a promoter-hire night; on that allocation
format A pays roughly **+$356** at $20 (not negative) and **$768** at a $30
sellout, and **C converges on D**.

**The directional finding holds: the platform's own percentage barely moves DJ
pay.** Cutting commission 12%→7% changes the required ticket count by zero
(120 either way at $25). The venue's door share is the lever — worth ~4× the
platform fee.

---

## 6. Event costs — licensed-venue baseline

| Line item | Cost | Basis |
|---|---|---|
| OneMusic RMFD licence | $438 | $2.19/person admitted (RMFD guide, Jul 2026) |
| Crowd controllers | $675 | 2 required for 101–200 patrons (QLD Liquor Reg 2002); 5h × $67.50 |
| Public liability, one-off | $475 | Category B event cover |
| **Total** | **$1,588** | |

For a promoter-hire night most of this sits with the **venue**: sound tech is
the venue's, and the OneMusic licensee is the venue operator since the licence
attaches to the premises. Security is genuinely deal-dependent. **The promoter's
exposure moves from line items to bar-shortfall risk** — a probabilistic cost.

**On the 60/40 split.** The intended headline split is **60% DJ pool / 40%
venue**, which is what `EventDraftViewModel` implements (`djPoolRatio` 0.6,
`venueShareRatio` 0.4). The research finding is narrower than "that's wrong":
**no Australian source was found supporting a 40% venue share of the *door* for
a DJ club night.** Peak bodies reportedly document venue-keeps-residual-door-
plus-bar as the standard *venue-booked* deal — but the three sources cited for
that (Live Toolkit, Music Victoria, Music NT) were never directly reachable, so
treat the provenance as unverified. The **only specific figure found anywhere
was one venue at 20%**, which makes the "~30% ceiling" quoted earlier one
datapoint generalised rather than an established limit — and means **40% is
double the only real observation in the evidence base.** In *promoter-hire* deals the venue takes 0% of the
door and is paid via a bar minimum instead.

**Under the pop-up premise (§7) the question largely dissolves:** the space is
paid a **hire fee**, so there is no door percentage to negotiate. The 60/40
split matters for the licensed-venue case, where it is worth testing against
what Brisbane venues actually ask for — one of the phone calls in §15.

---

## 7. The pop-up premise — the actual model

Venues are unconventional, non-purpose-built spaces (warehouse, gallery,
rooftop, retail) that **self-list as one-off pop-up hosts outside normal
hours**, described as handling their own licensing.

### "Spaces handle their own permits" does not survive

**No council permit is needed** — genuinely counterintuitive. Under the Events
Local Law 2022 a "prescribed event" requires 1,000+ attendance with an
assessable risk, or 2,000+ without. **Both limbs require at least 1,000
attendance**, so at 100–300 patrons nothing is triggered whatever the risk
classification. The old Entertainment Venues local law was repealed.

**The fatal gate is the Building Act 1975, and it lands on the space owner.**
Class 9b covers buildings where people assemble; a warehouse is 7b, a shop 6.
Sections 110, 114(3), 115 and 118 all read *"the owner must ensure"*, each at
**165 penalty units**, two with executive liability. Until a **building
certifier** approves a classification change and issues a **new certificate of
occupancy**, lawful public-assembly occupancy is **zero**. The only concession
covers buildings existing before 14 December 1993, still needs a certifier, and
still enforces fire-fighting and emergency-lighting provisions.

**Liquor is a closed shop.** The Commercial Public Event Permit is for
**existing licensees only**; the Community Liquor Permit for **non-proprietary
clubs or all-proceeds-to-community bodies only**. A for-profit promoter and an
unlicensed warehouse are both ineligible. Section 173 deems the **owner** to
have sold the liquor where they permit an unlicensed sale — including alcohol
bundled into a ticket price. **The only lawful path is dry or genuine BYO with
no sale of any kind.**

> These statutory readings come from a research pass, not a lawyer, and the
> absolute claims ("occupancy is zero", "no temporary exemption exists") warrant
> a building certifier and a liquor lawyer before the product gate is built on
> them.

**Minimum viable version:**

1. **Only already-approved spaces may list** — gate on verified upload of a
   certificate of occupancy showing **Class 9b** plus planning approval. This
   changes the product from "activate unconventional space" to **"fill idle
   capacity in already-compliant venues"**. Brisbane has real inventory
   (The Joinery 300, Lightspace 500, EC Venue 200).
2. **Dry by default**, or route alcohol through an engaged licensee.
3. **The promoter holds the event-side obligations** — $20m public liability
   naming the owner, OneMusic, crowd controllers, a curfew set by the noise
   standard for that location.
4. **Capacity and curfew as enforced fields**, capped by the certificate of
   occupancy and the noise assessment.

> **`VenueComplianceForm` is nowhere near this.** It collects one licence type
> and one contractor name from hardcoded placeholder lists, uploads no
> documents, verifies nothing, and — per the security audit — lets submitters
> approve their own submissions. Under this premise it is the entire legal basis
> for putting 300 people in a warehouse.

### The economics

Promoter-side stack for a dry 200-patron event: OneMusic $438, crowd controllers
$540–1,080, $20m public liability $360–620, portable toilets $380–450, PA
$295–1,500, first aid $400–800 *(estimate)*, generator $200–500 *(estimate)* =
**$2,613–5,388**, plus venue hire $1,500–3,500 → **$4,113–8,888**. Benga Box in
Brisbane — a fitted BYO warehouse taking 200 guests to 3am — charges **$2,200**.

At mid-range costs plus the $2,200 benchmark:

| Scenario | Door | Costs | Left | Per DJ ×4 |
|---|---|---|---|---|
| 200cap, 70%, $20 | $2,800 | $6,069 | −$3,269 | −$817 |
| 200cap, 70%, $25 | $3,500 | $6,069 | −$2,569 | −$642 |
| 200cap, 70%, $30 | $4,200 | $6,069 | −$1,869 | −$467 |
| 200cap, **sellout**, $30 | $6,000 | $6,200 | −$200 | −$50 |
| 300cap, sellout, $35 | $10,500 | $6,420 | $4,080 | $1,020 |

> **⚠ This table overstates the loss — three ways.**
>
> 1. **It double-counts the venue's fittings.** Benga Box is *fitted*; a Class 9b
>    space necessarily has power and sanitary facilities. Yet the stack adds
>    toilets, a generator "(no mains)" and a PA on top — **$1,662.50 of fittings
>    charged against a fitted venue's hire price.** Removing the overlap moves
>    the sellout row to **+$366/DJ**.
> 2. **Two unsourced estimates decide the sign.** First aid and generator
>    contribute **$950 at mid** against a stated $200 loss. Drop them: **+$187/DJ**.
> 3. **Mid-of-range is wrong on right-skewed ranges.** PA spans $295–1,500.
>    Across the sourced ranges the sellout row spans **−$722 to +$472/DJ**.
>
> **Honest statement: a sold-out 200-cap pop-up at $30 is approximately
> break-even**, in a range from −$722 to +$472 per DJ — and the distribution is
> skewed positive, since both corrections push the same way.

**What survives, and is stronger than the table:** the cost stack is **92.9%
fixed** ($5,762.50 of $6,200.50) — only OneMusic varies with headcount. A pop-up
**rents a venue's entire fixed-cost base for one night** and amortises it over
one night's door. A licensed club amortises the same base across every trading
night *and* has a bar as a second revenue line. At ~$50/head, 140 patrons is
~$7,000 of bar — more than the entire cost stack. **That is why a club can pay
DJs on a $14 door and a dry pop-up cannot.**

### The one configuration that works

"Fitted" = already has PA, toilets and mains power, which removes ~$1,660 — and
is also the only *lawful* version per the gate above.

| Scenario | Door | Costs | Left | Per DJ |
|---|---|---|---|---|
| 200cap, 70%, $30, 2 DJ, unfitted | $4,200 | $6,069 | −$1,869 | −$935 |
| 200cap, 70%, $30, 2 DJ, **fitted** | $4,200 | $4,407 | −$207 | −$103 |
| 200cap, sellout, $30, 2 DJ, fitted | $6,000 | $4,538 | $1,462 | $731 |
| **300cap, 70%, $30, 2 DJ, fitted** | $6,300 | $4,560 | $1,740 | **$870** ✅ |
| 300cap, 70%, $30, **4 DJ**, fitted | $6,300 | $4,560 | $1,740 | $435 |

The same row unfitted pays **$39/DJ**. So **the recommendation lives or dies on
the space being already fitted**, not on capacity or price.

Break-even ticket price for two DJs at $750: 200cap/70% unfitted **$54.07**;
200cap/70% fitted **$42.19**; **300cap/70% fitted $28.86**; 300cap sellout
fitted **$20.86** — adjacent to the $0–20 norm, not inside it.

**Recommended configuration: a pre-vetted, already-compliant, already-fitted
300-capacity space, two-DJ bill at $30 — $870/DJ at 70% fill**, no sellout
required — but note $30 sits **at** the Brisbane ceiling (§2), not inside it.
The configuration works only at the top of the local price range.

**Three honest caveats on it:**

- **Superannuation, if payouts are fees** (§10): $870.05 ÷ 1.12 = **$776.83** —
  a **3.6% margin** over $750, not comfortable.
- **The lineup size, not the curve, is the constraint** — see below.
- **Estimates still carry weight.** Strip the two `[EST]` lines and the row is
  ~$1,345/DJ; leave them and apply super and it is $777. True range ≈ **$777–
  $1,345**.

**Two levers, both necessary, neither sufficient:** fitting the space is worth
~$1,660/event; halving the lineup from four DJs to two doubles per-DJ pay.

### Who bears a losing night

The tables above show negative per-DJ figures — the unfitted version of the
recommended row is **−$935/DJ**. That loss does not fall evenly:

- **A supporting DJ on a genuine revenue share has no downside past zero.**
  §10's revenue-share logic protects them exactly: a quiet night pays less, and
  nothing makes them liable for a shortfall.
- **The host DJ, acting as promoter, personally carries the entire negative
  residual** — under the pop-up premise that is the whole cost stack, not just a
  thin margin.

**In the recommended two-DJ configuration that is half the lineup.** A host DJ
can end a night owing money, and the product must say so before they commit to a
booking. This is a trading loss, distinct from the superannuation exposure in
§10 — the creator DJ is exposed to both.

### How the DJ pool divides — gradual curve, not rank weights

**Two separate systems, not to be conflated.** The coin/rank weights
(5→25, 4→10, 3→7, 2→5) exist to gate the **tally** — whether an event accrues
enough lineup weight to leave limbo. **They are not payout ratios.** Payouts are
a bespoke gradual curve, as real billing works: the headliner takes more,
supports still earn properly.

**Two DJs, $1,740 pool** (the recommended 300-cap, 70% fill, $30, fitted):

| Host / support | Host | Support | |
|---|---|---|---|
| 50 / 50 | $870 | $870 | both clear the benchmark |
| 55 / 45 | $957 | $783 | both clear the benchmark |
| **57 / 43** | $992 | **$748** | threshold — support at the benchmark |
| 60 / 40 | $1,044 | $696 | above award floor, below benchmark |
| 70 / 30 | $1,218 | $522 | above award floor |
| 75 / 25 | $1,305 | **$435** | **support below the award floor** |

**The support DJ clears $750 while the host takes ≤ 56.9%, and clears the $513
award floor while the host takes ≤ 70.5%.** So a gradual curve has real room —
anything up to a 70/30 host premium stays lawful, and up to ~57/43 keeps both
DJs above the competitive benchmark. **The curve is not the problem.**

**Four DJs — the pool size is the problem, not the shape:**

| Pool | Curve | Payouts | Result |
|---|---|---|---|
| $1,740 (70% fill) | 40/25/20/15 | $696 / $435 / $348 / $261 | 0 of 4 clear the benchmark, 1 of 4 the floor |
| $1,740 (70% fill) | equal | $435 each | **none clear the award floor** |
| **$4,243 (sellout)** | 40/25/20/15 | $1,697 / $1,061 / $849 / $636 | 3 of 4 clear the benchmark, **4 of 4 the floor** |
| **$4,243 (sellout)** | **35/25/22/18** | $1,485 / $1,061 / $933 / **$764** | **all four clear the benchmark** |

> **That last row has a $13.74 margin, and superannuation erases it.** If
> payouts are treated as fees rather than a genuine revenue share (§10), the
> bottom DJ's $763.74 becomes **$681.91 in hand** — a fail. Under super the row
> is 3 of 4, not 4 of 4 ($1,326 / $947 / $833 / $682). "All four clear" holds
> **only** on the revenue-share characterisation, which §10 says must never be
> assumed casually.
>
> *(Pool derivation: 300 × $30 = $9,000 door, less fitted costs of
> 300 × $2.19 + $4,100 = $4,757, leaves $4,243.)*

**The governing rule, stated precisely:**

> **Pool size sets the ceiling on how many DJs can clear a threshold —
> `min(DJs, floor(pool ÷ threshold))`. Curve shape decides whether you actually
> reach that ceiling.**

The `min` matters: on the $4,243 pool `floor(4243 ÷ 513)` = 8, which is
meaningless for a four-DJ bill. The ceiling is whichever is smaller — the
lineup or what the pool can carry.

From a $1,740 pool: `floor(1740 ÷ 513)` = **3 DJs could clear the award floor**,
and `floor(1740 ÷ 750)` = **2 could clear the benchmark**. The 40/25/20/15 curve
only gets 1 over the floor, so that curve is leaving two lawful bookings on the
table — a strictly-decreasing 30/29.6/29.5/10.9 would pay $522/$515/$513/$190
and clear the floor for three.

**Flattening helps only above the line, and hurts below it.** A flat split
raises the minimum, so it is better *iff the equal-split value already clears
the threshold* — i.e. iff pool ≥ DJs × threshold. On $4,243 the equal split is
$1,061, comfortably over $750, so the flatter 35/25/22/18 beats the steeper
40/25/20/15. On $1,740 the equal split is $435, under the floor, so flattening
gets **nobody** over while the steeper curve at least gets **one** DJ over.

**Thresholds for a four-DJ bill:** 4 × $513 = **$2,052 to be lawful**;
4 × $750 = **$3,000 to be competitive**. A 70%-fill $1,740 pool clears neither.

**This resolves the tension I previously claimed** between the ranking system
and the economics. The rank ladder gates *who hosts*; the payout curve decides
*how the night divides*. They are compatible.

---

## 8. Sponsorship — keep the clause, don't model the revenue

- A brokered club-night deal at 100–500 capacity is **$500–2,000 cash plus
  product**. At 15%, **$75–300 per event** — noise. In-kind is most of what's
  offered and **is not commissionable**.
- **National brands will not engage a 200-capacity night individually.**
  Agencies won't touch a property under ~$500k.
- **15% is exactly market rate** (SponsorMyEvent 15%, Sponsoo 20%, agencies
  15–20%). Keep the clause; it costs nothing.
- **Aggregation is the only path to materiality** — one category-exclusive
  seasonal package across 20–25 events, estimated **$30,000–80,000** →
  **$4,500–12,000 commission**; 4–6 a year → $18,000–72,000.
- **Model year-1 sponsorship at $0.** Build the data assets instead: verified
  scanned attendance, DOB-derived age distribution, opt-in demographics,
  post-event content. They're the precondition for any package, they improve
  ticketing anyway, and they are the kind of audience evidence ABAC
  determinations have turned on.

> **Caveat on the 80% figure.** Earlier drafts cited a "≥80% adult" placement
> threshold as if it were in the ABAC Code. **No 80% figure appears in the Code
> text retrieved** — Parts 3(b) and 3(c) are qualitative, requiring that
> age-restriction controls be applied and that placement avoid audiences where
> they are absent. The 80% number may come from determinations or separate
> placement guidance rather than the Code itself. **Verify before relying on it**
> — it is currently the stated justification for building the data assets.

**The alcohol risk is Queensland, not ABAC.** The ABAC Code expressly does not
apply to sponsorship agreements, only to marketing arising from them. The real
exposures, in order: **QLD Liquor Act s142ZZC** — advertising discounted liquor
or on-premises prices is an offence and s142ZZ makes the licensee liable for
promotions another person is "allowed" to run, so **an in-app "$5 shots till
midnight" listing puts the venue in breach with N3ON as the channel**; then
serving alcohol creative or push notifications to under-18 accounts; then paid
or influencer DJs under 25 in sponsor hero creative.

N3ON does **not** need to become an 18+ app.

---

## 9. Government aid — one-off runway, ~$0–7,500 likely

- **Realistic 12-month reachable total: $0–42,500; most likely $0–7,500.** Every
  discretionary Queensland startup grant is closed with no announced round.
- **R&D Tax Incentive is the only genuinely reachable platform money** —
  refundable at ~43.5% under $20M turnover, $20,000 minimum spend. Requires a
  **Pty Ltd** and **real wage expenditure**; a founder coding unpaid has
  near-zero eligible spend. Routine app work doesn't qualify.
- **Business Basics ($7,500, no co-contribution)** is the likeliest quick win.
- **LGBTQ+ government grants pay a commercial nightclub $0** — restricted to
  community groups and incorporated NFPs.
- Money that improves *event* economics (Revive Live $150k, Growing Gigs, Live
  Music Venue Business Grants — venues ≤500 capacity, for-profit allowed) goes
  to venues and artists, never the platform. Worth knowing: DJ sets playing
  others' recordings may fail "original live music" tests.
- **Never model grants as recurring unit economics.**

---

## 10. Paying the DJs — superannuation decides the architecture

**The ATO names DJs explicitly.** SGAA s12(8) deems the performer an employee of
the payer and — unlike the ordinary contractor test — is **not** limited to
contracts "wholly or principally for labour". An ABN, an invoice, a one-off
booking, the "contractor" label, hobbyist status, and a signed Statement by a
Supplier **all fail to displace it**.

For $750 in the DJ's hand:

| Treatment | Per DJ | 4-DJ night |
|---|---|---|
| Genuine revenue share, or DJ bills through a company/trust | **$750** | $3,000 |
| ABN sole trader, super payable *(default outcome)* | **$840** | $3,360 |
| Casual employee under MA000081 | ~$848–855 | ~$3,400 |
| **No ABN — top-rate withholding** | **$1,585** | $6,340 |

**Mandate an ABN at onboarding** — Stripe doesn't collect one for individuals,
and the hobby form doesn't help because a gigging DJ is carrying on an
enterprise.

### The escape hatch fits what N3ON already is

The ATO's own example: where ticket sales are collected, costs and shares
deducted, and **the balance** paid to the performer as a joint venture, **no
super is payable**. That is structurally the DJ pool.

**The condition is that it must be a real share, not a disguised fee:**

- **Never promise a fixed amount.** The product may say "you keep X% of the
  door"; it must not say "you'll get $750".
- **The DJ must carry genuine venture risk.**
- **So $750 can only ever be an average at target fill, never a promise** —
  which is honest to the product, and is the difference between $750 and $840.

### The creator-DJ trap — the biggest liability here

The ATO has a directly analogous example: a lead performer paid a lump sum who
engages the others herself **personally owes their superannuation**.

**That is exactly the documented event-creation flow** — the host DJ invites the
lineup via chat and takes a higher share. On those facts a young sole-trader DJ
personally carries roughly **$270 a night of super for three peers**, plus the
super guarantee charge if missed (non-deductible, with interest).

**Shipping that flow without telling creator DJs is the single biggest liability
in this document.** The fix is a product decision: either the platform contracts
each DJ individually, or the creator expressly acts as **disclosed agent** for
the group.

### Two obligations, one decision

Structuring N3ON as a genuine **disclosed agent for suppliers** would both move
super liability to the principal *and* likely take it outside the "electronic
distribution platform" definition.

### SERR sets the onboarding data floor

Task-based gig services entered the Sharing Economy Reporting Regime on
**1 July 2024**. Reporting is **twice yearly, no threshold** — 31 January and
31 July — requiring per supplier: name, **date of birth**, address, email,
phone, **bank account details**, activity dates and amounts. **That exceeds what
Stripe collects for an AU individual.** Unresolved: whether lineup disbursements
are separately reportable — ask `sharingeconomyreporting@ato.gov.au`. **TPAR does
not apply.**

**Operationally super is worse than its price.** From 1 July 2026 Payday Super
requires contributions to reach each DJ's fund within **7 business days**, and
**super cannot be paid through Stripe** — roughly 600 individual contributions a
year at three nights a week.

---

## 11. Coins — do not build a wallet

**Keep coins as an internal `Int` rank weighting: no StoreKit, no top-up, no
user-facing balance.**

1. **App Store 3.1.3(e)** requires physical-event tickets to use payment methods
   *other than* IAP — Stripe or Apple Pay are mandatory, not merely allowed
   (verified: "Goods and Services Outside of the App"). A purchased coin that
   touched rank or visibility would likely engage 3.1.1 "unlock features or
   functionality" → IAP at 30%, though that reading is Apple's review discretion
   rather than guideline text.
2. **A sold stored-value balance spendable across many payees** looks like a
   non-cash payment facility under the Corporations Act, dragging in AFSL
   questions.

**Code consequence:** `INSUFFICIENT_COINS` as a purchase error, `User.coinBalance`,
and the coin-denominated `Transaction` ledger (`topUp`, `withdrawal`) all
describe a wallet that must not exist. `Transaction.amount` should be cents of
AUD, and the type list should lose `topUp`/`withdrawal`.

---

## 12. Money-flow architecture — the open legal question

Whether buyer funds touch N3ON's own Stripe balance decides the AFSL analysis,
safeguarding obligations, and exposure under Treasury's incoming PSP licensing
regime (exposure draft 12 Mar 2026, mandatory trust segregation).

- **Destination charges** route money through N3ON's balance → client-money
  expectations apply, and N3ON carries the rolling reserve and chargebacks.
- **Direct charges** on the connected account never do → both push to the
  organiser.

Stripe Payments Australia holds AFSL 500105; Zai (527370) and Airwallex (487221)
sell escrow and split-payment cover explicitly.

**This is for a financial services lawyer before any payout code is written.**

Unchanged from the security audit and incompatible with real money: tickets can
be minted client-side at price 0, and the QR is a permanent unsigned `userID`
that is never burned.

---

## 13. Platform break-even

Contribution per event, **12% GST-inclusive**:

| Face | Commission (incl GST) | Ex-GST | Processing | Chargeback | **Contribution** |
|---|---|---|---|---|---|
| $30 | $720.00 | $654.55 | $174.24 | $55 | **$425.31** |
| $20 | $480.00 | $436.36 | $136.16 | $45 | **$255.20** |
| $15 | $360.00 | $327.27 | $117.12 | $40 | **$170.15** |

Events per month, against fixed costs of **$619.97/month** plus salary — that
figure drives all nine cells below, and **no line-by-line breakdown of it
survives**, making it the one unauditable input in this section:

| Face | Fixed only | + $65k founder | + $95k market |
|---|---|---|---|
| **$15** | 4 | **40** | 56 |
| **$20** | 3 | **27** | 38 |
| $30 | 2 | 16 | 23 |

The table above assumes **sellouts**. At the 70% fill modelled elsewhere
(140 tickets), contribution falls to $178.64 at $20 and $119.11 at $15, giving:

| Fill assumption | $30 face | $20 face | $15 face |
|---|---|---|---|
| Sellout (200 tickets) | 16 | 27 | 40 |
| **70% fill (140 tickets)** | **23** | **38** | **57** |

At a $95k market salary the same grid is 23/38/56 at sellouts and **32/54/80**
at 70% fill — the $15/70% corner needs 80 events a month, which is past the
~100-event point where support alone forces a second hire.

**Planning number: 38–57 events/month at 70% fill**, or 27–40 at sellouts —
state which assumption is in use, and never blend them.

Against that, **~100 events/month** is where support alone (160–300 hours)
forces a first hire. **The window between "pays the founder" and "needs a second
person" is narrow** — and at $15 face with realistic fill it has essentially
closed. The GST-inclusive decision cost 13.3% of contribution.

**Infrastructure is not the near-term constraint.** AWS Sydney runs $1.83/month
at 500 MAU, $26.71 at 5k, $1,487 at 50k. But the earlier claim that this is
"0.02–0.6% of contribution at every scale" is not derivable — at 100
events/month it is **2.96%**, and on the high-concurrency AppSync branch
(~$8,400/month) **16.7%**.

**GST registration arrives before break-even.** The $75,000 threshold is
measured on GST-*exclusive* turnover, so as agent (turnover = $654.55/event)
it is **~10 events/month**; as principal (turnover = gross ticket sales),
**~1 event/month**. Both are $30 × 200-ticket figures — at the $15–20 band with
70% fill the agent threshold stretches to **~20 events/month at $20 face and
~27 at $15** (ex-GST commission of $305.45 and $229.09 respectively), while the
principal case stays near 1. Get agency terms in writing.

> **Unresolved contradiction:** the chargeback provision above charges N3ON the
> full $30 face of a reversed ticket, which presumes **merchant-of-record**
> liability — while this paragraph relies on **agent** treatment for the
> favourable threshold. The document cannot be agent for GST and principal for
> chargebacks. Same root decision as §12's Stripe charge type.

---

## 14. Engineering preconditions that outrank the format

1. **DataStore may silently lose chats.** No `DataStoreConfiguration` exists, so
   `syncMaxRecords` sits at its default (believed 10,000). With `Message`
   group-read, every client base-syncs every user's messages. Past the cap, base
   sync truncates and users' own chats may disappear. **Truncation behaviour is
   undocumented and must be tested** — but the fix (owner- or room-scoped
   `@auth` plus `syncExpressions`) also removes the quadratic subscription cost
   *and* the privacy leak already on record.
2. **Pinpoint shut down 30 October 2026** — build push against AWS End User
   Messaging.
3. **Cognito threat protection has no free tier** — $2,500/month at 50k MAU on
   the legacy rate (1.68× the rest of infrastructure), $1,000 on current
   Plus-tier pricing.
4. **Stripe Connect charge type decides the reserve** — 5–15% of turnover held
   **90–180 days**. At 20 events/month that is **$18,000–54,000 at the 90-day
   end, $36,000–108,000 at 180 days**. Both are computed at $30 × 200 tickets;
   at the $15–20 Brisbane band with realistic fill the turnover base — and so
   the reserve — is materially lower. It remains the most likely thing to kill
   the company while nominally profitable, and it applies **only** on the
   destination-charge branch. Same decision as §12.

---

## 15. What a human still has to do

1. **Ring three Brisbane venues** — do you take any percentage of ticketing;
   what is the bar minimum and the shortfall rule; who pays crowd controllers,
   OneMusic and sound tech; do we need our own public liability; and **do you
   already have ticketing exclusivity** (Festival Hall is Ticketmaster-only and
   bars third-party on-selling — a real threat to a commission model).
2. **Get a building certifier quote** for a Class 9b change on one candidate
   space. The $27,000–130,000 first-event figure is an estimate; certifier
   sources blocked automated access.
3. **A financial services lawyer** on Stripe charge type (§12), and **an
   accountant** on the revenue-share characterisation and the creator-DJ super
   exposure (§10).
4. **Phone Arts Queensland (07 3034 4016)** on Growing Gigs and whether DJ
   events qualify.
5. **Confirm whether Benga Box's $2,200 includes PA, toilets and power** — it is
   the single largest swing in the model ($1,662.50).
6. **Decide the payout curve.** Not "equal vs rank-weighted" — the rank weights
   gate the tally, not payouts (§7). The real decision is the host premium: at
   two DJs the host may take up to **56.9%** for both to clear $750, or up to
   **70.5%** for the support to stay above the $513 award floor. Past that, the
   support DJ is below the legal minimum for the set.

---

## 16. Confidence and gaps

**Verification status.** Every figure in this document has been re-derived by an
independent pass that did not write it. The arithmetic is signed off. What
follows is what the arithmetic *rests* on.

**The recommendation is supportable pending one phone call, not yet proven.**
The fitted 300-cap / two-DJ / $30 configuration pays $870/DJ at 70% fill — but:

| Dependency | Status |
|---|---|
| **Does a fitted 300-cap compliant space hire for ~$2,200?** | **Unverified — and load-bearing.** The unfitted version of the same row pays **$39/DJ**. The $1,662.50 fitted saving is subtracted while the hire price stays at Benga Box's $2,200; nobody has confirmed that $2,200 includes PA, toilets and power. If it doesn't, the recommendation has no venue. |
| **Is $750 the right benchmark?** | Confirmed by you as one DJ's fee, but externally unsourced. After super the margin is 3.6% — a 5% error either way flips the result. |
| **$30 ticket price** | Sits *at* the Brisbane ceiling, so there is no headroom if costs run high. |
| **The Class 9b listing gate** | Statutory readings from a research pass, not a lawyer. Gates *building the gate*, not the economics — can run in parallel. |

**Known-unverified inputs:** OneMusic $2.19/head, crowd controllers $45–90/hr,
$20m liability $360–620, PA $295–1,500, both `[EST]` lines (first aid,
generator), hire $1,500–3,500, the $619.97/month fixed cost base (no breakdown
survives), competitor rate cards, Fair Work MA000081's $513 derivation, all AWS
figures, `syncMaxRecords`' default, and the ABAC 80% threshold's true source.

**Changelog of corrected errors** (kept short deliberately — the current text is
what matters):

- Stripe processing was charged twice, to both the DJ pool and the platform;
  conservation failed by $108.64. Platform now bears it.
- The pop-up loss table overstated the loss three ways (fittings double-count,
  estimate-driven sign, mid-of-range on skewed ranges).
- Coin/rank weights were wrongly applied as payout ratios, producing a false
  "ranking breaks the economics" finding. Retracted.
- Net take, break-even counts and GST thresholds were restated after the
  GST-inclusive decision.
- The planning band "~40–55 events/month" spliced two fill assumptions.
