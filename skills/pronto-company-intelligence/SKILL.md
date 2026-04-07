---
name: pronto-company-intelligence
description: "Generates a full intelligence report for a single named company or ticker — covering earnings sentiment, investment score, stock performance, analyst and executive sentiment, trending topics, risk factors, and financial forecasts. Use when the user mentions one specific company name or ticker and asks about analysis, earnings, sentiment, financials, investment potential, stock performance, risks, or analyst opinions for that company. Triggers on phrases like: 'how is [company] doing', 'analyze [ticker]', '[company] earnings', 'should I buy [company]', 'what do analysts say about [company]', 'deep dive on [company]', '[company] sentiment', '[company] risks', '[ticker] outlook', 'give me a report on [company]'. Do not use when the user asks to compare two or more companies — use the compare-companies skill instead. Do not use for broad market overviews or sector-wide questions."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Company Intelligence Report Generator

> ⚠️ **OUTPUT RULE — READ FIRST:**
> Before rendering, detect the environment: if the `Bash` tool is available in this session, write the report as an **HTML file** (Claude Cowork). If `Bash` is NOT available, output as **inline HTML** rendered directly in the chat (claude.ai). Same HTML format either way — the only difference is inline vs written to file.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, `deepResearch`, or any interactive visualization tool from this skill. These are user-triggered only. Only call the tools explicitly listed in the batches below.

Produces company intelligence reports using ProntoNLP tools. The centerpiece is a **quarter-over-quarter comparison of every earnings call in the past year** — explicitly showing whether sentiment, investment scores, and stock price reaction are RISING or FALLING. Layered on top: analyst forecasts, competitive benchmarks, trending topics, management quotes, and risk factors.

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
- **Value coloring rule — applies to every numeric value, score, and % change rendered in the report:**
  - Value **> 0** (positive sentiment, positive stock change, positive delta): text color `#1D9E75` (green)
  - Value **< 0** (negative sentiment, negative stock change, negative delta): text color `#D85A30` (red)
  - Value **= 0**: no color — use default inherited text color
- **Score display rule:** Investment scores and sentiment scores are raw API values in the **0.0–1.0 range**. Display them exactly as returned — never multiply, never append "/10", never reformat as a fraction. Example: show `0.71`, not `7.1` or `7.1/10`. `sentimentScoreChange` and `investmentScoreChange` are percentage changes — always display with a `%` suffix (e.g. `+4.2%`, `-1.8%`). Any negative number or negative percentage (value < 0) **must** render in red `#D85A30` — this includes stock changes, score changes, deltas, and any other numeric field with a minus sign.
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants — never reference external files
- Clean layout: styled cards, HTML tables, badges, section headers

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named `[ticker]-report.html` (e.g. `NVDA-report.html`) using the `Write` tool
- After writing, tell the user the filename and open it

---

## Step 0: Choose Your Report Mode

Before making any tool calls, decide which template fits the user's request:

| Mode | Use when | Tool calls | Sections |
|------|----------|------------|---------|
| **Full Report** (default) | Deep dive, no specific focus | ~40 | All 11 |
| **Quick Report** | "quick", "overview", "brief" | ~13 | 1–3 |
| **Sentiment Report** | Earnings/sentiment focus | ~25 | 1, 4–7 |
| **Competitive Report** | Competitor/peer focus | ~15 | 1–2, 9 |
| **Risk Assessment** | Downside/risks focus | ~20 | 1, 4, 7, 9–10 |

See `reference/report-template-guide.md` for the batch plan of each template. Default to **Full Report** unless the user explicitly signals a narrower scope.

---

## Tools Reference

