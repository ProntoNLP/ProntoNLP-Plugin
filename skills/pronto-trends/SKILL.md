---
name: pronto-trends
description: "Use this skill when the user asks about trending keywords, topics, or themes across the market — e.g. 'what are the trending topics right now?', 'what themes are rising in tech?', 'show a mind map of AI in finance', 'term frequency heatmap for supply chain', 'what keywords are companies using most?', 'which topics are gaining momentum?', 'show me how often tariffs are mentioned across companies'. This skill covers keyword and topic trends only — getTrends, getMindMap, getTermHeatmap."
---

# ProntoNLP — Keyword & Topic Trends

Surfaces which topics, keywords, and themes are gaining or losing momentum across financial documents. Three tools cover the full picture: ranked trending topics with momentum scores, concept relationship mind maps, and per-company term frequency heatmaps. Use this skill whenever the user asks what is being talked about — not just what happened to a single company.

---

## Prerequisite

This skill is self-contained. All tool parameters, ID flows, and error handling are defined here. No other skill is required.

---

## When to Use Which Tool

| User question | Tool |
|---|---|
| "What topics are trending in tech?" / "What themes are rising right now?" | `getTrends` |
| "Show a mind map of AI" / "How does supply chain relate to other concepts?" | `getMindMap` |
| "How often do companies mention tariffs?" / "Term frequency heatmap for inflation" | `getTermHeatmap` |

Use `getTrends` **only when the user explicitly asks about trends, trending topics, or rising/falling themes.** Do not use it as a catch-all for general market questions.

---

## Tools Reference

### `getTrends`

Returns a ranked list of trending topics with score, hit count, and % change vs the prior period.

| Param | Type | Notes |
|---|---|---|
| `companyName` | `string` | Scope to a specific company's documents |
| `sectors` | `string[]` | Scope to one or more sectors — e.g. `["Information Technology"]` |
| `sinceDay` | `"YYYY-MM-DD"` | Start of date range |
| `untilDay` | `"YYYY-MM-DD"` | End of date range |
| `sortBy` | `"score"` \| `"count"` \| `"percentage"` | Always use `"score"` |
| `sortOrder` | `"asc"` \| `"desc"` | Always use `"desc"` |
| `limit` | `number` | Default 20 — always request at least 20 |
| `documentTypes` | `string[]` | Optional — filter by document type |
| `corpus` | `"S&P Transcripts"` \| `"SEC Filings"` \| `"Non-SEC Filings"` \| `"Macro"` | Optional corpus scope |
| `excludeNegative` | `boolean` | Set `true` to show only rising trends |
| `timeframeDays` | `number` | Alternative to `sinceDay`/`untilDay` |
| `speakerTypes` | `string[]` | Optional speaker filter |
| `country` | `string` | Optional country filter |

**Output per trend:** `name`, `explanation`, `score`, `hits`, `change` (% change vs prior period)

> **WARNING — there is NO `query` parameter in `getTrends`.** Use `companyName` to scope to a company and `sectors` to scope to a sector. Never pass `query` or `topic` to this tool — those parameters do not exist and will be silently ignored or cause errors.

---

### `getMindMap`

Returns a graph of related concepts for a topic. Use when the user asks how a concept connects to other themes.

| Param | Type | Notes |
|---|---|---|
| `topic` | `string` | The concept to map — e.g. `"AI"`, `"supply chain"`, `"tariffs"` |
| `sinceDay` | `"YYYY-MM-DD"` | Start of date range |
| `untilDay` | `"YYYY-MM-DD"` | End of date range |
| `sectors` | `string[]` | Optional sector filter |
| `companyName` | `string` | Optional — scope to a specific company |

**Output:** A graph structure with nodes and edges. Render as a nested markdown list grouping sub-themes under parent nodes.

---

### `getTermHeatmap`

Returns how frequently a specific term appears across companies and time periods. Use for "how often does X come up?" questions.

| Param | Type | Notes |
|---|---|---|
| `term` | `string` | The keyword to track — e.g. `"tariff"`, `"inflation"`, `"AI"` |
| `sectors` | `string[]` | Optional sector scope |
| `companyNames` | `string[]` | Optional company scope — array, e.g. `["Apple", "NVIDIA"]` |
| `sinceDay` | `"YYYY-MM-DD"` | Start of date range |
| `untilDay` | `"YYYY-MM-DD"` | End of date range |
| `documentTypes` | `string[]` | Optional document type filter |

**Output:** Frequency counts per company per time period. Sort by frequency descending and flag spikes.

