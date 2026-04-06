# Example: Full Report — Apple Inc. (AAPL)

Complete workflow showing companyId flow and the per-quarter earnings comparison.

---

## Batch 1: Foundation (parallel)
```
Tool: Pronto:getCompanyDescription
Params: { companyNameOrTicker: "AAPL" }
→ companyId: "4567"          ← SAVED
→ name: "Apple Inc.", sector: "Information Technology"

Tool: Pronto:getCompanyCompetitors
Params: { companyNameOrTicker: "AAPL" }
→ competitors:
    { companyId: "8901", name: "Samsung" }
    { companyId: "1234", name: "Microsoft" }
    { companyId: "5678", name: "Alphabet" }
    { companyId: "2345", name: "Dell Technologies" }
```

## Batch 2: Documents + Stock + Predictions (all parallel, using companyId "4567")
```
Tool: Pronto:getCompanyDocuments
Params: { companyName: "Apple", documentTypes: ["Earnings Calls", "10-K", "10-Q"] }
→ documents:
    { transcriptId: "doc_q1", title: "Apple Q1 FY2025 Earnings", day: "2025-04-28" }   ← SAVED
    { transcriptId: "doc_q2", title: "Apple Q2 FY2025 Earnings", day: "2025-07-31" }   ← SAVED
    { transcriptId: "doc_q3", title: "Apple Q3 FY2025 Earnings", day: "2025-10-30" }   ← SAVED
    { transcriptId: "doc_q4", title: "Apple Q4 FY2025 Earnings", day: "2026-01-30" }   ← SAVED
    { transcriptId: "doc_10k", title: "Apple 10-K FY2025", day: "2025-11-15" }

Tool: Pronto:getStockPrices
Params: { companyId: "4567", fromDate: "2025-03-03", toDate: "2026-03-03", interval: "week" }

Tool: Pronto:getStockChange x3
Params (YTD):    { companyId: "4567", fromDate: "2026-01-01", toDate: "2026-03-03" }
Params (6M):     { companyId: "4567", fromDate: "2025-09-03", toDate: "2026-03-03" }
Params (1Y):     { companyId: "4567", fromDate: "2025-03-03", toDate: "2026-03-03" }

Tool: Pronto:getPredictions x6 (all parallel, companyId: "4567")
  metric: "revenue"
  metric: "epsGaap"
  metric: "ebitda"
  metric: "netIncomeGaap"
  metric: "freeCashFlow"
  metric: "capitalExpenditure"

Tool: Pronto:getTrends
Params: { companyName: "Apple", sinceDay: "2025-12-03", untilDay: "2026-03-03", sortBy: "score", limit: 20 }
→ trends:
    { name: "Apple Intelligence", score: 95, hits: 312, change: 45% }
    { name: "Vision Pro", score: 82, hits: 187, change: -12% }
    { name: "Services Revenue", score: 78, hits: 256, change: 22% }
    { name: "iPhone 17", score: 71, hits: 198, change: 38% }
    { name: "China Market", score: 65, hits: 143, change: -8% }
    { name: "AI Integration", score: 62, hits: 167, change: 55% }
    { name: "Margin Expansion", score: 58, hits: 112, change: 15% }
    { name: "Capital Return", score: 54, hits: 98, change: 3% }
    { name: "Regulatory Risk", score: 51, hits: 89, change: 18% }
    { name: "Wearables Growth", score: 47, hits: 76, change: -5% }
```

## Batch 3: Per-Quarter Sentiment + Stock Around Calls + Speakers + Competitors (all parallel)

### Per-quarter analytics (4 calls, one per earnings call)
```
Tool: Pronto:getAnalytics (Q1)
Params: {
  companyName: "Apple",
  documentIDs: ["doc_q1"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-01", untilDay: "2025-04-30",
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
}
→ sentimentScore: 0.32, investmentScore: [X.X — raw value from API]

Tool: Pronto:getAnalytics (Q2)
Params: {
  companyName: "Apple",
  documentIDs: ["doc_q2"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-07-01", untilDay: "2025-07-31",
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
}
→ sentimentScore: 0.38, investmentScore: [X.X — raw value from API]

Tool: Pronto:getAnalytics (Q3)
Params: { ... documentIDs: ["doc_q3"], sinceDay: "2025-10-01", untilDay: "2025-10-31" ... }
→ sentimentScore: 0.35, investmentScore: [X.X — raw value from API]

Tool: Pronto:getAnalytics (Q4)
Params: { ... documentIDs: ["doc_q4"], sinceDay: "2026-01-01", untilDay: "2026-01-31" ... }
→ sentimentScore: 0.41, investmentScore: [X.X — raw value from API]
```

