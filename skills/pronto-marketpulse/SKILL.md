---
name: pronto-marketpulse
description: "Generates a broad market intelligence dashboard ranking companies across the entire market by investment score, sentiment shifts, and stock performance — based on recent earnings calls. Use when the user asks about the overall market rather than a specific company or sector. Triggers on phrases like: 'what's moving in the market', 'top movers', 'market recap', 'market summary', 'market overview', 'what happened in the market this week', 'stocks to watch', 'most bullish companies', 'biggest sentiment shifts', 'highest investment scores', 'earnings season highlights', 'which analyst firms are bearish', 'what large caps are outperforming'. Defaults to past 7 days when no time frame is specified. Do not use for a single named company — use the company intelligence skill. Do not use for a specific sector — use the sector intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Market Pulse — Recent Market Intelligence Dashboard

Generates a market intelligence dashboard from recent earnings calls — leaderboards, trending topics, and voice-of-the-market. Data gathering and section logic live here; HTML rendering is delegated to the `pronto-html-renderer` agent.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, or `deep-research` from this skill. These are user-triggered only. Use only the tools listed in Step 2.

---

## Step 0: Parse the Request — Sections and Filters

### A. Which sections to include

| User asked for | Sections |
|----------------|----------|
| "top movers", "what's moving", specific metric ("best stocks this week") | **Movers only** — leaderboards |
| "what happened this week/month", "market recap/summary/overview", broad open-ended | **Full** — movers + Trending Topics + Voice of the Market |
| "show me trends", "what topics are trending" | **Trends only** |
| "what are executives saying" | **Speakers only** |
| "show me [specific thing] only" | **Only that section** |

Key distinction: "what's moving" (price/score) → Movers only. "What's happening" (narrative) → Full. When in doubt, lean Full.

At the end of a Movers-only report, tell the user they can ask for a **full report** to also see Trending Topics and Voice of the Market.

### B. Market cap filter

| User says | `marketCaps` filter |
|-----------|---------------------|
| Nothing specific (default) | `$300M+` — Small + Mid + Large + Mega |
| "large caps", "big companies" | `$10B+` — Large + Mega |
| "mega cap", "only the biggest", "S&P 500 only" | `$200B+` — Mega only |
| "small caps", "micro cap" | Drop filter; note in report |
| Specific sector/country/index | Apply those filters; keep $300M+ default |

`marketCaps` key strings (smallest → largest):
- `"Nano (under $50mln)"`
- `"Micro ($50mln - $300mln)"`
- `"Small ($300mln - $2bln)"`
- `"Mid ($2bln - $10bln)"`
- `"Large ($10bln - $200bln)"`
- `"Mega ($200bln & more)"`

**Default ($300M+):** `["Small ($300mln - $2bln)", "Mid ($2bln - $10bln)", "Large ($10bln - $200bln)", "Mega ($200bln & more)"]`
**Large only ($10B+):** `["Large ($10bln - $200bln)", "Mega ($200bln & more)"]`
**Mega only:** `["Mega ($200bln & more)"]`

### C. Optional filters

- `sectors` — e.g. `["Information Technology", "Financials"]`
- `country` — e.g. `"United States"`
- `indices` — e.g. `["SP500_IND"]`

---

## Step 1: Date Range

- User-specified time frame → honor it.
- "recently", "currently", "now", "latest", or no time frame → **past 7 days**.
- Format: `YYYY-MM-DD`.
- Store a human-readable label (e.g. "Past 7 Days", "Mar 1 – Mar 26, 2026") for the report header.

---

## Confirm Before Proceeding

After Steps 0–1, **before calling any tools**, present a short summary and wait for the user to confirm.

Show the user:
- **Date range:** the resolved period (e.g. "Past 7 Days — Apr 12 to Apr 19, 2026")
- **Market cap filter:** e.g. "$300M+ (Small, Mid, Large, Mega)" or "Large caps only ($10B+)"
- **Sections:** which sections will be included (Movers / Trending Topics / Voice of the Market)
- **Filters:** any sector, country, or index filter applied

Then ask: *"Ready to generate the Market Pulse report. Reply **yes** to continue, or clarify anything above."*

**Do not call any tools until the user confirms.**

---

## Step 2: Call Data Tools

Fire all applicable calls simultaneously. Always include `getOrganization` — the `org` value is required by the renderer for citation/company links.

```
getOrganization    → save org
```

Only make the remaining calls needed for the sections chosen in Step 0.

### 2a. getTopMovers *(movers section)*

Make **one call** with `sortBy` as an array of all needed criteria. The response is keyed by criterion.

```
getTopMovers(
  sinceDay:      <period start>
  untilDay:      <today>
  documentTypes: ["Earnings Calls"]
  marketCaps:    <filter from Step 0>
  limit:         10
  sortBy:        ["stockChange", "investmentScore", "investmentScoreChange",
                  "sentimentScore", "sentimentScoreChange", "aspectScore", "marketcap"]
)
```

