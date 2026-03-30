# Sectors Analysis — Template Selection Guide

## Overview

| Mode | Use Case | Batches | Tool Calls | Output |
|------|----------|---------|-----------|--------|
| **A — Topic Scan** | Which companies or sectors discuss a topic most? | 3 | ~6–12 | Sector ranking + company ranking + quotes |
| **B — Sector Distribution** | How is sentiment/volume distributed across industries? | 2 | ~4–8 | Sector sentiment table + top companies per sector |
| **C — Event Drill-down** | What event types dominate a sector, and who leads them? | 3 | ~5–15 | Event type breakdown + per-event company ranking + quotes |

## Decision Tree

```
Is the user asking about a topic or theme across the market?
├── Yes — does the user want sector-level distribution?
│   ├── Yes — Mode B (Sector Distribution)
│   └── No — Mode A (Topic Scan)
└── No — is the user asking about event types or risk events?
    └── Yes — Mode C (Event Drill-down)
```

Default to **Mode A** when the request is ambiguous.

---

## ID Flow (applies to ALL modes)

The key dependency chain for sector analysis:

```
getAnalytics (sectors filter)
  → extract eventTypes[]
      → searchTopCompanies (one call per event type)
          → extract company names / IDs
              → search (one call per top company)
```

For Mode A and B, `getAnalytics` is optional — use `searchSectors` first to identify which sectors have signal, then `searchTopCompanies` to rank companies within those sectors.

---

## Mode A — Topic Scan (default)

**Use when:** "Which companies talked about tariffs most?", "Top companies on supply chain issues", "Who's discussing rate hikes?"

**Batches:** 3
**Approximate tool calls:** 6–12 depending on number of top sectors

### Batch Plan

**Batch 1** — sector-level view (parallel):
- `searchSectors` — topic + date range + document types
  - Returns: sector ranking by mention count and sentiment

**Batch 2** — company ranking per sector (parallel, one call per top-3 sector from Batch 1):
- `searchTopCompanies` — same topic, sector filter, date range, limit: 10
  - Returns: ranked company list with sentiment scores

**Batch 3** — supporting quotes per top company (parallel, one `search` per top-3 company):
- `search` — company name, topicSearchQuery, sentiment filter if applicable, size: 3
  - Returns: quote text, speaker, date

### Key Parameters

```
searchSectors:
  searchQueries: ["tariff", "tariffs", "trade war"]
  sinceDay: "<date>"
  untilDay: "<today>"
  documentTypes: ["Earnings Calls"]

searchTopCompanies:
  searchQueries: ["tariff", "tariffs"]
  sectors: ["<sector from Batch 1>"]
  documentTypes: ["Earnings Calls"]
  sinceDay: "<date>"
  untilDay: "<today>"
  limit: 10

search:
  companyName: "<company>"
  topicSearchQuery: "tariff trade war"
  sentiment: "negative"
  size: 3
  sortBy: "sentiment"
  sortOrder: "asc"
```

### Output

- Sector ranking table (Sector | Sentiment Score | Mention Count | Direction)
- Company ranking table per leading sector (Rank | Company | Sentiment | Mentions | Top Event)
- 1–2 quotes per top company with attribution
- Divergence callouts (high volume + negative sentiment = most interesting signal)

---

## Mode B — Sector Distribution

**Use when:** "Show AI sentiment across sectors", "Which industries are most bullish on rate cuts?", "How exposed is each sector to supply chain risk?"

**Batches:** 2
**Approximate tool calls:** 4–8

### Batch Plan

**Batch 1** — sector distribution (parallel, run positive and negative variants together if user wants both):
- `searchSectors` with `sentiment: "positive"` — topic + date range
- `searchSectors` with `sentiment: "negative"` — same topic + date range
  - Returns: sector sentiment split by direction

**Batch 2** — top companies per leading sector (parallel, one `searchTopCompanies` per top-3 sector):
- `searchTopCompanies` — topic, sector filter, date range, limit: 10
  - Returns: company ranking within each sector

### Key Parameters

