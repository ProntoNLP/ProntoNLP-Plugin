---
name: pronto-speakers
description: "Use this skill when the user asks about speakers, executives, analysts, or investor relations — e.g. 'who were the most positive speakers?', 'which analysts are most bullish on X?', 'what firms are bearish on tech?', 'CEO vs CFO sentiment comparison', 'which analyst firms are upgrading their outlook?', 'most active executives in earnings calls', or any question about individual people or firms participating in earnings calls."
---

# ProntoNLP — Speaker & Analyst Analysis

Produces speaker intelligence reports using ProntoNLP tools. The centerpiece is a **ranked comparison of executives and analysts by sentiment and activity** — explicitly showing who is most bullish or bearish, how CEO tone compares to CFO tone, which analyst firms are upgrading or downgrading their outlook, and which companies a given speaker focuses on. Layered on top: firm-level rankings, per-speaker company coverage, and key quotes pulled directly from earnings call transcripts.

---

## Prerequisite

This skill is fully self-contained. No other skill needs to be loaded first. All tool parameters, ID flow, error handling, and response rules are defined below.

---

## Step 0: Choose Your Analysis Mode

Before making any tool calls, decide which mode fits the user's request:

| Mode | Use when | Batches | Focus |
|------|----------|---------|-------|
| **Mode A: Analyst Ranking** | "Who are the most bullish analysts on Apple?" | 3 | Individual analyst sentiment + firm ranking + coverage focus |
| **Mode B: Executive Comparison** | "CEO vs CFO sentiment for Microsoft" | 3 | CEO vs CFO vs all-exec vs analyst gap |
| **Mode C: Firm Sentiment** | "Which analyst firms are most bearish on tech?" | 2 | Firm-level ranking + top analysts per firm |

See `reference/report-template-guide.md` for the exact batch plan of each mode.

---

## When to Use Which Tool

| Question | Primary tool | Notes |
|----------|-------------|-------|
| "Who are the most bullish analysts on X?" | `getSpeakers` (Analysts) | sortBy: sentiment, sortOrder: desc |
| "Who are the most bearish analysts on X?" | `getSpeakers` (Analysts) | sortBy: sentiment, sortOrder: asc |
| "Most active executives on earnings calls?" | `getSpeakers` (Executives) | sortBy: count, sortOrder: desc |
| "CEO vs CFO sentiment?" | `getSpeakers` (Executives_CEO) + `getSpeakers` (Executives_CFO) | Run both in parallel |
| "Which analyst firms are most positive/negative?" | `getSpeakerCompanies` | Returns firm-level aggregates |
| "What companies does analyst X focus on?" | `searchTopCompanies` (speakerId: X) | One call per speaker ID |
| "What did analyst X actually say?" | `search` | Use speakerTypes + sentiment filters |

---

## Tools Reference

### `getSpeakers`

Returns individual speakers ranked by sentiment or activity count.

| Parameter | Type | Notes |
|-----------|------|-------|
| `companyName` | string | Required. Company the speakers commented on. |
| `speakerTypes` | string[] | See enum below. E.g. `["Executives_CEO"]` or `["Analysts"]` |
| `sortBy` | `"sentiment"` \| `"count"` | `sentiment` = rank by positivity/negativity; `count` = most active |
| `sortOrder` | `"asc"` \| `"desc"` | `desc` = bullish-first; `asc` = bearish-first |
| `limit` | number | Default 20. Use 5 for focused role queries (CEO, CFO). |
| `sinceDay` | `"YYYY-MM-DD"` | Start of date range |
| `untilDay` | `"YYYY-MM-DD"` | End of date range |
| `documentTypes` | string[] | Optional. E.g. `["Earnings Calls"]` |

**Speaker type enum values:**
`Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP` | `Executives_Director` | `Executives_President` | `Executives_IR` | `Executives_Board`

**Reading the output:**
- Sentiment score range: **−1.0 (very negative) to +1.0 (very positive)**
- Above +0.10 = notably positive; below −0.10 = notably negative; −0.10 to +0.10 = neutral
- `numOfSentences` (or `count`) = how many sentences that speaker contributed — a proxy for how vocal they are

---

### `getSpeakerCompanies`

Returns analyst firms (e.g. Goldman Sachs, Morgan Stanley) ranked by their collective sentiment toward the companies they cover. Use when the user asks about firms or institutions rather than named individuals.

