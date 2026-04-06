---
name: pronto-compare-companies
description: "Generates a unified side-by-side comparison report for two or more named companies or tickers — scoring each across sentiment, investment score, stock performance, analyst and executive sentiment, financial forecasts, trending topics, and risk factors to determine an overall leader. Use when the user wants to compare specific named companies or tickers against each other. Triggers on phrases like: '[company] vs [company]', 'compare [company] and [company]', 'which is better [company] or [company]', 'side by side comparison of [company] and [company]', '[company] versus [company]', 'who wins between [company] and [company]'. Supports 2 to 5 companies. Do not use for a single named company — use the company intelligence skill. Do not use for sector-wide or broad market questions."
metadata:
  author: ProntoNLP
  version: 2.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Company Comparison Report Generator

Produces a self-contained side-by-side intelligence comparison of two or more named companies using ProntoNLP MCP tools directly. Collects per-quarter earnings sentiment, investment scores, stock performance, speaker sentiment, financial forecasts, trending topics, and risk factors for every company — then synthesizes all data into a single unified comparison report with scoring, charts, and a clear verdict.

---

## Output Format — Environment-Aware

**Detect the environment before rendering:**

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | HTML written to file |

### HTML rules (apply to BOTH environments — only delivery differs):
- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants — never reference external files

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named `[tickerA]-vs-[tickerB]-report.html` (e.g. `NVDA-vs-AMD-report.html`) using the `Write` tool
- After writing, tell the user the filename and open it

---

## Step 1: Parse Companies

Extract all companies from the user's request. Identify each by name or ticker. Support 2–5 companies maximum — if the user requests more than 5, ask them to narrow it down.

Assign a color per company (used consistently throughout all charts, cards, and scorecard columns):
- Company A: `#3B82F6` (blue)
- Company B: `#8B5CF6` (purple)
- Company C: `#F59E0B` (orange)
- Company D: `#14B8A6` (teal)
- Company E: `#EC4899` (pink)

---

## Step 2: Batch 1 — Foundation (fire all simultaneously, all companies at once)

For **every company in parallel**, call simultaneously:

```
getCompanyDescription(companyNameOrTicker: "<company>")
  → save: companyId, sector, subSector, description, risks[]
```

After Batch 1 completes:
- Save each company's `companyId` — required for all subsequent stock calls
- Save each company's `risks[]` — used in Section 7

---

## Step 3: Batch 2 — Core Data (fire all simultaneously, all companies at once)

For **every company in parallel**, fire all of the following at the same time:

```
getCompanyDocuments(companyName: "<name>", documentTypes: ["Earnings Calls"], limit: 4)
  → save: transcriptId[] and call dates for each earnings call (typically Q1–Q4)

getStockChange(companyId: "<id>", sinceDay: "<YTD start>", untilDay: "<today>")
  → save: YTD stock %

getStockChange(companyId: "<id>", sinceDay: "<6M ago>", untilDay: "<today>")
  → save: 6M stock %

getStockChange(companyId: "<id>", sinceDay: "<1Y ago>", untilDay: "<today>")
  → save: 1Y stock %

getPredictions(companyId: "<id>", metric: "revenue")
getPredictions(companyId: "<id>", metric: "epsGaap")
getPredictions(companyId: "<id>", metric: "ebitda")
getPredictions(companyId: "<id>", metric: "freeCashFlow")
  → save: forward consensus estimates for revenue, EPS, EBITDA, FCF

getTrends(companyName: "<name>", documentTypes: ["Earnings Calls"], sinceDay: "<1Y ago>", untilDay: "<today>", limit: 10)
  → save: top trending topics with score, hits, change %
```

After Batch 2 completes, every company has: transcriptIds, stock % changes, financial forecasts, and trending topics.

---

## Step 4: Batch 3 — Deep Analysis (fire all simultaneously, all companies at once)

For **every company in parallel**, using transcriptIds from Batch 2:

