---
name: pronto-sector-intelligence
description: "Generates a sector-level intelligence report analyzing all companies within an industry — ranking them by investment score and sentiment, identifying dominant events and themes, surfacing bullish and bearish signals, and tracking trending topics across the sector. Use when the user asks about an industry, sector, or market theme rather than a single company. Triggers on phrases like: 'analyze the [sector] sector', '[sector] industry report', 'what is happening in [sector]', 'which companies in [sector] are leading', 'sentiment in [sector]', 'top movers in [sector]', 'what themes are rising in [sector]', 'which sectors are most bullish', '[sector] outlook'. Do not use for a single named company — use the company intelligence skill. Do not use when comparing specific companies side by side — use the compare-companies skill."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Sector Intelligence Report Generator

Produces sector intelligence reports. Centerpiece: **cross-company view of a sector** — ranking companies by sentiment, investment score, and stock performance; identifying dominant themes and events; surfacing the most bullish and bearish voices; tracking what's RISING or FALLING across the industry.

Data gathering and cross-company analysis live here; HTML rendering is delegated to the `pronto-html-renderer` agent.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, or `deep-research`. These are user-triggered only.

---

## Step 0: Identify the Sector & Choose Report Mode

### Sector Identification

Map the user's input to the correct sector string — exact strings only, case-sensitive.

**Valid top-level sectors:**
`Financials` | `Industrials` | `Consumer Discretionary` | `Health Care` | `Information Technology` | `Materials` | `Real Estate` | `Consumer Staples` | `Communication Services` | `Energy` | `Utilities`

**Sub-sector drill-down:** When the user's input names a specific sub-industry, use the sub-sector string instead of the top-level sector. Sub-sector strings narrow the company set and produce a more focused report.

| User says | Use this string |
|-----------|----------------|
| semiconductors, chips, chip makers | `Information Technology-Semiconductors and Semiconductor Equipment` |
| software, SaaS, cloud software | `Information Technology-Software` |
| IT services, tech consulting | `Information Technology-IT Services` |
| tech hardware, servers, storage | `Information Technology-Technology Hardware, Storage and Peripherals` |
| biotech, biopharmaceuticals | `Health Care-Biotechnology` |
| pharma, drug makers | `Health Care-Pharmaceuticals` |
| medtech, medical devices | `Health Care-Health Care Equipment and Supplies` |
| managed care, hospitals, health providers | `Health Care-Health Care Providers and Services` |
| banks, commercial banking | `Financials-Banks` |
| insurance | `Financials-Insurance` |
| capital markets, asset managers, exchanges | `Financials-Capital Markets` |
| fintech, financial services | `Financials-Financial Services` |
| ev, electric vehicles, auto | `Consumer Discretionary-Automobiles` |
| retail, specialty retail | `Consumer Discretionary-Specialty Retail` |
| restaurants, hotels, gaming, leisure | `Consumer Discretionary-Hotels, Restaurants and Leisure` |
| aerospace, defense | `Industrials-Aerospace and Defense` |
| machinery, industrial equipment | `Industrials-Machinery` |
| oil, gas, upstream energy | `Energy-Oil, Gas and Consumable Fuels` |
| oilfield services, drilling | `Energy-Energy Equipment and Services` |
| chemicals | `Materials-Chemicals` |
| mining, metals | `Materials-Metals and Mining` |
| social media, search, internet platforms | `Communication Services-Interactive Media and Services` |
| telecom, wireless | `Communication Services-Wireless Telecommunication Services` |
| media, entertainment, broadcast | `Communication Services-Media` |

**Top-level aliases:** "tech" → `Information Technology` · "healthcare / health" → `Health Care` · "financials / finance / banking" → `Financials` · "telecom" → `Communication Services` · "REITs / real estate" → `Real Estate`

**Decision rule:**
- User mentions a specific sub-industry keyword → use the sub-sector string.
- User mentions only a broad sector name → use the top-level sector.
- When ambiguous → default to top-level sector and note the choice.
- Sub-sector not in the table → fall back to top-level sector; note the mapping.

### Report Mode

| Mode | Use when | Batches | Payload sections |
|------|----------|---------|------------------|
| **Full Report** (default) | "analyze tech sector", "sector report on healthcare" | 5 | all |
| **Movers Report** | "top movers in financials", "what's performing in energy" | 2 | meta, ranking |
| **Theme Analysis** | "what are tech companies talking about", "AI in semis" | 3 | meta, trends, themes |
| **Sentiment Report** | "sentiment in real estate", "how bullish is the sector" | 3 | meta, ranking, bullishVoices, bearishVoices |

