# pronto-live-feed — Design Spec
**Date:** 2026-04-29  
**Status:** Approved

---

## Overview

New skill `pronto-live-feed` generates a Claude live artifact showing the ProntoNLP home feed (or company-scoped feed): Top Movers, Trends, and Documents — always fetched fresh on open.

Alongside this, the existing `pronto-marketpulse-live-artifact` agent is replaced by a new shared `pronto-live-artifact` agent that handles all live artifact types (current: `live_marketpulse`, `live_feed`; extensible for future types).

---

## Files Changed

### Created
- `skills/pronto-live-feed/SKILL.md` — new skill
- `agents/pronto-live-artifact.md` — shared live artifact agent

### Modified
- `skills/pronto-marketpulse/SKILL.md` — Step 4: call `prontonlp-plugin:pronto-live-artifact` instead of `prontonlp-plugin:pronto-marketpulse-live-artifact`
- `.claude-plugin/marketplace.json` — register `pronto-live-feed`

### Deleted
- `agents/pronto-marketpulse-live-artifact.md` — absorbed into shared agent

---

## Section 1: Architecture & Flow

### Trigger Phrases
"show me a feed", "open the feed", "live feed", "show me the pronto feed", "show me the [company] feed", "what's happening in the market", "home feed", "open the live feed"

### Context Modes
- **Home** — market-wide, no company filter
- **Company** — scoped to a single company/ticker (e.g. "show me the Apple feed")

### Step-by-Step Flow

**Step 0 — Parse request**
- Detect context: Home or Company
- If Company: resolve name/ticker → `companyId` via `getCompanyDescription`

**Step 1 — Confirm gate**
Present to user:
- Context: "Home Feed" or "[Company Name] Feed"
- Top Movers: Last 30 days vs prior 90 days · Earnings Calls · Ordered by sentiment score change
- Trends: Last 90 days · Earnings Calls
- Documents: Upcoming / Today / Yesterday / This Week / This Month · Earnings Calls

Ask: *"Ready to open the Live Feed. Reply yes to continue, or adjust anything above."*
Do not call any tools until confirmed.

**Step 2a — Parallel batch 1** (all fire simultaneously)
- `getOrganization` → save `org`
- `getTopMovers` (sinceDay: 30d ago, priorSinceDay: 90d ago, sortBy: sentimentScoreChange, documentTypes: Earnings Calls, limit: 10, companyId if applicable)
- `getTrends` (sinceDay: 90d ago, documentTypes: Earnings Calls, limit: 20, companyId if applicable)
- `getCompanyDocuments` × 5 in parallel:
  - `upcoming` — future dates, documentTypes: Earnings Calls
  - `today` — sinceDay: today, untilDay: today
  - `yesterday` — sinceDay: yesterday, untilDay: yesterday
  - `thisWeek` — sinceDay: start of current week, untilDay: 2 days ago
  - `thisMonth` — sinceDay: start of current month, untilDay: start of current week - 1 day

**Step 2b — Parallel batch 2** (requires mover IDs from Step 2a)
- `getStockPrices` × N — one per mover, all parallel
  - Date range: ±8 days around each mover's `latestDocDate`

**Step 3 — Delegate to shared live artifact agent**
- `subagent_type: prontonlp-plugin:pronto-live-artifact`
- Pass full structured payload (see Section 2)
- Agent creates Claude live artifact

**Step 4 — Delivery summary**
- Context + date ranges applied
- Number of movers returned
- Top mover: name, sentimentScoreChange
- Top trend: name, score
- Upcoming docs count
- Mention: artifact refreshes on open

### No New MCP Tools Required
Existing tools cover all data needs: `getOrganization`, `getTopMovers`, `getTrends`, `getCompanyDocuments`, `getStockPrices`.

---

## Section 2: Data Model & Payload Contract

