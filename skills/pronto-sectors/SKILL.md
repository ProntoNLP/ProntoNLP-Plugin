---
name: pronto-sectors
description: "Use this skill when the user asks about a sector, industry, or topic across multiple companies — e.g. 'which companies talked about tariffs most?', 'show AI sentiment across the tech sector', 'what industries are most exposed to rate hikes?', 'which sectors are bullish on EV adoption?', 'top companies discussing supply chain issues', or any question involving topic/sentiment distribution across markets. Also trigger when the user wants to see which companies are leading or lagging on a specific theme, event, or keyword. Always load pronto-persona first."
---

# ProntoNLP — Sectors & Topic Analysis

Produces cross-company and cross-sector intelligence using ProntoNLP tools. The centerpiece is a **ranked distribution of companies or sectors by topic exposure, sentiment, or event frequency** — explicitly showing which players dominate a theme, which are lagging, and where the signal is strongest. Layered on top: event type breakdowns, supporting quotes, and HTML visualizations.

---

## Step 0: Choose Your Analysis Mode

Before making any tool calls, decide which mode fits the user's request:

| Mode | Use when | Batches | Key tools |
|------|----------|---------|-----------|
| **A — Topic Scan** (default) | "Which companies talked about tariffs most?" | 3 | `searchSectors` → `searchTopCompanies` → `search` |
| **B — Sector Distribution** | "Show AI sentiment across sectors" | 2 | `searchSectors` → `searchTopCompanies` |
| **C — Event Drill-down** | "Top negative events in tech this week" | 3 | `getAnalytics` → `searchTopCompanies` → `search` |

See `reference/report-template-guide.md` for the exact batch plan of each mode. Default to **Mode A** unless the user explicitly signals a narrower scope.

---

## Prerequisite

`pronto-persona` must already be loaded. It governs identity rules and citation format only — all tool parameters, ID flow, and error handling are defined in this skill.

---

## When to Use Which Tool

| Question type | Primary tool |
|---------------|-------------|
| "Which sectors mention X most?" | `searchSectors` |
| "Sentiment distribution of X across sectors" | `searchSectors` → `searchTopCompanies` |
| "Which companies discuss X most positively?" | `searchTopCompanies` |
| "Top companies by topic, filtered to one sector" | `searchTopCompanies` (sectors filter) |
| "What event types dominate [sector]?" | `getAnalytics` (sectors filter) |
| "Top negative events in tech this week" | `getAnalytics` → `searchTopCompanies` per event type |
| "Quotes from companies on a specific topic" | `search` (after ranking is done) |

---

## Tools Reference

### `searchSectors`

Ranks sectors by topic mention volume or sentiment distribution.

| Parameter | Type | Notes |
|-----------|------|-------|
| `searchQueries` | `string[]` | Topic terms — use synonyms (e.g. `["tariff", "tariffs", "trade war"]`) |
| `sinceDay` | `"YYYY-MM-DD"` | Start of date range |
| `untilDay` | `"YYYY-MM-DD"` | End of date range |
| `documentTypes` | `string[]` | e.g. `["Earnings Calls"]`, `["10-K"]` |
| `sentiment` | `"positive" \| "negative" \| "neutral"` | Only when user specifies a sentiment filter |

Use multiple `searchQueries` values to cover synonyms. Keep the date window to 1 year or less.

---

### `getAnalytics`

Discovers event types, sentiment scores, and aspects — with an optional sector filter to scope the analysis.

| Parameter | Type | Notes |
|-----------|------|-------|
| `companyName` | `string` | Company name (optional if using sector/query scope) |
| `documentIDs` | `string[]` | `transcriptId` values from `getCompanyDocuments` |
| `documentTypes` | `string[]` | e.g. `["Earnings Calls"]` |
| `sinceDay` / `untilDay` | `"YYYY-MM-DD"` | Max range: 1 year |
| `analyticsType` | `string[]` | `["scores", "eventTypes", "aspects", "patternSentiment", "importance"]` |
| `sectors` | `string[]` | Sector filter — narrows analytics to companies in those sectors |
| `searchQueries` | `string[]` | Topic filter within the analytics scope |

Always request `analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]` unless scoping to a single type. The `eventTypes` output feeds directly into `searchTopCompanies`.

---

### `searchTopCompanies`

Ranks companies by topic relevance, sentiment, or event frequency.

| Parameter | Type | Notes |
|-----------|------|-------|
| `searchQueries` | `string[]` | Topic terms matching the user's question |
| `sectors` | `string[]` | Sector filter when user specifies an industry |
| `documentTypes` | `string[]` | e.g. `["Earnings Calls"]` |
| `sinceDay` / `untilDay` | `"YYYY-MM-DD"` | Date range |
| `eventTypes` | `string[]` | Event type IDs from `getAnalytics` output — pass one per call |
| `speakerId` | `string` | One speaker ID only — never pass multiple |
| `sentiment` | `"positive" \| "negative" \| "neutral"` | Filter when user specifies direction |
| `limit` | `number` | Number of companies to return (default: 10, increase to 20 for broad scans) |

