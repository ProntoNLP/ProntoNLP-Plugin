# pronto-compare — Tool & Metrics Reference

This file documents the exact MCP tools, parameters, and metrics for each entity type (company or sector) across all 4 batches. All calls are made directly — no external skills are invoked.

---

## Entity Types

| Type | Identifies as | Batch 1 | Color |
|------|--------------|---------|-------|
| **Company** | Name or ticker | `getCompanies(companyNameOrTicker: ...)` | A=`#3B82F6`, B=`#8B5CF6`, C=`#F59E0B`, D=`#14B8A6`, E=`#EC4899` |
| **Sector** | Sector name normalized to exact API string | No API call — normalize only | Same color scheme |

---

## Sector Name Normalization Table

| User says | Exact API string to use |
|-----------|------------------------|
| tech, technology | `Information Technology` |
| healthcare, health, pharma, biotech | `Health Care` |
| financials, finance, banking | `Financials` |
| energy, oil, gas | `Energy` |
| consumer discretionary, retail | `Consumer Discretionary` |
| consumer staples, food, beverage | `Consumer Staples` |
| industrials, aerospace, defense | `Industrials` |
| utilities | `Utilities` |
| real estate, reits | `Real Estate` |
| materials, chemicals, mining | `Materials` |
| communication, media, telecom | `Communication Services` |
| semiconductors | `Information Technology-Semiconductors and Semiconductor Equipment` |
| software, cloud | `Information Technology-Software` |
| ev sector, electric vehicles | `Consumer Discretionary-Automobiles` |

Use `sectors: ["<Exact API string>"]` in all sector-level tool calls. Always an array.

---

## Date Format

All tools use `dateRange: { gte, lte }` — never `sinceDay`/`untilDay`.

| Scope | gte | lte |
|-------|-----|-----|
| Default (past year) | `now-1y/d` | `now` |
| "past quarter" | `now-90d/d` | `now` |
| "past 6 months" | `now-6M/d` | `now` |
| YTD | `<YYYY>-01-01` | `now` |

---

## Batch Execution Plan

| Batch | When | Company actions | Sector actions |
|-------|------|----------------|----------------|
| 1 | First | `getCompanies(companyNameOrTicker: ...)` ×N companies | Normalize sector string — no API call |
| 2 | After Batch 1 | `getDocuments` + `getStockChange` ×3 + `getCompanyConsensus` + `getTrends` | `getAnalytics` + `getTrends` + `getTopMovers` |
| 3 | After Batch 2 | `getAnalytics` ×4 + `getStockPrices` ×4 + `getSpeakers(entityType: 'speaker')` ×4 + `getSpeakers(entityType: 'company')` + `getDocumentSummary(focus: 'key risks')` | `getCompanies(companySearchMode:'byDocuments')` ×2 + `getSpeakers` (top co.) |
| 4 | After Batch 3 | `searchSentences` ×3 (via pronto-search-summarizer) | `searchSentences` ×2 (via top company in sector) |

**Fire all calls within a batch simultaneously — never sequence within a batch.**

---

## Batch 1 — Foundation

### Companies: `getCompanies`
```
getCompanies(companyNameOrTicker: "[name or ticker]")
```
**Save:** `companyId`, `sector`, `name`, `description_text`

### Sectors: No API call
Save the normalized exact API string. Mark entity type as `sector`.

---

## Batch 2 — Core Data

All Batch 2 calls fire simultaneously across all entities.

### Companies

**`getDocuments`** — 1 call for ALL companies simultaneously:
```
getDocuments(
  companiesIds: ["[co1]", "[co2]", "[co3]", ...],
  documentTypes: ["Earnings Calls"],
  size: 4,
  excludeFutureDocuments: true
)
```
Save: `transcriptId` per call date per company — used as `transcriptsIds` in Batch 3 `getAnalytics`

---

**`getStockChange`** — 3 calls total (one per period), each with ALL company IDs:
```
getStockChange(companiesIds: ["[co1]", "[co2]", ...], dateRange: {gte: "[YYYY]-01-01", lte: "now"})    → YTD all
getStockChange(companiesIds: ["[co1]", "[co2]", ...], dateRange: {gte: "now-6M/d", lte: "now"})       → 6M all
getStockChange(companiesIds: ["[co1]", "[co2]", ...], dateRange: {gte: "now-1y/d", lte: "now"})       → 1Y all
```
Save per company: `stockChangeYTD`, `stockChange6M`, `stockChange1Y`

---

**`getCompanyConsensus`** — 1 call for ALL companies simultaneously:
```
getCompanyConsensus(
  companiesIds: ["[co1]", "[co2]", ...],
  metrics: ["revenue", "epsGaap", "ebitda", "freeCashFlow"],
  timeframeInterval: "quarter"
)
```
Save per company: `revenueGrowthFwd`, `epsGaapFwd`, `ebitdaFwd`, `fcfFwd`

---

