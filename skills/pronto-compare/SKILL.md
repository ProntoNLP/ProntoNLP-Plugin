---
name: pronto-compare
description: "Generates a unified side-by-side comparison report for two or more named companies, tickers, market sectors, or any mix of companies and sectors — scoring each across sentiment, investment score, stock performance, trending topics, and risk factors to determine an overall leader. Use when the user wants to compare specific companies, sectors, or a company against a sector. Triggers on phrases like: '[company] vs [company]', '[sector] vs [sector]', '[company] vs [sector]', 'compare [company] and [sector]', 'tech vs healthcare', 'NVDA vs the tech sector', 'which sector leads — IT or financials', 'how does [company] compare to [sector]', 'semiconductors vs software'. Supports 2 to 5 entities (companies, sectors, or mixed). Do not use for a single named company — use the company intelligence skill. Do not use for a single sector — use the sector intelligence skill. Do not use for broad market overviews — use the market pulse skill."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Universal Comparison Report Generator

Produces a self-contained side-by-side intelligence comparison of two or more entities — which may be named companies, market sectors, or a mix of both. Collects sentiment, investment scores, stock performance, trending topics, and risk factors for every entity using ProntoNLP MCP tools directly, then synthesizes all data into a single unified comparison report with scoring, charts, and a clear verdict.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, `deepResearch`, or any interactive visualization tool from this skill. These are user-triggered only. Only call the tools explicitly listed in the batches below.

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

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named as follows, then tell the user the filename and open it:
  - Company vs company: `[tickerA]-vs-[tickerB]-report.html` (e.g. `NVDA-vs-AMD-report.html`)
  - Company vs sector: `[ticker]-vs-[sector-slug]-report.html` (e.g. `NVDA-vs-tech-report.html`)
  - Sector vs sector: `[sectorA-slug]-vs-[sectorB-slug]-report.html` (e.g. `tech-vs-healthcare-report.html`)

---

## Step 1: Parse Entities & Assign Types

Extract all entities from the user's request. Identify each as either a **company** or a **sector**.

**Support 2–5 entities maximum.** If the user requests more than 5, ask them to narrow it down.

### Entity Classification

| Entity type | Identifies as | Examples |
|-------------|--------------|----------|
| **Company** | Named company or ticker | "NVDA", "Apple", "Tesla", "MSFT" |
| **Sector** | Market sector or sub-sector | "tech sector", "healthcare", "semiconductors", "financials" |

**Company vs sector signal phrases:**
- "NVDA vs the tech sector" → company + sector
- "how does Apple compare to consumer discretionary" → company + sector
- "tech vs healthcare" → sector + sector
- "NVDA vs AMD vs semiconductors" → 2 companies + 1 sector

### Sector Name Normalization

Map informal sector names to the exact API strings:

| User says | Exact API string |
|-----------|-----------------|
| tech, technology | `Information Technology` |
| healthcare, health, pharma, biotech, medtech | `Health Care` |
| financials, finance, banking, financial services | `Financials` |
| energy, oil, gas | `Energy` |
| consumer discretionary, retail, auto | `Consumer Discretionary` |
| consumer staples, food, beverage | `Consumer Staples` |
| industrials, industrial, aerospace, defense | `Industrials` |
| utilities | `Utilities` |
| real estate, reits | `Real Estate` |
| materials, chemicals, mining | `Materials` |
| communication, media, telecom | `Communication Services` |
| semiconductors | `Information Technology-Semiconductors and Semiconductor Equipment` |
| software | `Information Technology-Software` |
| cloud | `Information Technology-Software` |
| ev sector, electric vehicles | `Consumer Discretionary-Automobiles` |

### Color Assignment

Assign a color per entity (used consistently throughout all charts, cards, and scorecard columns):

- Entity A: `#3B82F6` (blue)
- Entity B: `#8B5CF6` (purple)
- Entity C: `#F59E0B` (orange)
- Entity D: `#14B8A6` (teal)
- Entity E: `#EC4899` (pink)

---

## Step 2: Batch 1 — Foundation (fire all simultaneously)

Actions differ by entity type — fire all in parallel across all entities:

**For each COMPANY:**
```
getCompanyDescription(companyNameOrTicker: "<company>")
  → save: companyId, sector, subSector, description, risks[]
```

**For each SECTOR:**
- No API call needed — normalize the sector name to exact API string (done in Step 1)
- Mark entity type as `sector` and save the exact API string for use in all subsequent calls

