---
name: pronto-company-intelligence
description: "Generates a full intelligence report for a single named company or ticker — covering earnings sentiment, investment score, stock performance, analyst and executive sentiment, trending topics, risk factors, and financial forecasts. Use when the user mentions one specific company name or ticker and asks about analysis, earnings, sentiment, financials, investment potential, stock performance, risks, or analyst opinions for that company. Triggers on phrases like: 'how is [company] doing', 'analyze [ticker]', '[company] earnings', 'should I buy [company]', 'what do analysts say about [company]', 'deep dive on [company]', '[company] sentiment', '[company] risks', '[ticker] outlook', 'give me a report on [company]'. Do not use when the user asks to compare two or more companies — use the compare-companies skill instead. Do not use for broad market overviews or sector-wide questions."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Company Intelligence Report Generator

Produces a single-company intelligence report. Centerpiece: **quarter-over-quarter comparison of every earnings call in the past year**, explicitly showing whether sentiment, investment scores, and stock price reaction are RISING or FALLING. Layered on top: analyst forecasts, competitive benchmarks, trending topics, management quotes, and risk factors.

Data gathering and per-quarter analysis live here; HTML rendering is delegated to the `pronto-html-renderer` agent.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, or `deep-research`. These are user-triggered only.

---

## Step 0: Choose Report Mode

| Mode | Use when | Tool calls | Sections included (payload keys) |
|------|----------|------------|----------------------------------|
| **Full Report** (default) | Deep dive, no specific focus | ~40 | meta, kpi, quartersChart, stockChart, competitors, trends, speakers, quotes, predictions, risks |
| **Quick Report** | "quick", "overview", "brief" | ~13 | meta, kpi, stockChart, predictions |
| **Sentiment Report** | Earnings/sentiment focus | ~25 | meta, kpi, quartersChart, speakers, trends, quotes (bull/bear/forecast) |
| **Competitive Report** | Competitor/peer focus | ~15 | meta, kpi, stockChart, competitors |
| **Risk Assessment** | Downside focus | ~20 | meta, kpi, quartersChart, risks, quotes (bear/risk), speakers (analysts only) |

Default to Full Report unless the user signals a narrower scope. See [reference/report-template-guide.md](./reference/report-template-guide.md) for per-mode batch plans.

---

## Confirm Before Proceeding

After Step 0, **before calling any tools**, present a short summary and wait for the user to confirm.

Show the user:
- **Company:** name and ticker as understood
- **Report mode:** which mode was selected and why
- **Date range:** e.g. "Past year — Apr 2025 to Apr 2026"
- **Sections:** brief list of what will be included

Then ask: *"Ready to generate the report. Reply **yes** to continue, or clarify anything above."*

**Do not call any tools until the user confirms.**

---

## Tools Reference

| # | Tool | Purpose | Company param |
|---|------|---------|---------------|
| 1 | `getCompanyDescription` | Overview, risks, predictions | `companyNameOrTicker` |
| 2 | `getCompanyCompetitors` | Competitor list | `companyNameOrTicker` |
| 3 | `getCompanyDocuments` | Earnings calls, 10-K, 10-Q | `companyName` |
| 4 | `getStockPrices` | Historical price series | `companyId` |
| 5 | `getStockChange` | Price % change over period | `companyId` |
| 6 | `getPredictions` | Analyst consensus estimates | `companyId` |
| 7 | `getAnalytics` | Sentiment scores, events, aspects | `companyName` |
| 8 | `getTrends` | Trending topics | `companyName` |
| 9 | `getSpeakers` | Per-executive/analyst sentiment | `companyName` |
| 10 | `getSpeakerCompanies` | Analyst firm sentiment | `companyName` |
| 11 | `search` | Key quotes from filings (via search-summarizer) | — |

### ID Flow

- `getCompanyDescription` → `companyId` → pass to `getStockPrices`, `getStockChange`, `getPredictions`
- `getCompanyCompetitors` → competitor `companyId`s → pass to `getStockChange` (per competitor)
- `getCompanyDocuments` → `transcriptId` per doc → pass to `getAnalytics` and `search` per quarter

Prefer `companyId` over `companyName` when a tool accepts both.

---

## Parallel Execution — Full Report

Batches run sequentially; within a batch, fire all calls simultaneously.

**Batch 1** — foundation:
```
getCompanyDescription    → save companyId, sector, risks
getCompanyCompetitors    → save competitor companyIds[]
getOrganization          → save org (required by renderer for citation links)
```

**Batch 2** — data collection (needs companyId):
```
getCompanyDocuments      → save transcriptId per earnings call
getStockPrices           (1-year weekly)
getStockChange ×3        (YTD, 6M, 1Y)
getPredictions ×6        (revenue, epsGaap, ebitda, netIncomeGaap, freeCashFlow, capitalExpenditure)
getTrends
```

