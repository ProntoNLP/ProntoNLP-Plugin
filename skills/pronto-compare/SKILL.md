---
name: pronto-compare
description: "Generates a unified side-by-side comparison report for two or more named companies, tickers, market sectors, or any mix of companies and sectors — scoring each across sentiment, investment score, stock performance, trending topics, and risk factors to determine an overall leader. Use when the user wants to compare specific companies, sectors, or a company against a sector. Triggers on phrases like: '[company] vs [company]', '[sector] vs [sector]', '[company] vs [sector]', 'compare [company] and [sector]', 'tech vs healthcare', 'NVDA vs the tech sector', 'which sector leads — IT or financials', 'how does [company] compare to [sector]', 'semiconductors vs software'. Supports 2 to 5 entities (companies, sectors, or mixed). Do not use for a single named company — use the company intelligence skill. Do not use for a single sector — use the sector intelligence skill. Do not use for broad market overviews — use the market pulse skill."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Universal Comparison Report Generator

Side-by-side intelligence comparison of 2–5 entities (companies, sectors, or mixed). Gathers per-entity data, scores each across shared dimensions, picks a winner per dimension, synthesizes a verdict.

Data gathering + scoring live here; final output is a regular standalone HTML report delegated to the `pronto-html-renderer` agent. This skill is not a live artifact.

> ⛔ **TOOL RESTRICTION:** Never call `showDocumentMindMap` or `deepResearch`. These are user-triggered only.

---

## Step 1: Parse Entities & Assign Types

Extract all entities from the request. Classify each as **company** or **sector**. Support **2–5** entities; if more, ask the user to narrow.

### Entity classification

| Type | Identifies as | Examples |
|------|--------------|----------|
| Company | Named company or ticker | "NVDA", "Apple", "Tesla" |
| Sector | Market sector or sub-sector | "tech sector", "healthcare", "semiconductors" |

Signal phrases: "NVDA vs the tech sector" (company + sector) · "tech vs healthcare" (sector + sector) · "NVDA vs AMD vs semiconductors" (mixed).

### Sector name normalization

| User says | API string |
|-----------|-----------|
| tech, technology | `Information Technology` |
| healthcare, health, pharma, biotech, medtech | `Health Care` |
| financials, finance, banking | `Financials` |
| energy, oil, gas | `Energy` |
| consumer discretionary, retail, auto | `Consumer Discretionary` |
| consumer staples, food, beverage | `Consumer Staples` |
| industrials, aerospace, defense | `Industrials` |
| utilities | `Utilities` |
| real estate, reits | `Real Estate` |
| materials, chemicals, mining | `Materials` |
| communication, media, telecom | `Communication Services` |
| semiconductors | `Information Technology-Semiconductors and Semiconductor Equipment` |
| software, cloud | `Information Technology-Software` |
| ev sector, electric vehicles | `Consumer Discretionary-Automobiles` |

### Entity colors (passed in payload; renderer uses them consistently)

Entity A `#3B82F6` · B `#8B5CF6` · C `#F59E0B` · D `#14B8A6` · E `#EC4899`

---

## Confirm Before Proceeding

After Step 1, **before calling any tools**, present a short summary and wait for the user to confirm.

Show the user:
- **Entities:** each entity name, its type (Company / Sector), and the normalized API string (e.g. `Information Technology-Semiconductors…`)
- **Comparison mode:** company-vs-company / sector-vs-sector / mixed — and how many scoring dimensions will be used
- **Date range:** e.g. "Past year — Apr 2025 to Apr 2026"

Then ask: *"Ready to generate the comparison report. Reply **yes** to continue, or clarify anything above."*

**Do not call any tools until the user confirms.**

---

## Step 2: Batch 1 — Foundation (parallel across all entities)

**For each COMPANY:**
```
getCompanies(companyNameOrTicker: "<company>")
  → save: companyId, sector, name, description_text
  (risks deferred to Batch 3 — fetched via getDocumentSummary after transcriptIds are available)
```