After Batch 1 completes:
- Every company has a `companyId` — required for all stock calls
- Every entity has a confirmed entity type (company or sector) and display name

---

## Step 3: Batch 2 — Core Data (fire all simultaneously, all entities at once)

Actions differ by entity type — fire all in one parallel batch across all entities:

### Companies — Batch 2 calls:
```
getCompanyDocuments(companyName: "<name>", documentTypes: ["Earnings Calls"], limit: 4)
  → save: transcriptId[] and call dates for Q1–Q4

getStockChange(companyId: "<id>", sinceDay: "<YTD start>", untilDay: "<today>")     → YTD %
getStockChange(companyId: "<id>", sinceDay: "<6M ago>",    untilDay: "<today>")     → 6M %
getStockChange(companyId: "<id>", sinceDay: "<1Y ago>",    untilDay: "<today>")     → 1Y %

getPredictions(companyId: "<id>", metric: "revenue")
getPredictions(companyId: "<id>", metric: "epsGaap")
getPredictions(companyId: "<id>", metric: "ebitda")
getPredictions(companyId: "<id>", metric: "freeCashFlow")
  → save: forward consensus estimates

getTrends(companyName: "<name>", documentTypes: ["Earnings Calls"],
  sinceDay: "<1Y ago>", untilDay: "<today>", limit: 10)
  → save: top trending topics with score and change %
```

### Sectors — Batch 2 calls:
```
getAnalytics(sectors: ["<Exact Sector String>"], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "<1Y ago>", untilDay: "<today>")
  → save: sentimentScore, investmentScore, sentiment direction, investment direction,
           top positive events, top negative events, top aspects

getTrends(sectors: ["<Exact Sector String>"], documentTypes: ["Earnings Calls"],
  sinceDay: "<1Y ago>", untilDay: "<today>", limit: 10)
  → save: top trending topics with score and change %
  NOTE: do NOT pass a query or topicSearchQuery to getTrends

getTopMovers(sectors: ["<Exact Sector String>"], documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay: "<1Y ago>", untilDay: "<today>")
  → save: top company by investment score (name + score), top company by sentiment (name + score),
           top company by stock change (name + %), underperformers (high score + weak stock)
```

---

## Step 4: Batch 3 — Deep Analysis (fire all simultaneously, all entities at once)

Actions differ by entity type — fire all in one parallel batch:

### Companies — Batch 3 calls (using transcriptIds from Batch 2):
```
getAnalytics(companyName: "<name>", documentIDs: ["<Q1 transcriptId>"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"])
  → save: sentimentScore_Q1, investmentScore_Q1, top events Q1

getAnalytics(companyName: "<name>", documentIDs: ["<Q2 transcriptId>"], ...)  → Q2
getAnalytics(companyName: "<name>", documentIDs: ["<Q3 transcriptId>"], ...)  → Q3
getAnalytics(companyName: "<name>", documentIDs: ["<Q4 transcriptId>"], ...)  → Q4

getStockPrices(companyId: "<id>", fromDate: "<call date minus 2 days>",
  toDate: "<call date plus 5 days>", interval: "day")
  → compute: stock reaction % for Q1, Q2, Q3, Q4

getSpeakers(companyName: "<name>", speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
  → save: exec avg sentiment

getSpeakers(companyName: "<name>", speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
  → save: CEO sentiment

getSpeakers(companyName: "<name>", speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
  → save: CFO sentiment

getSpeakers(companyName: "<name>", speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
  → save: analyst avg sentiment, most bullish, most bearish

getSpeakerCompanies(companyName: "<name>", speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → save: most bullish analyst firm, most bearish analyst firm
```

### Sectors — Batch 3 calls (using top companies from getTopMovers in Batch 2):
```
searchTopCompanies(sectors: ["<Exact Sector String>"], eventTypes: ["GrowthDriver"],
  limit: 5, sinceDay: "<1Y ago>", untilDay: "<today>")
  → save: top 3 companies driving growth in this sector

searchTopCompanies(sectors: ["<Exact Sector String>"], eventTypes: ["RiskFactor"],
  limit: 5, sinceDay: "<1Y ago>", untilDay: "<today>")
  → save: top 3 companies with highest risk factor exposure

getSpeakers(companyName: "<top company from getTopMovers>", speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10, documentTypes: ["Earnings Calls"])
  → save: most bullish executive in the sector (name + score)

getSpeakerCompanies(companyName: "<top company from getTopMovers>",
  speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → save: most bullish analyst firm covering sector leader
```

