---
name: pronto-trends
description: "Use this skill when the user asks about trending keywords, topics, or themes across the market — e.g. 'what are the trending topics right now?', 'what themes are rising in tech?', 'show a mind map of AI in finance', 'term frequency heatmap for supply chain', 'what keywords are companies using most?', 'which topics are gaining momentum?', 'show me how often tariffs are mentioned across companies'. This skill covers keyword and topic trends only — getTrends, getMindMap, getTermHeatmap. Always load pronto-persona first."
---

# ProntoNLP — Keyword & Topic Trends

Use this skill when the user wants to see which topics, keywords, or themes are gaining or losing momentum across financial documents.

> **Prerequisite:** `pronto-persona` must already be loaded for core rules, citation format, and parameter guidelines.

---

## Tools

| Question type | Tool |
|---------------|------|
| "What topics are trending?" / "What themes are rising?" | `getTrends` |
| "Show a mind map of [topic]" | `getMindMap` |
| "Term frequency heatmap for [term]" | `getTermHeatmap` |

---

## Execution Sequences

### A — Trending Topics
*"What are the trending topics in tech?", "What themes are rising right now?"*

Use `getTrends` **only when the user explicitly says "trends" or "trending"** — do not use it for general market or company analysis.

```
getTrends    (companyName or sector + date range + sortBy: "score", limit: 20)
```

Present results as a table: Topic | Score | Hits | % Change | Direction (RISING / DECLINING).
Always call out the fastest-rising themes — those are emerging stories worth watching.

---

### B — Mind Map
*"Show me a mind map of AI in finance", "How does supply chain relate to other topics?"*

```
getMindMap    (topic + date range)
```

Render the output as a nested markdown list, grouping related concepts under parent nodes.

---

### C — Term Heatmap
*"Show term frequency heatmap for tariffs", "How often do companies mention inflation?"*

```
getTermHeatmap    (term + companies or sector + date range)
```

Present as a table: Term | Company / Quarter | Frequency — sorted by frequency descending. Call out any companies where the term frequency is spiking.

---

## Per-Tool Rules

### `getTrends`
- Sort by `score` descending, limit 20
- Direction: RISING (% change > 0) / DECLINING (% change < 0)
- Highlight fastest-rising themes (highest positive % change) as emerging narratives
- Use for a company (`companyName`) or a sector — not as a catch-all for "what's happening in the market"

### `getMindMap`
Returns a graph of related concepts for a topic. If the output is a JSON graph structure, convert it to a nested markdown list grouping related sub-themes under parent nodes.

### `getTermHeatmap`
Returns how frequently a specific term appears across companies and time periods. Sort by frequency descending. Flag spikes — companies where the term suddenly appears much more than before.

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/trends-charts.html`, then open it:

```
open /tmp/trends-charts.html
```

The template has 4 Chart.js graphs pre-wired:
- **Chart 1** — Top Trends by Score (from `getTrends` — horizontal bar, green=rising / red=declining)
- **Chart 2** — % Change per Topic (from `getTrends` — horizontal bar, positive=green / negative=red)
- **Chart 3** — Mention Volume / Hits per Topic (from `getTrends` — horizontal bar)
- **Chart 4** — Term Frequency by Company (from `getTermHeatmap` — vertical bar)

Populate only the charts that have data — leave arrays empty (`[]`) for tools not called (e.g. skip Chart 4 if `getTermHeatmap` wasn't used).

---

## Response Format

For trending topics always include:
1. **Table** — Topic | Score | Hits | % Change | Direction
2. **Top 3 fastest-rising** — brief explanation of why each is gaining momentum
3. **Notable declining themes** — what's fading and why it matters
4. **HTML charts** — open `/tmp/trends-charts.html` so the user can see the visualization

Minimum **10 topics** for trends — a short list misses the picture.

---

## Reference Docs

| Doc | When to load | What it covers |
|-----|-------------|----------------|
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need params or date helpers | getTrends params, direction labels, date ranges |
| [examples/trending-topics.md](examples/trending-topics.md) | Trending topics question | Full getTrends output with table, RISING/DECLINING labels, narrative interpretation |