**For each SECTOR:** no API call — use the normalized exact sector string.

After Batch 1: every company has `companyId`; every entity has a confirmed type and display name.

---

## Step 3: Batch 2 — Core Data (parallel across all entities)

### Per COMPANY:

**Batchable across all companies (one call for all company IDs):**
```
getDocuments(companiesIds: [co1, co2, ...], documentTypes: ["Earnings Calls"], size: 4, excludeFutureDocuments: true)
  → save transcriptId per call per company, call dates Q1–Q4
getStockChange(companiesIds: [co1, co2, ...], dateRange: YTD) — ONE call for all companies
getStockChange(companiesIds: [co1, co2, ...], dateRange: 6M)  — ONE call for all companies
getStockChange(companiesIds: [co1, co2, ...], dateRange: 1Y)  — ONE call for all companies
getCompanyConsensus(companiesIds: [co1, co2, ...], metrics: ['revenue', 'epsGaap', 'ebitda', 'freeCashFlow'], timeframeInterval: 'quarter')
  — ONE call for all companies
```

**Separate per company (results aggregate across companies — need per-company breakdown):**
```
getTrends(companiesIds: [companyId], documentTypes: ["Earnings Calls"], dateRange: {gte: 'now-1y/d', lte: 'now'}, limit: 10)
  → one call per company
```

### Per SECTOR:
```
getAnalytics(sectors: [...], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  dateRange: { gte: 'now-1y/d', lte: 'now' })
  → sentimentScore, investmentScore, directions, top positive/negative events, top aspects

getTrends(sectors: [...], documentTypes: ["Earnings Calls"],
  dateRange: { gte: 'now-1y/d', lte: 'now' }, limit: 10)
  (NEVER pass `query` to getTrends — `topicSearchQuery` is accepted for subject-area scoping)

getTopMovers(sectors: [...], documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange",
           "investmentScoreChange", "sentimentScoreChange"],
  limit: 10,
  dateRange: { gte: 'now-1y/d', lte: 'now' })
  → top by investment, top by sentiment, top by stock, underperformers
```

---

## Step 4: Batch 3 — Deep Analysis (parallel across all entities)

### Per COMPANY (uses transcriptIds from Batch 2):

**Separate per quarter (need per-quarter scores for RISING/FALLING computation):**
```
getAnalytics ×4   (per quarter per company, pass transcriptsIds: [transcriptId_qN], analyticsType: scores/events/aspects/patternSentiment)
getStockPrices(companiesIds: [companyId]) ×4  (dateRange: call date ±5 days, interval: 'day' → stock reaction per quarter)
```

**Separate per company (need per-company attribution):**
```
getSpeakers(entityType: 'speaker', speakerTypes: ['Executives'], sortBy: 'sentiment', sortOrder: 'desc', limit: 20, companiesIds: [companyId])
getSpeakers(entityType: 'speaker', speakerTypes: ['Executives_CEO'], limit: 3, companiesIds: [companyId])
getSpeakers(entityType: 'speaker', speakerTypes: ['Executives_CFO'], limit: 3, companiesIds: [companyId])
getSpeakers(entityType: 'speaker', speakerTypes: ['Analysts'], sortBy: 'sentiment', sortOrder: 'desc', limit: 20, companiesIds: [companyId])
getSpeakers(entityType: 'company', speakerTypes: ['Analysts'], sortBy: 'sentiment', sortOrder: 'desc', limit: 10, companiesIds: [companyId])
```

**Batchable across all companies (ONE call — max 5 transcripts):**
```
getDocumentSummary(focus: 'key risks and risk factors mentioned by management', transcriptsIds: [latestTx_co1, latestTx_co2, ...], corpus: ['S&P Transcripts'])
```