### Stock price around each earnings call (4 calls, using companyId "4567")
```
Tool: Pronto:getStockPrices (around Q1 call)
Params: { companyId: "4567", fromDate: "2025-04-21", toDate: "2025-05-05", interval: "day" }
→ Price before call: $198, price after: $202 → +2.0%

Tool: Pronto:getStockPrices (around Q2 call)
Params: { companyId: "4567", fromDate: "2025-07-24", toDate: "2025-08-07", interval: "day" }
→ Price before: $210, price after: $219 → +4.3%

Tool: Pronto:getStockPrices (around Q3 call)
Params: { companyId: "4567", fromDate: "2025-10-23", toDate: "2025-11-06", interval: "day" }
→ Price before: $225, price after: $222 → -1.3%

Tool: Pronto:getStockPrices (around Q4 call)
Params: { companyId: "4567", fromDate: "2026-01-23", toDate: "2026-02-06", interval: "day" }
→ Price before: $230, price after: $238 → +3.5%
```

### Speakers + Competitors (parallel with above)
```
Tool: Pronto:getSpeakers (all executives)
Params: { companyName: "Apple", speakerTypes: ["Executives"], sortBy: "count", sortOrder: "desc", limit: 20, ... }
→ speakers:
    { name: "Tim Cook", sentimentScore: 0.42, numOfSentences: 187 }
    { name: "Luca Maestri", sentimentScore: 0.35, numOfSentences: 156 }
    { name: "Jeff Williams", sentimentScore: 0.38, numOfSentences: 43 }
    { name: "Deirdre O'Brien", sentimentScore: 0.31, numOfSentences: 28 }
→ Average executive sentiment: 0.37

Tool: Pronto:getSpeakers (CEO)
Params: { companyName: "Apple", speakerTypes: ["Executives_CEO"], sortBy: "count", limit: 5, ... }
→ { name: "Tim Cook", sentimentScore: 0.42, numOfSentences: 187 }

Tool: Pronto:getSpeakers (CFO)
Params: { companyName: "Apple", speakerTypes: ["Executives_CFO"], sortBy: "count", limit: 5, ... }
→ { name: "Luca Maestri", sentimentScore: 0.35, numOfSentences: 156 }

Tool: Pronto:getSpeakers (analysts — bullish first)
Params: { companyName: "Apple", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, ... }
→ speakers:
    { name: "Erik Woodring", company: "Morgan Stanley", sentimentScore: 0.58, numOfSentences: 32 }
    { name: "Samik Chatterjee", company: "JPMorgan", sentimentScore: 0.51, numOfSentences: 28 }
    { name: "Wamsi Mohan", company: "Bank of America", sentimentScore: 0.45, numOfSentences: 25 }
    ... (15 more analysts)
    { name: "Toni Sacconaghi", company: "Bernstein", sentimentScore: -0.12, numOfSentences: 35 }
    { name: "Rod Hall", company: "Goldman Sachs", sentimentScore: -0.18, numOfSentences: 22 }
→ Average analyst sentiment: 0.29

Tool: Pronto:getSpeakerCompanies
Params: { companyName: "Apple", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, ... }
→ firms:
    { name: "Morgan Stanley", sentimentScore: 0.55, numOfSentences: 64 }
    { name: "JPMorgan", sentimentScore: 0.48, numOfSentences: 52 }
    ...
    { name: "Goldman Sachs", sentimentScore: -0.15, numOfSentences: 41 }
    { name: "Bernstein", sentimentScore: -0.22, numOfSentences: 38 }

Tool: Pronto:getStockChange (per competitor, parallel)
Params: { companyId: "8901", fromDate: "2025-03-03", toDate: "2026-03-03" }  // Samsung
Params: { companyId: "1234", fromDate: "2025-03-03", toDate: "2026-03-03" }  // Microsoft
Params: { companyId: "5678", fromDate: "2025-03-03", toDate: "2026-03-03" }  // Alphabet
Params: { companyId: "2345", fromDate: "2025-03-03", toDate: "2026-03-03" }  // Dell
```

## Batch 4: Forecast Sentences + Key Quotes (all parallel)

### Forecast search per quarter (4 calls)
```
Tool: Pronto:search (Q1 forecasts)
Params: {
  companyName: "Apple",
  documentIDs: ["doc_q1"],
  topicSearchQuery: "forecast guidance outlook expectations",
  speakerTypes: ["Executives"],
  size: 5, sortBy: "sentiment", sortOrder: "desc"
}
→ "We expect continued strength in Services, with revenue growth in the mid-teens..."

Tool: Pronto:search (Q2 forecasts)
Params: { ... documentIDs: ["doc_q2"], topicSearchQuery: "forecast guidance outlook expectations" ... }
→ "We're raising our full-year EPS guidance reflecting strong iPhone demand..."

Tool: Pronto:search (Q3 forecasts)
Params: { ... documentIDs: ["doc_q3"] ... }
→ "We anticipate some headwinds from FX and macro uncertainty in the December quarter..."

Tool: Pronto:search (Q4 forecasts)
Params: { ... documentIDs: ["doc_q4"] ... }
→ "We're very pleased with holiday performance and raising fiscal year guidance..."
```

