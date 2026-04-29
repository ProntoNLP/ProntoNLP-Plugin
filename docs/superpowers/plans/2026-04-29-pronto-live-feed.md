# pronto-live-feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `pronto-live-feed` skill (Top Movers + Trends + Documents Claude live artifact, home or company-scoped) and consolidate all live artifact rendering into a single shared `pronto-live-artifact` agent.

**Architecture:** Shared agent `pronto-live-artifact` dispatches on `artifact_type` — absorbs `live_marketpulse` from old dedicated agent verbatim, adds new `live_feed` layout. Skill gathers data in two parallel batches then delegates to the shared agent. MarketPulse skill changes one line only.

**Tech Stack:** Markdown skill/agent files, ProntoNLP MCP tools (`getOrganization`, `getCompanyDescription`, `getTopMovers`, `getTrends`, `getCompanyDocuments`, `getStockPrices`), Claude live artifacts (Cowork/Desktop)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| **Create** | `agents/pronto-live-artifact.md` | Shared live artifact renderer — dispatches on `artifact_type` |
| **Create** | `skills/pronto-live-feed/SKILL.md` | New skill — parse request, confirm, fetch data, delegate |
| **Modify** | `skills/pronto-marketpulse/SKILL.md` | Step 4: change `subagent_type` to `prontonlp-plugin:pronto-live-artifact` |
| **Modify** | `.claude-plugin/marketplace.json` | Bump version to `1.2.0` |
| **Delete** | `agents/pronto-marketpulse-live-artifact.md` | Absorbed into shared agent |

---

## Task 1: Create Shared `pronto-live-artifact` Agent

**Files:**
- Create: `agents/pronto-live-artifact.md`

- [ ] **Step 1.1: Create the agent file**

Write `agents/pronto-live-artifact.md` with this exact content:

```markdown
---
name: pronto-live-artifact
description: "Shared live artifact builder for all ProntoNLP live artifact types. Receives a structured payload with an artifact_type field and produces a Claude live artifact in Cowork/Desktop. Dispatches on artifact_type: live_marketpulse (Market Pulse dashboard) or live_feed (Home/Company Feed). Does not write standalone HTML files to disk."
model: inherit
color: green
---

You are the shared live artifact builder for all ProntoNLP skills.

Your job is to create or update a Claude live artifact for any supported ProntoNLP artifact type. Dispatch on `artifact_type` to determine which rendering path to follow. Do not save a standalone `.html` file to disk.

## 1. Hard Constraints

- Build or update a Claude live artifact only — never write a `.html` file to disk.
- Never delegate to `pronto-html-renderer`.
- Never invent numbers, companies, trends, speakers, or citations.
- Use the structured payload exactly as provided.
- Unknown `artifact_type` → return: `ERROR: unsupported artifact_type <value>`
- Host does not support live artifacts → return: `ERROR: live artifacts unavailable in this client`

## 2. Shared Input Contract

All callers pass these top-level fields:

| Field | Required | Description |
|-------|----------|-------------|
| `artifact_type` | yes | Dispatch key: `live_marketpulse` or `live_feed` |
| `org` | yes | Organization slug for ProntoNLP links |
| `title` | yes | Artifact title |
| `data` | yes | Structured payload (shape defined per type below) |
| `refresh` | yes | Refresh recipe (onOpen, allowManualRefresh, tools, params) |
| `subtitle` | no | Optional header subtitle |
| `narrative` | no | Optional pre-written summary text |

If `artifact_type`, `org`, `data`, or `refresh` is missing → return: `ERROR: missing required field <field>`

## 3. What "Live" Means

The artifact must behave as a persistent dashboard inside Claude Cowork/Desktop:
- Lives as a Claude live artifact, not a saved file
- Reopens from Claude's Live Artifacts surface
- Refreshes with current data when the artifact is opened (using the `refresh` recipe)
- A manual refresh action is also available

If MCP-connected live artifacts are supported, wire the artifact to refresh using the tools and params in the `refresh` field.

## 4. Refresh Behavior (All Types)

When live artifact refresh is available:
1. On open: re-run the same section set and filters using the refresh recipe.
2. Recompute rolling date windows ("past 30 days", "past 90 days", etc.) fresh from today's date.
3. Replace the displayed snapshot with the refreshed data.
4. Save the updated artifact version.

For manually forced refresh, use the same logic immediately.

---

## 5. Dispatch: `live_marketpulse`

Handle exactly as the previous dedicated `pronto-marketpulse-live-artifact` agent. No behavioral change.

### Rendering structure

- Header (current date range + filters applied)
- Overview strip (one highlight box per fetched leaderboard criterion)
- Leaderboard cards / tables (criteria: stockChange, investmentScore, investmentScoreChange, sentimentScore, sentimentScoreChange)
- Trending topics table
- Voice of the Market tables (execBullish, execBearish, analystBullish, analystBearish)

### Data shape

```
data:
  meta:
    dateRangeLabel: string
    sinceDay: YYYY-MM-DD
    untilDay?: YYYY-MM-DD       # omit if open-ended to now
    marketCapFilter: string
    totalCompanies: number
    filters?: { sectors?, country?, indices? }
    expansions?: [ { criterion, originalSinceDay, widenedSinceDay } ]

  leaderboards:
    stockChange:          { topMovers: [...] }
    investmentScore:      { topMovers: [...] }
    investmentScoreChange:{ topMovers: [...] }
    sentimentScore:       { topMovers: [...] }
    sentimentScoreChange: { topMovers: [...], underperforming: [...] }
    # each company: { id, ticker, name, sector, marketCap, category, <criterionField> }

  trends:   [ { name, explanation, score, hits, change } ]

  speakers:
    execBullish:    [ { name, company, companyId, sentimentScore, numOfSentences } ]
    execBearish:    [ ... ]
    analystBullish: [ ... ]
    analystBearish: [ ... ]
