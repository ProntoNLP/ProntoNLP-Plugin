# Compare Companies — Tool & Metrics Reference

This file documents the exact MCP tools, parameters, and metrics used in each batch of the compare-companies skill. All tool calls are made directly — no external skills are invoked.

---

## Batch Execution Plan

| Batch | When | Tools | Purpose |
|-------|------|-------|---------|
| Batch 1 | First | `getCompanyDescription` ×N | Resolve companyId, sector, subSector for all companies |
| Batch 2 | After Batch 1 | `getCompanyDocuments`, `getStockChange` ×3, `getPredictions` ×4, `getTrends` — for all N companies simultaneously | Core data |
| Batch 3 | After Batch 2 | `getAnalytics` ×4, `getStockPrices` ×4, `getSpeakers` ×4, `getSpeakerCompanies` — for all N companies simultaneously | Deep analysis |
| Batch 4 | After Batch 3 | `search` ×3 — for all N companies simultaneously | Supporting quotes |

Fire **all calls within a batch simultaneously**. Never sequence calls within the same batch.

---

## Batch 1 — Foundation

### `getCompanyDescription`
```
getCompanyDescription(companyNameOrTicker: "[name or ticker]")
```
**Save immediately:**
- `companyId` — required for all stock calls in Batches 2–3
- `sector`, `subSector` — used for cross-sector flagging
- `ticker` — used in report column headers

Call once per company. Fire all N calls in parallel.

---

## Batch 2 — Core Data

All Batch 2 calls fire simultaneously for all companies.

### `getCompanyDocuments`
```
getCompanyDocuments(
  companyName: "[Full company name]",
  documentTypes: ["Earnings Calls"],
  limit: 4
)
```
**Save:** `transcriptId` list (up to 4), call dates — used as `documentIDs` in Batch 3 `getAnalytics`

---

### `getStockChange`
Call three times per company (YTD, 6M, 1Y):
```
getStockChange(companyId: [id], sinceDay: "[YYYY-01-01]",       untilDay: "[today]")  → YTD
getStockChange(companyId: [id], sinceDay: "[today minus 6M]",   untilDay: "[today]")  → 6M
getStockChange(companyId: [id], sinceDay: "[today minus 1Y]",   untilDay: "[today]")  → 1Y
```
**Save:** `stockChangeYTD`, `stockChange6M`, `stockChange1Y` as signed percentages

---

### `getPredictions`
Call four times per company:
```
getPredictions(companyId: [id], metric: "revenue")
getPredictions(companyId: [id], metric: "epsGaap")
getPredictions(companyId: [id], metric: "ebitda")
getPredictions(companyId: [id], metric: "freeCashFlow")
```
**Save:** Forward consensus estimates for `revenueGrowthFwd`, `epsGaapFwd`, `ebitdaFwd`, `fcfFwd`

---

### `getTrends`
```
getTrends(
  companyName: "[Full company name]",
  documentTypes: ["Earnings Calls"],
  sinceDay: "[today minus 1Y]",
  untilDay: "[today]",
  limit: 10
)
```
**Save:** Top 3 topics by score → `topTopics[]`

Do NOT pass a `query` or `topicSearchQuery` to `getTrends`.

---

## Batch 3 — Deep Analysis

All Batch 3 calls fire simultaneously for all companies.

### `getAnalytics`
Call **once per quarter** using individual `documentIDs` — never one aggregate call:
```
getAnalytics(
  companyName: "[Full company name]",
  documentIDs: ["[transcriptId_Q1]"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"]
)
```
Repeat for Q2, Q3, Q4 using the transcript IDs saved from Batch 2.

**Save per quarter:** `sentimentScore`, `investmentScore`, top event types, top aspects

From these 4 calls, compute:
- `sentimentDirection`: RISING if Q4 > Q1, FALLING if Q4 < Q1
- `investmentDirection`: same logic

---

### `getStockPrices`
Call once per quarter per company — centered on the earnings call date (7-day window: call date −2 days to +5 days):
```
getStockPrices(
  companyId: [id],
  fromDate: "[call date minus 2 days]",
  toDate:   "[call date plus 5 days]",
  interval: "day"
)
```
**Compute:** `stockReaction_Q[n]` = price on last day ÷ price on first day − 1, expressed as %

