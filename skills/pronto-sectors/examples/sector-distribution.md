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

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | searchSectors → sector distribution |
| 2 | 2 | searchTopCompanies per top sector (parallel) |
| **Total** | **3** | **2 sequential batches** |
