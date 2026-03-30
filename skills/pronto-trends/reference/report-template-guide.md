# Trends Report Template Guide

## Overview

| Template | Use case | Batches | Tool calls | Output |
|---|---|---|---|---|
| **Trending Topics** | "What topics are trending?" / "What themes are rising in [sector]?" | 2 | 1 tool + 1 write | Ranked table with RISING/DECLINING labels, fastest-rising callouts, charts |
| **Mind Map** | "Show a mind map of [topic]" / "How does [concept] connect to other themes?" | 2 | 1 tool + 1 write | Nested markdown list, concept relationship narrative, charts |
| **Term Heatmap** | "How often do companies mention [term]?" / "Term frequency heatmap for [term]" | 2 | 1 tool + 1 write | Frequency table by company and period, spike callouts, charts |

Default to **Trending Topics** when the user says "trending", "rising", or "what's hot". Use **Term Heatmap** for frequency questions about a specific word. Use **Mind Map** for concept relationship or "how does X relate to Y" questions.

---

## Decision Tree

```
What is the user asking about?
├── A ranked list of topics — what is trending, rising, or falling?
│   └── Trending Topics template
├── How a specific concept connects to other themes?
│   └── Mind Map template
└── How often a specific word appears across companies or time?
    └── Term Heatmap template
```

---

## Template: Trending Topics

**Trigger phrases:** "trending topics", "rising themes", "what's gaining momentum", "what are companies talking about"

**Batches:** 2

### Batch Plan

**Batch 1** — fetch (no dependencies):
```
getTrends
  companyName: "<name>"     ← omit for sector or market-wide
  sectors: ["<sector>"]     ← omit when using companyName
  sinceDay: "<90 days ago>"
  untilDay: "<today>"
  sortBy: "score"
  sortOrder: "desc"
  limit: 20
```

**Batch 2** — write charts, open (needs Batch 1 results):
```
Write /tmp/trends-charts.html
  Populate: trendNames, trendScores, trendChanges, trendHits
  Leave empty: termNames, termFreqs

open /tmp/trends-charts.html
```

### Output Format Spec

```markdown
## Trending Topics — [Sector / Company / Market-Wide]
**Top [N] themes · [sinceDay] to [untilDay]**

| Topic | Score | Hits | % Change | Direction |
|-------|-------|------|----------|-----------|
| [name] | [score] | [hits] | [+/-X%] | RISING ↑ / DECLINING ↓ |
...

**Fastest-rising themes (highest positive % change):**
- **[Topic]** (+X%) — [1-sentence explanation of why this is gaining]
- **[Topic]** (+X%) — [explanation]
- **[Topic]** (+X%) — [explanation]

**Notable declining themes:**
- **[Topic]** (−X%) — [what the decline signals]
- **[Topic]** (−X%) — [interpretation]
```

**Rules:**
- Always show at least 20 rows
- Direction is based on `change` field: positive = `RISING ↑`, negative = `DECLINING ↓`
- Fastest-rising = highest positive `change` (not highest `score`)
- Always include a "Declining themes" section — fading topics are part of the story
- Do not mention tool names in responses

---

## Template: Mind Map

**Trigger phrases:** "mind map of", "show how X connects", "concept map for", "relationships around [topic]"

**Batches:** 2

### Batch Plan

**Batch 1** — fetch (no dependencies):
```
getMindMap
  topic: "<concept>"        ← the concept to map (string)
  sinceDay: "<date>"
  untilDay: "<date>"
  sectors: ["<sector>"]     ← optional
  companyName: "<name>"     ← optional
```

**Batch 2** — render markdown list, write charts, open:
```
Render output as nested markdown list (see format spec below)

Write /tmp/trends-charts.html
  Leave all arrays empty: [] (mind map does not populate chart variables)

open /tmp/trends-charts.html
```

### Output Format Spec

Convert the graph output to a nested markdown list. Group sub-themes under logical parent nodes. Aim for 3 levels of nesting where data supports it.