**Compute:** `positiveCallCount` = count of quarters where `stockReaction > 0`

---

### `getSpeakers`
Four calls per company:
```
getSpeakers(companyName: "[name]", speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(companyName: "[name]", speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(companyName: "[name]", speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(companyName: "[name]", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
```
**Save:** `execAvgSentiment`, `analystAvgSentiment`, `ceoSentiment`, `cfoSentiment`

**Compute:** `execAnalystGap` = execAvg − analystAvg

**Save:** `mostBullishAnalyst` (highest score), `mostBearishAnalyst` (lowest score) — name + firm + score

---

### `getSpeakerCompanies`
```
getSpeakerCompanies(
  companyName: "[name]",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 10
)
```
**Save:** Most bullish analyst firm and most bearish analyst firm (name + avg score)

---

## Batch 4 — Supporting Quotes

All Batch 4 calls fire simultaneously for all companies.

### `search`
Three calls per company:
```
search(companyName: "[name]", sentiment: "positive", speakerTypes: ["Executives"], topicSearchQuery: "growth outlook guidance", size: 3)
search(companyName: "[name]", sentiment: "negative", topicSearchQuery: "risk challenge headwind", size: 3)
search(companyName: "[name]", sections: ["EarningsCalls_Question"], size: 3)
```
**Save:** 1–2 quotes per company (bullish exec quote + bearish risk quote) with speaker name, role, and date

---

## Scoring Matrix

Score each company per dimension. Winner = highest value unless noted.

| Dimension | Metric used | Winner rule |
|-----------|------------|-------------|
| Sentiment Trend | `sentimentScore_Q4` + direction | Highest score; RISING breaks tie |
| Investment Score | `investmentScore_Q4` | Highest raw value |
| Stock Performance | `stockChangeYTD` | Highest % |
| Earnings Call Reaction | `positiveCallCount` / total quarters | Most positive reactions |
| Analyst Consensus | `analystAvgSentiment` | Highest |
| Revenue (fwd) | `revenueGrowthFwd` | Highest |
| EPS Outlook | `epsGaapFwd` | Highest |
| Exec Confidence | `execAvgSentiment` | Highest |
| Risk Profile | risk count / severity | Fewest or least severe |

Tally wins per company. Most wins = overall leader.

**Tie-breaker**: If two companies tie on win count, the one with the higher investment score is the leader.

---

## Cross-Company Topic Comparison

After all batches complete, compare `topTopics` arrays across all companies:

```
Shared topics  = topics in 2+ companies' top lists → macro theme
Unique topics  = topics in only one company's list  → company-specific narrative
Risk overlap   = risk events in 2+ companies        → systemic sector risk
```

Always flag:
- If 2+ companies share a risk → "Systemic risk: [topic] affects all compared companies"
- If one company has a unique risk → "Idiosyncratic risk for [Company]: [topic]"

---

## Divergence Signal

Flag if a company has a **high or rising investment score** but **weak or negative stock performance**:
> "Potential undervalued signal: [Company] investment score is RISING despite stock down X% — monitor for re-rating if [catalyst] materializes."

---

## Enum Reference

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q`

**Prediction Metrics**: `revenue` | `epsGaap` | `ebitda` | `netIncomeGaap` | `freeCashFlow` | `capitalExpenditure`

**Sentiment Score Range**: −1.0 (very negative) → +1.0 (very positive). Above +0.10 = notably positive. Below −0.10 = notably negative.

**Investment Score**: Raw value from the API. Higher = more attractive. Compare companies relative to each other — do not apply fixed thresholds. `investmentScore` (current score) and `investmentScoreChange` (change vs prior period) are two separate fields — never conflate them.

**Company Colors**: A=`#3B82F6` (blue) | B=`#8B5CF6` (purple) | C=`#F59E0B` (amber) | D=`#14B8A6` (teal) | E=`#EC4899` (pink)
