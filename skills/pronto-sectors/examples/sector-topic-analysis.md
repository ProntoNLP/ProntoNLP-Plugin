# Example: Sector / Topic Analysis — "Which companies talked about tariffs most positively?"

Full workflow showing getAnalytics → searchTopCompanies → search chaining.

---

## Batch 1: Identify Event Types

```
Tool: getAnalytics
Params: {
  searchQueries: ["tariff"],
  documentTypes: ["Earnings Calls", "Guidance/Update Calls"],
  sinceDay: "2025-12-26",
  untilDay: "2026-03-26"
}
→ eventTypes:
    { id: "FinancialPerformance", score: 0.52, totalPositives: 8500, totalNegatives: 2900 }
    { id: "Operations",           score: 0.63, totalPositives: 2400, totalNegatives: 450 }
    { id: "Forecast",             score: 0.57, totalPositives: 5000, totalNegatives: 1200 }
→ aspects:
    { id: "Supply Chain", score: 0.48 }
    { id: "Pricing",      score: 0.55 }
```

---

## Batch 2: Top Companies Per Event (one call per event type — all parallel)

```
Tool: searchTopCompanies (FinancialPerformance)
Params: {
  searchQueries: ["tariff"],
  eventTypes: ["FinancialPerformance"],
  documentTypes: ["Earnings Calls", "Guidance/Update Calls"],
  sinceDay: "2025-12-26",
  untilDay: "2026-03-26"
}
→ [
    { companyId: "$COMPANY-101", name: "Company A", sentiment: 0.88 },
    { companyId: "$COMPANY-102", name: "Company B", sentiment: 0.81 },
    { companyId: "$COMPANY-103", name: "Company C", sentiment: 0.74 }
  ]

Tool: searchTopCompanies (Operations)
Params: {
  searchQueries: ["tariff"],
  eventTypes: ["Operations"],
  ...same date range...
}
→ [
    { companyId: "$COMPANY-201", name: "Company D", sentiment: 0.92 },
    { companyId: "$COMPANY-202", name: "Company E", sentiment: 0.77 }
  ]
```

---

## Batch 3: Supporting Quotes

```
Tool: search
Params: {
  companyIDs: ["$COMPANY-101", "$COMPANY-102", "$COMPANY-103", "$COMPANY-201", "$COMPANY-202"],
  searchQuery: "tariff",
  eventTypes: ["FinancialPerformance", "Operations"],
  sentiment: "positive",
  size: 20,
  sinceDay: "2025-12-26",
  untilDay: "2026-03-26"
}
→ results:
    { id: "$SENTID387267-890", text: "We've actually seen tariff exposure as a competitive advantage — our domestic sourcing insulates us...", companyId: "$COMPANY-101" }
    { id: "$SENTID498276-327", text: "Our supply chain restructuring completed last year means tariffs have a near-zero net impact on margins...", companyId: "$COMPANY-202" }
    { id: "$SENTID512834-001", text: "We've been able to pass through tariff costs efficiently with minimal demand impact so far...", companyId: "$COMPANY-102" }
```

If fewer than 30 relevant results → re-run with `deepSearch: true`.

---

## Compile: Response

```markdown
## Companies Discussing Tariffs Most Positively

Based on analysis of earnings calls and guidance updates over the past 90 days,
the following companies showed the most positive sentiment around tariff-related topics:

**Sentiment Rankings**

| Company | Sentiment | Event Context |
|---------|-----------|---------------|
| Company D | 0.92 | Operations |
| Company A | 0.88 | Financial Performance |
| Company B | 0.81 | Financial Performance |
| Company E | 0.77 | Operations |
| Company C | 0.74 | Financial Performance |

**Company A** demonstrated strong tariff resilience, noting that domestic
sourcing "insulates" them from exposure ([1][1]).

**Company E** highlighted supply chain restructuring as a buffer, with tariffs having
"near-zero net impact on margins" ([2][2]).

**Company B** stood out for its proactive pricing strategy, with management noting
they've been able to "pass through tariff costs efficiently with minimal demand
impact" ([3][3]).

[1]: https://dev.prontonlp.com/#/ref/$SENTID387267-890
[2]: https://dev.prontonlp.com/#/ref/$SENTID498276-327
[3]: https://dev.prontonlp.com/#/ref/$SENTID512834-001
```

---

## Batch 4: Generate Charts

After all data is collected, write the HTML charts file:

```
Write file: /tmp/sectors-charts.html
Copy assets/charts-template.html and populate:

  sectorNames      = []    ← leave empty (searchSectors not called in this flow)
  sectorSentiments = []
  sectorMentions   = []
  companyNames     = ['Company D', 'Company A', 'Company B', 'Company E', 'Company C']
  companySentiments= [0.92, 0.88, 0.81, 0.77, 0.74]
  eventTypes       = ['FinancialPerformance', 'Operations', 'Forecast']
  eventCounts      = [8500, 2400, 5000]   ← totalPositives from getAnalytics
```

Then open it:
```
open /tmp/sectors-charts.html
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | getAnalytics → event types + aspects |
| 2 | 2 | searchTopCompanies per event type (parallel) |
| 3 | 1 | search → supporting quotes |
| 4 | 1 | Write HTML charts file |
| **Total** | **5** | **4 sequential batches** |