| # | Tool | Purpose | Company param |
|---|------|---------|---------------|
| 1 | `getCompanyDescription` | Overview, risks, predictions | `companyNameOrTicker` |
| 2 | `getCompanyCompetitors` | Competitor list | `companyNameOrTicker` |
| 3 | `getCompanyDocuments` | Earnings calls, 10-K, 10-Q | `companyName` |
| 4 | `getStockPrices` | Historical price series | `companyId` |
| 5 | `getStockChange` | Price % change over period | `companyId` |
| 6 | `getPredictions` | Analyst consensus estimates | `companyId` |
| 7 | `getAnalytics` | Sentiment scores, events, aspects | `companyName` |
| 8 | `getTrends` | Trending topics | `companyName` |
| 9 | `getSpeakers` | Per-executive/analyst sentiment | `companyName` |
| 10 | `getSpeakerCompanies` | Analyst firm sentiment | `companyName` |
| 11 | `search` | Key quotes from filings | `companyName` or `companyIDs` |

### ID Flow (critical)

IDs must be extracted and passed between tools. See `reference/tool-cheatsheet.md` for the full diagram. Summary:

- `getCompanyDescription` → yields `companyId` → pass to `getStockPrices`, `getStockChange`, `getPredictions`
- `getCompanyCompetitors` → yields competitor `companyId` list → pass to `getStockChange` (per competitor)
- `getCompanyDocuments` → yields `transcriptId` per document → pass to `getAnalytics` (per quarter), `search` (per quarter)

When a tool accepts both `companyName` and `companyId`, prefer `companyId` for precision.

---

## Parallel Execution — Full Report

Run each batch in sequence; within a batch, fire all calls simultaneously.

**Batch 1** — foundation (no dependencies):
```
getCompanyDescription    → save companyId, sector, risks
getCompanyCompetitors    → save competitor companyIds[]
```

**Batch 2** — data collection (needs companyId):
```
getCompanyDocuments      → save transcriptId per earnings call
getStockPrices           (1-year weekly)
getStockChange ×3        (YTD, 6M, 1Y)
getPredictions ×6        (revenue, epsGaap, ebitda, netIncomeGaap, freeCashFlow, capitalExpenditure)
getTrends
```

**Batch 3** — deep analysis (needs transcriptIds and companyId):
```
getAnalytics ×4          (one per earnings call, pass documentID)
getStockPrices ×4        (1 week before/after each call date, interval: "day")
getSpeakers              (Executives, sortBy: count)
getSpeakers              (Executives_CEO)
getSpeakers              (Executives_CFO)
getSpeakers              (Analysts, sortBy: sentiment desc)
getSpeakerCompanies      (Analysts)
getStockChange per competitor
```

**Batch 4** — quotes and forecasts (**REQUIRED — do not skip, do not render the report until this completes**):

Delegate to ONE `pronto-search-summarizer` (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):
```
"orgName: [your orgName from the MCP server instructions]

Fetch all quotes needed for the [company] intelligence report. Run these searches:
1. Forecast/guidance quotes — Q1 (documentIDs: [doc_q1]), topic: 'forecast guidance outlook', sentiment: positive, size: 3
2. Forecast/guidance quotes — Q2 (documentIDs: [doc_q2]), topic: 'forecast guidance outlook', sentiment: positive, size: 3
3. Forecast/guidance quotes — Q3 (documentIDs: [doc_q3]), topic: 'forecast guidance outlook', sentiment: positive, size: 3
4. Forecast/guidance quotes — Q4 (documentIDs: [doc_q4]), topic: 'forecast guidance outlook', sentiment: positive, size: 3
5. Most bullish executive quotes — speakerTypes: Executives, sentiment: positive, size: 3
6. Top risk/bearish quotes — topic: 'risk challenge headwind', sentiment: negative, size: 3
7. Notable analyst questions — sections: EarningsCalls_Question, size: 3
Return all results with speaker name, role, and date."
```

→ Save the top 1–2 quotes per task with speaker name, role, and date. Do not proceed to Batch 5 until Batch 4 results are in hand.

**Batch 5** — render the full HTML report: inline in chat on claude.ai, written to `[ticker]-report.html` file in Claude Cowork.

