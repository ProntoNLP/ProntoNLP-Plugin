---
name: pronto-marketpulse
description: "Generates a broad market intelligence dashboard ranking companies across the entire market by investment score, sentiment shifts, and stock performance — based on recent earnings calls. Use when the user asks about the overall market rather than a specific company or sector. Triggers on phrases like: 'what's moving in the market', 'top movers', 'market recap', 'market summary', 'market overview', 'what happened in the market this week', 'stocks to watch', 'most bullish companies', 'biggest sentiment shifts', 'highest investment scores', 'earnings season highlights', 'which analyst firms are bearish', 'what large caps are outperforming'. Defaults to past 7 days when no time frame is specified. Do not use for a single named company — use the company intelligence skill. Do not use for a specific sector — use the sector intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Market Pulse — Live Artifact Dashboard

Generates a Market Pulse **Live Artifact** — a self-refreshing dashboard that fetches live market data via the MCP App protocol each time it is opened. This skill resolves the request parameters and delegates artifact generation; it does not call data tools itself.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, `deep-research`, `getTopMovers`, `getTrends`, `getSpeakers`, or `getOrganization` from this skill. The generated artifact fetches all data live.

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

## Step 2: Generate the Live Artifact

Delegate to `pronto-marketpulse-artifact` (`subagent_type: prontonlp-plugin:pronto-marketpulse-artifact`). Pass exactly:

```
sinceDay:        <ISO date from Step 1>
untilDay:        <ISO date from Step 1>
dateRangeLabel:  <human label from Step 1, e.g. "Past 7 Days — Apr 21 to Apr 28, 2026">
marketCaps:      <array from Step 0.B>
marketCapFilter: <human label from Step 0.B, e.g. "$300M+ (Small, Mid, Large, Mega)">
sections:
  movers:   <true|false>
  trends:   <true|false>
  speakers: <true|false>
sortBy: <criteria array — include only criteria matching included sections>
```

`sortBy` reference by section:
- **Movers (full):** `["stockChange", "investmentScore", "investmentScoreChange", "sentimentScore", "sentimentScoreChange", "aspectScore", "marketcap"]`
- **Single metric only:** pass only that criterion, e.g. `["stockChange"]`
- **Trends/Speakers only (no movers):** `[]`

The agent returns complete HTML as plain text. Do not call any MCP tools yourself.

---

## Step 3: Emit the Artifact

Wrap the HTML returned by the agent in `<antArtifact>` tags and emit it in your response:

```
<antArtifact identifier="market-pulse-{YYYYMMDD}" type="text/html" title="Market Pulse — {dateRangeLabel}">
{full HTML from agent — paste verbatim}
</antArtifact>
```

- `identifier` must be `market-pulse-` followed by today's date in `YYYYMMDD` format.
- `title` must match the `dateRangeLabel` exactly as confirmed with the user.
- Paste the HTML verbatim — do not truncate or modify it.

---

## Step 4: Delivery

After emitting the artifact, send a short message:

- Confirm the time period and market cap filter that will be applied on each refresh.
- List the sections included (Movers / Trending Topics / Voice of the Market).
- Tell the user: *"This is a live dashboard — it fetches fresh market data each time you open it from the Live Artifacts tab."*
- If Movers-only: mention they can ask for a **full report** to also get Trending Topics and Voice of the Market.

---

## Best Practices

1. Never call data tools from this skill — the artifact fetches everything live.
2. Pass `marketCaps` as an array — never a plain string.
3. Include only the `sortBy` criteria that match the sections being shown.
4. Pass `dateRangeLabel` and `marketCapFilter` exactly as shown to the user in the confirm step — the artifact header displays them verbatim.
5. Do not mention tool names in responses.