```
searchSectors (positive):
  searchQueries: ["artificial intelligence", "AI", "machine learning"]
  sinceDay: "<date>"
  untilDay: "<today>"
  documentTypes: ["Earnings Calls"]
  sentiment: "positive"

searchSectors (negative):
  searchQueries: ["artificial intelligence", "AI", "machine learning"]
  sinceDay: "<date>"
  untilDay: "<today>"
  documentTypes: ["Earnings Calls"]
  sentiment: "negative"

searchTopCompanies:
  searchQueries: ["artificial intelligence", "AI"]
  sectors: ["<sector>"]
  documentTypes: ["Earnings Calls"]
  sinceDay: "<date>"
  untilDay: "<today>"
  limit: 10
```

### Output

- Sector sentiment distribution table (Sector | Positive Score | Negative Score | Net | Ranking)
- Company ranking within top-3 sectors
- Interpretation of which sectors are most/least aligned with the topic
- HTML charts — open `/tmp/sectors-charts.html`

---

## Mode C — Event Drill-down

**Use when:** "Top negative events in tech this week", "What risk events dominated healthcare earnings?", "Which companies had the most RiskFactor events?"

**Batches:** 3
**Approximate tool calls:** 5–15 depending on number of event types returned

### Batch Plan

**Batch 1** — discover event types (no dependencies):
- `getAnalytics` with `sectors` filter + full `analyticsType`
  - Returns: event type IDs and frequencies for the sector

**Batch 2** — rank companies per event type (parallel, one `searchTopCompanies` per event type from Batch 1):
- `searchTopCompanies` — `eventTypes: ["<one event type>"]`, sector filter, sentiment filter if applicable, limit: 10
  - Returns: top companies for each event type

**Batch 3** — supporting quotes per top company (parallel, one `search` per top-3 company):
- `search` — company name, event type filter, topic query, sentiment, size: 3
  - Returns: quote text, speaker, date

### Key Parameters

```
getAnalytics:
  sectors: ["Technology"]
  documentTypes: ["Earnings Calls"]
  sinceDay: "<7 days ago>"
  untilDay: "<today>"
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]

searchTopCompanies (one call per event type):
  eventTypes: ["<one event type from getAnalytics>"]
  sectors: ["Technology"]
  documentTypes: ["Earnings Calls"]
  sinceDay: "<date>"
  untilDay: "<today>"
  sentiment: "negative"
  limit: 10

search:
  companyName: "<company>"
  topicSearchQuery: "<event type topic>"
  eventTypes: ["<event type>"]
  sentiment: "negative"
  size: 3
  sortBy: "sentiment"
  sortOrder: "asc"
```

### Output

- Event type frequency table (Event Type | Count | Top Company | Sentiment Score)
- Per-event company ranking (one table per top event type)
- 1–2 supporting quotes per top company per event type
- Summary verdict: "RiskFactor and SupplyChain events dominated Technology sector this week, led by [Company]"

---

## Formatting Guidelines

### Sector Ranking Table

```markdown
| Rank | Sector | Sentiment Score | Mention Count | Direction |
|------|--------|----------------|--------------|-----------|
| 1 | Technology | +0.42 | 1,840 | LEADING |
| 2 | Consumer Discretionary | +0.31 | 1,205 | HIGH |
```

Always include at least 5 sectors. Show both positive and negative sentiment scores — do not filter to one side.

### Company Ranking Table

```markdown
| Rank | Company | Sector | Sentiment Score | Mentions | Top Event |
|------|---------|--------|----------------|---------|-----------|
| 1 | NVIDIA | Technology | +0.71 | 312 | GrowthDriver |
```

Always include at least 5 companies. Sentiment scores are between −1 and 1.

### Quote Attribution

```
"Quote text here"
— [Speaker Name], [Role], [Company] ([Date])
```

### Sentiment Labels (no emojis)

- Strong Positive: "BULLISH" or "STRONGLY POSITIVE"
- Positive: "Positive"
- Neutral: "Neutral"
- Negative: "Negative"
- Strong Negative: "BEARISH" or "STRONGLY NEGATIVE"

### Direction Labels

- Use "LEADING" / "LAGGING" for sector ranking position
- Use "RISING" / "FALLING" for trend comparisons across time periods
- Use "DOMINATED BY" / "ABSENT FROM" for event type presence in a sector

### Divergence Callouts

Always highlight when mention volume and sentiment move in opposite directions:

- High volume + negative sentiment → "Most exposed, but bearishly so"
- Low volume + strong positive sentiment → "Emerging bullish signal — early mover"
- Event type present + company sentiment rising → "Headwind absorbed — resilient signal"