---

## Core: Per-Quarter Earnings Comparison

This is the heart of the report. Instead of one aggregate analytics call, run `getAnalytics` **separately for each of the past year's earnings calls**. This is how RISING/FALLING comparisons are possible.

For each earnings call (typically 4):

```
getAnalytics:
  companyName: "<name>"
  documentIDs: ["<transcriptId for that quarter>"]
  documentTypes: ["Earnings Calls"]
  sinceDay / untilDay: bracket the quarter
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment", "importance"]
  → extract: sentimentScore, investmentScore, patternSentiment, top events, top aspects

getStockPrices (1 week window around call):
  companyId: "<id>"
  fromDate: 7 days before call date
  toDate: 7 days after call date
  interval: "day"
  → compute: % change before vs after = stock reaction
```

**Build the comparison table:**

| Quarter | Date | Sentiment | Direction | Investment | Direction | Stock After | Direction |
|---------|------|-----------|-----------|------------|-----------|-------------|-----------|
| Q1 2025 | Apr 28 | 0.32 | — | 0.61 | — | +2.3% | — |
| Q2 2025 | Jul 31 | 0.38 | RISING | 0.65 | RISING | +4.1% | RISING |
| Q3 2025 | Oct 30 | 0.35 | FALLING | 0.68 | RISING | -1.2% | FALLING |
| Q4 2025 | Jan 30 | 0.41 | RISING | 0.71 | RISING | +3.5% | RISING |

**You must explicitly state all three verdicts:**
1. "Sentiment score is [RISING/FALLING] — from X.XX (Q1) to X.XX (Q4)"
2. "Investment score is [RISING/FALLING] — from X.X (Q1) to X.X (Q4)"
3. "Stock price reacted [positively/negatively] to [N] of [total] earnings calls"

**Divergences are the most valuable insights — always highlight them:**
- Sentiment falling + stock rising → market disagrees with tone
- Sentiment rising + stock falling → market skeptical despite positive language
- Investment score falling while sentiment rising → deeper issues beneath the surface

---

## Speaker Analysis

Run these calls in parallel (all use `companyName`, 1-year window):

```
getSpeakers: Executives (sortBy: count, desc, limit: 20)
getSpeakers: Executives_CEO (limit: 5)
getSpeakers: Executives_CFO (limit: 5)
getSpeakers: Analysts (sortBy: sentiment, desc, limit: 20)  ← top 5 = bullish, bottom 5 = bearish
getSpeakerCompanies: Analysts (sortBy: sentiment, desc, limit: 20)
```

Compute and state explicitly in the report:
- Average executive sentiment vs average analyst sentiment
- **"Executives are MORE POSITIVE/MORE NEGATIVE than analysts by X.XX"**
- **"CEO is MORE BULLISH/MORE CAUTIOUS than CFO"** (compare their individual scores)
- Most bullish analyst: [Name] from [Firm] (X.XX) | Most bearish analyst: [Name] from [Firm] (X.XX)
- Gap interpretation: >+0.10 = management may be over-optimistic; <-0.10 = street sees more upside

---

## Report Structure

### Title
```
# [Company Name] ([Ticker]) — Intelligence Report
Generated: [Date] | Sector: [Sector] | Sub-Sector: [Sub-Sector]
Market Cap: [Cap] | Pronto Company ID: [companyId]
```

### Section 1: Executive Summary
2–3 paragraphs explicitly stating:
- Stock performance vs peers and S&P 500
- "Sentiment is RISING/FALLING from X.XX to X.XX over the past year"
- "Investment score is RISING/FALLING from X.X to X.X"
- "Stock reacted positively/negatively to N of M earnings calls"
- "Forecast tone is IMPROVING/DETERIORATING"
- "Executives are MORE POSITIVE/MORE NEGATIVE than analysts by X.XX"
- Key thesis (bullish/bearish/neutral) + 3 supporting points