```
getAnalytics(companyName: "<name>", documentIDs: ["<Q1 transcriptId>"], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"])
  → save: sentimentScore_Q1, investmentScore_Q1, patternSentiment_Q1, top events Q1

getAnalytics(companyName: "<name>", documentIDs: ["<Q2 transcriptId>"], ...)
  → save: sentimentScore_Q2, investmentScore_Q2 ...

getAnalytics(companyName: "<name>", documentIDs: ["<Q3 transcriptId>"], ...)
  → save: sentimentScore_Q3, investmentScore_Q3 ...

getAnalytics(companyName: "<name>", documentIDs: ["<Q4 transcriptId>"], ...)
  → save: sentimentScore_Q4, investmentScore_Q4 ...

getStockPrices(companyId: "<id>", fromDate: "<7 days before Q1 call>", toDate: "<7 days after Q1 call>", interval: "day")
  → compute: stock reaction to Q1 earnings call (% change before vs after)

getStockPrices(companyId: "<id>", fromDate: "<7 days before Q2 call>", toDate: "<7 days after Q2 call>", interval: "day")
  → compute: stock reaction to Q2

getStockPrices(companyId: "<id>", fromDate: "<7 days before Q3 call>", toDate: "<7 days after Q3 call>", interval: "day")
  → compute: stock reaction to Q3

getStockPrices(companyId: "<id>", fromDate: "<7 days before Q4 call>", toDate: "<7 days after Q4 call>", interval: "day")
  → compute: stock reaction to Q4

getSpeakers(companyName: "<name>", speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
  → save: exec avg sentiment, top executive names

getSpeakers(companyName: "<name>", speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
  → save: CEO sentiment score

getSpeakers(companyName: "<name>", speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
  → save: CFO sentiment score

getSpeakers(companyName: "<name>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
  → save: analyst avg sentiment, most bullish (top 3), most bearish (bottom 3)

getSpeakerCompanies(companyName: "<name>", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → save: most bullish analyst firm, most bearish analyst firm
```

Run all of the above for all companies simultaneously — all in one parallel batch.

After Batch 3:
- Each company has: sentimentScore per quarter, investmentScore per quarter, stock reaction per quarter, exec avg, analyst avg, CEO score, CFO score, bullish/bearish analysts

---

## Step 5: Batch 4 — Quotes (fire all simultaneously, all companies at once)

For **every company in parallel**:

```
search(companyName: "<name>", sentiment: "positive", speakerTypes: ["Executives"],
  topicSearchQuery: "growth outlook guidance", size: 3, documentTypes: ["Earnings Calls"])
  → save: top 2 bullish executive quotes

search(companyName: "<name>", sentiment: "negative",
  topicSearchQuery: "risk challenge headwind", size: 3, documentTypes: ["Earnings Calls"])
  → save: top 2 risk/bearish quotes

search(companyName: "<name>", sections: ["EarningsCalls_Question"], size: 3, documentTypes: ["Earnings Calls"])
  → save: top analyst questions
```

---

## Step 6: Synthesize & Score

After all batches complete, score each company across every dimension:

| Dimension | How to determine winner |
|-----------|------------------------|
| Sentiment trend | Highest Q4 sentiment score; tiebreak: RISING direction preferred |
| Investment score | Highest Q4 investment score |
| Stock YTD | Best YTD % change |
| Earnings call reaction | Most quarters with positive stock reaction (N of M) |
| Analyst consensus | Highest analyst avg sentiment |
| Financial outlook | Best forward revenue + EPS combination |
| Exec confidence | Highest executive avg sentiment |
| Risk profile | Fewest and least severe risks from `getCompanyDescription` |

Tally wins per company. Company with most wins = **overall leader**. On a tie, the company with the higher investment score leads.

**Always compute and state explicitly:**
- Sentiment direction per company: "RISING (Q1 X.XX → Q4 X.XX)" or "FALLING"
- Investment direction per company: "RISING / FALLING"
- Stock reaction: "positive to N of M earnings calls"
- Exec vs analyst gap: compute `exec avg − analyst avg` per company
  - Gap > +0.10 → "Management more optimistic than analysts"
  - Gap < −0.10 → "Analysts more bullish than management"
- Divergence signals: flag any company with a high investment score but weak stock performance (potential undervalued signal)
- Shared topics: topics in ALL companies → macro theme. Topics unique to one company → company-specific narrative

---

## Step 7: Render the Comparison Report

Generate a single unified HTML report. On claude.ai output it inline in the chat; in Claude Cowork write it to `[tickerA]-vs-[tickerB]-report.html`.

---

### Title Block

```
[Company A] vs [Company B] [vs ...] — Comparison Report
Generated: [Date] | [N] Companies | Period: Past Year
```

---

### Section 1: Overall Scorecard

One column per company + Winner column. Every row must have an explicit winner.