**Batch 3** — deep analysis (needs transcriptIds):
```
getAnalytics ×4          (one per earnings call, pass documentID)
getStockPrices ×4        (1 week before/after each call, interval: "day")
getSpeakers              (Executives, sortBy: count)
getSpeakers              (Executives_CEO)
getSpeakers              (Executives_CFO)
getSpeakers              (Analysts, sortBy: sentiment desc)
getSpeakerCompanies      (Analysts)
getStockChange per competitor
```

**Batch 4** — quotes and forecasts (**REQUIRED — do not render before this completes**):

Delegate to ONE `pronto-search-summarizer` (`subagent_type: prontonlp-plugin:pronto-search-summarizer`):
```
org: [org from getOrganization]

Fetch all quotes needed for the [company] intelligence report. Run these searches:
1–4. Forecast/guidance quotes per quarter — documentIDs: [doc_qN], topicSearchQuery: 'forecast guidance outlook', sentiment: positive, size: 3
5.   Most bullish executive quotes — companyName, speakerTypes: Executives, sentiment: positive, documentTypes: ["Earnings Calls"], size: 3
6.   Top risk/bearish quotes — topicSearchQuery: 'risk challenge headwind', sentiment: negative, documentTypes: ["Earnings Calls"], size: 3
7.   Notable analyst questions — sections: EarningsCalls_Question, documentTypes: ["Earnings Calls"], size: 3
Return with speaker name, role, date, and refId.
```

Save the top 1–2 quotes per task, tagging each by section (`bull`, `bear`, `forecast`, `risk`).

**Batch 5** — render (see Step 4 below).

---

## Core: Per-Quarter Earnings Comparison

This is the heart of the report. Run `getAnalytics` **separately for each of the past year's earnings calls** — the only way to produce RISING/FALLING comparisons.

For each earnings call:

```
getAnalytics:
  companyName: "<name>"
  documentIDs: ["<transcriptId>"]
  documentTypes: ["Earnings Calls"]
  sinceDay / untilDay: bracket the quarter
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
  → extract: sentimentScore, investmentScore, patternSentiment, top events, top aspects

getStockPrices (1 week window around call):
  companyId: "<id>"
  fromDate: 7 days before call date
  toDate:   7 days after call date
  interval: "day"
  → compute: % change before vs after = stock reaction
```

Compute for each quarter: `sentimentDirection`, `investmentDirection`, `stockReaction`. Compare first vs last quarter for overall trajectory.

Always surface in the narrative:
1. "Sentiment is [RISING/FALLING] — from X.XX (Q1) to X.XX (Q4)"
2. "Investment score is [RISING/FALLING] — from X.XX (Q1) to X.XX (Q4)"
3. "Stock reacted [positively/negatively] to [N] of [total] earnings calls"

**Divergences are the most valuable insights.** Flag them in the executive summary:
- Sentiment falling + stock rising → market disagrees with tone
- Sentiment rising + stock falling → market skeptical despite positive language
- Investment score falling while sentiment rising → deeper issues beneath the surface

---

## Speaker Analysis

After Batch 3 completes, compute and include in the narrative:
- Average executive sentiment vs average analyst sentiment
- "Executives are MORE POSITIVE/MORE NEGATIVE than analysts by X.XX"
- "CEO is MORE BULLISH/MORE CAUTIOUS than CFO" (compare individual scores)
- Most bullish analyst: [Name] from [Firm] (X.XX); most bearish: [Name] from [Firm] (X.XX)
- Gap interpretation: `> +0.10` = management may be over-optimistic; `< -0.10` = street sees more upside

---

## Step 4: Render

Delegate the HTML output to `pronto-html-renderer` (`subagent_type: prontonlp-plugin:pronto-html-renderer`). Do not render HTML here.

```
report_type: company
org: <from getOrganization>
filename: <TICKER>-report-<YYYYMMDD>.html
title: "<Company Name> (<Ticker>) — Intelligence Report"
subtitle: "Generated: <date> · Sector: <sector> · Market Cap: <cap>"
data:
  meta: { ticker, companyId, companyName, sector, subSector, asOfDate }
  kpi:  { investmentScore, investmentScoreChange, sentimentScore, sentimentScoreChange,
          stockChangeYTD, stockChange6M, stockChange1Y }
  quartersChart:
    quarters:          [ "Q1 2025", "Q2 2025", ... ]
    sentimentScores:   [ ... ]
    investmentScores:  [ ... ]
    stockReactions:    [ ... ]
    positiveEvents:    [ ... ]
    negativeEvents:    [ ... ]
  quarterCards: [ { label, date, sentiment, sentimentArrow, investment, investmentArrow,
                    patternPos, patternNeg, revenue, badge, notes, isLatest } ]
  stockChart: { dates: [...], prices: [...], earningsCallIndices: [...] }
  competitors: [ { name, ticker, return1Y, isTarget } ]           # sorted desc, target first
  trends: [ { name, score, change, hits, explanation } ]
  speakers:
    executives: [ { name, role, sentiment, sentenceCount } ]       # incl. CEO, CFO, execAvg rows
    analysts:   [ { name, firm, sentiment, sentenceCount } ]
    gap:        { execAvg, analystAvg, interpretation }
  quotes: [ { text, speakerName, role, company, date, refId, section } ]  # section ∈ {bull, bear, forecast, risk}
  predictions: { revenue: [...], epsGaap: [...], ebitda: [...],
                 netIncomeGaap: [...], freeCashFlow: [...], capitalExpenditure: [...] }
  risks: [ { title, evidence, refId } ]
narrative:
  executiveSummary: "<2–3 paragraphs that explicitly state all RISING/FALLING verdicts, the exec-vs-analyst gap, and the thesis>"
  verdict: "<bullish / bearish / neutral + 3 supporting points>"
```

