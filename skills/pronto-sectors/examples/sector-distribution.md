# Example: Sector Distribution — "Show AI sentiment across sectors"

Workflow showing searchSectors → searchTopCompanies for sector-level distribution.

---

## Batch 1: Sector-Level Distribution

```
Tool: searchSectors
Params: {
  searchQueries: ["artificial intelligence", "AI", "generative AI"],
  sinceDay: "2025-09-26",
  untilDay: "2026-03-26"
}
→ sectors:
    { name: "Information Technology", sentimentScore: 0.72, mentionCount: 4820 }
    { name: "Communication Services", sentimentScore: 0.65, mentionCount: 2140 }
    { name: "Health Care",            sentimentScore: 0.58, mentionCount: 1380 }
    { name: "Financials",             sentimentScore: 0.51, mentionCount: 980 }
    { name: "Consumer Discretionary", sentimentScore: 0.47, mentionCount: 760 }
    { name: "Industrials",            sentimentScore: 0.44, mentionCount: 510 }
    { name: "Energy",                 sentimentScore: 0.38, mentionCount: 290 }
```

---

## Batch 2: Top Companies Per Top Sector (parallel)

```
Tool: searchTopCompanies (Information Technology)
Params: {
  searchQueries: ["artificial intelligence"],
  sectors: ["Information Technology"],
  sinceDay: "2025-09-26",
  untilDay: "2026-03-26",
  limit: 5
}
→ [
    { companyId: "4567", name: "NVIDIA", sentiment: 0.89 },
    { companyId: "1234", name: "Microsoft", sentiment: 0.81 },
    { companyId: "5678", name: "Alphabet", sentiment: 0.76 }
  ]

Tool: searchTopCompanies (Communication Services)
Params: { sectors: ["Communication Services"], ... }
→ [
    { companyId: "7890", name: "Meta Platforms", sentiment: 0.78 },
    { companyId: "2345", name: "Netflix", sentiment: 0.61 }
  ]
```

---

## Compile: Response

```markdown
## AI Sentiment Across Sectors

**Sector Rankings — AI Sentiment**

| Sector | Sentiment Score | Mention Count |
|--------|----------------|---------------|
| Information Technology | 0.72 | 4,820 |
| Communication Services | 0.65 | 2,140 |
| Health Care | 0.58 | 1,380 |
| Financials | 0.51 | 980 |
| Consumer Discretionary | 0.47 | 760 |
| Industrials | 0.44 | 510 |
| Energy | 0.38 | 290 |

**Tech leads by a wide margin** — Information Technology companies not only discuss AI
most (4,820 mentions), but also with the highest positivity (0.72). NVIDIA and
Microsoft dominate within the sector.

**Health Care is a rising theme** — 1,380 mentions at 0.58 sentiment, driven by drug
discovery and diagnostics applications.

**Energy sector is cautious** — fewest mentions and lowest positivity, suggesting AI
is seen more as an operational tool than a growth driver in energy companies.
```

---

## Batch 3: Generate Charts

After all data is collected, write the HTML charts file:

```
Write file: /tmp/sectors-charts.html
Copy assets/charts-template.html and populate:

  sectorNames      = ['Information Technology', 'Communication Services', 'Health Care', ...]
  sectorSentiments = [0.72, 0.65, 0.58, 0.51, 0.47, 0.44, 0.38]
  sectorMentions   = [4820, 2140, 1380, 980, 760, 510, 290]
  companyNames     = ['NVIDIA', 'Microsoft', 'Alphabet', 'Meta Platforms', 'Netflix']
  companySentiments= [0.89, 0.81, 0.76, 0.78, 0.61]
  eventTypes       = []   ← leave empty if getAnalytics was not called
  eventCounts      = []
```

Then open it:
```
open /tmp/sectors-charts.html
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | searchSectors → sector distribution |
| 2 | 2 | searchTopCompanies per top sector (parallel) |
| 3 | 1 | Write HTML charts file |
| **Total** | **4** | **3 sequential batches** |
