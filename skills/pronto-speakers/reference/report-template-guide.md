# Speaker Analysis — Report Template Guide

## Overview

| Mode | Use Case | Batches | Tool Calls | Focus |
|------|----------|---------|------------|-------|
| Mode A: Analyst Ranking | "Who are the most bullish analysts on X?" | 3 | ~8 | Individual analyst sentiment + firm ranking + coverage |
| Mode B: Executive Comparison | "CEO vs CFO sentiment for X" | 3 | ~12 | CEO vs CFO vs exec avg vs analyst gap |
| Mode C: Firm Sentiment | "Which analyst firms are most bearish on X?" | 2 | ~5 | Firm-level ranking + top analysts per firm |

## Decision Tree

```
What is the user asking about?
├── Named individuals (analysts, CEO, CFO)
│   ├── Comparing roles (CEO vs CFO) → Mode B
│   └── Ranking analysts (most bullish / most bearish) → Mode A
└── Firms / institutions
    └── Firm-level stance → Mode C
```

## speakerId Flow (applies to ALL modes)

Every mode that drills into individual speakers follows the same ID chain:

```
1. getSpeakers → response contains speakerId per speaker
2. Extract speakerId for top N speakers (typically 3–5)
3. searchTopCompanies (speakerId: X) → one call per speaker, all in parallel
```

Key rules:
- `speakerId` comes only from `getSpeakers` output — never hardcode or guess
- `searchTopCompanies` accepts exactly ONE speakerId per call
- Run all `searchTopCompanies` calls in the same batch (they are independent of each other)

---

## Mode A: Analyst Ranking

**Use when:** "Who are the most bullish analysts on Apple?" / "Which analysts are most bearish on Netflix?"

**Batches:** 3
**Total calls:** ~8

### Batch Plan

**Batch 1** — Get analyst rankings and firm rankings (parallel, no dependencies):
```
getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"     ← "asc" for bearish-first
  limit: 20
  sinceDay / untilDay: 1-year window

getSpeakerCompanies:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20
  sinceDay / untilDay: same window
```

**Batch 2** — Per-speaker company coverage (needs speakerIds from Batch 1, all parallel):
```
searchTopCompanies (speakerId: analyst #1, limit: 10, sinceDay, untilDay)
searchTopCompanies (speakerId: analyst #2, limit: 10, sinceDay, untilDay)
searchTopCompanies (speakerId: analyst #3, limit: 10, sinceDay, untilDay)
  [top 3–5 analysts by sentiment]
```

**Batch 3** — Key quotes (parallel):
```
search:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sentiment: "positive"
  size: 5
  sections: ["EarningsCalls_Question"]

search:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sentiment: "negative"
  size: 5
  sections: ["EarningsCalls_Question"]
```

Then write `/tmp/speakers-charts.html` and open it.

### Required Verdicts

- "Most bullish analyst: [Name] from [Firm] (score: X.XX)"
- "Most bearish analyst: [Name] from [Firm] (score: −X.XX)"
- "Most bullish firm: [Firm] (score: X.XX)"
- "Most bearish firm: [Firm] (score: −X.XX)"
- Coverage summary per top speaker (from searchTopCompanies)

---

## Mode B: Executive Comparison

**Use when:** "CEO vs CFO sentiment for Microsoft" / "Are executives more positive than analysts?" / "Which executive speaks most on earnings calls?"

**Batches:** 3
**Total calls:** ~12

### Batch Plan

**Batch 1** — All five speaker views in parallel (no dependencies):
```
getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Executives_CEO"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 5

getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Executives_CFO"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 5

getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Executives"]
  sortBy: "count"
  sortOrder: "desc"
  limit: 20

getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20

getSpeakerCompanies:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "desc"
  limit: 20
```

**Batch 2** — Per-speaker company coverage for key executives and top analysts (all parallel, one call per speakerId):
```
searchTopCompanies (speakerId: CEO_ID, limit: 10)
searchTopCompanies (speakerId: CFO_ID, limit: 10)
searchTopCompanies (speakerId: top analyst #1, limit: 10)
searchTopCompanies (speakerId: top analyst #2, limit: 10)
```

