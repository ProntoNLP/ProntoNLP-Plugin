# Example: Top Movers — "What stocks are worth watching this week? Show me by investment score change and sentiment score change."

Full workflow showing multi-sort getTopMovers → getCompanyDescription → optional search.

---

## Batch 1: Get Movers (two independent ranked lists in one call)

```
Tool: getTopMovers
Params: {
  sinceDay: "2026-03-19",
  untilDay: "2026-03-26",
  sortBy: ["investmentScoreChange", "sentimentScoreChange"]
}
→ {
    "investmentScoreChange": {
      topMovers: [
        { id: "5678", ticker: "TSLA", investmentScore: 7.2, investmentScoreChange: +2.1, sentimentScore: 0.61, sentimentScoreChange: +0.18, stockChange: +11.2% },
        { id: "4567", ticker: "NVDA", investmentScore: 8.4, investmentScoreChange: +1.2, sentimentScore: 0.71, sentimentScoreChange: +0.09, stockChange: +9.3% },
        ...
      ],
      underperforming: [
        { id: "2345", ticker: "INTC", investmentScore: 4.2, investmentScoreChange: -1.5, sentimentScore: 0.21, stockChange: -7.4% },
        ...
      ],
      overperforming: [
        { id: "7890", ticker: "META", investmentScore: 3.1, investmentScoreChange: +0.4, sentimentScore: 0.65, stockChange: +6.1% },
        ...
      ]
    },
    "sentimentScoreChange": {
      topMovers: [
        { id: "1234", ticker: "AMZN", investmentScore: 7.5, sentimentScore: 0.58, sentimentScoreChange: +0.31, stockChange: +4.8% },
        { id: "5678", ticker: "TSLA", sentimentScoreChange: +0.18, stockChange: +11.2% },
        ...
      ],
      underperforming: [...],
      overperforming: [...]
    }
  }
```

**sortBy values and when to use each:**

| sortBy | What it ranks | Best for |
|--------|--------------|----------|
| `investmentScoreChange` | Change in investment score vs prior period | Finding companies whose investment strength is improving or deteriorating most |
| `sentimentScoreChange` | Change in management sentiment vs prior period | Finding companies where tone has shifted most — positive or negative |
| `investmentScore` | Current normalized investment score (0–10) | Finding companies with the strongest investment case right now |
| `sentimentScore` | Current sentiment score (-1 to +1) | Finding companies with the most positive or negative management tone |
| `stockChange` | Stock price % change over date range | Pure price momentum — biggest movers in the market |
| `aspectScore` | Raw aspect score from latest document | Raw investment signal before normalization |
| `marketcap` | Market cap descending | Largest companies first (default if no sortBy given) |

---

## Batch 2: Company Descriptions (top companies from both lists — parallel)

```
Tool: getCompanyDescription × 10
Params: { companyNameOrTicker: "TSLA" }  → companyId: "5678", sector: "Consumer Discretionary", description: "..."
Params: { companyNameOrTicker: "NVDA" }  → companyId: "4567", sector: "Information Technology", description: "..."
Params: { companyNameOrTicker: "AMZN" }  → companyId: "1234", sector: "Consumer Discretionary", description: "..."
Params: { companyNameOrTicker: "META" }  → companyId: "7890", sector: "Communication Services", description: "..."
Params: { companyNameOrTicker: "INTC" }  → companyId: "2345", sector: "Information Technology", description: "..."
... (5 more from remaining positions)
```

Deduplicate across lists — if the same company appears in both `investmentScoreChange` and `sentimentScoreChange` lists, call `getCompanyDescription` only once.

---

## Batch 3 (optional): Recent Context for Top Movers

```
Tool: search
Params: {
  companyIDs: ["5678", "4567"],   ← top 2 from investmentScoreChange topMovers
  sentiment: "positive",
  size: 10,
  sinceDay: "2026-03-19",
  untilDay: "2026-03-26"
}
→ { id: "$SENTID654321-112", text: "Energy storage deployments are ahead of plan and we're raising full-year delivery guidance...", companyId: "5678" }
   { id: "$SENTID765432-223", text: "We're seeing accelerating data center demand driven by AI inference workloads...", companyId: "4567" }
```

---

## Compile: Response

**IMPORTANT formatting rules:**
- Add empty markdown link with company `id` immediately after each name: `NVDA [](4567)`
- Use "worth monitoring", "potential buying opportunities", "potential sell signals" — NOT "hot", "underperforming", "overperforming"
- Present each sortBy list as a separate section

```markdown
## Stocks Worth Watching This Week

### Ranked by Investment Score Change

**Tesla [](5678)** — Investment score improved most this week (+2.1 → now 7.2), stock +11.2%.
Tesla designs electric vehicles and energy storage systems. Management stated energy storage deployments
are "ahead of plan" with raised delivery guidance ([1][1]).

**NVIDIA [](4567)** — Investment score +1.2 this week (now 8.4), stock +9.3%.
NVIDIA leads in accelerated computing for AI and data centers. Management cited
"accelerating data center demand driven by AI inference workloads" ([2][2]).

---

### Ranked by Sentiment Score Change

**Amazon [](1234)** — Largest sentiment improvement this week (+0.31 → now 0.58), stock +4.8%.
Amazon operates AWS (cloud), e-commerce, and advertising. Management tone shifted
notably positive on AWS margin expansion.

**Tesla [](5678)** — Also top 2 by sentiment change (+0.18), consistent with investment score improvement.

---

### Potential Buying Opportunities
*(Falling stock + high investment score — may be oversold)*

**Intel [](2345)** — Investment score 4.2 (−1.5 this week), stock −7.4%.
Intel designs and manufactures semiconductors; facing foundry execution challenges.

---

### Potential Sell Signals
*(Rising stock + low/declining investment score — may be overbought)*

**Meta Platforms [](7890)** — Investment score only 3.1 despite stock +6.1%.
Meta operates social platforms and is investing heavily in AI infrastructure.
The gap between stock performance and investment score warrants caution.

[1]: https://dev.prontonlp.com/#/ref/$SENTID654321-112
[2]: https://dev.prontonlp.com/#/ref/$SENTID765432-223
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | getTopMovers (sortBy: 2 criteria → 2 independent ranked lists) |
| 2 | 10 | getCompanyDescription × 10 (parallel, deduplicated across lists) |
| 3 | 1 | search (top movers only, optional) |
| **Total** | **12** | **3 sequential batches** |