Run all company AND sector calls simultaneously in one batch.

After Batch 3, compute per company:
- `sentimentDirection` (RISING if Q4 > Q1, FALLING if Q4 < Q1)
- `investmentDirection` (same logic)
- `positiveCallCount` (quarters where stock reaction > 0)
- `execAnalystGap` = execAvg − analystAvg

---

## Step 5: Batch 4 — Quotes

**Environment-aware — pick ONE path, do NOT run both:**

| Environment | Detection | Action |
|-------------|-----------|--------|
| **Claude Cowork** | `Bash` tool IS available | → delegate to ONE `pronto-search-agent` (stop here, do NOT also call `search`) |
| **claude.ai** | `Bash` tool NOT available | → call `search` MCP tool directly |

---

### Claude Cowork — delegate to ONE `pronto-search-agent` (subagent_type: `prontonlp-plugin:pronto-search-agent`):

```
"Fetch all quotes needed for the comparison report. Run these searches:

For each company entity — [company 1], [company 2], ...:
  - Bullish executive quotes: speakerTypes: Executives, sentiment: positive, topic: 'growth outlook guidance', documentTypes: Earnings Calls, size: 3
  - Bearish/risk quotes: sentiment: negative, topic: 'risk challenge headwind', documentTypes: Earnings Calls, size: 3
  - Notable analyst questions: sections: EarningsCalls_Question, documentTypes: Earnings Calls, size: 3

For each sector entity — use [top company in sector] as the representative:
  - Bullish quotes from [top company]: speakerTypes: Executives, sentiment: positive, topic: 'sector growth momentum', size: 3
  - Bearish/risk quotes from [top company]: sentiment: negative, topic: 'sector risk headwind', size: 3

Return all results with speaker name, role, and date."
```

---

### claude.ai — call `search` MCP tool directly, fire all in parallel:

**Companies (3 calls per company):**
```
search(companyName: "<name>", sentiment: "positive", speakerTypes: ["Executives"],
  topicSearchQuery: "growth outlook guidance", size: 3, documentTypes: ["Earnings Calls"])

search(companyName: "<name>", sentiment: "negative",
  topicSearchQuery: "risk challenge headwind", size: 3, documentTypes: ["Earnings Calls"])

search(companyName: "<name>", sections: ["EarningsCalls_Question"], size: 3, documentTypes: ["Earnings Calls"])
```

**Sectors (2 calls per sector, using top company as representative):**
```
search(companyName: "<top company in sector>", sentiment: "positive",
  speakerTypes: ["Executives"], topicSearchQuery: "sector growth momentum", size: 3)

search(companyName: "<top company in sector>", sentiment: "negative",
  topicSearchQuery: "sector risk headwind challenge", size: 3)
```

---

## Step 6: Synthesize & Score

### Scoring Rules by Comparison Mode

**Company vs Company — 9 dimensions (all entities are companies):**

| Dimension | How to determine winner |
|-----------|------------------------|
| Sentiment trend | Highest Q4 sentiment score; tiebreak: RISING direction preferred |
| Investment score | Highest Q4 investment score (raw API value) |
| Stock YTD | Best YTD % change |
| Earnings call reaction | Most quarters with positive stock reaction (N of M) |
| Analyst consensus | Highest analyst avg sentiment |
| Revenue (fwd) | Best forward revenue estimate |
| EPS (fwd) | Highest forward EPS |
| Exec confidence | Highest executive avg sentiment |
| Risk profile | Fewest and least severe risks |

**Sector vs Sector — 7 dimensions (all entities are sectors):**

| Dimension | How to determine winner |
|-----------|------------------------|
| Sentiment score | Highest aggregate sector sentiment score |
| Investment score | Highest aggregate sector investment score (raw) |
| Sentiment direction | RISING preferred over FALLING |
| Investment direction | RISING preferred over FALLING |
| Stock performance | Sector's top mover YTD % (or avg of top 5 from getTopMovers) |
| Theme momentum | Fastest-rising topic change % |
| Risk profile | Fewer dominant negative events / lower risk severity |

**Mixed (company + sector) — 7 universal dimensions + 2 company-only:**

Score all entities on universal dimensions. Company-only dimensions show N/A for sector entities in the scorecard.