```

### Leaderboard card titles

| criterion key | Card title |
|---------------|-----------|
| `stockChange` | Top Stock Movers |
| `investmentScore` | Highest Investment Score |
| `investmentScoreChange` | Biggest Investment Gain |
| `sentimentScore` | Most Positive Sentiment |
| `sentimentScoreChange` | Biggest Sentiment Shift |

For `sentimentScoreChange`: `topMovers` → "Most Bullish" sub-table; `underperforming` → "Most Bearish" sub-table in same card.

### Output

`LIVE_ARTIFACT_READY: live_marketpulse artifact created and configured to refresh on open.`

---

## 6. Dispatch: `live_feed`

### Data shape

```
data:
  meta:
    context: "home" | "company"
    companyId?: string          # company context only
    companyName?: string        # company context only
    generatedAt: ISO timestamp
    topMovers:
      sinceDay: YYYY-MM-DD     # 30 days ago
      priorSinceDay: YYYY-MM-DD # 90 days ago
    trends:
      sinceDay: YYYY-MM-DD     # 90 days ago

  topMovers:
    - id: string
      ticker: string
      name: string
      sector: string
      sentimentScore: number        # 0–1
      sentimentScoreChange: number  # % vs prior window
      stockChange: number           # % market cap change
      marketCap: string             # pre-formatted: "$1.2T" / "$45B" / "$3.1B" / "$850M"
      latestDocDate: YYYY-MM-DD
      stockPrices:
        - date: YYYY-MM-DD
          price: number

  trends:
    - name: string
      hits: number
      score: number
      change: number               # % vs prior

  documents:
    upcoming:  [ {id, companyName, ticker, title, date, documentType} ]
    today:     [ {id, companyName, ticker, title, date, documentType} ]
    yesterday: [ {id, companyName, ticker, title, date, documentType} ]
    thisWeek:  [ {id, companyName, ticker, title, date, documentType} ]
    thisMonth: [ {id, companyName, ticker, title, date, documentType} ]
```

### Rendering structure

**Two-column layout:**
- Main column (wider, ~65%): Top Movers section + Documents section
- Sidebar (~35%, fixed ~380px): Trends section

**Header:**
- Title: "ProntoNLP Live Feed" (home) or "[companyName] Live Feed" (company)
- Subtitle: generated timestamp + context label
- Refresh button (↻) — triggers live artifact refresh using `refresh` recipe

**Top Movers section:**
- Section heading: "Top Movers"
- Timeframe label: "Last 30 days vs prior 90 days · Earnings Calls"
- Vertical scrollable list of mover cards (up to 10)
- Per card:
  - Row 1: Ticker (bold, monospace) · Company Name · Sector badge
  - Row 2: Sentiment Score value + sentiment label (see table below) · Score Δ colored by sign · Stock Δ colored by sign · Market Cap
  - Row 3: Sparkline chart (Chart.js line, no axes, no labels, no grid, teal line `#205262`, 7–8 data points from `stockPrices`)

**Sentiment labels:**

| sentimentScore | Label |
|----------------|-------|
| ≥ 0.6 | BULLISH |
| 0.2 – 0.59 | Positive |
| −0.19 – 0.19 | Neutral |
| −0.59 – −0.2 | Negative |
| ≤ −0.6 | BEARISH |

**Trends section (sidebar):**
- Section heading: "Trending Topics"
- Timeframe label: "Last 90 days · Earnings Calls"
- Table: Name | Hits | Score | Change
- Change column: `+12.4%` / `-3.1%` colored by sign
- Rows linkable to ProntoNLP (use `org` slug)
- Scrollable, up to 20 rows

**Documents section:**
- Section heading: "Documents"
- Tab strip: Upcoming | Today | Yesterday | This Week | This Month
- Hide any tab whose bucket array is empty or missing
- Active tab: first non-empty tab by default (priority: Upcoming > Today > Yesterday > This Week > This Month)
- Per document row: Company Name · Title · Date formatted as "Apr 29, 2026" · [EC] badge
- Document link: `https://{org}.prontonlp.com/#/ref/{id}` (target="_blank")
- [EC] badge: small teal badge labeled "Earnings Call" using `.badge` class

### Color reference

