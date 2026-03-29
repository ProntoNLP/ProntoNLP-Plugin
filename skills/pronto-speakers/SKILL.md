---
name: pronto-speakers
description: "Use this skill when the user asks about speakers, executives, analysts, or investor relations — e.g. 'who were the most positive speakers?', 'which analysts are most bullish on X?', 'what firms are bearish on tech?', 'CEO vs CFO sentiment comparison', 'which analyst firms are upgrading their outlook?', 'most active executives in earnings calls', or any question about individual people or firms participating in earnings calls. Always load pronto-persona first."
---

# ProntoNLP — Speaker & Analyst Analysis

Use this skill for questions about individuals or firms who speak in earnings calls — executives (CEO, CFO, etc.) and sell-side analysts.

> **Prerequisite:** `pronto-persona` must already be loaded for core rules, citation format, and parameter guidelines.

---

## When to Use Which Tool

| Question type | Primary tool |
|---------------|-------------|
| "Who were the most positive executives?" | `getSpeakers` (speakerType: Executives) |
| "Which analysts are most bullish?" | `getSpeakers` (speakerType: Analysts) |
| "Which analyst firms are most positive?" | `getSpeakerCompanies` |
| "What topics did a specific speaker focus on?" | `searchTopCompanies` (with speakerId) |

---

## Execution Sequence — Speaker / Analyst Question

*"Who were the most positive speakers?", "What firms are most bullish on X?", "CEO vs CFO sentiment"*

**Batch 1:**
```
getSpeakers              (Executives or Analysts, sortBy: sentiment)
  AND/OR
getSpeakerCompanies      (Analysts)
```

**Batch 2** — drill into top speakers (one call per speakerId — **never batch**):
```
searchTopCompanies       (speakerId: X)
searchTopCompanies       (speakerId: Y)
```

Call `searchTopCompanies` with a `speakerId` to see which companies a specific analyst or executive commented on most. Each speaker requires its own separate call — do not attempt to pass multiple speaker IDs in one call.

---

## Per-Tool Rules

### `getSpeakers`
Returns individual speakers ranked by sentiment or activity. Always specify:
- `speakerType`: `Executives`, `Executives_CEO`, `Executives_CFO`, or `Analysts`
- `sortBy`: `sentiment` (desc = most positive, asc = most negative) or `count` (most active)
- Date range: typically 1 year unless user specifies

**Reading the output:**
- Sentiment score range: **-1 (very negative) to +1 (very positive)**
- A score above +0.1 = notably positive; below -0.1 = notably negative
- "Count" = number of sentences spoken — a proxy for how active/vocal that speaker is

### `getSpeakerCompanies`
Returns analyst firms (e.g. Goldman Sachs, Morgan Stanley) ranked by their collective sentiment toward companies they cover. Use this when the user asks about firms/institutions rather than named individuals.

Pair with `getSpeakers` (Analysts) to get both the firm-level and individual-level view.

### `searchTopCompanies` (per speaker)
After identifying top speakers from `getSpeakers`, call `searchTopCompanies` with that speaker's ID to see which companies they focused on. This reveals whether a bullish analyst is concentrated in one sector or spread across many.

**Critical rule:** Call once per `speakerId`. Never try to batch multiple speaker IDs.

---

## Reference Docs

| Doc | When to load | What it covers |
|-----|-------------|----------------|
| [reference/tool-cheatsheet.md](reference/tool-cheatsheet.md) | Need speaker type enums, sort params, or score interpretation | All speakerType values, sort options, sentiment score range, comparison statement templates |
| [examples/speaker-analysis.md](examples/speaker-analysis.md) | Speaker/analyst question | Full getSpeakers → getSpeakerCompanies → searchTopCompanies per speakerId workflow |

---

## Charts

Copy `assets/charts-template.html`, fill in the data arrays at the top of the `<script>` block with your tool results, write to `/tmp/speakers-charts.html`, then open it:

```
open /tmp/speakers-charts.html
```

The template has 4 Chart.js graphs pre-wired:
- **Chart 1** — Analyst Sentiment Distribution (from `getSpeakers` Analysts — bar sorted bullish→bearish, green/red)
- **Chart 2** — Executive vs Analyst Sentiment (CEO / CFO / Exec Avg / Analyst Avg — grouped bar)
- **Chart 3** — Analyst Firm Ranking (from `getSpeakerCompanies` — horizontal bar, green/red)
- **Chart 4** — Top Executives — Sentiment & Activity (from `getSpeakers` Executives — bar + line overlay showing sentence count)

Populate only the charts that have data — leave arrays empty (`[]`) for roles not queried.

---

## Response Format

Always include:
1. **Top speakers table** — Name | Role/Firm | Sentiment Score | Sentence Count
2. **Comparison statement** — e.g. "Executives are MORE POSITIVE than analysts by 0.12"
3. **CEO vs CFO** (if both available) — explicitly state who is more bullish/cautious
4. **Most bullish / most bearish** — top 3 and bottom 3 analysts by sentiment
5. **Key quotes** — 1–2 direct quotes per notable speaker (from `search` if needed)
6. **HTML charts** — open `/tmp/speakers-charts.html` so the user can see the visualization

Minimum **5 speakers or firms** — sparse answers miss nuance.

Do not mention tool names in responses — describe the action instead (e.g. "I ranked analysts by sentiment" not "I called getSpeakers").

---

## Date Handling

```
Past quarter:  sinceDay = 90 days ago,  untilDay = today
Past 6 months: sinceDay = 6 months ago, untilDay = today
Past year:     sinceDay = 1 year ago,   untilDay = today
```

Default to **1 year** unless the user specifies a shorter window.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Speaker not found | Try `companyName` without date filter; widen the window |
| No executives returned | Try `speakerTypes: ["Executives"]` instead of a specific role |
| Fewer than 5 speakers | Lower `limit` is fine — show what's available, note the small sample |
| `speakerId` not in `getSpeakers` output | Check for `id` or `speakerId` field in the raw response |
| No quotes from `search` | Say "No matching quotes found" — never fabricate |
