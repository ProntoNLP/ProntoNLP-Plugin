---
name: pronto-sector-intelligence
description: "Generates a sector-level intelligence report analyzing all companies within an industry — ranking them by investment score and sentiment, identifying dominant events and themes, surfacing bullish and bearish signals, and tracking trending topics across the sector. Use when the user asks about an industry, sector, or market theme rather than a single company. Triggers on phrases like: 'analyze the [sector] sector', '[sector] industry report', 'what is happening in [sector]', 'which companies in [sector] are leading', 'sentiment in [sector]', 'top movers in [sector]', 'what themes are rising in [sector]', 'which sectors are most bullish', '[sector] outlook'. Do not use for a single named company — use the company intelligence skill. Do not use when comparing specific companies side by side — use the compare-companies skill."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Sector Intelligence Report Generator

Produces sector intelligence reports using ProntoNLP tools. The centerpiece is a **cross-company view of a sector** — ranking companies by sentiment, investment score, and stock performance, identifying dominant themes and events, surfacing the most bullish and bearish voices, and showing what's RISING or FALLING across the industry. This is the sector-level counterpart to company intelligence.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, `deepResearch`, or any interactive visualization tool from this skill. These are user-triggered only. Only call the tools explicitly listed in the batches below.

---

## Output Format — Environment-Aware

**Detect the environment before rendering:**

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | HTML written to file |

### HTML rules (apply to BOTH environments — only delivery differs):
- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- **Value coloring rule — applies to every numeric value, score, and % change rendered in the report:**
  - Value **> 0** (positive sentiment, positive stock change, positive delta): text color `#1D9E75` (green)
  - Value **< 0** (negative sentiment, negative stock change, negative delta): text color `#D85A30` (red)
  - Value **= 0**: no color — use default inherited text color
- **Score display rule:** Investment scores and sentiment scores are raw API values in the **0.0–1.0 range**. Display them exactly as returned — never multiply, never append "/10", never reformat as a fraction. Example: show `0.71`, not `7.1` or `7.1/10`. `sentimentScoreChange` and `investmentScoreChange` are percentage changes — always display with a `%` suffix (e.g. `+4.2%`, `-1.8%`). Any negative number or negative percentage (value < 0) **must** render in red `#D85A30` — this includes stock changes, score changes, deltas, and any other numeric field with a minus sign.
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants — never reference external files
- Clean layout: cards, tables, badges, section headers

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named `[sector]-report.html` (e.g. `information-technology-report.html`) using the `Write` tool
- After writing, tell the user the filename and open it

---

## Step 0: Identify the Sector & Choose Report Mode

### Sector Identification

Map the user's input to the correct sector name(s) from the valid list. Always use exact strings — the tools will not match on approximate names.

**Valid top-level sectors (use these for broad queries):**
`Financials` | `Industrials` | `Consumer Discretionary` | `Health Care` | `Information Technology` | `Materials` | `Real Estate` | `Consumer Staples` | `Communication Services` | `Energy` | `Utilities`

**Sub-sectors are also valid** (e.g. `Information Technology-Semiconductors and Semiconductor Equipment`, `Health Care-Biotechnology`, `Financials-Banks`). Use sub-sectors when the user is specific.

If the user says "tech" → `Information Technology`. "Healthcare" / "pharma" → `Health Care`. "Finance" / "banking" → `Financials`. "Energy" → `Energy`. "Real estate" / "REITs" → `Real Estate`. "Telecom" → `Communication Services`. When ambiguous, use the top-level sector.

### Report Mode

| Mode | Use when | Batches | Sections |
|------|----------|---------|---------|
| **Full Report** (default) | "analyze tech sector", "sector report on healthcare" | 5 | All 8 |
| **Movers Report** | "top movers in financials", "what's performing in energy" | 2 | 1–2 |
| **Theme Analysis** | "what are tech companies talking about", "AI in semiconductors" | 3 | 1, 4–6 |
| **Sentiment Report** | "sentiment in real estate", "how bullish is the sector" | 3 | 1, 3, 6–7 |

Default to **Full Report** unless the user signals a narrower scope.

---

## Tools Reference

| # | Tool | Purpose | Sector param |
|---|------|---------|-------------|
| 1 | `getTopMovers` | Company rankings by stock/sentiment/investment | `sectors` array |
| 2 | `getTrends` | Trending topics within sector | `sectors` array |
| 3 | `getAnalytics` | Sentiment scores, event types, aspects | `sectors` array |
| 4 | `searchSectors` | Cross-sector topic distribution | n/a (returns sector rankings) |
| 5 | `searchTopCompanies` | Companies ranked by topic/event/sentiment | `sectors` array |
| 6 | `getSpeakers` | Executive/analyst sentiment per company | `companyName` (per top company) |
| 7 | `getSpeakerCompanies` | Analyst firm sentiment per company | `companyName` (per top company) |
| 8 | `search` | Key quotes from filings | `companyName` or `companyIDs` |

