#!/usr/bin/env python3
"""
N3ON financial model — reproduces every figure in FINANCIAL-FORMAT.md.

Run with no arguments to print all tables. Every number the document states
should appear here; if they diverge, the document is wrong.

    python3 financial_model.py

All money AUD. Figures marked SOURCED carry provenance in the document;
figures marked ESTIMATE are unverified and flagged as such in output.

Two independent verification passes checked these figures (2026-09-26).
"""

from dataclasses import dataclass, field

# ─────────────────────────────────────────────────────────── targets

BENCHMARK = 750.0   # one DJ's fee per night (The Beat; confirmed by owner)
AWARD_FLOOR = 513.0  # Fair Work MA000081, performer cat. 2, 4hr casual set

# ─────────────────────────────────────────────────────────── platform

COMMISSION_PCT = 0.12      # GST-INCLUSIVE
COMMISSION_FLOOR = 0.50    # per ticket; zero on free events
GST_DIVISOR = 1.1          # commission is GST-inclusive
STRIPE_PCT = 0.017         # 1.65% from 1 Oct 2026
STRIPE_FIXED = 0.30
STRIPE_DISPUTE = 25.0
CHARGEBACK_RATE = 0.005
FIXED_MONTHLY = 619.97     # UNAUDITABLE — no breakdown survives
SUPER_RATE = 0.12          # if payouts are fees, not a revenue share

# ─────────────────────────────────────────── per-event costs, licensed venue

ONEMUSIC_PER_HEAD = 2.19   # SOURCED: OneMusic RMFD guide, Jul 2026


def controllers(patrons: int) -> int:
    """SOURCED: QLD Liquor Regulation 2002 ratios, trading after 1am."""
    if patrons <= 100:
        return 1
    if patrons <= 500:
        return (patrons - 1) // 100 + 1
    return 5 + ((patrons - 500) + 249) // 250


# ─────────────────────────────────────────── pop-up cost stack (unconventional)

POPUP = {                      # (low, high, sourced)
    "Crowd controllers 2x6h":  (540, 1080, True),
    "Public liability $20m":   (360, 620, True),
    "Portable toilets x3":     (380, 450, True),
    "PA / DJ system":          (295, 1500, True),
    "First aid 2 personnel":   (400, 800, False),
    "Generator (no mains)":    (200, 500, False),
}
FITTED_REMOVES = ("PA / DJ system", "Portable toilets x3", "Generator (no mains)")
HIRE_BENCHMARK = 2200.0        # Benga Box: 200 guests, BYO, to 3am
HIRE_RANGE = (1500.0, 3500.0)


def popup_stack(patrons: int, fitted: bool = False, at: str = "mid") -> float:
    """Promoter-side cost for a dry pop-up, excluding venue hire."""
    base = patrons * ONEMUSIC_PER_HEAD
    for label, (lo, hi, _) in POPUP.items():
        if fitted and label in FITTED_REMOVES:
            continue
        base += lo if at == "low" else hi if at == "high" else (lo + hi) / 2
    return base


# ─────────────────────────────────────────────────────────── platform economics

def contribution(face: float, tickets: int) -> dict:
    """Platform contribution per event. Commission is GST-inclusive."""
    gross = max(face * tickets * COMMISSION_PCT, tickets * COMMISSION_FLOOR)
    ex_gst = gross / GST_DIVISOR
    charged = face * tickets + gross          # buyer pays face + commission
    processing = charged * STRIPE_PCT + tickets * STRIPE_FIXED
    disputes = tickets * CHARGEBACK_RATE
    chargeback = disputes * (STRIPE_DISPUTE + face)
    return {
        "gross": gross, "ex_gst": ex_gst, "gst": gross - ex_gst,
        "charged": charged, "processing": processing,
        "chargeback": chargeback,
        "contribution": ex_gst - processing - chargeback,
        "net_take_pct": (ex_gst - processing) / (face * tickets) * 100,
    }


def events_needed(face: float, tickets: int, salary: float) -> int:
    """Events per month to cover fixed costs plus salary (incl. 12% super)."""
    import math
    monthly = FIXED_MONTHLY + salary * (1 + SUPER_RATE) / 12
    return math.ceil(monthly / contribution(face, tickets)["contribution"])


# ─────────────────────────────────────────────────────────── payout curves

def split(pool: float, curve: list) -> list:
    total = sum(curve)
    return [pool * c / total for c in curve]