### Positive/negative quotes + analyst Q&A (3 calls)
```
Tool: Pronto:search (positive executive quotes)
Params: { companyName: "Apple", speakerTypes: ["Executives"], sentiment: "positive", size: 10, sortBy: "day", sortOrder: "desc" }

Tool: Pronto:search (negative/risk quotes)
Params: { companyName: "Apple", sentiment: "negative", size: 10, sortBy: "day", sortOrder: "desc" }

Tool: Pronto:search (analyst Q&A)
Params: { companyName: "Apple", speakerTypes: ["Analysts"], sections: ["EarningsCalls_Question"], size: 10 }
```

## Compile: Full Report

```markdown
# Apple Inc. (AAPL) — Intelligence Report
**Generated**: March 3, 2026
**Sector**: Information Technology | **Market Cap**: $3.8T
**Pronto Company ID**: 4567

---

## Executive Summary

Apple Inc. designs and sells consumer electronics, software, and services globally.
Over the past year, the stock gained +22.1%, outperforming both the peer average (+14.2%)
and S&P 500 (+11.8%).

**Sentiment score is RISING — from 0.32 (Q1) to 0.41 (Q4).**
**Investment score is RISING — Q1 to Q4 (use raw values from API).**
**Stock price reacted positively to 3 of 4 earnings calls.**
**Management's forecast tone is IMPROVING — guidance was raised in Q2 and Q4.**
**Executives are MORE POSITIVE than analysts by 0.08 (0.37 vs 0.29) — modest, healthy gap.**
**CEO (0.42) is MORE BULLISH than CFO (0.35).**

Thesis: BULLISH. Supported by (1) rising sentiment and investment scores across all quarters,
(2) consistent beat-and-raise pattern, (3) Services revenue growth accelerating,
(4) executive-analyst sentiment gap is narrow, indicating alignment.

---

## Earnings Call Comparison — Quarter Over Quarter

| Quarter | Date     | Sentiment | Dir     | Investment | Dir     | Stock After | Dir     |
|---------|----------|-----------|---------|------------|---------|-------------|---------|
| Q1 2025 | Apr 28   | 0.32      | —       | 0.61       | —       | +2.0%       | —       |
| Q2 2025 | Jul 31   | 0.38      | RISING  | 0.65       | RISING  | +4.3%       | RISING  |
| Q3 2025 | Oct 30   | 0.35      | FALLING | 0.68       | RISING  | -1.3%       | FALLING |
| Q4 2025 | Jan 30   | 0.41      | RISING  | 0.71       | RISING  | +3.5%       | RISING  |

Note: Q3 shows a divergence — investment score continued rising despite sentiment dip,
and the stock fell. This was driven by macro FX concerns, not fundamental deterioration.

---

## Management Forecast & Outlook

| Quarter | Tone | Key Guidance |
|---------|------|-------------|
| Q1 2025 | Cautiously optimistic | Services growth mid-teens, steady iPhone |
| Q2 2025 | Confident | Raised full-year EPS, strong iPhone demand |
| Q3 2025 | Cautious | FX headwinds, macro uncertainty flagged |
| Q4 2025 | Optimistic | Strong holiday, raised FY guidance again |

**Forecast tone is IMPROVING. Guidance was RAISED in 2 of 4 quarters.**

---

## Trending Topics

| Trend | Score | Hits | % Change | Direction |
|-------|-------|------|----------|-----------|
| Apple Intelligence | 95 | 312 | +45% | RISING |
| Vision Pro | 82 | 187 | -12% | DECLINING |
| Services Revenue | 78 | 256 | +22% | RISING |
| iPhone 17 | 71 | 198 | +38% | RISING |
| China Market | 65 | 143 | -8% | DECLINING |
| AI Integration | 62 | 167 | +55% | RISING |
| Margin Expansion | 58 | 112 | +15% | RISING |
| Capital Return | 54 | 98 | +3% | RISING |
| Regulatory Risk | 51 | 89 | +18% | RISING |
| Wearables Growth | 47 | 76 | -5% | DECLINING |

**Key takeaways:**
- Apple Intelligence and AI Integration are the fastest-rising topics (+45% and +55%), dominating executive commentary
- Vision Pro discussion is declining (-12%), suggesting reduced emphasis after initial launch hype
- China Market remains a watched topic but declining in mentions — potential risk fading or being avoided

---

## Executive Sentiment & Management Commentary

CEO vs CFO Comparison:
| Role | Name | Sentiment Score | Sentences | vs Exec Avg (0.37) |
|------|------|----------------|-----------|---------------------|
| CEO  | Tim Cook | 0.42 | 187 | ABOVE (+0.05) |
| CFO  | Luca Maestri | 0.35 | 156 | BELOW (-0.02) |

**CEO is MORE BULLISH than CFO (0.42 vs 0.35).** This is typical — CEO focuses on
vision and growth narrative while CFO tempers with financial realism.

Top Executives by Volume:
| Executive | Sentiment | Sentences |
|-----------|-----------|-----------|
| Tim Cook | 0.42 | 187 |
| Luca Maestri | 0.35 | 156 |
| Jeff Williams | 0.38 | 43 |
| Deirdre O'Brien | 0.31 | 28 |

---

## Analyst & Investor Sentiment

Average analyst sentiment: 0.29
Sentiment spread: 0.76 (most bullish 0.58 to most bearish -0.18)

Most Bullish Analysts:
| Analyst | Firm | Sentiment | Sentences |
|---------|------|-----------|-----------|
| Erik Woodring | Morgan Stanley | 0.58 | 32 |
| Samik Chatterjee | JPMorgan | 0.51 | 28 |
| Wamsi Mohan | Bank of America | 0.45 | 25 |

Most Bearish Analysts:
| Analyst | Firm | Sentiment | Sentences |
|---------|------|-----------|-----------|
| Rod Hall | Goldman Sachs | -0.18 | 22 |
| Toni Sacconaghi | Bernstein | -0.12 | 35 |

Most Bullish Firms:
| Firm | Sentiment | Sentences |
|------|-----------|-----------|
| Morgan Stanley | 0.55 | 64 |
| JPMorgan | 0.48 | 52 |

Most Bearish Firms:
| Firm | Sentiment | Sentences |
|------|-----------|-----------|
| Bernstein | -0.22 | 38 |
| Goldman Sachs | -0.15 | 41 |

EXECUTIVES vs ANALYSTS GAP:
| Group | Avg Sentiment |
|-------|--------------|
| Executives | 0.37 |
| Analysts | 0.29 |
| **Gap** | **+0.08** |

**Executives are MORE POSITIVE than analysts by 0.08.** Gap is modest — management
tone is slightly more optimistic than street, but not alarmingly so. Suggests
reasonable alignment between company narrative and analyst expectations.

---

[... Sections 9-11 continue with Competitors, Risks, Appendix ...]
```