**Critical:** Call `searchTopCompanies` **once per event type** when chaining from `getAnalytics` — never merge multiple event types into one call. Sentiment scores are between **-1 and 1**.

---

### `search`

Retrieves supporting quotes from filings and transcripts.

| Parameter | Type | Notes |
|-----------|------|-------|
| `companyName` | `string` | Target company name |
| `companyIDs` | `string[]` | Alternative to `companyName` — pass IDs for precision |
| `topicSearchQuery` | `string` | Free-text topic query (single string, not array) |
| `speakerTypes` | `string[]` | e.g. `["Executives"]`, `["Analysts"]` |
| `sections` | `string[]` | e.g. `["EarningsCalls_Presentation"]`, `["EarningsCalls_Question"]` |
| `eventTypes` | `string[]` | Filter by event type |
| `sentiment` | `"positive" \| "negative" \| "neutral"` | Sentiment direction for quotes |
| `size` | `number` | Number of results (3–5 per company is sufficient) |
| `sortBy` | `"sentiment" \| "day"` | Sort order dimension |
| `sortOrder` | `"asc" \| "desc"` | Direction of sort |
| `sinceDay` / `untilDay` | `"YYYY-MM-DD"` | Date range |
| `documentIDs` | `string[]` | Scope to specific transcripts |
| `deepSearch` | `boolean` | Set `true` if fewer than 30 results on first pass |

---

## ID Flow

`getAnalytics` → `eventTypes` → `searchTopCompanies` → company results → `search`

Step by step:

1. **`getAnalytics`** (with `sectors` filter) → extract the `eventTypes` list from the response
2. For each event type: **`searchTopCompanies`** (`eventTypes: ["<one event type>"]`) → extract top company names and any `companyId` values from results
3. For top-ranked companies: **`search`** (`companyName: "<name>"` or `companyIDs: ["<id>"]`) → retrieve supporting quotes

---

## Execution Sequences

Run each batch in sequence; within a batch, fire all calls simultaneously.

---

### Mode A — Topic Scan

*"Which companies talked about tariffs most?", "Top companies on supply chain issues"*

**Batch 1** — sector-level view (no dependencies):
```
searchSectors(
  searchQueries: ["tariff", "tariffs", "trade war"],
  sinceDay: "<date>",
  untilDay: "<today>",
  documentTypes: ["Earnings Calls"]
)
```

**Batch 2** — company ranking (parallel, one per top sector returned):
```
searchTopCompanies(
  searchQueries: ["tariff", "tariffs"],
  sectors: ["<sector from Batch 1>"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "<date>",
  untilDay: "<today>",
  limit: 10
)
```

**Batch 3** — supporting quotes (parallel, one per top company):
```
search(
  companyName: "<company>",
  topicSearchQuery: "tariff trade war",
  sentiment: "negative",
  size: 3,
  sortBy: "sentiment",
  sortOrder: "asc"
)
```

---

### Mode B — Sector Distribution

*"Show AI sentiment across sectors", "Which industries are most bullish on rate cuts?"*

**Batch 1** — sector distribution (parallel):
```
searchSectors(
  searchQueries: ["artificial intelligence", "AI", "machine learning"],
  sinceDay: "<date>",
  untilDay: "<today>",
  documentTypes: ["Earnings Calls"],
  sentiment: "positive"   ← only if user specified
)

searchSectors(
  searchQueries: ["artificial intelligence", "AI", "machine learning"],
  sinceDay: "<date>",
  untilDay: "<today>",
  documentTypes: ["Earnings Calls"],
  sentiment: "negative"   ← only if user specified
)
```

**Batch 2** — top companies per leading sector (parallel, one `searchTopCompanies` per top-3 sector):
```
searchTopCompanies(
  searchQueries: ["artificial intelligence", "AI"],
  sectors: ["<sector>"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "<date>",
  untilDay: "<today>",
  limit: 10
)
```

---

### Mode C — Event Drill-down

*"Top negative events in tech this week", "What risk events dominated healthcare earnings?"*

**Batch 1** — discover event types (no dependencies):
```
getAnalytics(
  sectors: ["Technology"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "<7 days ago>",
  untilDay: "<today>",
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
)
```

**Batch 2** — rank companies per event type (parallel, one call per event type from Batch 1):
```
searchTopCompanies(
  eventTypes: ["<one event type>"],
  sectors: ["Technology"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "<date>",
  untilDay: "<today>",
  sentiment: "negative",
  limit: 10
)
```

**Batch 3** — supporting quotes per top company (parallel):
```
search(
  companyName: "<company>",
  topicSearchQuery: "<event type topic>",
  eventTypes: ["<event type>"],
  sentiment: "negative",
  size: 3,
  sortBy: "sentiment",
  sortOrder: "asc"
)
```

---

## Response Template

### Sector Ranking Table

Produced from `searchSectors` output:

| Rank | Sector | Sentiment Score | Mention Count | Direction |
|------|--------|----------------|--------------|-----------|
| 1 | Technology | +0.42 | 1,840 | LEADING |
| 2 | Consumer Discretionary | +0.31 | 1,205 | HIGH |
| 3 | Industrials | −0.12 | 980 | MODERATE |
| 4 | Energy | −0.28 | 740 | LOW |
| 5 | Financials | −0.41 | 510 | LAGGING |

