# Sample Post-Generation Delivery

This is an example of what Claude should say to the user after generating the live Market Pulse artifact in Claude.

---

## Example 1: "What's moving in the market this week?" (Movers only — default)

*(live Market Pulse artifact created in Claude; refreshes on open)*

---

Here's your Market Pulse for **Mar 19 – Mar 26, 2026 (Past 7 Days)** — covering **63 unique companies** ($200M+ market cap, earnings calls only). The report shows 7 leaderboards, each the top 10 companies by a different metric.

**Top stock mover:** Palantir (PLTR) — ▲ **+18.4%** this week, driven by government contract wins discussed in earnings.

**Highest investment score:** Nvidia (NVDA) — also appeared in the Biggest Investment Gain and Sentiment leaderboards, making it the most consistent signal in this period.

**Potential Buy signals** (stock down but strong fundamentals):
- Pfizer (PFE) — stock −4.2% but investment score change +41%
- CVS Health (CVS) — similar pattern
- Ford (F) — strong earnings sentiment despite stock weakness

This Market Pulse now lives in Claude as a **live artifact**, so reopening it will refresh the view with current data.

Ask for a **full report** to also see Trending Topics and Voice of the Market (executive and analyst sentiment).

---

## Example 2: "What happened in the market this week?" (Full report)

*(live Market Pulse artifact created in Claude; refreshes on open)*

---

Here's your full Market Pulse for **Mar 19 – Mar 26, 2026**, covering **63 unique companies**.

**Top stock mover:** Palantir (PLTR) — ▲ +18.4%.

**Highest investment score:** Nvidia (NVDA).

**Top trend:** "AI infrastructure investment" — ▲ +187% change in mentions, significance 0.91. Dominant theme across 34 of 63 companies.

**Most bullish executive:** Jensen Huang (Nvidia) — sentiment +0.94 across 312 sentences.

**Most bearish executive:** Walgreens CEO — sentiment −0.61, flagged margin pressure and store closures.

**Most bullish analyst:** Erik Woodring (Morgan Stanley) — sentiment +0.78 covering 28 companies this week.

This dashboard is now a **live artifact** in Claude, so when you reopen it the data refreshes instead of staying frozen to today's snapshot.

---

## Example 3: "Show me only the top stock movers" (Single leaderboard)

*(live Market Pulse artifact created in Claude; refreshes on open)*

---

Here's your Top Stock Movers leaderboard for **Mar 19 – Mar 26, 2026** ($200M+ market cap, earnings calls only).

**#1:** Palantir (PLTR) ▲ +18.4% · **#2:** Super Micro Computer (SMCI) ▲ +14.1% · **#3:** Tesla (TSLA) ▲ +12.7%

**Biggest loser:** Walgreens (WBA) ▼ −11.3%

---

## Example 4: "Top movers, large companies only" (Movers with $5B+ filter)

*(live Market Pulse artifact created in Claude; refreshes on open)*

---

Here's your Market Pulse for **Mar 19 – Mar 26, 2026** — **large companies only ($5B+ market cap)**, 7 leaderboards, top 10 each.

**Top stock mover:** Tesla (TSLA) ▲ +12.7% · **Highest investment score:** Nvidia (NVDA).

---

## What makes a good delivery

1. **Lead with the date range, scope, and filter** — always tell the user what market cap tier and document type was used.
2. **Specific names and numbers** — "Nvidia (NVDA) up ▲ 11.2%", not "a tech company was up."
3. **Call out multi-leaderboard appearances** — a company showing up in 3+ leaderboards is the most interesting signal.
4. **Surface Potential Buy signals** — contrarian insight the user won't get from scanning prices.
5. **For full reports:** one standout trend, one bullish exec, one bearish exec, one bullish analyst.
6. **End with the interactive reminder** if in movers-only mode — a full report adds trends and speakers.
7. **Keep it scannable** — bold names/tickers, ▲/▼ for directions, ~10 lines total.
8. **Name the live behavior once** — tell the user the artifact refreshes on open, but do not over-explain it every time.