### Section 2: Stock Performance
Chart 5 + Chart 6 | Table: YTD/6M/1Y vs peers and S&P 500

### Section 3: Financial Outlook
Table: Revenue, EPS, EBITDA, Net Income, FCF, CapEx — actuals + consensus forward estimates (FY-2 through FY+1)

### Section 4: Earnings Call Comparison — Quarter Over Quarter *(CORE)*
Charts 1–4, 8 | Quarter comparison table with Direction columns | Verdicts | Per-quarter event breakdown | Divergence analysis

**Quarter Card Layout (use this exact HTML structure — prevents text overlap):**

Render **one card per available earnings call** — typically 4, but some companies have only 1, 2, or 3 quarters of data. Use `auto-fit` so the grid adjusts automatically to however many cards exist. Do NOT use `display: flex` with multiple children — cards become too narrow and text overlaps.

```html
<style>
  .qtr-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    margin: 24px 0;
  }
  .qtr-card {
    border: 1px solid #d1d5db;
    border-radius: 12px;
    padding: 16px;
    background: #fff;
    min-width: 0; /* allow card to shrink inside grid */
  }
  .qtr-card.latest { border-color: #6AA64A; border-width: 2px; }
  .qtr-header {
    font-size: 12px;
    font-weight: 600;
    color: #6b7280;
    margin-bottom: 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .qtr-metric {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 8px;
    margin-bottom: 6px;
    font-size: 13px;
  }
  .qtr-metric .label {
    color: #374151;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .qtr-metric .value {
    font-weight: 600;
    text-align: right;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    color: #111827;
  }
  .qtr-metric .arrow-up   { color: #1D9E75; }
  .qtr-metric .arrow-down { color: #D85A30; }
  .qtr-badge {
    display: inline-block;
    margin: 10px 0 8px;
    padding: 2px 10px;
    border-radius: 999px;
    font-size: 11px;
    font-weight: 600;
  }
  .badge-green { background: #dcfce7; color: #15803d; }
  .badge-red   { background: #fee2e2; color: #b91c1c; }
  .badge-blue  { background: #dbeafe; color: #1d4ed8; }
  .badge-amber { background: #fef3c7; color: #92400e; }
  .qtr-notes {
    font-size: 12px;
    color: #4b5563;
    line-height: 1.5;
    margin-top: 6px;
  }
</style>

<div class="qtr-grid">
  <!-- One .qtr-card per available earnings call (1–4 total, whatever getCompanyDocuments returned) -->
  <div class="qtr-card [add 'latest' class for most recent]">
    <div class="qtr-header">Q2 FY2025 · May 1, 2025</div>
    <div class="qtr-metric">
      <span class="label">Sentiment</span>
      <span class="value">0.32 <span class="arrow-up">▲</span></span>
    </div>
    <div class="qtr-metric">
      <span class="label">Investment</span>
      <span class="value">0.61 <span class="arrow-down">▼</span></span>
    </div>
    <div class="qtr-metric">
      <span class="label">Pattern +/−</span>
      <span class="value">+0.05 / −0.02</span>
    </div>
    <div class="qtr-metric">
      <span class="label">Revenue</span>
      <span class="value">$94.9B</span>
    </div>
    <span class="qtr-badge badge-red">Weakest quarter</span>
    <div class="qtr-notes">Top risk: tariffs ($900M cost impact flagged). RiskFactor event score: −0.95.</div>
  </div>
</div>
```

**Key rules:**
- `grid-template-columns: repeat(auto-fit, minmax(220px, 1fr))` — adapts to 1, 2, 3, or 4 available quarters automatically; each column is at least 220px wide
- Every metric row uses `justify-content: space-between` so label and value never collide
- Direction arrows (▲▼) stay inline with the value, colored green/red
- Badge color: Weakest → red, Strong recovery → green, Record → blue, Best score → amber (pick closest fit)
- Notes section is the 2–3 sentence qualitative summary for that quarter