| Parameter | Type | Notes |
|-----------|------|-------|
| `companyName` | string | Required. |
| `speakerTypes` | string[] | Typically `["Analysts"]` |
| `sortBy` | `"sentiment"` \| `"count"` | |
| `sortOrder` | `"asc"` \| `"desc"` | |
| `limit` | number | |
| `sinceDay` | `"YYYY-MM-DD"` | |
| `untilDay` | `"YYYY-MM-DD"` | |

Pair with `getSpeakers` (Analysts) in the same batch to get both the firm-level and individual-level view simultaneously.

---

### `searchTopCompanies`

Given a single speaker's ID, returns which companies that speaker commented on most — and with what sentiment. Use this after `getSpeakers` to understand the coverage focus of top-ranked analysts or executives.

| Parameter | Type | Notes |
|-----------|------|-------|
| `speakerId` | string | **ONE speaker ID only. Never pass multiple IDs.** |
| `limit` | number | Recommended: 10 |
| `sinceDay` | `"YYYY-MM-DD"` | |
| `untilDay` | `"YYYY-MM-DD"` | |

**Critical rule:** Each speaker requires its own separate call. Do not attempt to pass multiple speaker IDs in one call. Run these calls in parallel within a batch — they are independent of each other.

---

### `search`

Retrieves individual sentences or quote snippets matching a query. Use to pull key quotes from top-ranked speakers after identifying them via `getSpeakers`.

| Parameter | Type | Notes |
|-----------|------|-------|
| `companyName` | string | |
| `speakerTypes` | string[] | Filter by speaker role |
| `sentiment` | `"positive"` \| `"negative"` \| `"neutral"` | |
| `size` | number | Number of results |
| `sortBy` | `"sentiment"` \| `"day"` | |
| `sortOrder` | `"asc"` \| `"desc"` | |
| `sinceDay` | `"YYYY-MM-DD"` | |
| `untilDay` | `"YYYY-MM-DD"` | |
| `sections` | string[] | E.g. `["EarningsCalls_Question"]` for analyst Q&A |

---

## ID Flow: getSpeakers → speakerId → searchTopCompanies

```
getSpeakers (Analysts or Executives)
  → response contains: { speakerId: "SP_001", name: "...", sentimentScore: 0.XX, ... }
                                  ↓
  Extract speakerId for each top-N speaker you want to drill into
                                  ↓
searchTopCompanies (speakerId: "SP_001")   ← one call
searchTopCompanies (speakerId: "SP_002")   ← separate call
searchTopCompanies (speakerId: "SP_003")   ← separate call
  → each returns: [{ name: "Company A", sentiment: 0.XX }, ...]
```

Check the raw `getSpeakers` response for the field named `speakerId`, `id`, or similar — field name may vary. Extract it before proceeding to Batch 2.

---

## Execution Sequences

Run each batch in sequence. Within a batch, fire all calls simultaneously.

---

### Mode A: Analyst Ranking
*"Who are the most bullish analysts on Apple?"*

**Batch 1** — foundation (no dependencies, all parallel):
```
getSpeakers:
  companyName: "Apple"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20
  sinceDay / untilDay: 1-year window

getSpeakerCompanies:
  companyName: "Apple"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20
  sinceDay / untilDay: same window
```

**Batch 2** — per-speaker company coverage (needs speakerIds from Batch 1, one call per ID, all parallel):
```
searchTopCompanies (speakerId: top analyst #1, limit: 10)
searchTopCompanies (speakerId: top analyst #2, limit: 10)
searchTopCompanies (speakerId: top analyst #3, limit: 10)
  [repeat for top 3–5 analysts]
```

**Batch 3** — key quotes (parallel):
```
search:
  companyName: "Apple"
  speakerTypes: ["Analysts"]
  sentiment: "positive"
  size: 5
  sections: ["EarningsCalls_Question"]

search:
  companyName: "Apple"
  speakerTypes: ["Analysts"]
  sentiment: "negative"
  size: 5
  sections: ["EarningsCalls_Question"]
```

Then write `/tmp/speakers-charts.html` and open it.

---

### Mode B: Executive Comparison
*"CEO vs CFO sentiment for Microsoft"*