> **WARNING — there is NO `query` parameter in `getTermHeatmap`.** The term to track goes in `term`. For company scope, use `companyNames` (array, not `companyName`). These are the only correct parameter names.

---

## Execution Sequences

Run each batch in sequence. Within a batch, fire all calls simultaneously.

---

### Sequence A — Trending Topics

*Triggered by: "What are the trending topics in tech?", "What themes are rising right now?", "Show me trending keywords for Apple"*

**Batch 1** — fetch trends (no dependencies):
```
getTrends
  companyName: "Apple"                   ← use for company-scoped trends (omit for broad market)
  sectors: ["Information Technology"]    ← use for sector-scoped trends (omit when using companyName)
  sinceDay: "YYYY-MM-DD"                 ← 90 days ago by default
  untilDay: "YYYY-MM-DD"                 ← today
  sortBy: "score"
  sortOrder: "desc"
  limit: 20
```

Do not use both `companyName` and `sectors` in the same call. Omit both for broad market trends.

**Batch 2** — generate charts (needs Batch 1 results):
```
Write file: /tmp/trends-charts.html
  Copy assets/charts-template.html
  Populate: trendNames, trendScores, trendChanges, trendHits
  Leave termNames/termFreqs as [] (getTermHeatmap not called)

open /tmp/trends-charts.html
```

---

### Sequence B — Mind Map

*Triggered by: "Show me a mind map of AI in finance", "How does supply chain relate to other topics?", "Map out the concept of tariffs"*

**Batch 1** — fetch mind map (no dependencies):
```
getMindMap
  topic: "AI"                            ← the concept to map (string)
  sinceDay: "YYYY-MM-DD"
  untilDay: "YYYY-MM-DD"
  sectors: ["Information Technology"]    ← optional sector filter
  companyName: "Apple"                   ← optional company scope (omit for broad view)
```

**Batch 2** — render and chart:
```
Render output as nested markdown list (see Response Templates below)

Write file: /tmp/trends-charts.html
  Copy assets/charts-template.html
  Leave all data arrays as [] (mind map data does not populate chart variables)

open /tmp/trends-charts.html
```

---

### Sequence C — Term Heatmap

*Triggered by: "Show term frequency heatmap for tariffs", "How often do companies mention inflation?", "Which companies talk about AI the most?"*

**Batch 1** — fetch heatmap (no dependencies):
```
getTermHeatmap
  term: "tariff"                         ← the keyword to track (NOT "query")
  sectors: ["Information Technology"]    ← optional sector scope
  companyNames: ["Apple", "NVIDIA"]      ← optional company scope (array)
  sinceDay: "YYYY-MM-DD"
  untilDay: "YYYY-MM-DD"
```

**Batch 2** — render table, write charts, open:
```
Render output as heatmap table (see Response Templates below)

Write file: /tmp/trends-charts.html
  Copy assets/charts-template.html
  Populate: termNames (companies), termFreqs (frequencies)
  Leave trendNames/trendScores/trendChanges/trendHits as []

open /tmp/trends-charts.html
```

---

## Response Templates

### Trending Topics Table

Present all results in this format. Always request at least 20 topics — a short list misses the picture.

```markdown
## Trending Topics — [Scope: Sector / Company / Market-Wide]
**Top [N] themes over the past [period]:**

| Topic | Score | Hits | % Change | Direction |
|-------|-------|------|----------|-----------|
| AI Agents | 95 | 412 | +72% | RISING ↑ |
| Inference Workloads | 84 | 267 | +55% | RISING ↑ |
| Data Center Capacity | 88 | 298 | +38% | RISING ↑ |
| Vision Pro | 68 | 187 | -12% | DECLINING ↓ |
| China Revenue | 57 | 131 | -15% | DECLINING ↓ |

**Fastest-rising themes:**
- **[Topic]** (+X%) — [Why this is gaining momentum]
- **[Topic]** (+X%) — [Why this is gaining momentum]

**Notable declining themes:**
- **[Topic]** (−X%) — [What the decline signals]
```

Direction labels: `RISING ↑` when `change > 0`, `DECLINING ↓` when `change < 0`.

Always call out the 3 fastest-rising themes (highest positive % change) as emerging narratives worth watching.

---

### Mind Map — Nested Markdown List

Convert the graph output to a nested markdown list. Group related sub-themes under parent nodes.

```markdown
**[Topic]**
- [Parent concept]
  - [Sub-theme]
  - [Sub-theme]
- [Parent concept]
  - [Sub-theme]
  - [Sub-theme]
- [Parent concept]
  - [Sub-theme]
```