Default to Full Report unless the user signals a narrower scope.

---

## Confirm Before Proceeding

After Step 0, **before calling any tools**, present a short summary and wait for the user to confirm.

Show the user:
- **Sector:** the exact sector or sub-sector string that will be used (e.g. `Information Technology-Semiconductors and Semiconductor Equipment`)
- **Report mode:** which mode was selected and why
- **Date range:** e.g. "Past year — Apr 2025 to Apr 2026"
- **Sections:** brief list of what will be included

Then ask: *"Ready to generate the report. Reply **yes** to continue, or clarify anything above."*

**Do not call any tools until the user confirms.**

---

## Tools Reference

| # | Tool | Purpose | Sector param |
|---|------|---------|-------------|
| 1 | `getTopMovers` | Company rankings by stock/sentiment/investment | `sectors` array |
| 2 | `getTrends` | Trending topics within sector | `sectors` array |
| 3 | `getAnalytics` | Sentiment scores, event types, aspects | `sectors` array |
| 4 | `searchSectors` | Cross-sector topic distribution | n/a |
| 5 | `searchTopCompanies` | Companies ranked by topic/event/sentiment | `sectors` array |
| 6 | `getSpeakers` | Executive/analyst sentiment per company | `companyName` (per top company) |
| 7 | `getSpeakerCompanies` | Analyst firm sentiment per company | `companyName` (per top company) |
| 8 | `search` | Key quotes (via search-summarizer) | — |

### Critical parameter notes

- `sectors` is always an **array of strings** (e.g. `["Information Technology"]`), never a plain string.
- `getAnalytics` max date range: **1 year** — split longer requests into yearly calls.
- `getTrends` has **no `query` parameter** — scope with `sectors`.
- `searchTopCompanies` with `eventTypes`: **one event type per call**.
- `getSpeakers` / `getSpeakerCompanies` require `companyName` — call per top company from Batch 1.

---

## Parallel Execution — Full Report

**Batch 1** — foundation:
```
getOrganization          → save org (required by renderer)
getTopMovers(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange",
           "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay, untilDay)
  → save top company names and IDs for Batches 3–4

getTrends(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  sortBy: "score", sortOrder: "desc",
  limit: 20, sinceDay, untilDay)
  → save top trend names for Batch 2

getAnalytics(
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"],
  sinceDay, untilDay)
  → save sentimentScore, investmentScore, eventTypes list
```

**Post-Batch-1 Computation** — no tool calls needed:
```
potentialBuy.items = companies that appear in BOTH:
  - getTopMovers[investmentScore].topMovers  (high investment score)
  - getTopMovers[stockChange].underperforming (stock is falling)
Sort by investmentScore descending. Include: id, ticker, name, investmentScore, stockChange.
```
This is a cross-filter of data already in memory — compute before starting Batch 2.

**Batch 2** — topic and event breakdown (needs eventTypes and trend names):
```
searchTopCompanies(sectors, eventTypes: ["<top event 1>"], limit: 10)
searchTopCompanies(sectors, eventTypes: ["<top event 2>"], limit: 10)
searchTopCompanies(sectors, eventTypes: ["<top event 3>"], limit: 10)
searchTopCompanies(sectors, topicSearchQuery: "<top trend topic>", limit: 10)
searchSectors(searchQueries: ["<top trend 1>", "<top trend 2>"], documentTypes: ["Earnings Calls"])
```

**Batch 3** — speaker intelligence (top 2–3 companies by investment score, all parallel):
```
getSpeakers(companyName: "<topCo N>", speakerTypes: ["Executives"], sortBy: "sentiment", desc, limit: 10)
getSpeakers(companyName: "<topCo N>", speakerTypes: ["Analysts"],   sortBy: "sentiment", desc, limit: 20)
getSpeakerCompanies(companyName: "<topCo N>", speakerTypes: ["Analysts"], sortBy: "sentiment", desc, limit: 20)
```
Aggregate across companies.

**Batch 4** — supporting quotes (**REQUIRED — do not render until this completes**):