```yaml
artifact_type: live_feed
org: <string>
title: "ProntoNLP Live Feed" | "<Company> Live Feed"
data:
  meta:
    context: "home" | "company"
    companyId?: string
    companyName?: string
    generatedAt: ISO timestamp
    topMovers:
      sinceDay: YYYY-MM-DD        # 30 days ago
      priorSinceDay: YYYY-MM-DD   # 90 days ago
    trends:
      sinceDay: YYYY-MM-DD        # 90 days ago

  topMovers:
    - id: string
      ticker: string
      name: string
      sector: string
      sentimentScore: number        # 0–1
      sentimentScoreChange: number  # % vs prior window
      stockChange: number           # % market cap change
      marketCap: string             # "$1.2T" pre-formatted
      latestDocDate: YYYY-MM-DD
      stockPrices:
        - date: YYYY-MM-DD
          price: number

  trends:
    - name: string
      hits: number
      score: number
      change: number                # % vs prior

  documents:
    upcoming:  [ {id, companyName, ticker, title, date, documentType} ]
    today:     [ ... ]
    yesterday: [ ... ]
    thisWeek:  [ ... ]
    thisMonth: [ ... ]

refresh:
  onOpen: true
  allowManualRefresh: true
  tools: [getOrganization, getTopMovers, getTrends, getCompanyDocuments, getStockPrices]
  params:
    context: "home" | "company"
    companyId?: string
    dateRangeMode: rolling          # dates recomputed fresh each open
```

---

## Section 3: Live Artifact UI Structure

### Layout
Two-column grid mirroring Platform HomeFeed:
- **Main column** (left, wider): Top Movers + Documents
- **Sidebar** (right, ~380px): Trends

### Header
- Title: "ProntoNLP Live Feed" or "[Company] Live Feed"
- Subtitle: generated timestamp + context label
- Refresh button (↻) — re-runs all tools, replaces data in-place

### Top Movers
- Vertical list of cards (10 max, scrollable)
- Per card:
  - Ticker (bold) + Company Name + Sector badge
  - Sentiment Score: numeric + label (BULLISH / Positive / Neutral / Negative / BEARISH)
  - Sentiment Score Δ: `+12.4%` colored `#6AA64A` / `#ED4545`
  - Stock Δ: `+8.3%` colored
  - Market Cap: `$4.2B`
  - Sparkline chart (Chart.js line, 7–8 points, no axes, teal `#205262` line)
- Timeframe label: "Last 30 days vs prior 90 days"

### Trends
- Table: Name | Hits | Score | Change
- Change column: color-coded positive/negative
- Rows: clickable link to ProntoNLP
- Scrollable, 20 rows max
- Timeframe label: "Last 90 days"

### Documents
- Tab strip: Upcoming | Today | Yesterday | This Week | This Month
- Empty tabs hidden (not shown if no documents)
- Per document row: Company · Title · Date · [EC] badge
- Earnings Calls badge styled as platform badge

### Colors & Typography
Uses existing design-tokens.css palette:
- Positive: `#6AA64A`
- Negative: `#ED4545`
- Muted: `#718096`
- Brand/sparkline: `#205262`
- Background: `#ECEEF2` page / `#FFFFFF` content

---

## Section 4: Shared `pronto-live-artifact` Agent Contract

### File: `agents/pronto-live-artifact.md`

**Dispatch table:**

| `artifact_type` | Renderer | Source skill |
|---|---|---|
| `live_marketpulse` | MarketPulse layout (migrated verbatim from old agent) | pronto-marketpulse |
| `live_feed` | Feed layout (new) | pronto-live-feed |
| *(future types)* | New dispatch branch added | any |

**Hard constraints:**
- Build Claude live artifacts ONLY — never write HTML files to disk
- Never call MCP tools — all data arrives in payload
- Never invent data — render only what payload contains
- Unknown `artifact_type` → return error, do not guess or fallback

**Shared input fields (all types):**

| Field | Required | Description |
|---|---|---|
| `artifact_type` | yes | Dispatch key |
| `org` | yes | Organization slug for ProntoNLP links |
| `title` | yes | Artifact title |
| `data` | yes | Structured payload (shape per type) |
| `refresh` | yes | Refresh recipe |
| `subtitle` | no | Sub-header text |
| `narrative` | no | Pre-written prose |

**Output:** `LIVE_ARTIFACT_READY: <artifact_type> live artifact created.`

**Migration:** `pronto-marketpulse-live-artifact.md` rendering logic moves verbatim into this agent under the `live_marketpulse` dispatch branch. `pronto-marketpulse` skill Step 4 changes one line only (`subagent_type`). No behavioral change to MarketPulse.

---

## Open Questions / Future Work

- `getTopMovers` prior date range parameter: verify MCP tool supports `priorSinceDay` (or equivalent). If not, make two sequential `getTopMovers` calls (current + prior) and compute `sentimentScoreChange` in skill.
- Company context: test `getCompanyDocuments` behavior when company has no upcoming earnings calls.
- Future `artifact_type` values (e.g. `live_sector_feed`, `live_speaker_feed`) follow same dispatch pattern — add branch to shared agent, create skill.