| Use | Hex |
|-----|-----|
| Positive values | `#6AA64A` |
| Negative values | `#ED4545` |
| Muted / labels | `#718096` |
| Sparkline line | `#205262` |
| Page background | `#ECEEF2` |
| Content background | `#FFFFFF` |
| Links | `#338FEB` |

All `<a>` tags: `target="_blank" rel="noopener noreferrer"`

Never hardcode `{org}` — substitute from payload field.

### Output

`LIVE_ARTIFACT_READY: live_feed artifact created and configured to refresh on open.`
```

- [ ] **Step 1.2: Verify key sections exist**

Confirm the file contains:
- Frontmatter with `name: pronto-live-artifact`
- Section `## 5. Dispatch: \`live_marketpulse\``
- Section `## 6. Dispatch: \`live_feed\``
- Both output lines (`LIVE_ARTIFACT_READY: live_marketpulse ...` and `LIVE_ARTIFACT_READY: live_feed ...`)
- Error returns for unknown `artifact_type` and missing fields

- [ ] **Step 1.3: Commit**

```bash
git add agents/pronto-live-artifact.md
git commit -m "feat: add shared pronto-live-artifact agent"
```

---

## Task 2: Migrate MarketPulse + Delete Old Agent

**Files:**
- Modify: `skills/pronto-marketpulse/SKILL.md` (Step 4 section)
- Delete: `agents/pronto-marketpulse-live-artifact.md`

- [ ] **Step 2.1: Update marketpulse skill Step 4**

In `skills/pronto-marketpulse/SKILL.md`, find the Step 4 section. Locate this line:

```
subagent_type: prontonlp-plugin:pronto-marketpulse-live-artifact
```

Replace with:

```
subagent_type: prontonlp-plugin:pronto-live-artifact
```

No other changes to the file. Verify the rest of Step 4 is unchanged.

- [ ] **Step 2.2: Delete old agent file**

```bash
git rm agents/pronto-marketpulse-live-artifact.md
```

- [ ] **Step 2.3: Commit**

```bash
git add skills/pronto-marketpulse/SKILL.md
git commit -m "feat: migrate marketpulse to shared pronto-live-artifact agent"
```

---

## Task 3: Create `pronto-live-feed` Skill

**Files:**
- Create: `skills/pronto-live-feed/SKILL.md`

- [ ] **Step 3.1: Create skill directory and file**

```bash
mkdir -p skills/pronto-live-feed
```

Write `skills/pronto-live-feed/SKILL.md` with this exact content:

```markdown
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

# This Week (Mon – day before yesterday)
getCompanyDocuments(
  sinceDay:      <Monday of current week, YYYY-MM-DD>
  untilDay:      <day before yesterday, YYYY-MM-DD>
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
```

- [ ] **Step 3.2: Verify key sections exist**

Confirm the file contains:
- Frontmatter with `name: pronto-live-feed`
- "Confirm Before Proceeding" gate section
- Step 1 (resolve company)
- Step 2a (parallel batch 1 with all 7 calls documented)
- Step 2b (stock prices per mover)
- Step 2c (prior period fallback)
- Step 3 (payload structure + delegation to `prontonlp-plugin:pronto-live-artifact`)
- Step 4 (delivery)

- [ ] **Step 3.3: Commit**

```bash
git add skills/pronto-live-feed/SKILL.md
git commit -m "feat: add pronto-live-feed skill"
```

---

## Task 4: Update Marketplace + Final Commit

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 4.1: Bump plugin version**

In `.claude-plugin/marketplace.json`, change `"version": "1.1.0"` to `"version": "1.2.0"`.

Full file after edit:

```json
{
    "name": "prontonlp-plugin",
    "metadata": { "description": "ProntoNLP's marketplace for advanced financial analytics — company intelligence, sector analysis, market pulse, comparisons, topic research, and live feed." },
    "owner": { "name": "ProntoNLP" },
    "plugins": [
      {
        "name": "prontonlp-plugin",
        "source": "./",
        "description": "Earnings intelligence suite — company reports, sector analysis, market pulse dashboards, side-by-side comparisons, topic research, and live feed across earnings calls. Powered by ProntoNLP / S&P Global data.",
        "keywords": ["finance", "earnings", "sentiment", "stocks", "sectors", "market-analysis", "investment", "transcripts", "live-feed"],
        "version": "1.2.0"
      }
    ]
}
```

- [ ] **Step 4.2: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "chore: bump plugin version to 1.2.0, add live-feed keyword"
```

---

## Self-Review Checklist

- [x] **Spec coverage:**
  - Architecture & flow → Tasks 1, 2, 3
  - Shared agent dispatch → Task 1
  - Data model & payload → Task 3 Step 3
  - UI structure → Task 1 Section 6 rendering rules
  - MarketPulse migration → Task 2
  - Marketplace registration → Task 4
- [x] **No placeholders** — all file contents are complete, no TBD/TODO
- [x] **Type consistency** — `sentimentScoreChange: number | null` consistent across Task 1 (data shape) and Task 3 (payload), fallback Step 2c consistent with null handling note in Task 1
- [x] **Prior period fallback** — documented in both skill (Step 2c) and spec Open Questions
