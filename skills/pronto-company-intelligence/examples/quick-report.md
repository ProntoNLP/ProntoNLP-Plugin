# Example: Quick Report — Tesla Inc. (TSLA)

Abbreviated workflow — Sections 1-3 only, minimal tool calls, fast turnaround.

---

## Batch 1: Foundation
```
Tool: getCompanies
Params: { companyNameOrTicker: "TSLA" }
→ Response:
    id: "7890"   (save as companyId)   ← SAVED
    name: "Tesla, Inc."
    sector: "Consumer Discretionary"
    description_text: "..."
```

## Batch 2: Stock + Financials + Quick Sentiment (all parallel, using companiesIds: ["7890"])
```
Tool: getStockPrices
Params: { companiesIds: ["7890"], dateRange: { gte: "now-1y/d", lte: "now" }, interval: "week" }

Tool: getStockChange (YTD)
Params: { companiesIds: ["7890"], dateRange: { gte: "2026-01-01", lte: "now" } }

Tool: getStockChange (6M)
Params: { companiesIds: ["7890"], dateRange: { gte: "now-6M/d", lte: "now" } }

Tool: getStockChange (1Y)
Params: { companiesIds: ["7890"], dateRange: { gte: "now-1y/d", lte: "now" } }

Tool: getCompanyConsensus (1 call — all metrics at once)
Params: { companiesIds: ["7890"], metrics: ["revenue", "epsGaap", "ebitda", "netIncomeGaap", "freeCashFlow", "capitalExpenditure"], timeframeInterval: "quarter" }

Tool: getAnalytics (scores only — quick headline)
Params: {
  companiesIds: ["7890"],
  documentTypes: ["Earnings Calls"],
  dateRange: { gte: "now-1y/d", lte: "now" },
  analyticsType: ["scores", "patternSentiment"]
}
→ { sentimentScore: 0.28, investmentScore: [X.X — raw value from API], patternSentiment: "Positive" }
```

## Compile: Quick Report

```markdown
# Tesla, Inc. (TSLA) — Quick Intelligence Report
**Generated**: March 3, 2026
**Sector**: Consumer Discretionary-Automobiles | **Market Cap**: $XT
**Pronto Company ID**: 7890

---

## Executive Summary
[1 paragraph: what Tesla does + stock performance + sentiment score headline]

---

## Stock Performance
| Timeframe | TSLA |
|-----------|------|
| YTD       | +X%  |
| 6-Month   | +X%  |
| 1-Year    | +X%  |

---

## Financial Outlook
| Metric         | FY24A | FY25A | FY26E | FY27E |
|----------------|-------|-------|-------|-------|
| Revenue ($B)   |       |       |       |       |
| EPS (GAAP)     |       |       |       |       |
| EBITDA ($B)    |       |       |       |       |
| Net Income ($B)|       |       |       |       |
| FCF ($B)       |       |       |       |       |
| CapEx ($B)     |       |       |       |       |

---

## Sentiment Snapshot
- **Sentiment Score**: 0.28
- **Investment Score**: [raw value from API]
- **Pattern Sentiment**: Positive
```

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | getCompanies(companyNameOrTicker) → companyId |
| 2 | 6 | getStockPrices + getStockChange×3 + getCompanyConsensus(all metrics) + getAnalytics(scores) |
| **Total** | **~7** | **2 sequential batches** |
