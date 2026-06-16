# Sector Intelligence — Tool & Metrics Reference

This file documents every tool used in `pronto-sector-intelligence`, the exact parameters to pass, and how the results map to the report sections.

---

## Valid Sector Names

Always use **exact strings** — tools will not match approximate names.

**Top-level sectors:**
`Financials` | `Industrials` | `Consumer Discretionary` | `Health Care` | `Information Technology` | `Materials` | `Real Estate` | `Consumer Staples` | `Communication Services` | `Energy` | `Utilities`

**Sub-sector format:** `<Sector>-<SubSector>` — e.g.:
- `Information Technology-Semiconductors and Semiconductor Equipment`
- `Health Care-Biotechnology`
- `Financials-Banks`
- `Communication Services-Interactive Media and Services`

**User input mapping:**
| User says | Use sector string |
|-----------|------------------|
| "tech", "technology" | `Information Technology` |
| "healthcare", "pharma", "biotech" | `Health Care` |
| "finance", "banking", "banks" | `Financials` |
| "energy", "oil & gas" | `Energy` |
| "real estate", "REITs" | `Real Estate` |
| "telecom", "media" | `Communication Services` |
| "consumer", "retail" | `Consumer Discretionary` |
| "semiconductors", "chips" | `Information Technology-Semiconductors and Semiconductor Equipment` |

---

## Tool Reference

### 1. `getTopMovers`

**Purpose:** Rank companies within the sector by score, sentiment, stock performance, or market cap.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "documentTypes": ["Earnings Calls"],
  "sortBy": ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  "limit": 10,
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**Response structure:**
```json
{
  "investmentScore": {
    "topMovers": [...],
    "underperforming": [...],
    "overperforming": [...]
  },
  "sentimentScore": { ... },
  "stockChange": { ... },
  ...
}
```

**Fields per company entry:**
| Field | Description |
|-------|-------------|
| `id` | Company ID |
| `name` | Company name |
| `ticker` | Ticker symbol |
| `sector` | Sector string |
| `subSector` | Sub-sector string |
| `sentimentScore` | Current sentiment score |
| `sentimentScoreChange` | Change vs prior period |
| `investmentScore` | Investment attractiveness score |
| `investmentScoreChange` | Change vs prior period |
| `stockChange` | % stock change over period |
| `marketCap` | Market cap label |

---

### 2. `getTrends`

**Purpose:** Trending topics within the sector.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "documentTypes": ["Earnings Calls"],
  "sortBy": "score",
  "sortOrder": "desc",
  "limit": 20,
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**⚠️ Critical:** `getTrends` does NOT accept a `query` parameter. Scope with `sectors` only.

---

### 3. `getAnalytics`

**Purpose:** Aggregate sentiment and investment scores, event type breakdown, and aspect analysis.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "documentTypes": ["Earnings Calls"],
  "analyticsType": ["scores", "eventTypes", "aspects", "patternSentiment", "importance"],
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**⚠️ Max date range: 1 year.**

---

### 4. `getCompanies` (replaces `searchTopCompanies`)

**Purpose:** Companies most associated with a specific topic or event type within the sector.

**Parameters — by event type:**
```json
{
  "sectors": ["<sector>"],
  "eventTypes": ["<single event type>"],
  "companySearchMode": "byDocuments",
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**Parameters — by topic:**
```json
{
  "sectors": ["<sector>"],
  "topicSearchQuery": "<topic string>",
  "companySearchMode": "byDocuments",
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**⚠️ Critical:** Pass **one event type per call** — never merge multiple event types.

---

### 5. `getSectors` (replaces `searchSectors`)

**Purpose:** Cross-sector topic distribution — which sectors are discussing a theme most.

**Parameters:**
```json
{
  "topicSearchQuery": "<topic>",
  "documentTypes": ["Earnings Calls"],
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

**⚠️ Note:** `getSectors` takes ONE `topicSearchQuery` — not an array. Run separate calls for each topic.

---

### 6. `getSpeakers`

**Purpose:** Executive or analyst sentiment scores for a specific company.

**Parameters (individuals):**
```json
{
  "entityType": "speaker",
  "companiesIds": ["<companyId>"],
  "speakerTypes": ["Executives"],
  "sortBy": "sentiment",
  "sortOrder": "desc",
  "limit": 10,
  "documentTypes": ["Earnings Calls"],
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

Use `sortOrder: "asc"` for most bearish. Use `speakerTypes: ["Analysts"]` for analyst view.

⚠️ Resolve company IDs from `getTopMovers.topMovers[*].id` before calling `getSpeakers`.

---

### 7. `getSpeakers` (entityType: 'company')

**Purpose:** Analyst firm sentiment breakdown.

**Parameters:**
```json
{
  "entityType": "company",
  "companiesIds": ["<companyId>"],
  "speakerTypes": ["Analysts"],
  "sortBy": "sentiment",
  "sortOrder": "desc",
  "limit": 20,
  "dateRange": { "gte": "now-1y/d", "lte": "now" }
}
```

---

### 8. Quote Retrieval

**Purpose:** Key quotes from earnings calls via `pronto-search-summarizer`.

Task format:
```
"Find [positive/negative/analyst] quotes about [topic] for [company].
  companiesIds: [companyId], DLSentiment: ['positive'/'negative'],
  sections: [optional], documentTypes: ['Earnings Calls'],
  size: 3, dateRange: { gte: YYYY-MM-DD, lte: YYYY-MM-DD }"
```

---

## Date Handling

All tools use `dateRange: { gte, lte }` format. Elasticsearch relative syntax accepted.

| Request | gte | lte |
|---------|-----|-----|
| Default (Full Report) | `now-1y/d` | `now` |
| "past quarter" | `now-90d/d` | `now` |
| "past 6 months" | `now-6M/d` | `now` |
| "YTD" | `<YYYY>-01-01` | `now` |
| "this week" | `now-7d/d` | `now` |

---

## Parallel Execution Batches

### Batch 1 (no dependencies — fire simultaneously):
- `getTopMovers` (all sortBy in one call)
- `getTrends`
- `getAnalytics`

→ Save: top company names/IDs, top trend names, top event type names

### Batch 2 (needs event types and trend names from Batch 1 — fire simultaneously):
- `getCompanies(companySearchMode: 'byDocuments')` per top event type (one call each)
- `getCompanies(companySearchMode: 'byDocuments')` per top trend topic
- `getSectors` per top trend (one call per topic)

### Batch 3 (needs company IDs from Batch 1 — fire simultaneously):
- `getSpeakers(entityType: 'speaker')` (Executives, desc) per top company
- `getSpeakers(entityType: 'speaker')` (Analysts, desc) per top company
- `getSpeakers(entityType: 'company')` (Analysts, desc) per top company
Run for top 2–3 companies by investment score.

### Batch 4 (needs company IDs and topics from Batches 1–2 — fire simultaneously):
- `searchSentences` via pronto-search-summarizer (positive quotes, top trend) per top company
- `searchSentences` via pronto-search-summarizer (negative quotes, top risk event) per top company
- `searchSentences` via pronto-search-summarizer (EarningsCalls_Question section) per top company

### Batch 5:
- Render HTML report

---

## Key Tool Name Changes (vs old API)

| Old | New |
|-----|-----|
| `searchTopCompanies` | `getCompanies(companySearchMode: 'byDocuments')` |
| `searchSectors` | `getSectors` (one query per call) |
| `search` | `searchSentences` |
| `companyName` param in getSpeakers | `companiesIds: [id]` |