| Dimension | Companies | Sectors |
|-----------|-----------|---------|
| Sentiment score | Q4 score | Aggregate score |
| Investment score | Q4 raw score | Aggregate raw score |
| Sentiment direction | RISING/FALLING Q1→Q4 | RISING/FALLING (YoY) |
| Investment direction | RISING/FALLING Q1→Q4 | RISING/FALLING (YoY) |
| Stock performance | Company YTD % | Sector's top mover YTD % |
| Theme momentum | Fastest-rising topic change % | Fastest-rising topic change % |
| Risk profile | Risk count and severity | Dominant negative event severity |
| Earnings reaction *(company-only)* | N of M positive quarters | N/A |
| Financial outlook *(company-only)* | Revenue + EPS forward | N/A |

### Always Compute and State:
- Sentiment direction per entity: "RISING (X.XX → X.XX)" or "FALLING (X.XX → X.XX)"
- Investment direction per entity: "RISING / FALLING"
- Stock performance context: for sectors, note this is the top mover, not the full sector average
- Divergence signal: any entity with rising investment score + weak stock = potential undervalued / re-rating signal
- Topic overlap: shared topics across entities = macro theme; unique topics = entity-specific narrative
- Risk overlap: risks in 2+ entities = systemic; in 1 entity = idiosyncratic

---

## Step 7: Render the Comparison Report

Generate a single unified HTML report.

---

### Title Block

```
[Entity A] vs [Entity B] [vs ...] — Comparison Report
Generated: [Date] | [N] Entities ([type breakdown, e.g. "2 Companies", "1 Company / 1 Sector"]) | Period: Past Year
```

---

### Section 1: Overall Scorecard

One column per entity + Winner column. Every scoreable row must have an explicit winner.

**Row coloring (cell background):**
- 2 entities: winner cell = green background (`#dcfce7`) + green text (`#15803d`), loser cell = red background (`#fee2e2`) + red text (`#b91c1c`)
- 3+ entities: winner cell = green background + green text only; all other cells neutral
- N/A cells (sector entity in company-only row): neutral background, muted text (`var(--color-text-tertiary)`), labeled "N/A — Sector"

**Value text coloring (applied INSIDE each cell, independent of winner/loser background):**
- Positive numbers (`+X%`, positive sentiment, positive stock, value **> 0**): text color `#1D9E75` (green)
- Negative numbers (`−X%`, negative sentiment, negative stock, value **< 0**): text color `#D85A30` (red)
- Zero (value **= 0**): no color — use default inherited text color
- N/A: `var(--color-text-tertiary)`

**Winner column — every row must show the actual entity name:**
- Every dimension row: `🏆 [EntityName]` (e.g. `🏆 NVDA`, `🏆 IT Sector`) — never just a letter like `🏆 A`
- Direction-only rows (Sentiment Direction, Investment Direction): use `—` if both entities share the same direction; otherwise name the RISING entity
- Overall Wins row: `🏆 [EntityName] (N wins)`

| Metric | [A] | [B] | [C] | Winner |
|--------|-----|-----|-----|--------|
| Sentiment Score | 0.67 ↑ | 0.39 ↓ | 0.48 | 🏆 NVDA |
| Investment Score | 0.71 | 0.52 | 0.63 | 🏆 NVDA |
| Sentiment Direction | RISING | FALLING | RISING | 🏆 NVDA / IT Sector |
| Investment Direction | RISING | RISING | FALLING | — |
| Stock Performance | +38.4% | −12.3% | +22.1% | 🏆 NVDA |
| Theme Momentum | +91% | +84% | +68% | 🏆 NVDA |
| Risk Profile | Low | Medium | High | 🏆 NVDA |
| Earnings Reaction *(co. only)* | 4/4 | 2/4 | N/A — Sector | 🏆 NVDA |
| Financial Outlook *(co. only)* | $48B rev | $9B rev | N/A — Sector | 🏆 NVDA |
| **Overall Wins** | **7** | **1** | **1** | 🏆 **NVDA (7 wins)** |

---

### Section 2: Quarter-Over-Quarter Sentiment (companies) / Sector Trend Summary (sectors)

**For each COMPANY entity:** Show quarter cards (same layout as company vs company):

```html
<div class="co-section">
  <div class="co-label">
    <span class="co-dot" style="background:#3B82F6"></span> NVDA
    <span style="font-size:11px;color:var(--color-text-tertiary)">Company</span>
  </div>
  <div class="qtr-grid">
    <div class="qtr-card">
      <div class="qtr-header">Q1 · [Date]</div>
      <div class="qtr-metric"><span class="label">Sentiment</span><span class="value">X.XX</span></div>
      <div class="qtr-metric"><span class="label">Investment</span><span class="value">X.X</span></div>
      <div class="qtr-metric"><span class="label">Stock Reaction</span><span class="value up">+X%</span></div>
    </div>
    <!-- Q2, Q3, Q4 cards -->
  </div>
</div>
```