### Critical parameter notes

- `sectors` is always an **array of strings** — e.g. `["Information Technology"]` — never a plain string
- `getAnalytics` max date range: **1 year** — split longer requests into yearly calls
- `getTrends` has **no `query` parameter** — scope with `sectors`, never pass a `query` field
- `searchTopCompanies` with `eventTypes`: **one event type per call** — never merge multiple event types into one call
- `getSpeakers` and `getSpeakerCompanies` require `companyName` — call per top company from Batch 1

---

## Parallel Execution — Full Report

Run each batch in sequence; within a batch, fire all calls simultaneously.

**Batch 1** — foundation (no dependencies):
```
getTopMovers(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10,
  sinceDay, untilDay
)
→ save top company names and IDs for Batches 3–4

getTrends(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  sortBy: "score", sortOrder: "desc",
  limit: 20,
  sinceDay, untilDay
)
→ save top trend names for Batch 2

getAnalytics(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"],
  sinceDay, untilDay
)
→ save sentimentScore, investmentScore, eventTypes list for Batch 2
```

**Batch 2** — topic and event breakdown (needs eventTypes and trend names from Batch 1):
```
searchTopCompanies(sectors: ["<sector>"], eventTypes: ["<top event 1>"], limit: 10, sinceDay, untilDay)
searchTopCompanies(sectors: ["<sector>"], eventTypes: ["<top event 2>"], limit: 10, sinceDay, untilDay)
searchTopCompanies(sectors: ["<sector>"], eventTypes: ["<top event 3>"], limit: 10, sinceDay, untilDay)
searchTopCompanies(sectors: ["<sector>"], topicSearchQuery: "<top trend topic>", limit: 10, sinceDay, untilDay)
searchSectors(searchQueries: ["<top trend 1>", "<top trend 2>"], documentTypes: ["Earnings Calls"], sinceDay, untilDay)
```

**Batch 3** — speaker intelligence (needs top company names from Batch 1, one set per company, parallel):
```
getSpeakers(companyName: "<top company 1>", speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 10, sinceDay, untilDay)
getSpeakers(companyName: "<top company 1>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, sinceDay, untilDay)
getSpeakers(companyName: "<top company 2>", speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 10, sinceDay, untilDay)
getSpeakers(companyName: "<top company 2>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, sinceDay, untilDay)
getSpeakerCompanies(companyName: "<top company 1>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, sinceDay, untilDay)
getSpeakerCompanies(companyName: "<top company 2>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, sinceDay, untilDay)
```
Run for the top 2–3 companies by investment score from Batch 1. Aggregate across companies.

**Batch 4** — supporting quotes (**REQUIRED — do not skip, do not render the report until this completes**):

**Environment-aware — pick ONE path, do NOT run both:**

| Environment | Detection | Action |
|-------------|-----------|--------|
| **Claude Cowork** | `Bash` tool IS available | → delegate to ONE `pronto-search-summarizer` (stop here, do NOT also call `search`) |
| **claude.ai** | `Bash` tool NOT available | → call `search` MCP tool directly |

**Claude Cowork — delegate to ONE `pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):
```
"orgName: [your orgName from the MCP server instructions]