**Batch 1** — all speaker views in parallel (no dependencies):
```
getSpeakers:
  companyName: "Microsoft"
  speakerTypes: ["Executives_CEO"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 5

getSpeakers:
  companyName: "Microsoft"
  speakerTypes: ["Executives_CFO"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 5

getSpeakers:
  companyName: "Microsoft"
  speakerTypes: ["Executives"]
  sortBy: "count"
  sortOrder: "desc"
  limit: 20

getSpeakers:
  companyName: "Microsoft"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20

getSpeakerCompanies:
  companyName: "Microsoft"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20
```

**Batch 2** — per-speaker company coverage for top executives and top analysts (all parallel, one call per speakerId):
```
searchTopCompanies (speakerId: CEO_ID,  limit: 10)
searchTopCompanies (speakerId: CFO_ID,  limit: 10)
searchTopCompanies (speakerId: top analyst #1, limit: 10)
searchTopCompanies (speakerId: top analyst #2, limit: 10)
```

**Batch 3** — key quotes (parallel):
```
search:
  companyName: "Microsoft"
  speakerTypes: ["Executives_CEO"]
  sentiment: "positive"
  size: 3

search:
  companyName: "Microsoft"
  speakerTypes: ["Executives_CFO"]
  sentiment: "positive"
  size: 3

search:
  companyName: "Microsoft"
  speakerTypes: ["Analysts"]
  sentiment: "negative"
  size: 3
  sections: ["EarningsCalls_Question"]
```

Then write `/tmp/speakers-charts.html` and open it.

---

### Mode C: Firm Sentiment
*"Which analyst firms are most bearish on tech?"*

**Batch 1** — firm and individual rankings in parallel:
```
getSpeakerCompanies:
  companyName: "<tech company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "asc"      ← bearish-first
  limit: 20

getSpeakers:
  companyName: "<tech company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "asc"
  limit: 20
```

**Batch 2** — drill into most bearish analysts (one call per speakerId, all parallel):
```
searchTopCompanies (speakerId: most bearish analyst #1, limit: 10)
searchTopCompanies (speakerId: most bearish analyst #2, limit: 10)
searchTopCompanies (speakerId: most bearish analyst #3, limit: 10)
```

Then write `/tmp/speakers-charts.html` and open it.

---

## Key Verdicts to Always State

Every speaker analysis response must include these explicit comparison statements where data is available:

1. **"[Analyst Name] from [Firm] is the most bullish, with a sentiment score of X.XX"**
2. **"[Analyst Name] from [Firm] is the most bearish, with a sentiment score of −X.XX"**
3. **"Executives are MORE POSITIVE / MORE NEGATIVE than analysts by X.XX"** (compute: exec avg − analyst avg)
4. **"CEO is MORE BULLISH / MORE CAUTIOUS than CFO"** (compare their individual scores explicitly)
5. **"[Firm] is the most bullish firm" / "[Firm] is the most bearish firm"**
6. **"The exec-analyst gap is X.XX — [interpretation]"** (>+0.10 = management may be over-optimistic; <−0.10 = street sees more upside)

Never omit these even if the difference is small. If scores are within 0.02 of each other, say "essentially in line."

---

## Response Template

### Speaker Table (individual analysts or executives)

| Name | Firm / Role | Sentiment Score | Sentences | Coverage Focus |
|------|-------------|-----------------|-----------|----------------|
| Erik Woodring | Morgan Stanley | +0.58 | 32 | Apple, Samsung, Qualcomm |
| Samik Chatterjee | JPMorgan | +0.51 | 28 | Apple, Alphabet, Meta |
| Toni Sacconaghi | Bernstein | −0.12 | 35 | Apple, Dell |
| Rod Hall | Goldman Sachs | −0.18 | 22 | Apple, Lenovo |

Fill "Coverage Focus" column from `searchTopCompanies` results (top 2–3 companies per speaker).

---

### Analyst Firm Table

| Firm | Sentiment Score | Sentences | Stance |
|------|-----------------|-----------|--------|
| Morgan Stanley | +0.55 | 64 | BULLISH |
| JPMorgan | +0.48 | 52 | Positive |
| Goldman Sachs | −0.15 | 41 | Negative |
| Bernstein | −0.22 | 38 | BEARISH |