**`getTrends`** — 1 call per company:
```
getTrends(
  companiesIds: ["[companyId]"],
  documentTypes: ["Earnings Calls"],
  dateRange: { gte: "now-1y/d", lte: "now" },
  limit: 10
)
```
Save: Top 3 topics by score, fastest-rising topic (highest `change %`), fastest-declining

⚠️ Do NOT pass `query` to `getTrends`. `topicSearchQuery` is accepted if you want to scope by subject area.

---

### Sectors

**`getAnalytics`** — 1 call per sector:
```
getAnalytics(
  sectors: ["<Exact Sector String>"],
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  dateRange: { gte: "now-1y/d", lte: "now" }
)
```
Save:
- `sentimentScore` (aggregate)
- `investmentScore` (aggregate raw value)
- `sentimentDirection`: RISING/FALLING/FLAT
- `investmentDirection`: RISING/FALLING/FLAT
- `topPositiveEvents[]` — name + hit count
- `topNegativeEvents[]` — name + hit count
- `topAspects[]`

---

**`getTrends`** — 1 call per sector:
```
getTrends(
  sectors: ["<Exact Sector String>"],
  documentTypes: ["Earnings Calls"],
  dateRange: { gte: "now-1y/d", lte: "now" },
  limit: 10
)
```
Save: Top 5 topics, fastest-rising (`change %`), fastest-declining

---

**`getTopMovers`** — 1 call per sector:
```
getTopMovers(
  sectors: ["<Exact Sector String>"],
  documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10,
  dateRange: { gte: "now-1y/d", lte: "now" }
)
```
Save:
- `topByInvestment[]` — company name + raw score + `id`
- `topBySentiment[]` — company name + score + `id`
- `topByStockChange[]` — company name + % change
- `underperformers[]`
- `topCompanyId` — `id` of #1 by investment score (used in Batch 3 and 4)

---

## Batch 3 — Deep Analysis

All Batch 3 calls fire simultaneously across all entities.

### Companies

**`getAnalytics`** — 1 call **per quarter**:
```
getAnalytics(
  companiesIds: ["[companyId]"],
  transcriptsIds: ["[transcriptId_Q1]"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"]
)
```
Repeat for Q2, Q3, Q4 using transcriptIds from Batch 2.

Save per quarter: `sentimentScore_Qn`, `investmentScore_Qn`

Compute:
- `sentimentDirection`: RISING if Q4 > Q1, FALLING if Q4 < Q1
- `investmentDirection`: same

---

**`getStockPrices`** — 1 call per quarter per company (7-day window around call date):
```
getStockPrices(
  companiesIds: ["[companyId]"],
  dateRange: { gte: "[call date minus 2 days]", lte: "[call date plus 5 days]" },
  interval: "day"
)
```
Compute: `stockReaction_Qn` = last price ÷ first price − 1 (as %)

Compute: `positiveCallCount` = count of quarters where `stockReaction > 0`

---

**`getDocumentSummary`** — 1 call for ALL companies (latest transcript per company, max 5):
```
getDocumentSummary(
  focus: "key risks and risk factors mentioned by management",
  transcriptsIds: ["[latestTx_co1]", "[latestTx_co2]", "[latestTx_co3]", ...],
  corpus: ["S&P Transcripts"]
)
```
⚠️ Max 5 transcripts per call. Results are keyed by transcript — attribute risks back to the correct company.

Save per company: `risks[]` — array of {text, sources} risk factors

---

**`getSpeakers(entityType: 'speaker')`** — 4 calls per company:
```
getSpeakers(entityType: "speaker", companiesIds: ["[companyId]"], speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["[companyId]"], speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["[companyId]"], speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["[companyId]"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
```
Save: `execAvgSentiment`, `ceoSentiment`, `cfoSentiment`, `analystAvgSentiment`

---

**`getSpeakers(entityType: 'company')`** — 1 call per company:
```
getSpeakers(
  entityType: "company",
  companiesIds: ["[companyId]"],
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 10
)
```
Save: `mostBullishAnalystFirm`, `mostBearishAnalystFirm`

---

### Sectors