```markdown
## Mind Map — [Topic]
**[sinceDay] to [untilDay] · [Sector or "Market-Wide"]**

**[Topic]**
- [Parent concept]
  - [Sub-theme]
  - [Sub-theme]
  - [Sub-theme]
- [Parent concept]
  - [Sub-theme]
  - [Sub-theme]
- [Parent concept]
  - [Sub-theme]
  - [Sub-theme]

**Key relationships:**
- [Most prominent connection and why it matters]
- [Second notable cluster]
- [Emerging or unexpected association worth noting]
```

**Rules:**
- Never show a flat list — always nest sub-themes under parent concepts
- Group by logical theme (technology, risk, operational impact, etc.)
- Call out the strongest and most surprising relationships in prose below the map
- If the graph output has node weights or edge weights, sort parents by weight descending

---

## Template: Term Heatmap

**Trigger phrases:** "term frequency", "heatmap for [term]", "how often do companies mention", "track [word] across companies"

**Batches:** 2

### Batch Plan

**Batch 1** — fetch (no dependencies):
```
getTermHeatmap
  term: "<keyword>"                      ← root/singular form
  sectors: ["<sector>"]                  ← optional
  companyNames: ["<name>", "<name>"]     ← optional, must be array
  sinceDay: "<date>"
  untilDay: "<date>"
  documentTypes: ["<type>"]             ← optional
```

**Batch 2** — render table, write charts, open (needs Batch 1 results):
```
Write /tmp/trends-charts.html
  Populate: termNames (companies), termFreqs (frequencies)
  Leave empty: trendNames, trendScores, trendChanges, trendHits

open /tmp/trends-charts.html
```

### Output Format Spec

```markdown
## Term Frequency Heatmap — "[term]"
**[sinceDay] to [untilDay] · [Sector or Company scope or "Market-Wide"]**

| Term | Company | Period | Frequency | Direction |
|------|---------|--------|-----------|-----------|
| [term] | [company] | [period] | [N] | RISING ↑ / DECLINING ↓ / STABLE → |
...
*(sorted by frequency descending)*

**Spikes worth noting:**
- **[Company]** — frequency jumped from X to Y (+Z%) in [period] — [brief interpretation of what drove the spike]

**Companies with lowest mention rate:**
- [Company] — mentioned [term] only [N] times — [interpretation]

**Takeaway:**
[2-3 sentences interpreting the overall pattern — e.g. broad industry concern vs isolated company exposure]
```

**Rules:**
- Sort rows by frequency descending
- Flag spikes: any company where frequency is materially above the group average
- Always include a "Takeaway" paragraph — frequency data alone is not insight
- Use the `term` root form (singular, no inflection) for the broadest possible match
- `companyNames` must be an array — never a plain string

---

## Formatting Guidelines

### Direction Labels

| Signal | Label |
|---|---|
| `change > 0` (getTrends) | `RISING ↑` |
| `change < 0` (getTrends) | `DECLINING ↓` |
| Frequency up vs prior period | `RISING ↑` |
| Frequency down vs prior period | `DECLINING ↓` |
| Frequency flat vs prior period | `STABLE →` |

### Date Range Defaults

```
Past quarter:  sinceDay = 90 days ago,  untilDay = today   ← default for all templates
Past 6 months: sinceDay = 6 months ago, untilDay = today
Past year:     sinceDay = 1 year ago,   untilDay = today
```

### Charts Variables

| Variable | Populated by | Template |
|---|---|---|
| `trendNames` | `getTrends` → `name` | Trending Topics |
| `trendScores` | `getTrends` → `score` | Trending Topics |
| `trendChanges` | `getTrends` → `change` | Trending Topics |
| `trendHits` | `getTrends` → `hits` | Trending Topics |
| `termNames` | `getTermHeatmap` → company names | Term Heatmap |
| `termFreqs` | `getTermHeatmap` → frequency values | Term Heatmap |

Leave any unused variable as `[]`.