def ceiling(pool: float, djs: int, threshold: float) -> int:
    """min(DJs, floor(pool / threshold)) — how many CAN clear the threshold."""
    return min(djs, int(pool // threshold))


# ─────────────────────────────────────────────────────────── output

def rule(title):
    print("\n" + "=" * 74)
    print(title)
    print("=" * 74)


def main():
    print(f"N3ON financial model — benchmark ${BENCHMARK:,.0f}/DJ, "
          f"award floor ${AWARD_FLOOR:,.0f}")
    print("Commission 12% GST-INCLUSIVE; platform bears Stripe; "
          "DJ pool keeps full face value.")

    # ---- §4 net take
    rule("§4  NET TAKE  (12% GST-inclusive)")
    print(f"  {'face':>6} {'buyer pays':>11} {'ex-GST':>8} {'Stripe':>8} "
          f"{'net':>8} {'% of face':>10}")
    for face in (30, 20, 10):
        r = contribution(face, 1)
        print(f"  ${face:>5} ${r['charged']:>10,.2f} ${r['ex_gst']:>7,.2f} "
              f"${r['processing']:>7,.2f} "
              f"${r['ex_gst'] - r['processing']:>7,.2f} "
              f"{r['net_take_pct']:>9.1f}%")

    # ---- §13 contribution + break-even
    rule("§13  CONTRIBUTION PER EVENT  (200 tickets = sellout)")
    print(f"  {'face':>6} {'comm incl':>10} {'ex-GST':>9} {'processing':>11} "
          f"{'chargeback':>11} {'contribution':>13}")
    for face in (30, 20, 15):
        r = contribution(face, 200)
        print(f"  ${face:>5} ${r['gross']:>9,.2f} ${r['ex_gst']:>8,.2f} "
              f"${r['processing']:>10,.2f} ${r['chargeback']:>10,.2f} "
              f"${r['contribution']:>12,.2f}")

    rule("§13  EVENTS/MONTH TO BREAK EVEN")
    print(f"  fixed costs ${FIXED_MONTHLY:,.2f}/mo  [UNAUDITABLE - no breakdown]")
    print(f"  {'face':>6} {'fill':>9} {'fixed only':>11} {'+$65k':>7} {'+$95k':>7}")
    for face in (15, 20, 30):
        for tickets, label in ((200, "sellout"), (140, "70% fill")):
            print(f"  ${face:>5} {label:>9} "
                  f"{events_needed(face, tickets, 0):>11} "
                  f"{events_needed(face, tickets, 65000):>7} "
                  f"{events_needed(face, tickets, 95000):>7}")

    # ---- §7 pop-up stack
    rule("§7  POP-UP COST STACK  (dry, 200 patrons)")
    for at in ("low", "mid", "high"):
        s = popup_stack(200, fitted=False, at=at)
        print(f"  unfitted {at:>4}: ${s:>8,.2f}  + hire "
              f"${HIRE_RANGE[0]:,.0f}-{HIRE_RANGE[1]:,.0f} "
              f"= ${s + HIRE_RANGE[0]:>8,.0f} - ${s + HIRE_RANGE[1]:,.0f}")
    print(f"  fitted mid:     ${popup_stack(200, True):>8,.2f}   "
          f"(fitted removes PA + toilets + generator)")
    print(f"  fitted saving:  ${popup_stack(200) - popup_stack(200, True):>8,.2f}")
    print("  ESTIMATE lines (first aid, generator) contribute "
          f"${(400+800)/2 + (200+500)/2:,.2f} at mid — they decide the sign.")

    # ---- §7 scenarios
    rule("§7  PER-DJ OUTCOMES  (pop-up; costs at mid + $2,200 hire)")
    print(f"  {'scenario':<34}{'door':>8}{'costs':>9}{'left':>9}{'per DJ':>9}")
    for cap, fill, price, djs, fitted in (
        (200, 0.70, 20, 4, False), (200, 0.70, 25, 4, False),
        (200, 0.70, 30, 4, False), (200, 1.00, 30, 4, False),
        (300, 1.00, 35, 4, False),
        (200, 0.70, 30, 2, False), (200, 0.70, 30, 2, True),
        (200, 1.00, 30, 2, True),
        (300, 0.70, 30, 2, True), (300, 0.70, 30, 4, True),
        (300, 1.00, 30, 4, True),
    ):
        tickets = round(cap * fill)
        door = tickets * price
        costs = popup_stack(tickets, fitted) + HIRE_BENCHMARK
        left = door - costs
        per = left / djs
        tag = ("PASS" if per >= BENCHMARK else "award" if per >= AWARD_FLOOR
               else "LOSS" if per < 0 else "FAIL")
        label = (f"{cap}cap {fill*100:.0f}% ${price} {djs}DJ"
                 f"{' fitted' if fitted else ''}")
        print(f"  {label:<34}${door:>7,.0f}${costs:>8,.0f}"
              f"${left:>8,.0f}${per:>8,.0f}  {tag}")

    # ---- §7 payout curves
    rule("§7  PAYOUT CURVES  (gradual, NOT the coin/rank weights)")
    pool70 = 300 * 0.70 * 30 - (popup_stack(210, True) + HIRE_BENCHMARK)
    pool100 = 300 * 30 - (popup_stack(300, True) + HIRE_BENCHMARK)
    print(f"  pool at 300cap/70%/$30 fitted:  ${pool70:,.2f}")
    print(f"  pool at 300cap/sellout/$30:     ${pool100:,.2f}")

    print(f"\n  Two DJs on ${pool70:,.0f}:")
    for h in (50, 55, 57, 60, 65, 70, 75):
        host, sup = split(pool70, [h, 100 - h])
        v = ("both clear benchmark" if sup >= BENCHMARK else
             "support above award floor" if sup >= AWARD_FLOOR else
             "support BELOW AWARD FLOOR")
        print(f"    {h}/{100-h:<3} ${host:>8,.0f} / ${sup:>7,.0f}   {v}")
    print(f"    support clears ${BENCHMARK:,.0f} while host <= "
          f"{100 - BENCHMARK/pool70*100:.1f}%")
    print(f"    support clears ${AWARD_FLOOR:,.0f} while host <= "
          f"{100 - AWARD_FLOOR/pool70*100:.1f}%")

    print(f"\n  Ceiling = min(DJs, floor(pool/threshold)):")
    for pool, label in ((pool70, "70% fill"), (pool100, "sellout")):
        print(f"    ${pool:>8,.0f} ({label:>8}): "
              f"{ceiling(pool, 4, AWARD_FLOOR)} of 4 can clear the floor, "
              f"{ceiling(pool, 4, BENCHMARK)} of 4 the benchmark")

    print(f"\n  Four DJs:")
    for pool, label in ((pool70, "70% fill"), (pool100, "sellout")):
        for curve in ([40, 25, 20, 15], [35, 25, 22, 18], [25, 25, 25, 25]):
            pays = split(pool, curve)
            nb = sum(1 for p in pays if p >= BENCHMARK)
            nf = sum(1 for p in pays if p >= AWARD_FLOOR)
            print(f"    {label:>8} {str(curve):<18} "
                  + " / ".join(f"${p:>6,.0f}" for p in pays)
                  + f"   {nb}/4 bench, {nf}/4 floor")
    print(f"\n  Thresholds for a four-DJ bill: "
          f"4 x ${AWARD_FLOOR:,.0f} = ${4*AWARD_FLOOR:,.0f} lawful; "
          f"4 x ${BENCHMARK:,.0f} = ${4*BENCHMARK:,.0f} competitive")

    # ---- super sensitivity
    rule("SUPERANNUATION — if payouts are FEES, not a revenue share")
    rec = split(pool70, [50, 50])[0]
    print(f"  Recommended row ${rec:,.2f}/DJ -> "
          f"${rec/(1+SUPER_RATE):,.2f} in hand "
          f"({(rec/(1+SUPER_RATE)/BENCHMARK - 1)*100:+.1f}% vs benchmark)")
    bottom = split(pool100, [35, 25, 22, 18])[3]
    print(f"  Four-DJ bottom  ${bottom:,.2f}/DJ -> "
          f"${bottom/(1+SUPER_RATE):,.2f} in hand "
          f"({(bottom/(1+SUPER_RATE)/BENCHMARK - 1)*100:+.1f}% vs benchmark)")
    print(f"  All-in cost to deliver ${BENCHMARK:,.0f} in hand: "
          f"revenue share ${BENCHMARK:,.0f}, "
          f"fees ${BENCHMARK*(1+SUPER_RATE):,.0f}, "
          f"no ABN ${BENCHMARK/0.53*(1+SUPER_RATE):,.0f}")

    # ---- break-even prices
    rule("BREAK-EVEN TICKET PRICE")
    for cap, fill, djs, fitted in ((200, 0.70, 2, False), (200, 0.70, 2, True),
                                   (300, 0.70, 2, True), (300, 1.00, 2, True),
                                   (200, 0.70, 4, False), (200, 1.00, 4, False),
                                   (300, 1.00, 4, False)):
        t = round(cap * fill)
        need = (popup_stack(t, fitted) + HIRE_BENCHMARK + djs * BENCHMARK) / t
        print(f"  {cap}cap {fill*100:>3.0f}% {djs}DJ"
              f"{' fitted' if fitted else '       '} ({t:>3} tix): "
              f"${need:>6,.2f}/ticket")
    print("  Brisbane norm is $0-20 face; $30 is the ceiling.")


if __name__ == "__main__":
    main()