**Batch 3** — Key quotes (parallel):
```
search:
  companyName: "<company>"
  speakerTypes: ["Executives_CEO"]
  sentiment: "positive"
  size: 3

search:
  companyName: "<company>"
  speakerTypes: ["Executives_CFO"]
  sentiment: "positive"
  size: 3

search:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sentiment: "negative"
  size: 3
  sections: ["EarningsCalls_Question"]
```

Then write `/tmp/speakers-charts.html` and open it.

### Required Verdicts

- "CEO is MORE BULLISH / MORE CAUTIOUS than CFO by X.XX" (explicit score comparison)
- "Executives are MORE POSITIVE / MORE NEGATIVE than analysts by X.XX" (exec avg − analyst avg)
- "Exec-analyst gap: X.XX — [interpretation]" (>+0.10 = management may be over-optimistic; <−0.10 = street sees more upside)
- Most active executive (by sentence count)
- Most bullish and most bearish analyst

---

## Mode C: Firm Sentiment

**Use when:** "Which analyst firms are most bearish on tech?" / "What is Goldman's stance on Apple?" / "Rank analyst firms covering Netflix"

**Batches:** 2
**Total calls:** ~5

### Batch Plan

**Batch 1** — Firm and individual rankings in parallel (no dependencies):
```
getSpeakerCompanies:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "asc"     ← "desc" for bullish-first
  limit: 20
  sinceDay / untilDay: 1-year window

getSpeakers:
  companyName: "<company>"
  speakerTypes: ["Analysts"]
  sortBy: "sentiment"
  sortOrder: "asc"
  limit: 20
  sinceDay / untilDay: same window
```

**Batch 2** — Per-speaker company coverage for most extreme-sentiment analysts (all parallel):
```
searchTopCompanies (speakerId: most bearish analyst #1, limit: 10)
searchTopCompanies (speakerId: most bearish analyst #2, limit: 10)
searchTopCompanies (speakerId: most bearish analyst #3, limit: 10)
```

Then write `/tmp/speakers-charts.html` and open it.

### Required Verdicts

- "Most bearish firm: [Firm] (score: −X.XX)"
- "Most bullish firm: [Firm] (score: +X.XX)"
- "Spread between most bullish and most bearish firm: X.XX points"
- Coverage focus per top analysts (from searchTopCompanies)

---

## Formatting Guidelines

### Speaker Table

```markdown
| Name | Firm / Role | Sentiment Score | Sentences | Stance |
|------|-------------|-----------------|-----------|--------|
| Name | Firm | +0.XX | NN | BULLISH |
```

### Firm Table

```markdown
| Firm | Sentiment Score | Sentences | Stance |
|------|-----------------|-----------|--------|
| Firm A | +0.XX | NN | Positive |
```

### Executive vs Analyst Gap Table

```markdown
| Group | Avg Sentiment | Sentences | Note |
|-------|---------------|-----------|------|
| CEO | +0.XX | NN | — |
| CFO | +0.XX | NN | More cautious than CEO by X.XX |
| All Executives | +0.XX | NN | — |
| All Analysts | +0.XX | NN | Executives MORE POSITIVE by X.XX |
```

### Stance Labels

- BULLISH: score > +0.20
- Positive: +0.10 to +0.20
- Neutral: −0.10 to +0.10
- Negative: −0.10 to −0.20
- BEARISH: score < −0.20

### Quote Attribution

```
"Quote text here."
— [Speaker Name], [Role], [Firm / Company] ([Date])
```

### Direction Labels

- Use "MORE BULLISH" / "MORE CAUTIOUS" for role comparisons
- Use "MORE POSITIVE" / "MORE NEGATIVE" for group comparisons
- Use "RISING" / "FALLING" if tracking the same speaker across time periods