**Row coloring rule:**
- 2 companies: winner cell = green (`#dcfce7` / `#15803d`), loser cell = red (`#fee2e2` / `#b91c1c`)
- 3+ companies: winner cell = green only, no red for losers

| Metric | [Co A] | [Co B] | [Co C] | Winner |
|--------|--------|--------|--------|--------|
| Sentiment Score | X.XX ↑ | X.XX ↓ | X.XX ↑ | 🏆 A |
| Investment Score | X.X | X.X | X.X | 🏆 C |
| Stock YTD | +X% | −X% | +X% | 🏆 A |
| Earnings Call Reaction | N/M | N/M | N/M | 🏆 A |
| Analyst Sentiment | X.XX | X.XX | X.XX | 🏆 B |
| Exec vs Analyst Gap | +X.XX | −X.XX | +X.XX | — |
| Revenue (fwd) | $XB | $XB | $XB | 🏆 C |
| EPS (fwd) | X.XX | X.XX | X.XX | 🏆 B |
| Risk Profile | Low | High | Medium | 🏆 A |
| **Overall Wins** | **N** | **N** | **N** | 🏆 [Leader] |

---

### Section 2: Earnings Sentiment — Quarter Over Quarter

For each company, show a quarter card row using the grid layout below. All companies stacked vertically so quarters align by position.

**Quarter card grid (one row per company, one card per quarter):**

```html
<style>
  .co-section { margin-bottom: 32px; }
  .co-label {
    font-size: 13px; font-weight: 700; color: var(--color-text-secondary);
    margin-bottom: 12px; display: flex; align-items: center; gap: 8px;
  }
  .co-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
  .qtr-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 14px;
  }
  .qtr-card {
    border: 2px solid transparent;
    border-radius: var(--border-radius-md);
    padding: 14px;
    background: var(--color-background-primary);
  }
  .qtr-card.leader { border-color: #1D9E75; }
  .qtr-header { font-size: 11px; font-weight: 600; color: var(--color-text-tertiary); margin-bottom: 10px; }
  .qtr-metric { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 5px; }
  .qtr-metric .label { color: var(--color-text-secondary); }
  .qtr-metric .value { font-weight: 600; color: var(--color-text-primary); }
  .up { color: #1D9E75; } .down { color: #D85A30; }
</style>

<!-- Company A -->
<div class="co-section">
  <div class="co-label">
    <span class="co-dot" style="background:#3B82F6"></span> NVDA
  </div>
  <div class="qtr-grid">
    <div class="qtr-card">
      <div class="qtr-header">Q1 · Apr 2025</div>
      <div class="qtr-metric"><span class="label">Sentiment</span><span class="value">X.XX</span></div>
      <div class="qtr-metric"><span class="label">Investment</span><span class="value">X.X</span></div>
      <div class="qtr-metric"><span class="label">Stock Reaction</span><span class="value up">+X%</span></div>
    </div>
    <!-- repeat for Q2, Q3, Q4 -->
  </div>
</div>
<!-- repeat co-section for each additional company -->
```

After the cards, include a **comparison callout**:
> 📊 Sentiment comparison: [Company A] is **RISING** (Q1 → Q4), [Company B] is **FALLING** — diverging trajectories.

Place **Chart 3** (multi-line sentiment trend) and **Chart 4** (multi-line investment trend) here.

---

### Section 3: Stock Performance

Chart 1 — Grouped bar: YTD / 6M / 1Y for all companies (one group per period, one bar per company, colored by company color).

Table below the chart:

| Period | [Co A] | [Co B] | [Co C] | Leader |
|--------|--------|--------|--------|--------|
| YTD | +X% | −X% | +X% | 🏆 A |
| 6 Months | +X% | +X% | −X% | 🏆 B |
| 1 Year | +X% | −X% | +X% | 🏆 A |

---

### Section 4: Financial Outlook

Table: forward consensus estimates side by side. Highlight the highest value per row in green.

| Metric | [Co A] | [Co B] | [Co C] | Leader |
|--------|--------|--------|--------|--------|
| Revenue (fwd) | $XB | $XB | $XB | 🏆 |
| EPS GAAP (fwd) | X.XX | X.XX | X.XX | 🏆 |
| EBITDA (fwd) | $XB | $XB | $XB | 🏆 |
| FCF (fwd) | $XB | $XB | $XB | 🏆 |

---

### Section 5: Analyst & Executive Sentiment

