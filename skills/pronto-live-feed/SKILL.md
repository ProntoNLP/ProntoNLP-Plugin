---
name: pronto-live-feed
description: "Generates a Claude live artifact showing the ProntoNLP live feed — Top Movers ordered by sentiment score change, Trending Topics, and recent/upcoming Earnings Call documents. Supports home (market-wide) and company-specific contexts. Triggers on: 'show me a feed', 'open the feed', 'live feed', 'home feed', 'show me the pronto feed', 'what's in the feed', 'show me the [company] feed', 'open [company/ticker] live feed'. Always fetches fresh data when the artifact opens."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# ProntoNLP Live Feed

Generates a live Claude artifact showing the ProntoNLP home feed (or company-scoped feed): Top Movers by sentiment score change, Trending Topics, and recent/upcoming Earnings Call documents. Data is always fetched fresh when the artifact opens.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, or `deep-research` from this skill. Use only the tools listed in the steps below.

---

## Step 0: Parse the Request

### A. Detect context

| User says | Context |
|-----------|---------|
| "show me a feed", "open the feed", "live feed", "home feed", "show me the pronto feed", no company named | **Home** — market-wide, no company filter |
| "show me the [company/ticker] feed", "open [company] feed", "[company] live feed" | **Company** — scoped to that entity |

### B. Date ranges (all rolling — recomputed from today each run)

| Range | Value |
|-------|-------|
| Top Movers current | `sinceDay` = today − 30 days |
| Top Movers prior | `sinceDay` = today − 90 days, `untilDay` = today − 30 days |
| Trends | `timeframeDays` = 90 |
| Documents | Upcoming (future) + Recent (last 30 days) |

---

## Confirm Before Proceeding

After Step 0, **before calling any tools**, show a short summary and wait for user confirmation.

Show:
- **Context:** "Home Feed" or "[Company Name] Feed"
- **Top Movers:** Last 30 days vs prior 90 days · Earnings Calls · Ordered by sentiment score change
- **Trends:** Last 90 days · Earnings Calls
- **Documents:** Upcoming + Recent · Earnings Calls

Ask: *"Ready to open the Live Feed. Reply yes to continue, or adjust anything above."*

**Do not call any tools until the user confirms.**

---

## Step 1: Resolve Company (Company Context Only)

Skip this step if context is Home.

Call `getCompanyDescription` with the company name or ticker to resolve the canonical entity:

```
getCompanyDescription(query: <name or ticker>)
```

Save:
- `companyId` — used for `getTopMovers` and `getStockPrices`
- `companyName` — used for `getTrends`, `getCompanyDocuments`, artifact title, and header

If the company cannot be resolved, ask the user to clarify before continuing.

---

## Step 2a: Parallel Batch 1

Fire all of the following simultaneously. Always include `getOrganization`.

**Organization:**
```
getOrganization    → save org (required for artifact links and delegation)
```

**Top Movers — current period:**
```
getTopMovers(
  sinceDay:      <today − 30 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        ["sentimentScoreChange"]
  limit:         10
  companyIDs:    [<companyId>]   # include only for company context
)
```

**Top Movers — prior period (for sentimentScoreChange computation):**
```
getTopMovers(
  sinceDay:      <today − 90 days, YYYY-MM-DD>
  untilDay:      <today − 30 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        ["sentimentScore"]
  limit:         10
  companyIDs:    [<companyId>]   # include only for company context
)
```

**Trends:**
```
getTrends(
  timeframeDays: 90
  documentTypes: ["Earnings Calls"]
  limit:         20
  sortBy:        "score"
  companyName:   <companyName>   # include only for company context
)
```

> **Note:** `getTrends` does not accept `companyId` or `marketCaps`. Use `companyName` for company context.

**Documents:**

*Home context — 2 calls in parallel:*
```
# Recent (last 30 days, market-wide)
search(
  sinceDay:      <today − 30 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        "day"
  sortOrder:     "desc"
  size:          50
)

# Upcoming (future, market-wide)
search(
  sinceDay:      <today + 1 day, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        "day"
  sortOrder:     "asc"
  size:          30
)
```

After receiving `search` results, deduplicate by `(companyName, documentDate)` — keep one entry per document. Extract: `companyName`, `date`, document title (from result metadata). Limit to 30 recent and 20 upcoming.