Fetch all quotes needed for the [sector] sector intelligence report. Run these searches:
1. Bullish quotes about [top trend topic] for [top company 1] — sentiment: positive, size: 3, sinceDay: [date], untilDay: [date]
2. Bearish/risk quotes about [top risk event] for [top company 1] — sentiment: negative, size: 3, sinceDay: [date], untilDay: [date]
3. Bullish quotes about [top trend topic] for [top company 2] — sentiment: positive, size: 3, sinceDay: [date], untilDay: [date]
4. Notable analyst questions for [top company 2] — sections: EarningsCalls_Question, size: 3, sinceDay: [date], untilDay: [date]
Return all results with speaker name, role, and date."
```

**claude.ai — call `search` directly**, fire all in parallel:
```
search(companyName: "<top company 1>", topicSearchQuery: "<top trend>", sentiment: "positive", size: 3, sinceDay, untilDay)
search(companyName: "<top company 1>", topicSearchQuery: "<top risk>", sentiment: "negative", size: 3, sinceDay, untilDay)
search(companyName: "<top company 2>", topicSearchQuery: "<top trend>", sentiment: "positive", size: 3, sinceDay, untilDay)
search(companyName: "<top company 2>", sections: ["EarningsCalls_Question"], size: 3, sinceDay, untilDay)
```

→ Save the top 1–2 quotes per task with speaker name, role, and date. Do not proceed to Batch 5 until Batch 4 results are in hand.

**Batch 5** — render the full HTML report: inline in chat on claude.ai, written to `[sector]-report.html` file in Claude Cowork.

---

## Core: Sector-Level Signals

Unlike company intelligence, there is no single earnings call to track. The sector view looks at **patterns across many companies simultaneously**. Focus on:

1. **Sentiment direction** — is the average `sentimentScore` from `getAnalytics` RISING or FALLING vs the prior period? State explicitly.
2. **Investment score leaders** — which companies in `getTopMovers` (sorted by `investmentScore`) are at the top? What do they have in common?
3. **Divergence signals** — companies with high investment scores but negative stock change (`underperforming` bucket in getTopMovers) = potential buy signals. Companies with high stock change but low investment score (`overperforming` bucket) = potential overvalued signal.
4. **Dominant events** — the top event types from `getAnalytics` reveal what the sector is experiencing. Positive events (e.g. GrowthDriver, CapexExpansion) vs negative (RiskFactor, Restructuring) define the sector's current posture.
5. **Theme momentum** — which topics from `getTrends` are RISING fastest (highest positive `change` %)? These are emerging narratives.

**Always explicitly state:**
- "Sector sentiment is RISING/FALLING — average score: X.XX"
- "Investment score leaders: [Company A] (X.X), [Company B] (X.X)"
- "Dominant positive event: [event] | Dominant negative event: [event]"
- "Fastest-rising theme: [topic] (+X%)"
- "Most undervalued signal: [company] — high investment score (X.X) but stock down X%"

---

## Report Structure

### Title
```
# [Sector Name] — Sector Intelligence Report
Generated: [Date] | Period: [sinceDay] to [untilDay]
Companies analyzed: [N] | Document type: Earnings Calls
```

### Section 1: Executive Summary
2–3 paragraphs explicitly stating:
- Overall sector direction (bullish / bearish / mixed) with sentiment and investment score
- Top 3 performing companies and bottom 3 laggards
- Most dominant theme or event driving the sector
- Key divergence signals (underperforming high-score companies, overperforming low-score)
- 3-point thesis for the sector

### Section 2: Sector Movers
From `getTopMovers` — render one leaderboard card per sort criterion:

| Leaderboard | Sort criterion | Show |
|-------------|---------------|------|
| Top by Investment Score | `investmentScore` | `topMovers` |
| Biggest Investment Gain | `investmentScoreChange` | `topMovers` |
| Most Positive Sentiment | `sentimentScore` | `topMovers` |
| Biggest Sentiment Shift | `sentimentScoreChange` | `topMovers` (bullish) + `underperforming` (bearish) |
| Top Stock Performers | `stockChange` | `topMovers` |
| Potential Buy Signals | cross `underperforming` (investmentScore) | high score + falling stock |

### Section 3: Sector Sentiment & Investment Scores
From `getAnalytics` — aggregate sector scores with direction labels:

| Metric | Score | Direction | Interpretation |
|--------|-------|-----------|---------------|
| Sentiment Score | X.XX | RISING/FALLING | — |
| Investment Score | X.X | RISING/FALLING | — |
| Positive Pattern | +X.XX | — | — |
| Negative Pattern | −X.XX | — | — |

Include top aspects (products, strategy, guidance) and their sentiment polarity.

### Section 4: Trending Topics
From `getTrends` — top 20 topics with direction:

| Topic | Score | Hits | % Change | Direction |
|-------|-------|------|----------|-----------|
| [topic] | X | X | +X% | RISING ↑ |

Call out the 3 fastest-rising themes (highest positive `change` %) and 2 fastest-declining.

### Section 5: Event Analysis
From `getAnalytics` eventTypes — what events dominate the sector:
- Top 5 positive events (by frequency) — signals sector strengths
- Top 5 negative events (by frequency) — signals sector risks
- Per-event: which companies are most exposed (from `searchTopCompanies` per event type)

### Section 6: Company Rankings by Theme
From `searchTopCompanies` per topic/event:
- Which companies lead on top theme (e.g. "AI", "rates", "supply chain")
- Which companies dominate the top positive event type
- Which companies are most exposed to the top negative event type

| Rank | Company | Sector | Sentiment Score | Mentions | Signal |
|------|---------|--------|----------------|---------|--------|
| 1 | ... | ... | +X.XX | X | LEADING |

### Section 7: Executive & Analyst Voice
From `getSpeakers` and `getSpeakerCompanies` (aggregated across top 2–3 companies):
- Most bullish executive across sector companies
- Most bearish analyst across sector companies
- Analyst firm sentiment ranking
- Exec vs analyst gap for representative companies

State explicitly:
- **"Most bullish executive: [Name], [Role] at [Company] (score: X.XX)"**
- **"Most bearish analyst: [Name] from [Firm] (score: −X.XX)"**
- **"[Firm] is the most bullish firm | [Firm] is the most bearish firm"**

### Section 8: Risk Themes
- Top negative events from `getAnalytics` with company exposure
- Bearish analyst quotes (from `search`, sentiment: "negative", sections: ["EarningsCalls_Question"])
- Risk factors mentioned across sector companies


---

## Charts

**On claude.ai:** Output all charts as inline HTML — no file writing. Load Chart.js once near the top: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
**In Claude Cowork:** Charts are included in the HTML file exactly as on claude.ai — no changes needed.

| Chart | Data source | Type |
|-------|------------|------|
| Chart 1 | `getTopMovers` investmentScore — top 10 companies | Horizontal bar, green/red |
| Chart 2 | `getTopMovers` stockChange — top 10 vs bottom 5 | Horizontal bar, green/red |
| Chart 3 | `getAnalytics` sentimentScore + investmentScore | Grouped bar |
| Chart 4 | `getTrends` top 15 by score | Horizontal bar, color by change sign |
| Chart 5 | `getTrends` % change — RISING vs DECLINING | Horizontal bar, green/red |
| Chart 6 | `getAnalytics` eventTypes — top 10 positive events | Horizontal bar, green |
| Chart 7 | `getAnalytics` eventTypes — top 10 negative events | Horizontal bar, red |
| Chart 8 | `searchTopCompanies` per top theme — company ranking | Horizontal bar |
| Chart 9 | `getSpeakers` Analysts — bullish to bearish | Bar sorted desc, green→red gradient |

Place charts within their corresponding section. All data as inline JS constants.

---

## Date Handling

```
Past year (default): sinceDay = 1 year ago,   untilDay = today
Past quarter:        sinceDay = 90 days ago,  untilDay = today
Past 6 months:       sinceDay = 6 months ago, untilDay = today
YTD:                 sinceDay = Jan 1,         untilDay = today
```

Default to **past year** for Full Report. Use **90 days** for Movers and Theme reports.
`getAnalytics` max range: 1 year — split longer requests into multiple yearly calls.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Sector name not recognized | Check spelling against valid sector list; try top-level sector if sub-sector fails |
| `getTopMovers` returns fewer than 5 companies | Widen date range; remove `documentTypes` filter |
| `getAnalytics` returns no event types | Confirm date range ≤ 1 year; try without `documentTypes` filter |
| `searchTopCompanies` returns empty for event type | Skip that event type; note it; proceed with remaining |
| `getTrends` returns fewer than 10 results | Widen date range; remove `documentTypes` filter |
| `getSpeakers` returns no results for a company | Try without date filter; widen the window |
| No quotes from `search` | State "No matching quotes found" — never fabricate |
| Ambiguous sector (user says "tech") | Map to "Information Technology"; note the mapping in the report |

---

## Best Practices

1. Always pass `sectors` as an array — `["Information Technology"]` not `"Information Technology"`
2. Call `searchTopCompanies` once per event type — never merge multiple event types into one call
3. Never pass a `query` field to `getTrends` — it does not exist; use `sectors` to scope
4. Maximize parallelism — batch all independent calls per the strategy above
5. Always state divergences — `underperforming` companies (high score + falling stock) are the most actionable signals
6. Never fabricate data — if a tool returns nothing, say so and note it in the report
7. Always cite quotes: `"Quote text" — [Name], [Role], [Company] ([Date])`
8. Do not mention tool names in responses — describe the action instead (e.g. "I scanned the sector" not "I called getAnalytics")

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Every tool with exact parameters, response field definitions, report section mapping, batch execution plan, computed signal formulas, and date handling rules |
| `reference/report-template-guide.md` | HTML layout guide — design tokens, leaderboard card structure, badge styling, company link format, section-by-section template, all 9 charts reference, formatting rules |
| `examples/information-technology.md` | Full worked example: Information Technology sector — all 4 batches with real parameters, saved metrics, key signals summary, and full report structure walkthrough |
| `evaluations/criteria.md` | Evaluation rubric — triggering, report mode selection, parallel execution, key signals, HTML structure (all 8 sections), visual design, formatting, and error handling criteria |
| `evals/evals.json` | 5 structured test cases with assertions: full IT sector report, Financials movers report, semiconductors theme analysis, single-company (should NOT trigger), Energy sentiment report |
