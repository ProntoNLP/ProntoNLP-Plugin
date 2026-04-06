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
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
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
| `id` | Numeric company ID |
| `name` | Company name |
| `ticker` | Ticker symbol |
| `sector` | Sector string |
| `subSector` | Sub-sector string |
| `sentimentScore` | Current sentiment score (−1.0 to +1.0) |
| `sentimentScoreChange` | Change vs prior period |
| `investmentScore` | Investment attractiveness score (raw value from API) |
| `investmentScoreChange` | Change vs prior period |
| `stockChange` | % stock change over period |
| `marketCap` | Market cap label |

**Report usage:**
- `topMovers[investmentScore]` → Section 2: Top by Investment Score leaderboard
- `topMovers[sentimentScoreChange]` → Section 2: Biggest Sentiment Shift — Most Bullish
- `underperforming[sentimentScoreChange]` → Section 2: Biggest Sentiment Shift — Most Bearish
- `underperforming[investmentScore]` → Section 2: Potential Buy Signals (high score + falling stock)
- `topMovers[stockChange]` → Section 2: Top Stock Performers

---

### 2. `getTrends`

**Purpose:** Trending topics within the sector — which themes are rising or falling in earnings calls.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "documentTypes": ["Earnings Calls"],
  "sortBy": "score",
  "sortOrder": "desc",
  "limit": 20,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**⚠️ Critical:** `getTrends` does NOT accept a `query` or `topicSearchQuery` parameter. Scope with `sectors` only.

**Fields per trend entry:**
| Field | Description |
|-------|-------------|
| `topic` | Topic name string |
| `score` | Relevance score |
| `hits` | Number of mentions |
| `change` | % change vs prior period (positive = RISING, negative = FALLING) |

**Report usage:**
- All entries → Section 4: Trending Topics table
- Top 3 by `change` (positive) → "Fastest-rising themes"
- Bottom 2 by `change` (most negative) → "Fastest-declining themes"
- Top topic names → input for Batch 2 `searchTopCompanies`

---

### 3. `getAnalytics`

