# Example: Top Movers / Investment Opportunities — "What stocks are worth watching this week?"

Workflow showing getTopMovers → getCompanyDescription → optional search.

---

## Batch 1: Get Movers

```
Tool: getTopMovers
Params: {
  sinceDay: "2026-03-19",
  untilDay: "2026-03-26"
}
→ {
    overperforming: [
      { id: "4567", ticker: "NVDA", investmentScore: 8.4, investmentScoreChange: +1.2, sentimentScore: 0.71, stockChange: +9.3% },
      { id: "7890", ticker: "META", investmentScore: 7.9, investmentScoreChange: +0.8, sentimentScore: 0.65, stockChange: +6.1% },
      { id: "1234", ticker: "AMZN", investmentScore: 7.5, investmentScoreChange: +0.6, sentimentScore: 0.58, stockChange: +4.8% },
      ...
    ],
    underperforming: [
      { id: "2345", ticker: "INTC", investmentScore: 4.2, investmentScoreChange: -1.5, sentimentScore: 0.21, stockChange: -7.4% },
      { id: "3456", ticker: "BA",   investmentScore: 3.9, investmentScoreChange: -1.1, sentimentScore: 0.18, stockChange: -5.2% },
      ...
    ],
    topMovers: [
      { id: "5678", ticker: "TSLA", investmentScoreChange: +2.1, stockChange: +11.2% },
      ...
    ]
  }
```

---

## Batch 2: Company Descriptions (top 12 most relevant — parallel)

```
Tool: getCompanyDescription × 12
Params: { companyNameOrTicker: "NVDA" }   → companyId: "4567", sector: "Information Technology", description: "..."
Params: { companyNameOrTicker: "META" }   → companyId: "7890", ...
Params: { companyNameOrTicker: "AMZN" }  → companyId: "1234", ...
Params: { companyNameOrTicker: "TSLA" }  → companyId: "5678", ...
Params: { companyNameOrTicker: "INTC" }  → companyId: "2345", ...
Params: { companyNameOrTicker: "BA" }    → companyId: "3456", ...
... (6 more)
```

---

## Batch 3 (optional): Recent Context

```
Tool: search
Params: {
  companyIDs: ["4567", "5678"],   ← top movers only
  sentiment: "positive",
  size: 10,
  sinceDay: "2026-03-19",
  untilDay: "2026-03-26"
}
→ { id: "$SENTID654321-112", text: "We're seeing accelerating data center demand driven by AI inference workloads...", companyId: "4567" }
   { id: "$SENTID765432-223", text: "Energy storage deployments are ahead of plan and we're raising full-year delivery guidance...", companyId: "5678" }
```

---

## Compile: Response

**IMPORTANT formatting rules:**
- Add empty markdown link with company `id` immediately after each name: `NVDA [](4567)`
- Use "worth monitoring", "potential buying opportunities", "potential sell signals" — NOT "hot", "underperforming", "overperforming"

```markdown
## Stocks Worth Watching This Week

### Potential Buying Opportunities

**NVIDIA [](4567)** — Investment score 8.4 (+1.2 this week), stock +9.3%.
NVIDIA designs accelerated computing platforms for AI and data center workloads.
Management highlighted "accelerating data center demand driven by AI inference workloads" ([1][1]).

**Meta Platforms [](7890)** — Investment score 7.9 (+0.8), stock +6.1%.
Meta operates the world's largest social platforms and is investing heavily in AI infrastructure.

**Amazon [](1234)** — Investment score 7.5 (+0.6), stock +4.8%.
Amazon's AWS segment continues to drive cloud infrastructure growth.

---

### Potential Sell Signals

**Intel [](2345)** — Investment score 4.2 (−1.5 this week), stock −7.4%.
Intel designs and manufactures semiconductors; facing foundry execution challenges and market share pressure.

**Boeing [](3456)** — Investment score 3.9 (−1.1), stock −5.2%.
Boeing manufactures commercial and defense aircraft; production ramp challenges persist.

---

### Top Movers

**Tesla [](5678)** — Largest investment score change this week (+2.1), stock +11.2%.
Tesla designs electric vehicles and energy storage. Management noted energy storage deployments
are "ahead of plan" with raised delivery guidance ([2][2]).

[1]: https://dev.prontonlp.com/#/ref/$SENTID654321-112
[2]: https://dev.prontonlp.com/#/ref/$SENTID765432-223
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | getTopMovers |
| 2 | 12 | getCompanyDescription × 12 (parallel) |
| 3 | 1 | search (top movers only, optional) |
| **Total** | **14** | **3 sequential batches** |