Delegate to ONE `pronto-search-summarizer` (`subagent_type: prontonlp-plugin:pronto-search-summarizer`):
```
org: [org]

Fetch quotes for the [sector] sector intelligence report. Run these searches:
1. Bullish quotes about [top trend] for [top company 1] — sentiment: positive, documentTypes: ["Earnings Calls"], size: 3
2. Bearish/risk quotes for [top company 1] — sentiment: negative, documentTypes: ["Earnings Calls"], size: 3
3. Bullish quotes about [top trend] for [top company 2] — sentiment: positive, size: 3
4. Notable analyst questions for [top company 2] — sections: EarningsCalls_Question, size: 3
Return with speaker name, role, date, refId.
```

Tag each quote by role (`bullish`, `bearish`, `analyst-question`).

**Batch 5** — render (see Step 3 below).

---

## Core: Sector-Level Signals

Focus on cross-company patterns. Always compute and include in the narrative:

- "Sector sentiment is RISING/FALLING — average score: X.XX"
- "Investment score leaders: [Company A] (X.X), [Company B] (X.X)"
- "Dominant positive event: [event] | Dominant negative event: [event]"
- "Fastest-rising theme: [topic] (+X%)"
- "Most undervalued signal: [company] — high investment score (X.X) but stock down X%" (`underperforming` bucket with high investment score)

Divergences: high investment + falling stock = potential buy; high stock + low investment = potential overvalued.

---

## Step 3: Render

Delegate HTML output to `pronto-html-renderer` (`subagent_type: prontonlp-plugin:pronto-html-renderer`).

```
report_type: sector
org: <from getOrganization>
filename: <sector-slug>-report-<YYYYMMDD>.html
title: "<Sector Name> — Sector Intelligence Report"
subtitle: "<sinceDay> to <untilDay> · <N> companies · Earnings Calls"
data:
  meta: { sectorName, asOfDate, sinceDay, untilDay, companyCount }
  ranking: [ { rank, id, ticker, name, investmentScore, investmentScoreChange,
               sentimentScore, sentimentScoreChange, stockChange, category } ]
  leaderboards:                                                  # same shape as marketpulse
    investmentScore:       { topMovers: [...] }
    investmentScoreChange: { topMovers: [...] }
    sentimentScore:        { topMovers: [...] }
    sentimentScoreChange:  { topMovers: [...], underperforming: [...] }
    stockChange:           { topMovers: [...] }
    potentialBuy:          { items: [...] }                      # cross-filtered signal
  sectorScores:
    sentimentScore: { value, direction }                         # direction ∈ RISING|FALLING
    investmentScore:{ value, direction }
    patternSentiment: { positive, negative }
    topAspects: [ { name, sentiment } ]
  trends: [ { name, score, hits, change, direction } ]
  events:
    positive: [ { name, count, topCompanies: [...] } ]
    negative: [ { name, count, topCompanies: [...] } ]
  companyRankingsByTheme: [ { theme, rows: [ { rank, company, sector, sentimentScore, mentions, signal } ] } ]
  bullishVoices: [ { name, role, company, sentiment, quote, refId } ]
  bearishVoices: [ { name, firm, sentiment, quote, refId } ]
  themes: [ { title, insight, evidence: [ { text, company, refId } ] } ]
  risks:  [ { title, evidence, refId } ]
narrative:
  executiveSummary: "<overall direction + top 3 / bottom 3 + dominant theme + divergences + 3-point thesis>"
```

For narrower report modes, omit payload keys not gathered — renderer skips absent sections.

---

## Step 4: Optional XLSX Export

After the HTML renderer reports success, ask the user:

> "Your report is ready: `<filename>.html`. Want this also as an XLSX file? (yes/no)"

**Skip the prompt** if the user explicitly asked for XLSX up front (e.g. "give me the sector report as xlsx", "in spreadsheet form") — in that case generate both formats automatically.

If the user answers yes (or pre-asked), invoke `anthropic-skills:xlsx` **directly from this skill** (not via a sub-agent) using the same data you already built for the HTML renderer.

**Filename:** same as the HTML file but `.xlsx` extension.