Always include at least **5 sectors** — sparse tables miss distribution nuance.

---

### Company Ranking Table

Produced from `searchTopCompanies` output:

| Rank | Company | Sector | Sentiment Score | Mentions | Top Event |
|------|---------|--------|----------------|---------|-----------|
| 1 | NVIDIA | Technology | +0.71 | 312 | GrowthDriver |
| 2 | Apple | Technology | +0.44 | 287 | CapexExpansion |
| 3 | Microsoft | Technology | +0.39 | 261 | ProductLaunch |
| 4 | Amazon | Consumer Disc. | +0.18 | 198 | SupplyChain |
| 5 | Tesla | Consumer Disc. | −0.22 | 176 | RiskFactor |

Always show at least **5 companies**. Sentiment scores are between −1 and 1 — surface the full range, not just the positives.

---

### Response Structure

Every sector/topic response must include:

1. **Opening verdict** — one sentence stating the overall finding (e.g. "Technology dominates AI discussion with the highest sentiment score, while Energy lags significantly")
2. **Sector ranking table** — from `searchSectors`
3. **Company ranking table** — from `searchTopCompanies` (top 5–10 per leading sector)
4. **Key quotes** — 1–2 supporting quotes per top-3 company, with full attribution
5. **Divergence callouts** — note any sector/company where sentiment and mention volume move in opposite directions
6. **HTML charts** — open `/tmp/sectors-charts.html` so the user can see the visualization

Do not mention tool names in responses — describe the action instead (e.g. "I scanned across sectors" not "I called searchSectors").

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/sectors-charts.html`, then open it:

```
open /tmp/sectors-charts.html
```

The template has 4 Chart.js graphs pre-wired:

- **Chart 1** — Sector Sentiment Ranking (from `searchSectors` — horizontal bar, green/red by sentiment)
- **Chart 2** — Sector Mention Volume (from `searchSectors` — horizontal bar, sorted by count)
- **Chart 3** — Top Companies by Topic (from `searchTopCompanies` — horizontal bar, green/red by sentiment)
- **Chart 4** — Event Type Distribution (from `getAnalytics` eventTypes — horizontal bar)

Populate only the arrays that have data — leave the rest empty (`[]`) if a tool was not called for that chart.

---

## Best Practices

1. **Always use synonym arrays** — `searchQueries: ["tariff", "tariffs", "trade war"]` returns more coverage than a single term
2. **One event type per `searchTopCompanies` call** — never merge multiple event types into one call; the results are not comparable
3. **Minimum 5 results per table** — surface the full distribution, not just the top 1–2
4. **Never fabricate data** — if a tool returns nothing, say so honestly and try the fallback in Error Handling below
5. **Always cite quotes** — `"Quote text" — [Speaker Name], [Role], [Company] ([Date])`
6. **Surface divergences** — a sector with high mention volume but negative sentiment is more interesting than a simple top-mention ranking; always call this out explicitly

---

## Date Handling

```
Past week:     sinceDay = 7 days ago,   untilDay = today
Past 2 weeks:  sinceDay = 14 days ago,  untilDay = today
Past quarter:  sinceDay = 90 days ago,  untilDay = today
Past 6 months: sinceDay = 6 months ago, untilDay = today
Past year:     sinceDay = 1 year ago,   untilDay = today
```

`getAnalytics` max date range is 1 year — split longer requests into yearly chunks and aggregate results manually.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| No sectors returned from `searchSectors` | Broaden `searchQueries`; remove `sentiment` filter; widen date range |
| `searchSectors` returns fewer than 5 sectors | Remove `documentTypes` filter to include all document types |
| `getAnalytics` returns no event types | Try without `documentIDs`; widen date range; remove `sectors` filter |
| `searchTopCompanies` returns fewer than 5 companies | Remove `sectors` filter — topic may be cross-sector; increase `limit` |
| Fewer than 30 results from `search` | Re-run with `deepSearch: true` |
| No quotes from `search` for a company | State "No matching quotes found" — never fabricate |
| `getAnalytics` date range error | Confirm range is ≤ 1 year; split into two calls if needed |
| `searchTopCompanies` returns no results for an event type | Skip that event type; note it in the response; proceed with remaining types |

---

## Reference Docs

| Doc | When to load | What it covers |
|-----|-------------|----------------|
| [reference/report-template-guide.md](reference/report-template-guide.md) | Choosing a mode or planning batches | Exact batch plans for Mode A, B, and C |
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need enum values, sector names, or document type strings | Sector enums, analytics types, document types, citation URL format |
| [examples/sector-topic-analysis.md](examples/sector-topic-analysis.md) | Topic sentiment across companies | Full `getAnalytics` → `searchTopCompanies` → `search` workflow with real params |
| [examples/sector-distribution.md](examples/sector-distribution.md) | Sector-level distribution question | `searchSectors` → `searchTopCompanies` with ranked output example |