Example for topic "AI":
```markdown
**AI**
- Machine Learning
  - Large Language Models
  - Computer Vision
- Data Infrastructure
  - Cloud Computing
  - Edge Computing
- Applications
  - Drug Discovery
  - Fraud Detection
```

---

### Term Heatmap Table

Present frequency data sorted by frequency descending. Flag spikes — companies where the term frequency jumped significantly vs the prior period.

```markdown
## Term Frequency Heatmap — "[term]"
**[Period]**

| Term | Company | Period | Frequency | Direction |
|------|---------|--------|-----------|-----------|
| tariff | Apple | Q1 2025 | 47 | RISING ↑ |
| tariff | NVIDIA | Q1 2025 | 31 | RISING ↑ |
| tariff | Microsoft | Q1 2025 | 18 | STABLE → |
| tariff | Qualcomm | Q4 2024 | 9 | DECLINING ↓ |

**Spikes worth noting:**
- **[Company]** — frequency jumped from X to Y (+Z%) — [brief interpretation]
```

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/trends-charts.html`, then open it:

```
open /tmp/trends-charts.html
```

The template has 4 Chart.js graphs pre-wired:

| Chart | Data source | Type | Color logic |
|---|---|---|---|
| Chart 1 | `getTrends` — scores | Horizontal bar | Green = RISING, Red = DECLINING |
| Chart 2 | `getTrends` — % change | Horizontal bar | Positive = green, Negative = red |
| Chart 3 | `getTrends` — hit counts | Horizontal bar | Uniform blue |
| Chart 4 | `getTermHeatmap` — frequency by company | Vertical bar | Intensity by frequency |

Populate only the charts that have data. Leave arrays empty (`[]`) for tools not called — for example, leave `termNames` and `termFreqs` as `[]` if `getTermHeatmap` was not used.

---

## Best Practices

1. **Always use `sortBy: "score"` and `sortOrder: "desc"`** for `getTrends` — score reflects overall prominence, not just raw volume
2. **Minimum 20 topics** — request `limit: 20` every time; fewer results miss the full picture
3. **Fastest-rising ≠ highest-scoring** — call out topics with the highest positive `change` separately from those with the highest `score`
4. **Use the right scope param** — `companyName` (string) for company scope in `getTrends`; `companyNames` (array) for company scope in `getTermHeatmap` — they are different params
5. **Try root forms for term lookups** — use `"tariff"` not `"tariffs"`, `"inflation"` not `"inflationary"` — singular/root forms return broader results
6. **Never fabricate trends** — if a tool returns fewer results than expected, widen the date range or remove scope filters; do not invent topics

---

## Date Handling

```
Past quarter:  sinceDay = 90 days ago,  untilDay = today   ← default
Past 6 months: sinceDay = 6 months ago, untilDay = today
Past year:     sinceDay = 1 year ago,   untilDay = today
```

Default to **90 days** unless the user specifies a different window. Always set `untilDay` to today's date — stale end dates cause stale results.

---

## Error Handling

| Problem | What to do |
|---|---|
| `getTrends` returns fewer than 10 results | Widen date range or remove `sectors`/`companyName` filter |
| `getTrends` returns no results | Check that `sectors` is an array (not a string); verify date range is not in the future |
| No mind map results | Try a simpler or broader topic term — e.g. `"AI"` instead of `"large language models"` |
| `getTermHeatmap` returns empty | Check spelling; try the root/singular form of the word (e.g. `"tariff"` not `"tariffs"`) |
| `getTermHeatmap` returns wrong companies | Verify `companyNames` is an array, not a single string |
| Trends look stale or unexpected | Confirm `untilDay` is today's date; confirm `sinceDay` is not accidentally set to the future |
| Results seem too narrow | Remove optional filters (`corpus`, `documentTypes`, `speakerTypes`) one at a time to broaden scope |
| Charts file fails to open | Confirm the write step completed before calling open; check `/tmp/` is accessible |

---

## Reference Docs

| Doc | When to load | What it covers |
|---|---|---|
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need a quick param lookup or date range helper | All three tool params, output fields, direction labels, date range formulas |
| [reference/report-template-guide.md](reference/report-template-guide.md) | Building a structured trends report | Three report templates (Trending Topics, Mind Map, Term Heatmap) with exact batch plans and output format specs |
| [examples/trending-topics.md](examples/trending-topics.md) | Trending topics question | Full `getTrends` workflow — batches, realistic output, table with RISING/DECLINING labels, narrative interpretation |
| [examples/term-heatmap.md](examples/term-heatmap.md) | Term frequency heatmap question | Full `getTermHeatmap` workflow for "tariff" across tech companies — batches, frequency table, spike callouts, interpretation |