### Section 5: Management Forecast & Outlook
Table: Quarter | Forecast Tone | Key Guidance Points | 1–2 direct quotes per quarter
State: "Guidance was RAISED/LOWERED/MAINTAINED in N of [total] quarters"

### Section 6: Trending Topics
Chart 7 | Top 20 trends table (score, hits, % change, RISING/DECLINING)

### Section 7: Executive Sentiment & Commentary
Chart 10 | CEO vs CFO table | Top executives by sentence volume | Key quotes with attribution

### Section 8: Analyst & Investor Sentiment
Chart 9 | Most bullish/bearish analysts (top/bottom 5) | Firm ranking | Exec vs Analyst gap table + interpretation

### Section 9: Competitive Landscape
1Y stock % change vs competitors (from `getStockChange` per competitor)

### Section 10: Risk Factors
Risks from `getCompanyDescription` + negative event types from analytics + analyst concerns

### Section 11: Appendix
Documents analyzed (title, date, transcriptId) | Pronto company ID | Date ranges used

---

## Charts

**On claude.ai:** Charts render as inline HTML — no separate file. Use `assets/charts-template.html` as a reference for the 10 Chart.js configurations (canvas IDs c1–c10, chart types, options). Populate the data arrays from tool results.
**In Claude Cowork:** Charts are included in the HTML file exactly as on claude.ai — no changes needed.

**Chart placement:**
- Load Chart.js once near the top of the HTML output: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- Place Charts 1–4 and 8 inside **Section 4** (Earnings Call Comparison), after the quarter comparison table
- Place Chart 5 inside **Section 2** (Stock Performance)
- Place Charts 6 inside **Section 9** (Competitive Landscape)
- Place Chart 7 inside **Section 6** (Trending Topics)
- Place Charts 9–10 inside **Section 8** (Analyst & Investor Sentiment) and **Section 7** (Executive Sentiment)
- All chart data defined as JS constants at the point of use (or collected into one `<script>` block near the end)

---

## Date Handling

```
Past year:     sinceDay = 1 year ago,   untilDay = today
Past quarter:  sinceDay = 90 days ago,  untilDay = today
YTD:           sinceDay = Jan 1,        untilDay = today
Past 6 months: sinceDay = 6 months ago, untilDay = today
```

**Important:** `getAnalytics` cannot handle date ranges over 1 year. Split longer requests into multiple yearly calls.

---

## Error Handling & Common Issues

| Problem | What to do |
|---------|-----------|
| Company not found | Try ticker instead of name (or vice versa); check spelling |
| `getCompanyDescription` returns no result | Ask user to verify; do not proceed without companyId |
| Fewer than 4 earnings calls | Work with available quarters; note the gap in the comparison table |
| No predictions for a metric | Show "N/A" in that cell; skip gracefully |
| Analytics returns empty | Verify date range ≤ 1 year; try without `documentIDs` filter as fallback |
| No competitors returned | Skip competitive section; note it in the report |
| No quotes from search | Note "No matching quotes found" — never fabricate |
| Private/unlisted company | ProntoNLP covers public companies only — tell the user |
| companyId not in response | Check for `id` or nested field; inspect the full response object |

---

## Best Practices

1. **Detect environment first** — inline HTML on claude.ai (`Bash` not available), HTML written to `[ticker]-report.html` file in Claude Cowork (`Bash` available)
2. Save `companyId` the moment you get it from `getCompanyDescription`
3. Maximize parallelism — batch all independent calls per the strategy above
4. Never fabricate data — if a tool returns nothing, say so honestly
5. Always cite quotes: `"Quote text" — [Name], [Role], [Company] ([Date])`
6. Present both sides — always pair positive findings with negative/risk findings
7. Prefer `companyId` over `companyName` when a tool accepts both
8. Do not mention tool names in responses — describe the action instead (e.g. "I analyzed 4 earnings calls" not "I called getAnalytics 4 times")