**Purpose:** Aggregate sentiment and investment scores, event type breakdown, and aspect analysis for the sector.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "documentTypes": ["Earnings Calls"],
  "analyticsType": ["scores", "eventTypes", "aspects", "patternSentiment", "importance"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**⚠️ Max date range: 1 year.** Split requests longer than 1 year into multiple yearly calls.

**Key response fields:**
| Field | Description |
|-------|-------------|
| `scores.sentimentScore` | Aggregate sector sentiment (−1.0 to +1.0) |
| `scores.investmentScore` | Aggregate sector investment score (raw value from API) |
| `scores.sentimentScoreChange` | Direction indicator vs prior period |
| `eventTypes[]` | Array of event types with name, count, sentiment |
| `aspects[]` | Named aspects (products, strategy, guidance) with sentiment |
| `patternSentiment.positive` | Avg positive pattern score |
| `patternSentiment.negative` | Avg negative pattern score |

**Report usage:**
- `scores` → Section 3: Sentiment & Investment scores table
- `eventTypes` (positive) → Section 5: Top positive events
- `eventTypes` (negative) → Section 5: Top negative events
- Top event type names → input for Batch 2 `searchTopCompanies`
- `aspects` → Section 3: Top aspects and their polarity

---

### 4. `searchTopCompanies`

**Purpose:** Companies most associated with a specific topic or event type within the sector.

**Parameters:**
```json
{
  "sectors": ["<sector>"],
  "eventTypes": ["<single event type>"],
  "limit": 10,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

OR with topic:
```json
{
  "sectors": ["<sector>"],
  "topicSearchQuery": "<topic string>",
  "limit": 10,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**⚠️ Critical:** Pass **one event type per call** — never merge multiple event types into a single call.

**Report usage:**
- Per top positive event → Section 5: which companies are most exposed
- Per top negative event → Section 5 / Section 8: risk exposure leaders
- Per top trend topic → Section 6: company rankings by theme

---

### 5. `searchSectors`

**Purpose:** Cross-sector topic distribution — which sectors are discussing a theme most.

**Parameters:**
```json
{
  "searchQueries": ["<topic 1>", "<topic 2>"],
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Report usage:**
- Section 4 or Section 6: how the target sector compares to others on the same theme

---

### 6. `getSpeakers`

**Purpose:** Executive or analyst sentiment scores for a specific company.

**Parameters:**
```json
{
  "companyName": "<company name>",
  "speakerTypes": ["Executives"],
  "sortBy": "sentiment",
  "sortOrder": "desc",
  "limit": 10,
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

Use `sortOrder: "asc"` for most bearish. Use `speakerTypes: ["Analysts"]` for analyst view.

**Fields per speaker:**
| Field | Description |
|-------|-------------|
| `name` | Speaker name |
| `role` | Title / role |
| `company` | Company name |
| `sentiment` | Sentiment score |
| `mentions` | Number of mentions |

**Report usage:** Called per top 2–3 companies from Batch 1. Section 7: most bullish exec, most bearish analyst across sector.

---

### 7. `getSpeakerCompanies`

**Purpose:** Analyst firm sentiment breakdown — which firms are most bullish/bearish on a company.

**Parameters:**
```json
{
  "companyName": "<company name>",
  "speakerTypes": ["Analysts"],
  "sortBy": "sentiment",
  "sortOrder": "desc",
  "limit": 20,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Report usage:** Section 7: analyst firm sentiment ranking.

---

### 8. Quote Retrieval (environment-aware)

**Purpose:** Key quotes from earnings calls — supporting evidence for themes and risks.

**Environment detection:**
- **Claude Cowork** (`Bash` IS available) → use `pronto-search-agent` via Agent tool
- **claude.ai** (`Bash` NOT available) → call `search` MCP tool directly

---

**Claude Cowork — `pronto-search-agent`** (subagent_type: `prontonlp-plugin:pronto-search-agent`):

Task format:
```
pronto-search-agent: "Find [positive/negative/analyst] quotes for [company] about [topic].
  Sentiment: [positive/negative], SpeakerTypes: [optional], Sections: [optional],
  Size: 3, SinceDay: [YYYY-MM-DD], UntilDay: [YYYY-MM-DD]"
```

Examples:
```
pronto-search-agent: "Find bullish quotes about AI Agents for NVIDIA. Sentiment: positive. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
pronto-search-agent: "Find risk quotes about Export Controls for NVIDIA. Sentiment: negative. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
pronto-search-agent: "Find notable analyst questions for Microsoft. Sections: EarningsCalls_Question. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
```

→ Agent returns a clean summary with top quotes, speaker names, roles, and dates.

---

**claude.ai — `search` MCP tool directly:**
```json
{
  "companyName": "<company name>",
  "topicSearchQuery": "<topic>",
  "sentiment": "positive",
  "size": 3,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```
For analyst questions: use `"sections": ["EarningsCalls_Question"]`
For risk quotes: use `"sentiment": "negative"`

---

**Report usage:** Section 5 / Section 8: supporting quotes per event or risk topic.

---

## Date Handling

| Request | sinceDay | untilDay |
|---------|----------|----------|
| Default (Full Report) | 1 year ago | today |
| "past quarter" | 90 days ago | today |
| "past 6 months" | 6 months ago | today |
| "YTD" | Jan 1 current year | today |
| "this week" | 7 days ago | today |

---

## Parallel Execution Batches

### Batch 1 (no dependencies — fire simultaneously):
- `getTopMovers` (all sortBy in one call)
- `getTrends`
- `getAnalytics`

→ Save: top company names/IDs, top trend names, top event type names

### Batch 2 (needs event types and trend names from Batch 1 — fire simultaneously):
- `searchTopCompanies` per top event type (one call each)
- `searchTopCompanies` per top trend topic
- `searchSectors` for top trends

### Batch 3 (needs company names from Batch 1 — fire simultaneously):
- `getSpeakers` (Executives, desc) per top company
- `getSpeakers` (Analysts, desc) per top company
- `getSpeakerCompanies` per top company
Run for top 2–3 companies by investment score.

### Batch 4 (needs company names and topics from Batches 1–2 — fire simultaneously):
- `search` (positive quotes, top trend) per top company
- `search` (negative quotes, top risk event) per top company
- `search` (EarningsCalls_Question section) per top company

### Batch 5:
- Render full inline HTML report with all charts

---

## Key Computed Signals

| Signal | How to compute |
|--------|---------------|
| Sector direction | `sentimentScoreChange` from getAnalytics: positive = RISING, negative = FALLING |
| Investment leaders | Top 3 from `topMovers[investmentScore]` |
| Undervalued signal | Companies in `underperforming[investmentScore]` — high investment score, negative stockChange |
| Overvalued signal | Companies in `overperforming[investmentScore]` — low investment score, strong positive stockChange |
| Fastest rising theme | Top 3 `getTrends` entries by `change` (most positive) |
| Fastest declining theme | Bottom 2 `getTrends` entries by `change` (most negative) |
| Dominant positive event | Top `getAnalytics.eventTypes` entry with positive sentiment |
| Dominant negative event | Top `getAnalytics.eventTypes` entry with negative sentiment |