Stance labels: BULLISH (>+0.20) | Positive (+0.10 to +0.20) | Neutral (−0.10 to +0.10) | Negative (−0.10 to −0.20) | BEARISH (<−0.20)

---

### Executive vs Analyst Gap Table

| Speaker Group | Avg Sentiment | Sentences | Verdict |
|---------------|---------------|-----------|---------|
| CEO | +0.42 | 85 | — |
| CFO | +0.31 | 72 | More cautious than CEO by 0.11 |
| All Executives (avg) | +0.36 | 420 | — |
| All Analysts (avg) | +0.24 | 310 | Executives MORE POSITIVE by 0.12 |

Always include this table when both executive and analyst data are available.

---

### Quote Attribution Format

```
"Quote text here."
— [Speaker Name], [Role], [Firm / Company] ([Date])
```

Never fabricate quotes. If `search` returns nothing, say "No matching quotes found."

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/speakers-charts.html`, then open it:

```
open /tmp/speakers-charts.html
```

The template has 4 Chart.js graphs pre-wired:

- **Chart 1** — Analyst Sentiment Distribution (from `getSpeakers` Analysts — bar sorted bullish → bearish, green/red)
- **Chart 2** — Executive vs Analyst Sentiment (CEO / CFO / Exec Avg / Analyst Avg — grouped bar)
- **Chart 3** — Analyst Firm Ranking (from `getSpeakerCompanies` — horizontal bar, green/red)
- **Chart 4** — Top Executives — Sentiment & Activity (from `getSpeakers` Executives — bar + line overlay for sentence count)

Populate only the charts that have data — leave arrays empty (`[]`) for roles not queried. Never skip this step when data is available.

---

## Best Practices

1. **Always batch independent calls.** All calls within a batch have no dependencies on each other — fire them simultaneously before moving to the next batch.
2. **One speakerId per searchTopCompanies call.** Never try to pass multiple IDs. Multiple calls in parallel is correct; batching IDs in one call is not.
3. **Always produce the verdicts.** State CEO vs CFO, exec vs analyst gap, most bullish, most bearish — even when differences are small.
4. **Never fabricate data.** If a tool returns nothing, say so. Do not invent speakers, scores, or quotes.
5. **Minimum 5 speakers or firms.** Sparse answers miss nuance. If fewer than 5 are returned, show what is available and note the small sample size.
6. **Do not mention tool names in responses.** Describe the action instead — e.g. "I ranked analysts by sentiment" not "I called getSpeakers."

---

## Date Handling

```
Past quarter:  sinceDay = 90 days ago,  untilDay = today
Past 6 months: sinceDay = 6 months ago, untilDay = today
Past year:     sinceDay = 1 year ago,   untilDay = today
```

Default to **1 year** unless the user specifies a shorter window. Always use `"YYYY-MM-DD"` format for both parameters.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Speaker not found | Try `companyName` without a date filter first; then widen the date window |
| No executives returned for a specific role | Fall back to `speakerTypes: ["Executives"]` instead of the specific role enum |
| Fewer than 5 speakers returned | Show what is available; note the small sample — do not pad with invented entries |
| `speakerId` not visible in `getSpeakers` output | Check for `id`, `speakerId`, or a nested speaker object in the raw response |
| No quotes from `search` | Say "No matching quotes found" — never fabricate |
| `searchTopCompanies` returns empty | The speaker may not have commented on other companies in the window; note it and move on |
| Duplicate speaker across CEO/CFO/Executives results | Use the role-specific result; note the overlap in the response |
| Company name returns wrong entity | Try the ticker symbol; check spelling; ask the user to confirm if still ambiguous |

---

## Reference Docs

| Doc | When to load | What it covers |
|-----|-------------|----------------|
| [reference/report-template-guide.md](reference/report-template-guide.md) | Choosing a mode or need exact batch plans | Mode A/B/C batch plans, decision tree, formatting guidelines |
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need speaker type enums or sort params | All speakerType values, sort options, sentiment score ranges |
| [examples/speaker-analysis.md](examples/speaker-analysis.md) | Analyst ranking question | Full getSpeakers → getSpeakerCompanies → searchTopCompanies workflow for Apple analysts |
| [examples/exec-sentiment.md](examples/exec-sentiment.md) | CEO vs CFO comparison | Full Mode B workflow for Microsoft with compiled response, gap table, and charts |
