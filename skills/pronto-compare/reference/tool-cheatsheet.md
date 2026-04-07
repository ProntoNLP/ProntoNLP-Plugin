# pronto-compare — Tool & Metrics Reference

This file documents the exact MCP tools, parameters, and metrics for each entity type (company or sector) across all 4 batches. All calls are made directly — no external skills are invoked.

---

## Entity Types

| Type | Identified by | Batch 1 | Color |
|------|--------------|---------|-------|
| **Company** | Name or ticker | `getCompanyDescription` (API call) | A=`#3B82F6`, B=`#8B5CF6`, C=`#F59E0B`, D=`#14B8A6`, E=`#EC4899` |
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

## Batch Execution Plan

| Batch | When | Company actions | Sector actions |
|-------|------|----------------|----------------|
| 1 | First | `getCompanyDescription` ×N companies | Normalize sector string — no API call |
| 2 | After Batch 1 | `getCompanyDocuments` + `getStockChange` ×3 + `getPredictions` ×4 + `getTrends` | `getAnalytics` + `getTrends` + `getTopMovers` |
| 3 | After Batch 2 | `getAnalytics` ×4 + `getStockPrices` ×4 + `getSpeakers` ×4 + `getSpeakerCompanies` | `searchTopCompanies` ×2 + `getSpeakers` (top co.) + `getSpeakerCompanies` (top co.) |
| 4 | After Batch 3 | `search` ×3 | `search` ×2 (via top company in sector) |

**Fire all calls within a batch simultaneously — never sequence within a batch.**

---

## Batch 1 — Foundation

### Companies: `getCompanyDescription`
```
getCompanyDescription(companyNameOrTicker: "[name or ticker]")
```
**Save:** `companyId` (required for all stock calls), `sector`, `subSector`, `risks[]`

### Sectors: No API call
Save the normalized exact API string. Mark entity type as `sector`.

---

## Batch 2 — Core Data

All Batch 2 calls fire simultaneously across all entities.

### Companies

**`getCompanyDocuments`**
```
getCompanyDocuments(
  companyName: "[Full name]",
  documentTypes: ["Earnings Calls"],
  limit: 4
)
```
Save: `transcriptId[]`, call dates — used as `documentIDs` in Batch 3 `getAnalytics`

---

**`getStockChange`** — 3 calls per company:
```
getStockChange(companyId: [id], sinceDay: "[YYYY-01-01]", untilDay: "[today]")    → YTD
getStockChange(companyId: [id], sinceDay: "[today minus 6M]", untilDay: "[today]") → 6M
getStockChange(companyId: [id], sinceDay: "[today minus 1Y]", untilDay: "[today]") → 1Y
```
Save: `stockChangeYTD`, `stockChange6M`, `stockChange1Y`

---

**`getPredictions`** — 4 calls per company:
```
getPredictions(companyId: [id], metric: "revenue")
getPredictions(companyId: [id], metric: "epsGaap")
getPredictions(companyId: [id], metric: "ebitda")
getPredictions(companyId: [id], metric: "freeCashFlow")
```
Save: `revenueGrowthFwd`, `epsGaapFwd`, `ebitdaFwd`, `fcfFwd`

---

**`getTrends`** — 1 call per company:
```
getTrends(
  companyName: "[Full name]",
  documentTypes: ["Earnings Calls"],
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]",
  limit: 10
)
```
Save: Top 3 topics by score, fastest-rising topic (highest `change %`), fastest-declining

⚠️ Do NOT pass `query` or `topicSearchQuery` to `getTrends`.

---

### Sectors