Use `topCompanyId` (from Batch 2 `getTopMovers` #1 by investment score) for all Batch 3 sector calls.

**`getCompanies(companySearchMode: 'byDocuments')`** — 2 calls per sector (one per event type):
```
getCompanies(
  sectors: ["<Exact Sector String>"],
  eventTypes: ["GrowthDriver"],
  companySearchMode: 'byDocuments',
  dateRange: { gte: "now-1y/d", lte: "now" }
)
getCompanies(
  sectors: ["<Exact Sector String>"],
  eventTypes: ["RiskFactor"],
  companySearchMode: 'byDocuments',
  dateRange: { gte: "now-1y/d", lte: "now" }
)
```
Save: `topGrowthCompanies[]`, `topRiskCompanies[]`

One `eventType` per call — never combine multiple event types into one call.

---

**`getSpeakers(entityType: 'speaker')`** — 1 call per sector (for top company):
```
getSpeakers(
  entityType: "speaker",
  companiesIds: ["[topCompanyId]"],
  speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc",
  limit: 10, documentTypes: ["Earnings Calls"]
)
```
Save: `sectorBullishExec`

---

## Batch 4 — Quotes

**`pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):

**Companies — 3 tasks per company:**
```
"Find bullish executive quotes for [company]. companiesIds: [companyId]. speakerTypes: Executives. DLSentiment: ['positive']. documentTypes: Earnings Calls. size: 3"
"Find bearish and risk quotes for [company]. companiesIds: [companyId]. DLSentiment: ['negative']. documentTypes: Earnings Calls. size: 3"
"Find notable analyst questions for [company]. companiesIds: [companyId]. sections: EarningsCalls_Question. documentTypes: Earnings Calls. size: 3"
```

**Sectors — 2 tasks per sector (via top company):**
```
"Find bullish executive quotes. companiesIds: [topCompanyId]. speakerTypes: Executives. DLSentiment: ['positive']. size: 3"
"Find bearish and risk quotes. companiesIds: [topCompanyId]. DLSentiment: ['negative']. size: 3"
```

Save: 1 bullish exec quote, 1 risk quote, 1 notable analyst question per company; 1 bullish + 1 risk quote per sector

---

## Scoring Matrix by Mode

### Company vs Company (9 dimensions)

| Dimension | Metric used | Winner rule |
|-----------|------------|-------------|
| Sentiment Trend | `sentimentScore_Q4` + direction | Highest; RISING breaks tie |
| Investment Score | `investmentScore_Q4` raw | Highest |
| Stock YTD | `stockChangeYTD` | Highest % |
| Earnings Reaction | `positiveCallCount` / quarters | Most positive |
| Analyst Consensus | `analystAvgSentiment` | Highest |
| Revenue (fwd) | `revenueGrowthFwd` from getCompanyConsensus | Highest |
| EPS (fwd) | `epsGaapFwd` from getCompanyConsensus | Highest |
| Exec Confidence | `execAvgSentiment` | Highest |
| Risk Profile | risk count + severity | Fewest/least severe |

### Sector vs Sector (7 dimensions)

| Dimension | Metric used | Winner rule |
|-----------|------------|-------------|
| Sentiment Score | Aggregate `sentimentScore` | Highest |
| Investment Score | Aggregate `investmentScore` raw | Highest |
| Sentiment Direction | RISING/FALLING/FLAT | RISING beats FLAT beats FALLING |
| Investment Direction | RISING/FALLING/FLAT | RISING beats FLAT beats FALLING |
| Stock Performance | Top mover `stockChangeYTD` | Highest % |
| Theme Momentum | Fastest-rising topic `change %` | Highest % |
| Risk Profile | `topNegativeEvents` hit count | Fewer hits = lower risk |

### Mixed (7 universal + 2 company-only)

Score all entities on the 7 universal dimensions. For company-only rows (Earnings Reaction, Financial Outlook), show the company values and mark sector columns as "N/A — Sector".

---

## Divergence Signal Rule

Flag when: `investmentScore` is RISING (or above sector average) **AND** stock performance is weak.

Format: "⚠️ Potential re-rating signal: [Entity] — investment score RISING despite stock [+X% / down X%]."

---

## Multi-ID Batching Rules

| Tool | Batching behavior |
|------|------------------|
| `getDocuments` | **1 call** with all company IDs |
| `getStockChange` | **1 call per period** with all company IDs |
| `getCompanyConsensus` | **1 call** with all company IDs |
| `getDocumentSummary` | **1 call** with all latest transcript IDs — **max 5 transcripts** |
| `searchSentences` | Pass all `transcriptsIds` in one call |
| `getTrends` (per company) | **Keep separate** — needs per-company topic breakdown |
| `getSpeakers` (per company) | **Keep separate** — needs per-company attribution |
| `getAnalytics` (per quarter) | **Keep separate** — needs per-quarter attribution |
| `getStockPrices` (earnings reaction) | **Keep separate** — each call needs a different date window |
| `showDocumentMindMap` | ⚠️ Takes a **single string** `transcriptId`, NOT an array |

---

## Enum Reference

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q`

**getCompanyConsensus Metrics**: `revenue` | `epsGaap` | `ebitda` | `netIncomeGaap` | `freeCashFlow` | `capitalExpenditure`

**getDocumentSummary `focus`**: free-form string describing what to summarize. Examples: `"key risks and risk factors"` · `"forward guidance and predictions"` · `"analyst questions and management responses"` · `"revenue growth commentary"`

**Analytics Types**: `scores` | `eventTypes` | `aspects` | `patternSentiment` | `importance`

**Sentiment Score Range**: −1.0 (very negative) → +1.0 (very positive). Above +0.10 = notably positive. Below −0.10 = notably negative.

**Investment Score**: Raw value from API. Higher = more attractive. Compare entities relative to each other.