### Per SECTOR (uses top companies from getTopMovers):
```
getCompanies(sectors: [...], eventTypes: ["GrowthDriver"], companySearchMode: 'byDocuments')
getCompanies(sectors: [...], eventTypes: ["RiskFactor"], companySearchMode: 'byDocuments')
getSpeakers(entityType: 'speaker', companiesIds: [topCompanyId], speakerTypes: ["Executives"], limit: 10)
getSpeakers(entityType: 'company', companiesIds: [topCompanyId], speakerTypes: ["Analysts"], limit: 10)
```

Compute per company:
- `sentimentDirection` (RISING if Q4 > Q1, FALLING if Q4 < Q1)
- `investmentDirection` (same logic)
- `positiveCallCount` (quarters with stock reaction > 0)
- `execAnalystGap = execAvg - analystAvg`

---

## Step 5: Batch 4 — Quotes (**REQUIRED — do not proceed until complete**)

Delegate to ONE `pronto-search-summarizer` (`subagent_type: prontonlp-plugin:pronto-search-summarizer`):

```
dateRange: { gte: 'now-1y/d', lte: 'now' }

Fetch quotes for the comparison report.

Per COMPANY entity:
- Bullish executive quotes — speakerTypes: Executives, DLSentiment: ['positive'],
  topicSearchQuery: 'growth outlook guidance', documentTypes: ["Earnings Calls"], companiesIds: [companyId], size: 3
- Bearish/risk quotes — DLSentiment: ['negative'],
  topicSearchQuery: 'risk challenge headwind', companiesIds: [companyId], size: 3
- Notable analyst questions — sections: EarningsCalls_Question, companiesIds: [companyId], size: 3

Per SECTOR entity (use the sector's top company as representative):
- Bullish quotes — companiesIds: [topCompanyId], speakerTypes: Executives, DLSentiment: ['positive'],
  topicSearchQuery: 'sector growth momentum', size: 3
- Bearish/risk quotes — DLSentiment: ['negative'],
  topicSearchQuery: 'sector risk headwind', companiesIds: [topCompanyId], size: 3

Return with speaker name, role, date. Citation link is already embedded in the text field.
```

Tag each quote by section (`bull`, `bear`, `analyst-question`) and by entity.

---

## Step 6: Score Entities

### Company-only comparison — 9 dimensions

| Dimension | Winner |
|-----------|--------|
| Sentiment trend | Highest Q4 sentiment; tiebreak RISING |
| Investment score | Highest Q4 raw score |
| Stock YTD | Best YTD % |
| Earnings reaction | Most N of M positive quarters |
| Analyst consensus | Highest analyst avg sentiment |
| Revenue (fwd) | Best forward revenue |
| EPS (fwd) | Highest forward EPS |
| Exec confidence | Highest executive avg sentiment |
| Risk profile | Fewest/least severe risks |

### Sector-only — 7 dimensions

| Dimension | Winner |
|-----------|--------|
| Sentiment score | Highest aggregate |
| Investment score | Highest aggregate raw |
| Sentiment direction | RISING > FALLING |
| Investment direction | RISING > FALLING |
| Stock performance | Sector's top mover YTD % (or avg of top 5) |
| Theme momentum | Fastest-rising topic change % |
| Risk profile | Fewer negative events / lower severity |

### Mixed (company + sector) — 7 universal + 2 company-only (N/A for sectors)

Universal rows: sentiment score, investment score, sentiment direction, investment direction, stock performance, theme momentum, risk profile.
Company-only rows: earnings reaction, financial outlook (revenue + EPS).

### Always compute

- Per-entity sentiment direction: `"RISING (X.XX → X.XX)"` or `"FALLING"`
- Per-entity investment direction
- Stock context: for sectors, note this is the top mover, not full-sector average
- Divergence: rising investment + weak stock = potential undervalued / re-rating signal
- Topic overlap: shared = macro theme; unique = entity-specific narrative
- Risk overlap: in 2+ entities = systemic; in 1 = idiosyncratic

---

## Step 7: Render

