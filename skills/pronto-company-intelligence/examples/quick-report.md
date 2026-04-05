# Example: Quick Report — Tesla Inc. (TSLA)

Abbreviated workflow — Sections 1-3 only, minimal tool calls, fast turnaround.

---

## Batch 1: Foundation
```
Tool: Pronto:getCompanyDescription
Params: { companyNameOrTicker: "TSLA" }
→ Response:
    companyId: "7890"          ← SAVED
    name: "Tesla, Inc."
    sector: "Consumer Discretionary"
    subSector: "Automobiles"
    description: "..."
    risks: [...]
```

## Batch 2: Stock + Financials + Quick Sentiment (all parallel, using companyId "7890")
```
Tool: Pronto:getStockPrices
Params: { companyId: "7890", fromDate: "2025-03-03", toDate: "2026-03-03", interval: "week" }

Tool: Pronto:getStockChange (YTD)
Params: { companyId: "7890", fromDate: "2026-01-01", toDate: "2026-03-03" }

Tool: Pronto:getStockChange (6M)
Params: { companyId: "7890", fromDate: "2025-09-03", toDate: "2026-03-03" }

Tool: Pronto:getStockChange (1Y)
Params: { companyId: "7890", fromDate: "2025-03-03", toDate: "2026-03-03" }

Tool: Pronto:getPredictions x6 (all parallel, using companyId "7890")
  { companyId: "7890", metric: "revenue", untilDate: "2026-03-03" }
  { companyId: "7890", metric: "epsGaap", untilDate: "2026-03-03" }
  { companyId: "7890", metric: "ebitda", untilDate: "2026-03-03" }
  { companyId: "7890", metric: "netIncomeGaap", untilDate: "2026-03-03" }
  { companyId: "7890", metric: "freeCashFlow", untilDate: "2026-03-03" }
  { companyId: "7890", metric: "capitalExpenditure", untilDate: "2026-03-03" }

Tool: Pronto:getAnalytics (scores only — quick headline)
Params: {
  companyName: "Tesla",
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-03-03",
  untilDay: "2026-03-03",
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
| 1 | 1 | getCompanyDescription → companyId |
| 2 | 11 | stock prices + 3 stock changes + 6 predictions + analytics (scores only) |
| **Total** | **~12** | **2 sequential batches** |