**Sheets to create** (skip any whose source data is missing or empty):
1. **Summary** *(tab teal `#205262`, no autofilter)* — `meta` fields as Key / Value rows, then `narrative.executiveSummary` as a wrapped text block
2. **Sector Scores** — Metric (Sentiment Score, Investment Score, Pattern Positive, Pattern Negative, Top Aspects), Value, Direction
3. **Ranking** — Rank, Ticker, Name, Investment Score, Inv. Score Change, Sentiment Score, Sentiment Change, Stock Change, Category
4. **Inv. Score** — `leaderboards.investmentScore.topMovers`: Rank, Name, Ticker, Investment Score, Stock Change, Sentiment Score
5. **Inv. Score Change** — `leaderboards.investmentScoreChange.topMovers`: same columns
6. **Sentiment Score** — `leaderboards.sentimentScore.topMovers`: same columns
7. **Sentiment Shift** — `leaderboards.sentimentScoreChange`: `topMovers` (bullish) and `underperforming` (bearish) in one sheet with Group column
8. **Stock Change** — `leaderboards.stockChange.topMovers`: same columns
9. **Potential Buy** — `leaderboards.potentialBuy.items`: Name, Ticker, Investment Score, Stock Change
10. **Events** — Type (Positive/Negative), Event Name, Count, Top Companies
11. **Trends** — Topic, Score, Change, Hits, Direction
12. **Theme Rankings** — Theme, Rank, Company, Sector, Sentiment Score, Mentions, Signal (flattened from `companyRankingsByTheme`)
13. **Bullish Voices** *(tab green `#6AA64A`)* — Name, Role, Company, Sentiment, Quote, Source (hyperlink to refId)
14. **Bearish Voices** *(tab red `#ED4545`)* — Firm, Sentiment, Quote, Source (hyperlink to refId)
15. **Themes** — Theme Title, Insight, Evidence Text, Company, Source (hyperlink to refId); evidence rows indented below each theme
16. **Risks** *(tab red `#ED4545`)* — Risk, Evidence, Source (hyperlink to refId)

**Styling** (every sheet):
- Row 1: fill `#205262`, white bold text, height 22pt, frozen so it stays visible when scrolling
- Autofilter on header row (all sheets except Summary)
- Positive numeric values → font `#6AA64A` (green) · Negative → `#ED4545` (red)
- Scores: `0.00` · Change/% columns: `0.0%` · Counts: whole numbers
- Hyperlinks: blue underlined, display text "Source"
- Wrap long text (quotes, narratives) — no column wider than ~50 chars
- No zebra striping · No cell borders

Report the saved filename to the user when complete.

If the user answers no, end the skill normally.

---

## Date Handling

```
Past year (default): sinceDay = 1 year ago,   untilDay = today
Past quarter:        sinceDay = 90 days ago,  untilDay = today
Past 6 months:       sinceDay = 6 months ago, untilDay = today
YTD:                 sinceDay = Jan 1,        untilDay = today
```

Default to past year for Full Report, 90 days for Movers and Theme reports. `getAnalytics` max 1 year — split longer requests.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Sector name not recognized | Check against valid list; fall back to top-level sector |
| `getTopMovers` returns fewer than 5 companies | Widen date range; remove `documentTypes` filter |
| `getAnalytics` returns no event types | Confirm range ≤ 1 year; try without `documentTypes` |
| `searchTopCompanies` empty for event type | Skip that event type; note it; proceed |
| `getTrends` returns fewer than 10 | Widen date range; remove `documentTypes` |
| `getSpeakers` returns nothing for a company | Try without date filter; widen window |
| No quotes returned | Omit `themes`/`bullishVoices`/`bearishVoices` keys — never fabricate |
| Ambiguous sector | Map to "Information Technology" (or appropriate top-level); note in narrative |

---

## Best Practices

1. Always pass `sectors` as an array — `["Information Technology"]`, not `"Information Technology"`.
2. Call `searchTopCompanies` once per event type — never merge event types.
3. Never pass `query` to `getTrends` — it does not exist.
4. Maximize parallelism.
5. Always state divergences — `underperforming` with high investment score is the most actionable signal.
6. Never fabricate — missing data → omit the key.
7. Do not mention tool names — describe the action.

---

## Supporting Files

| File | Purpose |
|------|---------|
| [reference/tool-cheatsheet.md](./reference/tool-cheatsheet.md) | Tool parameters, response fields, batch plan, computed formulas |
| [examples/information-technology.md](./examples/information-technology.md) | Full worked example: IT sector |
| [evaluations/criteria.md](./evaluations/criteria.md) | Evaluation rubric |
| [evals/evals.json](./evals/evals.json) | Structured test cases |
