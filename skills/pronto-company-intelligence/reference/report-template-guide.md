# Report Template Selection Guide

## Overview

| Template | Use Case | Phases | Sections | Tool Calls |
|----------|----------|--------|----------|------------|
| Full Report | Comprehensive deep-dive | All (1-9) | All (1-11) | ~40 |
| Quick Report | Fast overview | 1-2 | 1-3 | ~13 |
| Sentiment Report | Earnings sentiment focus | 1, 3, 4, 5, 7 | 1, 4-7 | ~25 |
| Competitive Report | Peer comparison | 1-2, 6 | 1-2, 9 | ~15 |
| Risk Assessment | Downside analysis | 1, 3, 5, 6, 7 | 1, 4, 7, 9, 10 | ~20 |

## Decision Tree

```
Is this a quick lookup or a full analysis?
├── Quick lookup → Quick Report
└── Full analysis
    ├── Specific focus?
    │   ├── Sentiment / earnings → Sentiment Report
    │   ├── Competitors / positioning → Competitive Report
    │   └── Risks / downside → Risk Assessment
    └── No specific focus → Full Report
```

## companyId Flow (applies to ALL templates)

Every template starts the same way:

```
1. getCompanyDescription → SAVE companyId
2. getCompanyCompetitors → SAVE competitor companyIds (skip for Quick Report)
```

Then use these IDs:
- `companyId` → getStockPrices, getStockChange, getPredictions
- competitor `companyIds` → getStockChange (per competitor)
- `transcriptId` from getCompanyDocuments → getAnalytics (per quarter), search (per quarter)
- `companyName` → getAnalytics, getTrends, getSpeakers, getSpeakerCompanies, search

---

## Template: Full Report (default)

**Phases**: All (1-9)
**Sections**: All (1-11)
**Batches**: 5

### Batch plan:
1. `getCompanyDescription` + `getCompanyCompetitors` (parallel)
2. `getCompanyDocuments` + `getStockPrices` + `getStockChange` x3 + `getPredictions` x6 + `getTrends` (parallel)
3. `getAnalytics` x4 (per quarter) + `getStockPrices` x4 (around calls) + `getSpeakers` x2 + `getSpeakerCompanies` + `getStockChange` per competitor (parallel)
4. Quotes — **Claude Cowork:** `pronto-search-summarizer` ×4 (forecast) + positive + negative + analyst Q&A via Agent tool in parallel | **claude.ai:** `search` ×4 + positive + negative + analyst Q&A directly in parallel
5. Write HTML charts file

---

## Template: Quick Report

**Phases**: 1-2 only
**Sections**: 1-3 (Executive Summary, Stock, Predictions)

### Batch plan:
1. `getCompanyDescription` (save companyId)
2. `getStockPrices` + `getStockChange` x3 + `getPredictions` x6 + `getAnalytics` with `analyticsType: ["scores"]` only (parallel, using companyId)

---

## Template: Sentiment Report

**Phases**: 1, 3, 4, 5, 7
**Sections**: 1, 4-7 (Earnings Comparison, Forecast, Trends, Commentary)

### Batch plan:
1. `getCompanyDescription`
2. `getCompanyDocuments` + `getTrends` (parallel)
3. `getAnalytics` x4 (per quarter) + `getStockPrices` x4 (around calls) + `getSpeakers` (executives) + `getSpeakers` (analysts) + `getSpeakerCompanies` (parallel)
4. `pronto-search-summarizer` ×4 (forecast per quarter) + `pronto-search-summarizer` (positive) + `pronto-search-summarizer` (negative) — all via Agent tool in parallel

---

## Template: Competitive Report

**Phases**: 1-2, 6
**Sections**: 1-2, 9 (Executive Summary, Stock, Competitive Landscape)

### Batch plan:
1. `getCompanyDescription` + `getCompanyCompetitors` (parallel → save all companyIds)
2. `getStockPrices` + `getStockChange` (target company) + `getStockChange` per competitor (all parallel, using companyIds)

---

## Template: Risk Assessment

**Phases**: 1, 3, 5, 6, 7
**Sections**: 1, 4, 7, 9, 10 (Earnings Comparison, Commentary, Competitors, Risks)

### Batch plan:
1. `getCompanyDescription` + `getCompanyCompetitors` (parallel — extract risk factors + competitor IDs)
2. `getCompanyDocuments`
3. `getAnalytics` x4 (per quarter) + `getAnalytics` (10-K risk factors) + `getSpeakers` (analysts, sortOrder: "asc" for bears) + `getStockChange` per competitor (parallel)
4. Quotes — **Claude Cowork:** `pronto-search-summarizer` (negative) + `pronto-search-summarizer` (analyst negative questions) via Agent tool | **claude.ai:** `search` (negative) + `search` (analyst negative questions) directly

Key: Sort analysts by `sortOrder: "asc"` to find most bearish first.

---

## Formatting Guidelines

### Tables
```markdown
| Metric | Q1 | Q2 | Q3 | Q4 | Trend |
|--------|-----|-----|-----|-----|-------|
| Revenue | $X | $X | $X | $X | +X% |
```

### Quote Attribution
```
"Quote text here"
— [Speaker Name], [Role], [Company] ([Date])
```

### Sentiment Indicators (no emojis)
- Strong Positive: "BULLISH"
- Positive: "Positive"
- Neutral: "Neutral"
- Negative: "Negative"
- Strong Negative: "BEARISH"

### Direction Labels
- Use "RISING" / "FALLING" for quarter-over-quarter changes
- Use "IMPROVING" / "DETERIORATING" for forecast tone
- Always compare first quarter to last quarter for the overall direction
