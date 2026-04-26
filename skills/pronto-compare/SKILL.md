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

Data gathering + scoring live here; HTML rendering is delegated to the `pronto-html-renderer` agent.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, or `deep-research`. These are user-triggered only.

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

```
getOrganization    → save org
```

**For each COMPANY:**
```
getCompanyDescription(companyNameOrTicker: "<company>")
  → save: companyId, sector, subSector, description, risks[]
```

**For each SECTOR:** no API call — use the normalized exact sector string.

After Batch 1: every company has `companyId`; every entity has a confirmed type and display name.

---

## Step 3: Batch 2 — Core Data (parallel across all entities)

### Per COMPANY:
```
getCompanyDocuments(companyName, documentTypes: ["Earnings Calls"], limit: 4)
  → save transcriptId[] and call dates Q1–Q4
getStockChange ×3   (YTD, 6M, 1Y)
getPredictions ×4   (revenue, epsGaap, ebitda, freeCashFlow)
getTrends(companyName, documentTypes: ["Earnings Calls"], sinceDay: 1Y ago, limit: 10)
```

### Per SECTOR:
```
getAnalytics(sectors, documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: 1Y ago, untilDay: today)
  → sentimentScore, investmentScore, directions, top positive/negative events, top aspects

getTrends(sectors, documentTypes: ["Earnings Calls"], sinceDay: 1Y ago, limit: 10)
  (NEVER pass `query` or `topicSearchQuery` to getTrends)

getTopMovers(sectors, documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange",
           "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay: 1Y ago)
  → top by investment, top by sentiment, top by stock, underperformers
```

---

## Step 4: Batch 3 — Deep Analysis (parallel across all entities)

### Per COMPANY (uses transcriptIds from Batch 2):
```
getAnalytics ×4   (per quarter, pass documentIDs, analyticsType: scores/events/aspects/patternSentiment)
getStockPrices ×4 (call date ±5 days, interval: "day" → stock reaction per quarter)
getSpeakers       (Executives, sortBy: sentiment, limit: 20)
getSpeakers       (Executives_CEO, limit: 3)
getSpeakers       (Executives_CFO, limit: 3)
getSpeakers       (Analysts, sortBy: sentiment, limit: 20)
getSpeakerCompanies (Analysts, sortBy: sentiment, limit: 10)
```

### Per SECTOR (uses top companies from getTopMovers):
```
searchTopCompanies(sectors, eventTypes: ["GrowthDriver"], limit: 5)
searchTopCompanies(sectors, eventTypes: ["RiskFactor"],   limit: 5)
getSpeakers(companyName: "<sector's top company>", speakerTypes: ["Executives"], limit: 10)
getSpeakerCompanies(companyName: "<sector's top company>", speakerTypes: ["Analysts"], limit: 10)
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
org: [org]
sinceDay: 1Y ago
untilDay: today

Fetch quotes for the comparison report.

Per COMPANY entity:
- Bullish executive quotes — speakerTypes: Executives, sentiment: positive,
  topicSearchQuery: 'growth outlook guidance', documentTypes: ["Earnings Calls"], size: 3
- Bearish/risk quotes — sentiment: negative,
  topicSearchQuery: 'risk challenge headwind', size: 3
- Notable analyst questions — sections: EarningsCalls_Question, size: 3

Per SECTOR entity (use the sector's top company as representative):
- Bullish quotes — companyName: [top company], speakerTypes: Executives, sentiment: positive,
  topicSearchQuery: 'sector growth momentum', size: 3
- Bearish/risk quotes — sentiment: negative,
  topicSearchQuery: 'sector risk headwind', size: 3

Return with speaker name, role, date, refId.
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
org: <org>
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
      risks:  [ { title, evidence, refId } ]
      quotes: [ { text, speakerName, role, date, refId, section } ]
  sectors:   # keyed by sector string, sector entities only
    <sector>:
      scores: { sentiment: { value, direction }, investment: { value, direction } }
      topMover:        { company, ytdChange }
      fastestRisingTheme: { name, change }
      dominantPositiveEvent: { name, hits }
      dominantNegativeEvent: { name, hits }
      trends:  [ { name, score, change } ]
      quotes:  [ { text, speakerName, role, date, refId, section } ]
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
    [ { text, speakerName, role, company, date, refId, entityName } ]
```

**Populating `verdictEvidence`:** After writing the verdict paragraphs, look at each entity's `quotes` array (in `data.companies.<name>.quotes` or `data.sectors.<name>.quotes`). Select the 1–2 quotes that most directly back up the claim made in the corresponding verdict paragraph — e.g. if the `overallLeader` paragraph cites NVDA's investment score rising, pick a bullish executive quote from NVDA's `bull` section. Include the `entityName` field on every entry so the renderer can group by entity.

The renderer handles the scorecard coloring (green for winner, red for loser in 2-entity mode; green for winner only in 3+), N/A cells for company-only rows on sector entities, entity colors across all charts, and quarter-card / sector-summary layouts.

---

## Date Handling

| Scope | sinceDay | untilDay |
|-------|----------|----------|
| Default (past year) | 1 year ago | today |
| "past quarter" | 90 days ago | today |
| "past 6 months" | 6 months ago | today |
| YTD | Jan 1 current year | today |

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

1. Save `companyId` immediately for every company entity.
2. Fire all entities simultaneously within each batch — never process one at a time.
3. Scorecard adapts to entity mix — use null / companyOnly flag for sector entities on company-only rows.
4. Label entity types in every section header (renderer does this from the `type` field).
5. Divergence signal (rising investment + weak stock) is the most actionable insight.
6. Never fabricate — missing data → null.
7. Consistent entity colors across charts (passed in `data.entities[*].color`).

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