Chart 2 — Grouped bar: CEO / CFO / Exec avg / Analyst avg per company.

**Gap table:**

| Company | Exec Avg | Analyst Avg | Gap | Signal |
|---------|----------|-------------|-----|--------|
| [Co A] | X.XX | X.XX | +X.XX | Management more optimistic |
| [Co B] | X.XX | X.XX | −X.XX | Street more bullish |

**Most bullish analyst** per company: [Name], [Firm] (X.XX)
**Most bearish analyst** per company: [Name], [Firm] (X.XX)

---

### Section 6: Trending Topics — Overlap & Divergence

Three-column layout:

| Shared by all | [Co A] only | [Co B] only |
|---------------|------------|------------|
| Topic X | Topic Y | Topic Z |

Shared topics → label as **"Macro theme"**
Unique topics → label as **"[Company] narrative"**
Risk topics present in 2+ companies → label as **"Systemic sector risk"**

---

### Section 7: Risk Comparison

Table with ✅ (present) / — (not present) per company per risk:

| Risk | [Co A] | [Co B] | [Co C] | Type |
|------|--------|--------|--------|------|
| [Risk name] | ✅ | ✅ | — | Systemic |
| [Risk name] | — | ✅ | — | Idiosyncratic |

---

### Section 8: Verdict

4 concise paragraphs:
1. **Overall leader** — which company wins most dimensions and why
2. **Most undervalued signal** — which company has a high investment score relative to weak stock performance (if any)
3. **Highest risk** — which company carries the most idiosyncratic risk
4. **Bottom line** — "If you had to pick one: [Company] — because..."

---

## Charts Reference

| Chart | Section | Type | Data |
|-------|---------|------|------|
| Chart 1 | Section 3 | Grouped bar | Stock % change (YTD/6M/1Y) per company |
| Chart 2 | Section 5 | Grouped bar | CEO / CFO / Exec avg / Analyst avg per company |
| Chart 3 | Section 2 | Multi-line | Sentiment score Q1–Q4 per company (one line per company, company color) |
| Chart 4 | Section 2 | Multi-line | Investment score Q1–Q4 per company |

Load Chart.js once at the top of the HTML. All data as inline JS constants.

---

## Date Handling

| Scope | sinceDay | untilDay |
|-------|----------|----------|
| Default (past year) | 1 year ago | today |
| "past quarter" | 90 days ago | today |
| "past 6 months" | 6 months ago | today |
| YTD | Jan 1 current year | today |

`getAnalytics` max date range: 1 year. Always pass `documentIDs` per quarter for per-quarter analysis.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Company not found by `getCompanyDescription` | Try ticker instead of name; note and continue with remaining companies |
| Fewer than 4 quarters returned | Show available quarters only; note the gap in cards |
| No predictions for a metric | Show "N/A" in that cell |
| No analyst data | Show "N/A" for analyst rows; do not skip the row |
| No quotes from `search` | State "No matching quotes found" — never fabricate |
| More than 5 companies requested | Ask user to narrow down to 5 or fewer |
| Different fiscal year calendars | Note mismatch; compare on TTM basis where possible |

---

## Best Practices

1. **Detect environment first** — inline HTML on claude.ai (`Bash` not available), HTML written to `[tickerA]-vs-[tickerB]-report.html` in Claude Cowork (`Bash` available)
2. Save each company's `companyId` immediately after Batch 1 — it is required for all stock calls
3. Fire all companies' calls simultaneously within each batch — never process one company at a time
4. Always produce an explicit winner per scorecard row — never leave a row blank
5. Surface divergences — a company strong on sentiment but weak on stock, or high investment score with falling stock, is the most interesting insight
6. Never fabricate data — missing metric = "N/A", never an invented number
7. Use company color consistently across all charts, cards, and scorecard column headers
8. Do not mention tool names in the report — describe actions instead

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Exact metrics to capture per company, scoring matrix, cross-company topic comparison logic, enum reference |
| `reference/report-template-guide.md` | HTML layout guide — company colors, scorecard coloring rules, section-by-section structure, chart placement, formatting rules |
| `examples/nvda-vs-amd.md` | Full worked example: NVDA vs AMD — all batches, captured metrics, scoring matrix, topic overlap, report structure |
| `evaluations/criteria.md` | Evaluation rubric — triggering, data collection, scoring, HTML structure, visual design, formatting, error handling |
| `evals/evals.json` | Structured test cases with assertions |