**For each SECTOR entity:** Show a sector summary card instead of quarter cards:

```html
<div class="co-section">
  <div class="co-label">
    <span class="co-dot" style="background:#8B5CF6"></span> Information Technology
    <span style="font-size:11px;color:var(--color-text-tertiary)">Sector</span>
  </div>
  <div class="sector-summary-grid">
    <div class="sector-card">
      <div class="sector-card-label">Sentiment Score</div>
      <div class="sector-card-value">X.XX <span class="up">↑ RISING</span></div>
    </div>
    <div class="sector-card">
      <div class="sector-card-label">Investment Score</div>
      <div class="sector-card-value">[raw] <span class="up">↑ RISING</span></div>
    </div>
    <div class="sector-card">
      <div class="sector-card-label">Top Mover</div>
      <div class="sector-card-value">[Company] +X% YTD</div>
    </div>
    <div class="sector-card">
      <div class="sector-card-label">Fastest Rising Theme</div>
      <div class="sector-card-value">[Topic] +X%</div>
    </div>
    <div class="sector-card">
      <div class="sector-card-label">Dominant Positive Event</div>
      <div class="sector-card-value">[EventType] (N hits)</div>
    </div>
    <div class="sector-card">
      <div class="sector-card-label">Dominant Negative Event</div>
      <div class="sector-card-value">[EventType] (N hits)</div>
    </div>
  </div>
</div>
```

Place **Chart 3** (multi-line sentiment trend) after all blocks:
- For companies: Q1–Q4 per quarter
- For sectors: single point (aggregate score) — render as a flat line or a single marker on the chart with a label

Place **Chart 4** (multi-line investment trend) with the same logic.

After all blocks, include the comparison callout:
> 📊 Comparison: [Entity A] sentiment is **RISING**, [Entity B] sector sentiment is **RISING** — similar trajectory but [A] leads by X.XX points.

---

### Section 3: Stock Performance

**Chart 1** — Grouped bar: YTD / 6M / 1Y for all entities.
- For companies: actual stock change from `getStockChange`
- For sectors: top mover's stock change from `getTopMovers` — label clearly as "Sector leader ([Company]) YTD"

Table below chart with a footnote if any value is a sector top-mover proxy rather than sector average.

---

### Section 4: Financial Outlook (companies only)

Shown only if at least one entity is a company. Sector columns show "N/A — Sector" in this section.

| Metric | [Company A] | [Sector B] | [Company C] | Leader |
|--------|------------|------------|------------|--------|
| Revenue (fwd) | $XB | N/A — Sector | $XB | 🏆 A |
| EPS GAAP (fwd) | X.XX | N/A — Sector | X.XX | 🏆 C |
| EBITDA (fwd) | $XB | N/A — Sector | $XB | 🏆 A |
| FCF (fwd) | $XB | N/A — Sector | $XB | 🏆 A |

If ALL entities are sectors, omit Section 4 entirely.

---

### Section 5: Speaker Sentiment

**For company entities:** CEO / CFO / Exec avg / Analyst avg (same as company vs company).

**For sector entities:** Show most bullish exec from sector's top company + most bullish analyst firm.

| Speaker | [Company A] | [Sector B] | [Company C] |
|---------|------------|------------|------------|
| CEO | X.XX | N/A — Sector | X.XX |
| CFO | X.XX | N/A — Sector | X.XX |
| Exec Avg | X.XX | X.XX (sector leader) | X.XX |
| Analyst Avg | X.XX | N/A | X.XX |
| Exec-Analyst Gap | +X.XX | — | +X.XX |
| Most Bullish Analyst Firm | [Firm] (X.XX) | [Firm] (sector leader) | [Firm] (X.XX) |

**Chart 2** — Grouped bar: entities side by side with available speaker scores.

---

### Section 6: Trending Topics — Overlap & Divergence

Side-by-side topic lists, one column per entity. Flag overlapping themes.

| [Entity A] Topics | [Entity B] Topics | [Entity C] Topics |
|------------------|------------------|------------------|
| 1. Topic X ↑+84% | 1. Topic X ↑+61% | 1. Topic Y ↑+42% |
| 2. Topic Y ↑+38% | 2. Topic Z ↑+29% | 2. Topic X ↑+18% |