**`getAnalytics`** — 1 call per sector:
```
getAnalytics(
  sectors: ["<Exact Sector String>"],
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]"
)
```
Save:
- `sentimentScore` (aggregate)
- `investmentScore` (aggregate raw value)
- `sentimentDirection`: RISING/FALLING/FLAT (compare to prior year if available)
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
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]",
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
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]"
)
```
Save:
- `topByInvestment[]` — company name + raw score
- `topBySentiment[]` — company name + score
- `topByStockChange[]` — company name + % change
- `underperformers[]` — companies with high investment score + weak stock (divergence signal)
- `topCompanyName` — #1 by investment score (used as representative in Batch 3 and 4)

---

## Batch 3 — Deep Analysis

All Batch 3 calls fire simultaneously across all entities.

### Companies

**`getAnalytics`** — 1 call **per quarter** (do NOT combine quarters into one call):
```
getAnalytics(
  companyName: "[name]",
  documentIDs: ["[transcriptId_Q1]"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"]
)
```
Repeat for Q2, Q3, Q4 using transcript IDs from Batch 2.

Save per quarter: `sentimentScore_Qn`, `investmentScore_Qn`

Compute:
- `sentimentDirection`: RISING if Q4 > Q1, FALLING if Q4 < Q1
- `investmentDirection`: same

---

**`getStockPrices`** — 1 call per quarter per company (7-day window around call date):
```
getStockPrices(
  companyId: [id],
  fromDate: "[call date minus 2 days]",
  toDate:   "[call date plus 5 days]",
  interval: "day"
)
```
Compute: `stockReaction_Qn` = last price ÷ first price − 1 (as %)

Compute: `positiveCallCount` = count of quarters where `stockReaction > 0`

---

**`getSpeakers`** — 4 calls per company:
```
getSpeakers(companyName, speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(companyName, speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(companyName, speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(companyName, speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
```
Save: `execAvgSentiment`, `ceoSentiment`, `cfoSentiment`, `analystAvgSentiment`

Compute: `execAnalystGap` = execAvg − analystAvg

---

**`getSpeakerCompanies`** — 1 call per company:
```
getSpeakerCompanies(companyName, speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
```
Save: `mostBullishAnalystFirm`, `mostBearishAnalystFirm` (name + avg score)

---

### Sectors

Use `topCompanyName` (from Batch 2 `getTopMovers` #1 by investment score) for all Batch 3 sector calls.

**`searchTopCompanies`** — 2 calls per sector (one per event type):
```
searchTopCompanies(
  sectors: ["<Exact Sector String>"],
  eventTypes: ["GrowthDriver"],
  limit: 5,
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]"
)
```
```
searchTopCompanies(
  sectors: ["<Exact Sector String>"],
  eventTypes: ["RiskFactor"],
  limit: 5,
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]"
)
```
Save: `topGrowthCompanies[]`, `topRiskCompanies[]`

One `eventType` per `searchTopCompanies` call — never combine multiple event types into one call.

---

**`getSpeakers`** — 1 call per sector (for top company):
```
getSpeakers(
  companyName: "[topCompanyName]",
  speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc",
  limit: 10, documentTypes: ["Earnings Calls"]
)
```
Save: `sectorBullishExec` = most bullish exec in the sector's top company

---

**`getSpeakerCompanies`** — 1 call per sector (for top company):
```
getSpeakerCompanies(
  companyName: "[topCompanyName]",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc",
  limit: 10
)
```
Save: `sectorBullishAnalystFirm`

---

## Batch 4 — Quotes

**`pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):

**Companies — 3 agents per company:**
```
pronto-search-summarizer: "Find bullish executive quotes for [company] about growth outlook and guidance. SpeakerTypes: Executives. Sentiment: positive. DocumentTypes: Earnings Calls. Size: 3"
pronto-search-summarizer: "Find bearish and risk quotes for [company] about risks, challenges, and headwinds. Sentiment: negative. DocumentTypes: Earnings Calls. Size: 3"
pronto-search-summarizer: "Find notable analyst questions for [company]. Sections: EarningsCalls_Question. DocumentTypes: Earnings Calls. Size: 3"
```

**Sectors — 2 agents per sector (via top company):**
```
pronto-search-summarizer: "Find bullish executive quotes from [topCompanyName] about sector growth and momentum. SpeakerTypes: Executives. Sentiment: positive. Size: 3"
pronto-search-summarizer: "Find bearish and risk quotes from [topCompanyName] about sector risks and headwinds. Sentiment: negative. Size: 3"
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
| Revenue (fwd) | `revenueGrowthFwd` | Highest |
| EPS (fwd) | `epsGaapFwd` | Highest |
| Exec Confidence | `execAvgSentiment` | Highest |
| Risk Profile | risk count + severity | Fewest/least severe |

### Sector vs Sector (7 dimensions)

| Dimension | Metric used | Winner rule |
|-----------|------------|-------------|
| Sentiment Score | Aggregate `sentimentScore` | Highest |
| Investment Score | Aggregate `investmentScore` raw | Highest |
| Sentiment Direction | RISING/FALLING/FLAT | RISING beats FLAT beats FALLING |
| Investment Direction | RISING/FALLING/FLAT | RISING beats FLAT beats FALLING |
| Stock Performance | Top mover `stockChangeYTD` | Highest % (note: proxy for sector) |
| Theme Momentum | Fastest-rising topic `change %` | Highest % |
| Risk Profile | `topNegativeEvents` hit count | Fewer hits = lower risk |

### Mixed (7 universal + 2 company-only)

Score all entities on the 7 universal dimensions. For company-only rows (Earnings Reaction, Financial Outlook), show the company values and mark sector columns as "N/A — Sector".

---

## Divergence Signal Rule

Flag when: `investmentScore` is RISING (or above sector average) **AND** stock performance is weak (negative or significantly below peers).

Format: "⚠️ Potential re-rating signal: [Entity] — investment score RISING despite stock [+X% / down X%]."

---

## Enum Reference

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q`

**Prediction Metrics**: `revenue` | `epsGaap` | `ebitda` | `netIncomeGaap` | `freeCashFlow` | `capitalExpenditure`

**Analytics Types**: `scores` | `eventTypes` | `aspects` | `patternSentiment` | `importance`

**Sentiment Score Range**: −1.0 (very negative) → +1.0 (very positive). Above +0.10 = notably positive. Below −0.10 = notably negative.

**Investment Score**: Raw value from API. Higher = more attractive. Compare entities relative to each other — do not apply fixed thresholds. `investmentScore` and `investmentScoreChange` are two distinct fields — never conflate.