*Company context — 2 calls in parallel:*
```
# Recent (current year/quarter)
getCompanyDocuments(
  companyName:            <companyName>
  documentTypes:          ["Earnings Calls"]
  excludeFutureDocuments: true
)

# Upcoming
getCompanyDocuments(
  companyName:            <companyName>
  documentTypes:          ["Earnings Calls"]
  excludeFutureDocuments: false
)
```

After receiving results, filter the `upcoming` call to keep only future-dated documents.

---

## Step 2b: Parallel Batch 2

After Step 2a completes, use `id` and `latestDocDate` from each mover in the **current period** `getTopMovers` result.

Compute `sentimentScoreChange` for each mover:
```
sentimentScoreChange = currentSentimentScore − priorSentimentScore
```
Match movers by `id` between current and prior calls. For movers with no prior match, set `sentimentScoreChange = null`.

Then fire one `getStockPrices` call per mover, all simultaneously:
```
# Repeat for each mover (up to 10):
getStockPrices(
  companyId: <mover.id>
  sinceDay:  <mover.latestDocDate − 8 days, YYYY-MM-DD>
  untilDay:  <mover.latestDocDate + 8 days, YYYY-MM-DD>
)
```

Attach the returned price array to the mover object as `stockPrices`.

---

## Step 3: Build the Payload and Delegate

Pre-format `marketCap` for each mover:

| Raw value | Formatted |
|-----------|-----------|
| ≥ 1 trillion | `$1.2T` |
| ≥ 1 billion | `$45B` |
| ≥ 1 million | `$850M` |

Delegate to `pronto-live-artifact` agent (`subagent_type: prontonlp-plugin:pronto-live-artifact`). Do not render HTML here.

Pass the following structured payload:

```
artifact_type: live_feed
org: <from getOrganization>
title: "ProntoNLP Live Feed"      # home context
      | "<companyName> Live Feed"  # company context

data:
  meta:
    context: "home" | "company"
    companyId?: <string>           # company context only
    companyName?: <string>         # company context only
    generatedAt: <ISO 8601 timestamp>
    topMovers:
      sinceDay: <YYYY-MM-DD>       # today − 30 days
      priorSinceDay: <YYYY-MM-DD>  # today − 90 days
    trends:
      timeframeDays: 90

  topMovers:                       # from current-period getTopMovers, enriched
    - id: string
      ticker: string
      name: string
      sector: string
      sentimentScore: number       # 0–1, from current call
      sentimentScoreChange: number | null  # computed; null if no prior match
      stockChange: number          # % market cap change
      marketCap: string            # pre-formatted
      latestDocDate: YYYY-MM-DD
      stockPrices:                 # from getStockPrices; omit if call failed
        - date: YYYY-MM-DD
          price: number

  trends:                          # from getTrends
    - name: string
      hits: number
      score: number
      change: number

  documents:
    upcoming: [ {companyName, title, date, documentType} ]  # future events
    recent:   [ {companyName, title, date, documentType} ]  # last 30 days

refresh:
  onOpen: true
  allowManualRefresh: true
  tools: [getOrganization, getTopMovers, getTrends, search, getCompanyDocuments, getStockPrices]
  params:
    context: "home" | "company"
    companyId?: <string>
    companyName?: <string>
    dateRangeMode: rolling
```

---

## Step 4: Delivery

After the live artifact is ready, summarize in chat:

- **Context:** "Home Feed" or "[Company Name] Feed"
- **Movers:** N companies returned, sorted by sentiment score change
- **Top mover:** [Company name] with [+X.X% / −X.X%] sentiment score change
- **Top trend:** [Trend name], score [X.XX]
- **Upcoming earnings:** N documents scheduled
- **Artifact:** Lives in Claude and refreshes automatically on open

Do not mention tool names in the summary — describe results, not mechanics.

---

## Best Practices

1. Always fire `getOrganization` — `org` is required by the artifact agent for all links.
2. Never pass `marketCaps` or `companyId` to `getTrends` — use `companyName` for company context.
3. `getTopMovers` company filter uses `companyIDs` (array), not `companyId`.
4. Never fabricate — empty document buckets → pass empty arrays. Do not invent documents.
5. Stock prices are optional — if `getStockPrices` fails for a mover, omit `stockPrices`; the artifact skips the sparkline silently.
6. Do not mention tool names in user-facing messages — describe results, not API calls.