Delegate HTML output to `pronto-html-renderer` (`subagent_type: prontonlp-plugin:pronto-html-renderer`).

File naming:
- Company vs company: `<tickerA>-vs-<tickerB>-<YYYYMMDD>.html`
- Company vs sector: `<ticker>-vs-<sector-slug>-<YYYYMMDD>.html`
- Sector vs sector: `<sectorA-slug>-vs-<sectorB-slug>-<YYYYMMDD>.html`

```
report_type: compare
filename: <as above>
title: "<Entity A> vs <Entity B> [vs ...] — Comparison Report"
subtitle: "<N> Entities (<type breakdown>) · Period: Past Year"
data:
  entities: [ { type, name, displayLabel, ticker?, sectorString?, color } ]
  scorecard: [ { metric, values: { <entityName>: { raw, formatted, direction? } },
                 winner: <entityName or "—">, companyOnly?: bool } ]
  overallWins: { <entityName>: <int> }
  companies:  # keyed by entity name, company entities only
    <name>:
      quarters: [ { label, date, sentiment, investment, stockReaction } ]
      kpi: { sentimentQ4, investmentQ4, stockYTD, stock6M, stock1Y }
      speakers: { ceo, cfo, execAvg, analystAvg, mostBullishAnalystFirm, mostBearishAnalystFirm }
      predictions: { revenueFwd, epsFwd, ebitdaFwd, fcfFwd }
      trends: [ { name, score, change } ]
      risks:  [ { title, evidence } ]  # evidence contains "[Source](url)"
      quotes: [ { text, speakerName, role, date, section } ]  # text ends with "[Source](url)"
  sectors:   # keyed by sector string, sector entities only
    <sector>:
      scores: { sentiment: { value, direction }, investment: { value, direction } }
      topMover:        { company, ytdChange }
      fastestRisingTheme: { name, change }
      dominantPositiveEvent: { name, hits }
      dominantNegativeEvent: { name, hits }
      trends:  [ { name, score, change } ]
      quotes:  [ { text, speakerName, role, date, section } ]
  topicMatrix: [ [ { entity, topic, change } ] ]         # per-entity top-10 topic lists
  overlap: { sharedAll: [...], sharedBy2: [...], uniqueTo: { <entity>: [...] } }
  riskMatrix: [ { risk, byEntity: { <entity>: bool }, type: "Systemic"|"Idiosyncratic" } ]
narrative:
  verdict:
    overallLeader: "<paragraph — cite the specific metrics that decided the winner>"
    undervaluedSignal: "<paragraph — cite the divergence signal if present>"
    highestRisk: "<paragraph — cite the dominant risk and which entity it affects>"
    bottomLine: "<one-liner: 'If you had to pick one: <entity> — because…'>"
  verdictEvidence:
    # Select 1–2 quotes per entity from their quotes array that best support the verdict claims.
    # Pick bull quotes for the winner, bear/risk quotes for the loser or the highest-risk entity.
    # Each entry must include entityName so the renderer groups them by entity.
    [ { text, speakerName, role, company, date, entityName } ]  # text ends with "[Source](url)"
```

**Populating `verdictEvidence`:** After writing the verdict paragraphs, look at each entity's `quotes` array (in `data.companies.<name>.quotes` or `data.sectors.<name>.quotes`). Select the 1–2 quotes that most directly back up the claim made in the corresponding verdict paragraph — e.g. if the `overallLeader` paragraph cites NVDA's investment score rising, pick a bullish executive quote from NVDA's `bull` section. Include the `entityName` field on every entry so the renderer can group by entity.

The renderer handles the scorecard coloring (green for winner, red for loser in 2-entity mode; green for winner only in 3+), N/A cells for company-only rows on sector entities, entity colors across all charts, and quarter-card / sector-summary layouts.

---

## Step 8: Optional XLSX Export

After the HTML renderer reports success, ask the user:

> "Your report is ready: `<filename>.html`. Want this also as an XLSX file? (yes/no)"