**Report section order** (renderer follows this sequence):
1. Header
2. Executive Summary
3. Stock Performance — stock chart + stock KPI tiles (YTD · 6M · 1Y)
4. Financial Outlook — predictions table (Revenue, EPS, EBITDA, Net Income, FCF, CapEx)
5. Quarter Cards — one card per earnings call
6. Competitors — peer return table
7. KPI grid (full — all 7 metrics)
8. Quarters chart (sentiment + investment lines + stock reaction bars)
9. Trends, Speakers, Quotes, Risks, Verdict

The renderer applies shared conventions (color rule, score display, company/citation links, chart palette, quarter-card styling, badge rules). For narrower report modes, omit payload keys that were not gathered — the renderer skips absent sections.

---

## Step 5: Optional XLSX Export

After the HTML renderer reports success, ask the user:

> "Your report is ready: `<filename>.html`. Want this also as an XLSX file? (yes/no)"

**Skip the prompt** if the user explicitly asked for XLSX up front (e.g. "give me the Tesla report as xlsx", "in spreadsheet form") — in that case generate both formats automatically.

If the user answers yes (or pre-asked), invoke `anthropic-skills:xlsx` **directly from this skill** (not via a sub-agent) using the same data you already built for the HTML renderer.

**Filename:** same as the HTML file but `.xlsx` extension.

**Sheets to create** (skip any whose source data is missing or empty):
1. **Summary** *(tab teal `#205262`, no autofilter)* — `meta` fields as Key / Value rows, then `narrative.executiveSummary` and `narrative.verdict` as wrapped text blocks
2. **Stock Performance** — `stockChart` dates × prices, followed by a separator and YTD / 6M / 1Y stock-change KPI rows
3. **Financial Outlook** — `predictions` flattened: one row per (Metric, Period, Estimate, Low, High, Actual) across all 6 metrics
4. **Quarter Cards** — one row per `quarterCards` entry: Quarter, Date, Sentiment, Investment, Revenue, Badge, Notes
5. **Competitors** — Company, Ticker, 1Y Return, Target (✓ for `isTarget`)
6. **KPI Grid** — all 7 KPI metrics as Label / Value rows
7. **Quarters Chart Data** — Quarter, Sentiment, Investment, Stock Reaction, Positive Events, Negative Events
8. **Trends** — Topic, Score, Change, Hits, Explanation
9. **Speakers** — Type (Executive / Analyst), Name, Role / Firm, Sentiment, Sentences; gap footer rows below
10. **Quotes** — Section, Quote, Speaker, Role, Company, Date, Source (hyperlink to refId)
11. **Risks** *(tab red `#ED4545`)* — Risk, Evidence, Source (hyperlink to refId)

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
Past year:     sinceDay = 1 year ago,   untilDay = today
Past quarter:  sinceDay = 90 days ago,  untilDay = today
YTD:           sinceDay = Jan 1,        untilDay = today
Past 6 months: sinceDay = 6 months ago, untilDay = today
```

`getAnalytics` max range: 1 year — split longer requests into multiple yearly calls.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Company not found | Try ticker instead of name (or vice versa); check spelling |
| `getCompanyDescription` returns nothing | Ask user to verify; do not proceed without companyId |
| Fewer than 4 earnings calls | Work with available quarters; note the gap in the payload |
| No predictions for a metric | Omit from payload; renderer skips absent rows |
| Analytics returns empty | Verify date range ≤ 1 year; try without `documentIDs` filter |
| No competitors returned | Omit `competitors` from payload |
| No quotes returned | Omit `quotes` — never fabricate |
| Private/unlisted company | ProntoNLP covers public companies only — tell the user |
| companyId missing from response | Inspect the full object for `id` or nested field |

---

## Best Practices

1. Save `companyId` the moment you get it from `getCompanyDescription`.
2. Maximize parallelism — batch all independent calls per the strategy above.
3. Never fabricate data — if a tool returns nothing, omit the corresponding payload key.
4. Never reformat raw scores — pass `0.71`, not `7.1` or `7.1/10` (renderer enforces).
5. Prefer `companyId` over `companyName` when a tool accepts both.
6. Do not mention tool names in responses — describe the action ("I analyzed 4 earnings calls", not "I called getAnalytics 4 times").