## Phase 8: Generate Charts

After all data is collected, write an HTML file with Chart.js:

```
Write file: /tmp/apple-report-charts.html

Populate the data arrays from tool results:
  sentimentScores = [0.32, 0.38, 0.35, 0.41]
  investmentScores = [Q1_score, Q2_score, Q3_score, Q4_score]  // raw values from API
  stockReactions = [2.0, 4.3, -1.3, 3.5]
  weeklyDates = [... 52 weekly dates from getStockPrices ...]
  weeklyPrices = [... 52 weekly prices ...]
  competitorNames = ['Apple', 'Samsung', 'Microsoft', 'Alphabet', 'Dell', 'S&P 500']
  competitorReturns = [22.1, 12.5, 18.3, 16.7, 8.9, 11.8]
  trendNames = ['Apple Intelligence', 'Vision Pro', 'Services Revenue', ...]
  trendScores = [95, 82, 78, ...]
  trendChanges = [45, -12, 22, ...]  // % change — positive = green, negative = red
  speakerLabels = ['CEO', 'CFO', 'Exec Avg', 'Analyst Avg']
  speakerSentiments = [0.42, 0.35, 0.37, 0.29]
  positiveEvents = [42, 51, 38, 55]
  negativeEvents = [8, 5, 14, 6]
  analystNames = ['Analyst A', 'Analyst B', ...]
  analystSentiments = [0.65, 0.52, ...]

→ This produces 9 interactive charts in a 2-column grid layout.
→ User can open /tmp/apple-report-charts.html in any browser.
```

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 2 | getCompanyDescription + getCompanyCompetitors |
| 2 | 12 | docs + stock prices + 3 stock changes + 6 predictions + trends |
| 3 | 19 | 4 analytics (per quarter) + 4 stock around calls + 5 speakers (all execs, CEO, CFO, analysts, firms) + deep research avg + 4 competitor changes |
| 4 | 7 | 4 forecast searches + positive quotes + negative quotes + analyst Q&A |
| 5 | 1 | Write HTML charts file |
| **Total** | **~41** | **5 sequential batches, heavily parallelized** |