**Skip the prompt** if the user explicitly asked for XLSX up front (e.g. "give me the comparison as xlsx", "in spreadsheet form") — in that case generate both formats automatically.

If the user answers yes (or pre-asked), invoke `anthropic-skills:xlsx` **directly from this skill** (not via a sub-agent) using the same data you already built for the HTML renderer.

**Filename:** same as the HTML file but `.xlsx` extension.

**Sheets to create** (skip any whose source data is missing or empty):
1. **Summary** *(tab teal `#205262`, no autofilter)* — entity list (type, name, ticker/sector) as rows, then `narrative.verdict` paragraphs (overallLeader, undervaluedSignal, highestRisk, bottomLine) as wrapped text blocks
2. **Entities** — Type, Name, Display Label, Ticker, Sector String, Color for each entity
3. **Scorecard** — Metric, one column per entity (value + formatted), Winner, Company-Only flag
4. **Overall Wins** — Entity, Wins (count)
5. **Per-Entity Detail** — all company and sector entities on one sheet; entity blocks separated by a header row; columns: Entity, Quarter/Period, Sentiment, Investment, Stock Reaction, Revenue, EPS, Notes
6. **Topic Matrix** — Entity, Topic, Change (flattened from per-entity top-10 topic lists)
7. **Topic Overlap** — Category (Shared All / Shared by 2 / Unique To), Entity, Topic
8. **Risk Matrix** — Risk, Type (Systemic/Idiosyncratic), one column per entity (✓ or blank)
9. **Verdict Evidence** *(tab green `#6AA64A`)* — Entity, Quote (with embedded [Source](url) link), Speaker, Role, Company, Date

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

All tool calls use `dateRange: {gte, lte}` format.

| Scope | gte | lte |
|-------|-----|-----|
| Default (past year) | `now-1y/d` | `now` |
| "past quarter" | `now-90d/d` | `now` |
| "past 6 months" | `now-6M/d` | `now` |
| YTD | `<YYYY>-01-01` | `now` |

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Company not found | Try ticker; note and continue with remaining entities |
| Sector unrecognized | Try top-level sector if sub-sector fails; note mapping |
| Fewer than 4 quarters | Use available quarters; note gap |
| No predictions for a company metric | Emit null in payload — renderer shows "N/A" |
| No analyst data | Emit null — renderer shows "N/A" |
| `getTopMovers` returns < 3 for a sector | Widen date range; remove `documentTypes` filter |
| More than 5 entities | Ask user to narrow to 5 |
| All-sector comparison | Omit company-only scorecard rows from payload |

---

## Best Practices

1. Save `companyId` immediately for every company entity (from `getCompanies`).
2. Fire all entities simultaneously within each batch — never process one at a time.
3. Scorecard adapts to entity mix — use null / companyOnly flag for sector entities on company-only rows.
4. Label entity types in every section header (renderer does this from the `type` field).
5. Divergence signal (rising investment + weak stock) is the most actionable insight.
6. Never fabricate — missing data → null.
7. Consistent entity colors across charts (passed in `data.entities[*].color`).
8. Always pass `companiesIds: [companyId]` (array) to all tools that accept company filtering.

---

## Supporting Files

| File | Purpose |
|------|---------|
| [reference/tool-cheatsheet.md](./reference/tool-cheatsheet.md) | Tool params per entity type, scoring matrix, enum reference |
| [examples/nvda-vs-amd.md](./examples/nvda-vs-amd.md) | Worked example: company vs company |
| [examples/nvda-vs-tech-sector.md](./examples/nvda-vs-tech-sector.md) | Worked example: company vs sector |
| [examples/it-vs-healthcare.md](./examples/it-vs-healthcare.md) | Worked example: sector vs sector |
| [evaluations/criteria.md](./evaluations/criteria.md) | Evaluation rubric |
| [evals/evals.json](./evals/evals.json) | Structured test cases |
