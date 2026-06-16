# Example: Full Report — Apple Inc. (AAPL)

Complete workflow showing companyId flow and the per-quarter earnings comparison.

---

## Batch 1: Foundation (parallel)
```
Tool: getCompanies
Params: { companyNameOrTicker: "AAPL" }
→ id: "4567"   (save as companyId)   ← SAVED
→ name: "Apple Inc.", sector: "Information Technology"

Tool: getCompanyPeers
Params: { companiesIds: ["4567"] }
→ peers:
    { companyId: "8901", name: "Samsung" }
    { companyId: "1234", name: "Microsoft" }
    { companyId: "5678", name: "Alphabet" }
    { companyId: "2345", name: "Dell Technologies" }
```

## Batch 2: Documents + Stock + Predictions (all parallel, using companiesIds: ["4567"])
```
Tool: getDocuments
Params: { companiesIds: ["4567"], documentTypes: ["Earnings Calls", "10-K", "10-Q"], excludeFutureDocuments: true }
→ documents:
    { transcriptId: "doc_q1", title: "Apple Q1 FY2025 Earnings", date: "2025-04-28" }   ← SAVED
    { transcriptId: "doc_q2", title: "Apple Q2 FY2025 Earnings", date: "2025-07-31" }   ← SAVED
    { transcriptId: "doc_q3", title: "Apple Q3 FY2025 Earnings", date: "2025-10-30" }   ← SAVED
    { transcriptId: "doc_q4", title: "Apple Q4 FY2025 Earnings", date: "2026-01-30" }   ← SAVED
    { transcriptId: "doc_10k", title: "Apple 10-K FY2025", date: "2025-11-15" }

Tool: getStockPrices (1-year weekly)
Params: { companiesIds: ["4567"], dateRange: { gte: "now-1y/d", lte: "now" }, interval: "week" }

Tool: getStockChange x3
Params (YTD): { companiesIds: ["4567"], dateRange: { gte: "2026-01-01", lte: "now" } }
Params (6M):  { companiesIds: ["4567"], dateRange: { gte: "now-6M/d",  lte: "now" } }
Params (1Y):  { companiesIds: ["4567"], dateRange: { gte: "now-1y/d",  lte: "now" } }

Tool: getCompanyConsensus (1 call — all metrics at once)
Params: { companiesIds: ["4567"], metrics: ["revenue", "epsGaap", "ebitda", "netIncomeGaap", "freeCashFlow", "capitalExpenditure"], timeframeInterval: "quarter" }

Tool: getTrends
Params: { companiesIds: ["4567"], dateRange: { gte: "now-90d/d", lte: "now" }, sortBy: "score", limit: 20 }
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

## Batch 3: Per-Quarter Sentiment + Stock Around Calls + Speakers + Peers (all parallel)

### Per-quarter analytics (4 calls, one per earnings call)
```
Tool: getAnalytics (Q1)
Params: {
  companiesIds: ["4567"],
  transcriptsIds: ["doc_q1"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
}
→ sentimentScore: 0.32, investmentScore: [X.X — raw value from API]

Tool: getAnalytics (Q2)
Params: {
  companiesIds: ["4567"],
  transcriptsIds: ["doc_q2"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
}
→ sentimentScore: 0.38, investmentScore: [X.X — raw value from API]

Tool: getAnalytics (Q3)
Params: { companiesIds: ["4567"], transcriptsIds: ["doc_q3"], analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"] }
→ sentimentScore: 0.35, investmentScore: [X.X — raw value from API]

Tool: getAnalytics (Q4)
Params: { companiesIds: ["4567"], transcriptsIds: ["doc_q4"], analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"] }
→ sentimentScore: 0.41, investmentScore: [X.X — raw value from API]
```

### Stock price around each earnings call (4 calls, using companiesIds: ["4567"])
```
Tool: getStockPrices (around Q1 call)
Params: { companiesIds: ["4567"], dateRange: { gte: "2025-04-21", lte: "2025-05-05" }, interval: "day" }
→ Price before call: $198, price after: $202 → +2.0%

Tool: getStockPrices (around Q2 call)
Params: { companiesIds: ["4567"], dateRange: { gte: "2025-07-24", lte: "2025-08-07" }, interval: "day" }
→ Price before: $210, price after: $219 → +4.3%

Tool: getStockPrices (around Q3 call)
Params: { companiesIds: ["4567"], dateRange: { gte: "2025-10-23", lte: "2025-11-06" }, interval: "day" }
→ Price before: $225, price after: $222 → -1.3%

Tool: getStockPrices (around Q4 call)
Params: { companiesIds: ["4567"], dateRange: { gte: "2026-01-23", lte: "2026-02-06" }, interval: "day" }
→ Price before: $230, price after: $238 → +3.5%
```

### Speakers + Peers + Risks (parallel with above)
```
Tool: getSpeakers (entityType: "speaker", all executives)
Params: { entityType: "speaker", companiesIds: ["4567"], speakerTypes: ["Executives"], sortBy: "count", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"] }
→ speakers:
    { name: "Tim Cook", sentimentScore: 0.42, numOfSentences: 187 }
    { name: "Luca Maestri", sentimentScore: 0.35, numOfSentences: 156 }
    { name: "Jeff Williams", sentimentScore: 0.38, numOfSentences: 43 }
    { name: "Deirdre O'Brien", sentimentScore: 0.31, numOfSentences: 28 }
→ Average executive sentiment: 0.37

Tool: getSpeakers (entityType: "speaker", CEO)
Params: { entityType: "speaker", companiesIds: ["4567"], speakerTypes: ["Executives_CEO"], limit: 5, documentTypes: ["Earnings Calls"] }
→ { name: "Tim Cook", sentimentScore: 0.42, numOfSentences: 187 }

Tool: getSpeakers (entityType: "speaker", CFO)
Params: { entityType: "speaker", companiesIds: ["4567"], speakerTypes: ["Executives_CFO"], limit: 5, documentTypes: ["Earnings Calls"] }
→ { name: "Luca Maestri", sentimentScore: 0.35, numOfSentences: 156 }

Tool: getSpeakers (entityType: "speaker", analysts — bullish first)
Params: { entityType: "speaker", companiesIds: ["4567"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"] }
→ speakers:
    { name: "Erik Woodring", company: "Morgan Stanley", sentimentScore: 0.58, numOfSentences: 32 }
    { name: "Samik Chatterjee", company: "JPMorgan", sentimentScore: 0.51, numOfSentences: 28 }
    { name: "Wamsi Mohan", company: "Bank of America", sentimentScore: 0.45, numOfSentences: 25 }
    ... (15 more analysts)
    { name: "Toni Sacconaghi", company: "Bernstein", sentimentScore: -0.12, numOfSentences: 35 }
    { name: "Rod Hall", company: "Goldman Sachs", sentimentScore: -0.18, numOfSentences: 22 }
→ Average analyst sentiment: 0.29

Tool: getSpeakers (entityType: "company" — analyst firms)
Params: { entityType: "company", companiesIds: ["4567"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20 }
→ firms:
    { name: "Morgan Stanley", sentimentScore: 0.55, numOfSentences: 64 }
    { name: "JPMorgan", sentimentScore: 0.48, numOfSentences: 52 }
    ...
    { name: "Goldman Sachs", sentimentScore: -0.15, numOfSentences: 41 }
    { name: "Bernstein", sentimentScore: -0.22, numOfSentences: 38 }

Tool: getDocumentSummary (risks, all 4 quarters — max 5)
Params: { focus: "key risks and risk factors mentioned by management", transcriptsIds: ["doc_q1", "doc_q2", "doc_q3", "doc_q4"], corpus: ["S&P Transcripts"] }
→ risks: [{ text: "China Revenue Concentration...", sources: [...] }, ...]

Tool: getStockChange (all peers — 1 call)
Params: { companiesIds: ["8901", "1234", "5678", "2345"], dateRange: { gte: "now-1y/d", lte: "now" } }  // Samsung, Microsoft, Alphabet, Dell
```

## Batch 4: Forecast Sentences + Key Quotes (all parallel)

**`pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`), fire all 4 simultaneously:

```
"Find forecast and guidance quotes for Apple across all recent earnings calls. companiesIds: [4567]. transcriptsIds: [doc_q1, doc_q2, doc_q3, doc_q4]. Topic: forecast guidance outlook expectations. speakerTypes: Executives. DLSentiment: ['positive']. size: 8"
→ "We expect continued strength in Services, with revenue growth in the mid-teens..." (Q1)
→ "We're raising our full-year EPS guidance reflecting strong iPhone demand..." (Q2)
→ "We anticipate some headwinds from FX and macro uncertainty in the December quarter..." (Q3)
→ "We're very pleased with holiday performance and raising fiscal year guidance..." (Q4)

"Find most bullish executive quotes for Apple. companiesIds: [4567]. speakerTypes: Executives. DLSentiment: ['positive']. size: 10"
"Find top risk and bearish quotes for Apple. companiesIds: [4567]. DLSentiment: ['negative']. size: 10"
"Find notable analyst questions for Apple. companiesIds: [4567]. speakerTypes: Analysts. sections: EarningsCalls_Question. size: 10"
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
```

## Phase 8: Render

Delegate to `pronto-html-renderer` (`subagent_type: prontonlp-plugin:pronto-html-renderer`):

```
report_type: company
filename: AAPL-report-20260419.html
title: "Apple Inc. (AAPL) — Intelligence Report"
subtitle: "Generated: Apr 19, 2026 · Sector: Information Technology · Market Cap: $3.2T"
data:
  meta: { ticker: "AAPL", companyId: "4567", companyName: "Apple Inc.",
          sector: "Information Technology", asOfDate: "2026-04-19" }
  kpi:  { investmentScore: 0.74, investmentScoreChange: +0.06,
          sentimentScore: 0.41, sentimentScoreChange: +0.09,
          stockChangeYTD: +12.3, stockChange6M: +18.7, stockChange1Y: +22.1 }
  quartersChart:
    quarters:        ["Q1 FY2025", "Q2 FY2025", "Q3 FY2025", "Q4 FY2025"]
    sentimentScores: [0.32, 0.38, 0.35, 0.41]
    investmentScores:[Q1_score, Q2_score, Q3_score, Q4_score]
    stockReactions:  [2.0, 4.3, -1.3, 3.5]
    positiveEvents:  [42, 51, 38, 55]
    negativeEvents:  [8, 5, 14, 6]
  quarterCards: [ { label: "Q1 FY2025", date: "2025-04-28", sentiment: 0.32,
                    sentimentArrow: "up", investment: Q1_score, investmentArrow: "flat",
                    patternPos: 42, patternNeg: 8, badge: null, isLatest: false },
                  ... ]
  stockChart: { dates: [...52 weekly dates...], prices: [...52 weekly prices...],
                earningsCallIndices: [4, 17, 30, 43] }
  peers: [ { name: "Apple",      ticker: "AAPL", return1Y: 22.1, isTarget: true },
           { name: "Microsoft",  ticker: "MSFT", return1Y: 18.3, isTarget: false },
           { name: "Alphabet",   ticker: "GOOGL", return1Y: 16.7, isTarget: false },
           { name: "Samsung",    ticker: "005930", return1Y: 12.5, isTarget: false },
           { name: "Dell",       ticker: "DELL",  return1Y: 8.9,  isTarget: false } ]
  trends: [ { name: "Apple Intelligence", score: 95, change: +45, hits: 312 },
            { name: "Vision Pro",         score: 82, change: -12, hits: 187 },
            { name: "Services Revenue",   score: 78, change: +22, hits: 241 } ]
  speakers:
    executives: [ { name: "Tim Cook",    role: "CEO", sentiment: 0.42, sentenceCount: 84 },
                  { name: "Kevan Parekh", role: "CFO", sentiment: 0.35, sentenceCount: 51 } ]
    analysts:   [ { name: "Analyst A", firm: "Goldman Sachs", sentiment: 0.65, sentenceCount: 12 },
                  { name: "Analyst B", firm: "Morgan Stanley", sentiment: 0.52, sentenceCount: 9 } ]
    gap: { execAvg: 0.37, analystAvg: 0.29, interpretation: "Executives are MORE POSITIVE than analysts by 0.08" }
  quotes: [ { text: "We expect continued strength in Services... [Source](https://acme.prontonlp.com/#/ref/$SENTID_AAPL_Q4_2025_044)",
               speakerName: "Tim Cook", role: "CEO", company: "Apple", date: "2026-01-29", section: "bull" }, ... ]
  predictions: { revenue: [...], epsGaap: [...], ebitda: [...],
                 netIncomeGaap: [...], freeCashFlow: [...], capitalExpenditure: [...] }
  risks: [ { title: "China Revenue Concentration",
              evidence: "China revenue represents approximately 20% of total revenue... [Source](https://acme.prontonlp.com/#/ref/$SENTID_AAPL_Q4_2025_112)" } ]
narrative:
  executiveSummary: "Apple sentiment is RISING — from 0.32 (Q1) to 0.41 (Q4)..."
  verdict: "Bullish — investment score rising, stock outperforming peers, CEO notably more positive than analysts."

→ Renderer writes AAPL-report-20260419.html
```

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 2 | getCompanies(companyNameOrTicker) + getCompanyPeers |
| 2 | 7 | getDocuments + getStockPrices(1Y) + getStockChange×3 + getCompanyConsensus(all metrics) + getTrends |
| 3 | 12 | getAnalytics×4 (per quarter) + getStockPrices×4 (around calls) + getSpeakers(speaker)×4 (execs/CEO/CFO/analysts) + getSpeakers(company) + getDocumentSummary(risks, all quarters in 1 call) + getStockChange×1 (all peers in 1 call) |
| 4 | 1 | pronto-search-summarizer (forecast all quarters in 1 call + bull + bear + analyst Q&A) |
| 5 | 1 | pronto-html-renderer → writes AAPL-report-20260419.html |
| **Total** | **~23** | **5 sequential batches, heavily parallelized** |
