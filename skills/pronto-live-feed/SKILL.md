---
name: pronto-live-feed
description: "Generates a Claude live artifact showing the ProntoNLP live feed — Top Movers ordered by sentiment score change, Trending Topics, and recent/upcoming Earnings Call documents. Supports home (market-wide) and company-specific contexts. Triggers on: 'show me a feed', 'open the feed', 'live feed', 'home feed', 'show me the pronto feed', 'what's in the feed', 'show me the [company] feed', 'open [company/ticker] live feed'. Always fetches fresh data when the artifact opens."
metadata:
  author: ProntoNLP
  version: 1.0.0
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

### B. Compute date ranges

All ranges are **rolling** — recomputed from today's date each time the skill runs:

| Range | Formula |
|-------|---------|
| Top Movers current | `sinceDay` = today − 30 days |
| Top Movers prior | `priorSinceDay` = today − 90 days |
| Trends | `sinceDay` = today − 90 days |
| Documents: upcoming | `sinceDay` = today + 1 day (tomorrow), no `untilDay` |
| Documents: today | `sinceDay` = today, `untilDay` = today |
| Documents: yesterday | `sinceDay` = yesterday, `untilDay` = yesterday |
| Documents: this week | `sinceDay` = Monday of current week, `untilDay` = yesterday |
| Documents: this month | `sinceDay` = 1st of current month, `untilDay` = Sunday before current week |

Store computed dates as `YYYY-MM-DD` strings.

---

## Confirm Before Proceeding

After Step 0, **before calling any tools**, show a short summary and wait for user confirmation.

Show:
- **Context:** "Home Feed" or "[Company Name] Feed"
- **Top Movers:** Last 30 days vs prior 90 days · Earnings Calls · Ordered by sentiment score change
- **Trends:** Last 90 days · Earnings Calls
- **Documents:** Upcoming / Today / Yesterday / This Week / This Month · Earnings Calls

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
- `companyId` — required for filtering all subsequent tool calls
- `companyName` — used in artifact title and header

If the company cannot be resolved, ask the user to clarify before continuing.

---

## Step 2a: Parallel Batch 1

Fire all of the following simultaneously. Always include `getOrganization`.

**Organization:**
```
getOrganization    → save org (required for artifact links and delegation)
```

**Top Movers:**
```
getTopMovers(
  sinceDay:      <today − 30 days, YYYY-MM-DD>
  priorSinceDay: <today − 90 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        ["sentimentScoreChange"]
  limit:         10
  companyId:     <companyId — include only for company context>
)
```

> **Note:** If `getTopMovers` does not accept `priorSinceDay`, omit it and follow the fallback in Step 2c.

**Trends:**
```
getTrends(
  sinceDay:      <today − 90 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  sortBy:        "score"
  companyId:     <companyId — include only for company context>
)
```

> **Note:** `getTrends` does not accept `marketCaps`. Scope only with `documentTypes`, `sinceDay`, and `companyId`.

**Documents (5 calls in parallel):**

```
# Upcoming — future earnings calls
getCompanyDocuments(
  sinceDay:      <today + 1 day, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  companyId:     <companyId — include only for company context>
)

# Today
getCompanyDocuments(
  sinceDay:      <today, YYYY-MM-DD>
  untilDay:      <today, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  companyId:     <companyId — include only for company context>
)

# Yesterday
getCompanyDocuments(
  sinceDay:      <yesterday, YYYY-MM-DD>
  untilDay:      <yesterday, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  companyId:     <companyId — include only for company context>
)

# This Week (Mon – yesterday)
getCompanyDocuments(
  sinceDay:      <Monday of current week, YYYY-MM-DD>
  untilDay:      <yesterday, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  companyId:     <companyId — include only for company context>
)

# This Month (1st of month – day before current week Monday)
getCompanyDocuments(
  sinceDay:      <1st of current month, YYYY-MM-DD>
  untilDay:      <day before Monday of current week, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  limit:         20
  companyId:     <companyId — include only for company context>
)
```

---

## Step 2b: Parallel Batch 2

After Step 2a completes, use `id` and `latestDocDate` from each mover returned by `getTopMovers`.

Fire one `getStockPrices` call per mover, all simultaneously:

```
# Repeat for each mover (up to 10):
getStockPrices(
  companyId: <mover.id>
  sinceDay:  <mover.latestDocDate − 8 days, YYYY-MM-DD>
  untilDay:  <mover.latestDocDate + 8 days, YYYY-MM-DD>
)
```

Attach the returned `prices` array to the corresponding mover object as `stockPrices`.

---

## Step 2c: Prior Period Fallback

Use this step **only** if `getTopMovers` did not accept `priorSinceDay` in Step 2a.

Make a second `getTopMovers` call for the prior window:

```
getTopMovers(
  sinceDay:      <today − 90 days, YYYY-MM-DD>
  untilDay:      <today − 30 days, YYYY-MM-DD>
  documentTypes: ["Earnings Calls"]
  sortBy:        ["sentimentScore"]
  limit:         10
  companyId:     <companyId — include only for company context>
)
```

Match movers by `id` across both calls. For each matched mover, compute:

```
sentimentScoreChange = currentSentimentScore − priorSentimentScore
```

For movers with no prior match, set `sentimentScoreChange = null` and omit the Δ display in the artifact.

---

## Step 3: Build the Payload and Delegate

Pre-format `marketCap` for each mover before delegating:

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
title: "ProntoNLP Live Feed"     # home context
      | "<companyName> Live Feed" # company context

data:
  meta:
    context: "home" | "company"
    companyId?: <string>          # company context only
    companyName?: <string>        # company context only
    generatedAt: <ISO 8601 timestamp, e.g. "2026-04-29T14:32:00Z">
    topMovers:
      sinceDay: <YYYY-MM-DD>
      priorSinceDay: <YYYY-MM-DD>
    trends:
      sinceDay: <YYYY-MM-DD>

  topMovers:
    - id: string
      ticker: string
      name: string
      sector: string
      sentimentScore: number
      sentimentScoreChange: number | null
      stockChange: number
      marketCap: string             # pre-formatted string
      latestDocDate: YYYY-MM-DD
      stockPrices:
        - date: YYYY-MM-DD
          price: number

  trends:
    - name: string
      hits: number
      score: number
      change: number

  documents:
    upcoming:  [ {id, companyName, ticker, title, date, documentType} ]
    today:     [ {id, companyName, ticker, title, date, documentType} ]
    yesterday: [ {id, companyName, ticker, title, date, documentType} ]
    thisWeek:  [ {id, companyName, ticker, title, date, documentType} ]
    thisMonth: [ {id, companyName, ticker, title, date, documentType} ]

refresh:
  onOpen: true
  allowManualRefresh: true
  tools: [getOrganization, getTopMovers, getTrends, getCompanyDocuments, getStockPrices]
  params:
    context: "home" | "company"
    companyId?: <string>           # company context only
    dateRangeMode: rolling         # all date ranges recomputed fresh from today on each open
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

## Field Reference

See `reference/api-fields.md` if available for canonical field names returned by each MCP tool.

## Best Practices

1. Always fire `getOrganization` — the `org` value is required by the live artifact agent for links.
2. Never pass `marketCaps` to `getTrends` — it does not accept that parameter.
3. Never fabricate — if a document bucket is empty, pass an empty array. Do not invent documents.
4. Stock prices are optional per mover — if `getStockPrices` fails for a mover, omit `stockPrices` from that mover object; the artifact will skip the sparkline silently.
5. Do not mention tool names in user-facing messages — describe the action, not the API call.