If the user asked for only one metric, pass only that criterion.

**Leaderboard mapping** (renderer emits one card per criterion fetched):

| sortBy | Card title | Source array |
|--------|-----------|--------------|
| `stockChange` | Top Stock Movers | `topMovers` |
| `investmentScore` | Highest Investment Score | `topMovers` |
| `investmentScoreChange` | Biggest Investment Gain | `topMovers` |
| `sentimentScore` | Most Positive Sentiment | `topMovers` |
| `sentimentScoreChange` (bullish) | Biggest Sentiment Shift — Most Bullish | `topMovers` |
| `sentimentScoreChange` (bearish) | Biggest Sentiment Shift — Most Bearish | `underperforming` |
| `aspectScore` | Top Aspect Score | `topMovers` |
| `marketcap` | Largest by Market Cap | `topMovers` |

**Sparse data:** if any leaderboard returns fewer than 5 companies, widen the date range by 7 days and re-call that criterion only. Note the expansion in the payload so the renderer can surface it.

### 2b. getTrends *(trends section)*

```
getTrends(
  documentTypes: ["Earnings Calls"]
  sinceDay:      <period start>
  untilDay:      <today>
  limit:         30
  sortBy:        "score"
)
```

`getTrends` does not accept `marketCaps`.

### 2c / 2d. getSpeakers — Executives and Analysts *(Voice of the Market)*

Most bullish (both speaker types): `sortBy: "sentiment"`, `sortOrder: "desc"`, `limit: 20`, `documentTypes: ["Earnings Calls"]`, same date range.
Most bearish: same but `sortOrder: "asc"`, `limit: 10`.

---

## Step 3: Process Data

Each criterion key in `getTopMovers` contains `topMovers`, `underperforming`, and `overperforming` arrays. Use `topMovers` for each leaderboard. For the Sentiment Shift card, pair `topMovers` (bullish) with `underperforming` (bearish).

Build a deduplicated master list by `id` across all arrays for the total company count.

Field reference: [reference/api-fields.md](./reference/api-fields.md).

---

## Step 4: Render

Delegate the entire HTML output to the `pronto-html-renderer` agent (`subagent_type: prontonlp-plugin:pronto-html-renderer`). Pass the structured data — do not render HTML here.

```
report_type: marketpulse
org: <from getOrganization>
filename: market-pulse-<YYYYMMDD>.html
title: "Market Pulse — <date range label>"
subtitle: "<total companies> companies · <market cap filter label> · Earnings Calls"
data:
  meta:
    dateRangeLabel: <human label>
    sinceDay: <YYYY-MM-DD>
    untilDay: <YYYY-MM-DD>
    marketCapFilter: <label>
    totalCompanies: <deduped count>
    filters: { sectors?, country?, indices? }
  leaderboards:
    # Only include keys that were fetched in Step 2a.
    stockChange:          { topMovers: [...] }
    investmentScore:      { topMovers: [...] }
    investmentScoreChange:{ topMovers: [...] }
    sentimentScore:       { topMovers: [...] }
    sentimentScoreChange: { topMovers: [...], underperforming: [...] }
    aspectScore:          { topMovers: [...] }
    marketcap:            { topMovers: [...] }
  trends: [ { name, explanation, score, hits, change }, ... ]   # when trends fetched
  speakers:                                                      # when speakers fetched
    execBullish:    [ { name, company, companyId, sentimentScore, numOfSentences } ]
    execBearish:    [ ... ]
    analystBullish: [ ... ]
    analystBearish: [ ... ]
```

The renderer applies the shared conventions (color rule, score display, company links, signal badges like `Potential Buy` / `Watch` / `Caution`). Do not reimplement any of that here.

---

## Step 5: Delivery

After the renderer returns the saved filename, summarize:
- Time period + any date-range expansion applied
- Company count + filters applied
- Top company by stock performance over the period
- Companies appearing across multiple leaderboards (consistent outperformers)
- Potential Buy signals (high investment score + in `underperforming` category)
- Top trend *(if trends included)*
- Most bullish / bearish executive and analyst *(if speakers included)*
- If Movers-only: mention a full report will add Trending Topics and Voice of the Market.

See [examples/sample-delivery.md](./examples/sample-delivery.md) for delivery phrasing.

---

## Best Practices

1. Always pass `marketCaps` as an array — never a plain string.
2. `getTrends` does not accept `marketCaps` — scope only with `documentTypes` and date range.
3. Never fabricate — missing data → omit the leaderboard key entirely.
4. Maximize parallelism — all tool calls in Step 2 fire simultaneously.
5. Do not mention tool names in responses — describe the action ("I analyzed earnings calls from the past 7 days", not "I called getTopMovers").