Below: three-part overlap analysis:
- **Shared across all:** [Topic] → **Macro theme**
- **Shared by 2:** [Topic] in [A] and [B] → **Emerging convergence**
- **Unique to one:** [Topic] in [A] only → **[A] narrative**
- **Systemic risk:** risk topic in 2+ entities → **Sector-wide risk**

---

### Section 7: Risk Comparison

| Risk | [A] | [B] | [C] | Type |
|------|-----|-----|-----|------|
| [Risk name] | ✅ | ✅ | — | Systemic |
| [Risk name] | — | ✅ | — | Idiosyncratic |

For company entities: risks from `getCompanyDescription` and negative events from `getAnalytics`.
For sector entities: dominant negative event types from `getAnalytics` at sector level.

---

### Section 8: Verdict

4 concise paragraphs:
1. **Overall leader** — which entity wins most scored dimensions and why
2. **Most undervalued / re-rating signal** — entity with rising investment score but weak stock performance
3. **Highest risk** — which entity carries the most concentrated or idiosyncratic risk
4. **Bottom line** — "If you had to pick one: [Entity] — because..."

For mixed company-vs-sector comparisons, acknowledge the different nature in the verdict:
> "Comparing [Company] to the broader [Sector] is not apples-to-apples — [Company] carries single-stock concentration risk while [Sector] provides breadth. On the metrics available for both, [Company] leads on sentiment and investment score, suggesting significant alpha vs the sector."

---

## Charts Reference

| Chart | Section | Type | Data |
|-------|---------|------|------|
| Chart 1 | Section 3 | Grouped bar | Stock % change (YTD/6M/1Y) per entity |
| Chart 2 | Section 5 | Grouped bar | Speaker scores per entity (CEO/CFO/Exec/Analyst where available) |
| Chart 3 | Section 2 | Multi-line | Sentiment score trend per entity (companies: Q1–Q4; sectors: single aggregate point) |
| Chart 4 | Section 2 | Multi-line | Investment score trend per entity |

Load Chart.js once at the top of the HTML. All data as inline JS constants.

---

## Date Handling

| Scope | sinceDay | untilDay |
|-------|----------|----------|
| Default (past year) | 1 year ago | today |
| "past quarter" | 90 days ago | today |
| "past 6 months" | 6 months ago | today |
| YTD | Jan 1 current year | today |

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Company not found by `getCompanyDescription` | Try ticker; note and continue with remaining entities |
| Sector name unrecognized | Try top-level sector if sub-sector fails; note mapping used |
| Fewer than 4 quarters for a company | Show available quarters only; note the gap |
| No predictions for a company metric | Show "N/A" — never fabricate |
| No analyst data for a company | Show "N/A" for analyst rows — do not skip the row |
| `getTopMovers` returns fewer than 3 companies for a sector | Widen date range; remove `documentTypes` filter |
| More than 5 entities requested | Ask user to narrow to 5 or fewer |
| All-sector comparison — financial outlook is empty | Omit Section 4; note it applies to company comparisons only |

---

## Best Practices

1. **Detect environment first** — inline HTML on claude.ai (`Bash` not available), write HTML file in Claude Cowork (`Bash` available)
2. **Save `companyId` immediately** after Batch 1 for every company entity — required for all stock calls
3. **Fire all entities simultaneously within each batch** — never process one entity at a time
4. **Adapt the scorecard** — when sectors are present, show N/A clearly in company-only rows rather than leaving them blank
5. **Label entity types** in all section headers — "(Company)" or "(Sector)" after each entity name so the reader knows what they're comparing
6. **Divergence signal** — entity with rising investment score but weak stock performance is the most actionable insight
7. **Never fabricate** — missing metric = "N/A", never an invented number
8. **Consistent entity colors** across all charts, cards, and scorecard column headers

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Exact tool parameters per entity type (company vs sector), scoring matrix, enum reference |
| `reference/report-template-guide.md` | HTML layout, section structure, chart placement, formatting rules for mixed entity types |
| `examples/nvda-vs-amd.md` | Full worked example: company vs company (NVDA vs AMD) |
| `examples/nvda-vs-tech-sector.md` | Full worked example: company vs sector (NVDA vs Information Technology) |
| `examples/it-vs-healthcare.md` | Full worked example: sector vs sector (Information Technology vs Health Care) |
| `evaluations/criteria.md` | Evaluation rubric — triggering, data collection, adaptive scoring, HTML structure |
| `evals/evals.json` | Structured test cases covering all comparison modes |
