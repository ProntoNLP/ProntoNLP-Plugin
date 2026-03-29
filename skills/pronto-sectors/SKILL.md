---
name: pronto-sectors
description: "Use this skill when the user asks about a sector, industry, or topic across multiple companies — e.g. 'which companies talked about tariffs most?', 'show AI sentiment across the tech sector', 'what industries are most exposed to rate hikes?', 'which sectors are bullish on EV adoption?', 'top companies discussing supply chain issues', or any question involving topic/sentiment distribution across markets. Also trigger when the user wants to see which companies are leading or lagging on a specific theme, event, or keyword. Always load pronto-persona first."
---

# ProntoNLP — Sectors & Topic Analysis

Use this skill for cross-company, cross-sector questions: which companies or industries are most/least exposed to a topic, event, or sentiment.

> **Prerequisite:** `pronto-persona` must already be loaded for core rules, citation format, and parameter guidelines.

---

## When to Use Which Tool

| Question type | Primary tool |
|---------------|-------------|
| "Which sectors mention X most?" | `searchSectors` |
| "Which companies discuss X most positively?" | `searchTopCompanies` |
| "Top negative events in [sector] this week" | `getAnalytics` (sectors filter) → `searchTopCompanies` per event |

---

## Execution Sequence

*"Which companies talked about tariffs most positively?", "Show AI sentiment across sectors", "Top companies discussing supply chain issues"*

**Batch 1:**
```
searchSectors            (topic + sentiment + date range)
  OR
getAnalytics             (sectors filter → discover event types first)
```

**Batch 2** (one call per event type — all parallel):
```
searchTopCompanies       (eventType / topic + sector filter)
```

**Batch 3** (if quotes needed):
```
search                   (top result IDs → supporting quotes per company)
```

---

## Per-Tool Rules

### `searchSectors`
Use to get topic mention volume or sentiment distribution across sectors. Always specify:
- A `topic` or `searchQueries` describing the theme
- `sinceDay` / `untilDay` — keep within a 1-year window
- `sentiment` filter when the user specifies positive/negative

Display results as a ranked table: Sector | Mention Count | Sentiment Score.

### `getAnalytics` (with sector filter)
When the user asks about events/themes within a specific sector, call `getAnalytics` first with `sectors: [...]` to discover the correct event type IDs. Then call `searchTopCompanies` once per event type.

### `searchTopCompanies`
Use to rank companies by topic relevance or sentiment. Key rules:
- Filter with `sectors`, `documentTypes`, and date range when the user specifies them
- Display sentiment as a number between **-1 and 1**
- Call **once per event type** when chaining from `getAnalytics` — never merge all event types into one call

---

## Reference Docs

| Doc | When to load | What it covers |
|-----|-------------|----------------|
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need enum values, ID flow, or date helpers | Sector enums, analytics types, document types, citation URL |
| [examples/sector-topic-analysis.md](examples/sector-topic-analysis.md) | Topic sentiment across companies | Full getAnalytics → searchTopCompanies → search workflow with real params |
| [examples/sector-distribution.md](examples/sector-distribution.md) | Sector-level distribution question | searchSectors → searchTopCompanies with ranked output example |

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/sectors-charts.html`, then open it:

```
open /tmp/sectors-charts.html
```

The template has 4 Chart.js graphs pre-wired:
- **Chart 1** — Sector Sentiment Ranking (from `searchSectors` — horizontal bar, green/red)
- **Chart 2** — Sector Mention Volume (from `searchSectors` — horizontal bar)
- **Chart 3** — Top Companies by Topic (from `searchTopCompanies` — horizontal bar, green/red by sentiment)
- **Chart 4** — Event Type Distribution (from `getAnalytics` eventTypes — horizontal bar)

Populate only the arrays that have data — leave the rest empty (`[]`) if a tool wasn't called.

---

## Response Format

For sector/topic results always include:
1. **Ranking table** — company or sector, sentiment score, mention count
2. **Key quotes** — 1–2 supporting quotes per top result (from `search` enrichment)
3. **Interpretation** — what the distribution means (e.g. "Tech sector is most exposed, led by Apple and NVIDIA")
4. **HTML charts** — open `/tmp/sectors-charts.html` so the user can see the visualization

Minimum **5 companies or sectors** as examples — sparse answers miss nuance.
