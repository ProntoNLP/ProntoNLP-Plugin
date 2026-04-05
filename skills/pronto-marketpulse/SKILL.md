---
name: pronto-marketpulse
description: "Generates a broad market intelligence dashboard ranking companies across the entire market by investment score, sentiment shifts, and stock performance — based on recent earnings calls. Use when the user asks about the overall market rather than a specific company or sector. Triggers on phrases like: 'what's moving in the market', 'top movers', 'market recap', 'market summary', 'market overview', 'what happened in the market this week', 'stocks to watch', 'most bullish companies', 'biggest sentiment shifts', 'highest investment scores', 'earnings season highlights', 'which analyst firms are bearish', 'what large caps are outperforming'. Defaults to past 7 days when no time frame is specified. Do not use for a single named company — use the company intelligence skill. Do not use for a specific sector — use the sector intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Market Pulse — Recent Market Intelligence Dashboard

**This skill generates an interactive HTML market intelligence dashboard** using ProntoNLP data. It focuses on companies that have recently published **earnings calls**, giving a fundamentals-driven view of market activity — not just price noise.

The report always states the exact time period it covers so the user knows the context.

---

## Step 0: Parse the Request — Determine Sections and Filters

Before making any tool calls, analyze what the user is asking for and decide:

### A. Which sections to include

| What the user asked | Sections to generate |
|---------------------|----------------------|
| "top movers", "what's moving", "show me movers", specific metric like "best stocks this week" | **Movers only** — the leaderboards. No trends, no speakers. |
| "what happened this week/month", "market recap", "market summary", "market overview", "what's going on in the market", or any broad open-ended question about the market | **Full** — movers + Trending Topics + Voice of the Market |
| "show me trends", "what topics are trending", "what are executives saying" | **Trends only** or **Speakers only** as relevant |
| "show me [specific thing] only" | **Only that section** |

**The key distinction**: if the user is asking *what's moving* (price/score focus) → Movers only. If they're asking *what's happening* (narrative/context focus) → Full. When in doubt, lean toward Full.

At the end of a Movers-only report, tell the user they can ask for a **full report** to also see Trending Topics and Voice of the Market.

**Only generate what was asked for.** Match the HTML output to the request exactly.

### B. Which market cap filter to apply

| User says | Market cap filter |
|-----------|------------------|
| Nothing specific (default) | **$300M+** — Small + Mid + Large + Mega |
| "large companies", "large caps", "big companies" | **$10B+** — Large + Mega |
| "mega cap", "only the biggest", "S&P 500 only" | **$200B+** — Mega only |
| "small caps", "small companies", "micro cap" | Drop filter entirely; note it in the report |
| Specifies a sector, country, or index | Apply those filters; keep the $300M+ default market cap floor |

Pass `marketCaps` as an array of key strings. Available keys (from smallest to largest):
- `"Nano (under $50mln)"`
- `"Micro ($50mln - $300mln)"`
- `"Small ($300mln - $2bln)"`
- `"Mid ($2bln - $10bln)"`
- `"Large ($10bln - $200bln)"`
- `"Mega ($200bln & more)"`

**Default filter ($300M+):**
```json
["Small ($300mln - $2bln)", "Mid ($2bln - $10bln)", "Large ($10bln - $200bln)", "Mega ($200bln & more)"]
```

**Large companies filter ($10B+):**
```json
["Large ($10bln - $200bln)", "Mega ($200bln & more)"]
```

**Mega cap filter ($200B+):**
```json
["Mega ($200bln & more)"]
```

### C. Optional user-specified filters

Apply any of these when the user specifies them:
- `sectors` — e.g., `["Information Technology", "Financials"]`
- `country` — e.g., `"United States"`
- `indices` — e.g., `["SP500_IND"]`

---

## Step 1: Determine the Date Range

- If the user specifies a time frame ("this month", "last 2 weeks", "past quarter"), use that.
- If the user says "recently", "currently", "now", "latest", or gives no time frame → **default to the past 7 days**.
- Format: `YYYY-MM-DD`.
- Store a human-readable label (e.g., "Past 7 Days", "Past 30 Days", "Mar 1 – Mar 26, 2026") — it appears in the report header and every section heading.

---

## Step 2: Call Data Tools

Fire all applicable calls **simultaneously**. Only make the calls needed for the sections determined in Step 0.

### 2a. getTopMovers — Single Call with Multiple Sort Criteria *(when movers section is needed)*

Make **one `getTopMovers` call** passing `sortBy` as an array of all needed sort criteria. The tool returns an independent ranked result set for each criterion — one call replaces many.

```
getTopMovers(
  sinceDay:      <period start>
  untilDay:      <today>
  documentTypes: ["Earnings Calls"]
  marketCaps:    <filter from Step 0>
  limit:         10
  sortBy:        ["stockChange", "investmentScore", "investmentScoreChange",
                  "sentimentScore", "sentimentScoreChange", "aspectScore", "marketcap"]
)
```

**If the user asked for only a specific metric** (e.g., "top stock movers"), pass only the relevant criterion in the `sortBy` array.

**The response is keyed by sort criterion:**
```json
{
  "stockChange":          { "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "investmentScore":      { "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "investmentScoreChange":{ "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "sentimentScore":       { "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "sentimentScoreChange": { "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "aspectScore":          { "topMovers": [...], "underperforming": [...], "overperforming": [...] },
  "marketcap":            { "topMovers": [...], "underperforming": [...], "overperforming": [...] }
}
```

**Leaderboard mapping** (render one leaderboard card per criterion):

| sortBy criterion | Card title | Primary column | Source array |
|------------------|-----------|----------------|--------------|
| `stockChange` | Top Stock Movers | Stock Δ (%) | `topMovers` |
| `investmentScore` | Highest Investment Score | Investment Score | `topMovers` |
| `investmentScoreChange` | Biggest Investment Gain | Investment Score Δ | `topMovers` |
| `sentimentScore` | Most Positive Sentiment | Sentiment Score | `topMovers` |
| `sentimentScoreChange` (desc) | Biggest Sentiment Shift — Most Bullish | Sentiment Δ | `topMovers` |
| `sentimentScoreChange` (asc) | Biggest Sentiment Shift — Most Bearish | Sentiment Δ | `underperforming` |
| `aspectScore` | Top Aspect Score | Aspect Score | `topMovers` |
| `marketcap` | Largest by Market Cap | Market Cap | `topMovers` |

**Sentiment Shift card**: render as a single card with two sub-tables — Most Bullish (from `topMovers`) on top, Most Bearish (from `underperforming`) below. This gives both sides of the sentiment picture from the single `sentimentScoreChange` call.

**Handling sparse data:** If any leaderboard returns fewer than 5 companies, widen the date range by 7 days and re-call for that criterion only — note the expansion in the relevant leaderboard heading.

### 2b. getTrends *(when trends section is needed)*

```
getTrends(
  documentTypes: ["Earnings Calls"]
  sinceDay:      <period start>
  untilDay:      <today>
  limit:         30
  sortBy:        "score"
)
```

Note: `getTrends` does not accept a `marketCaps` parameter — the market cap filter only applies to `getTopMovers`.

### 2c. getSpeakers — Executives *(when Voice of the Market is needed)*

**Most bullish:** `speakerTypes: ["Executives"]`, `sortBy: "sentiment"`, `sortOrder: "desc"`, `limit: 20`, with the same date range and `documentTypes: ["Earnings Calls"]`

**Most bearish:** Same but `sortOrder: "asc"`, `limit: 10`

### 2d. getSpeakers — Analysts *(when Voice of the Market is needed)*

Same as 2c but `speakerTypes: ["Analysts"]`.

---

## Step 3: Process the Data

### getTopMovers results

Each criterion key in the response contains `topMovers`, `underperforming`, and `overperforming` arrays. Use `topMovers` as the primary source for each leaderboard. For the Sentiment Shift card, combine `topMovers` (bullish) and `underperforming` (bearish) for `sentimentScoreChange`.

Build a deduplicated master list by `id` across all arrays — use this for the header company count.

### Field Reference

See `reference/api-fields.md` for the complete field reference.

---

## Step 4: Generate the Report

**Detect the environment before rendering:**

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | Markdown written to file |

**Design the layout and visual style yourself.** Read `reference/html-spec.md` for the required sections and data fields.

### claude.ai — inline HTML constraints:
- **No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags** — output only a `<style>` block followed by the HTML content
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--font-mono)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- All data embedded as inline JS constants at the top of the `<script>` block
- Company names must link to ProntoNLP (see Company Link Format below)
- **Only include sections the user asked for.** Use flex or grid so removing a section never breaks the layout.

### Claude Cowork — markdown file constraints:
- Write the report to a file named `market-pulse-report.md` in the current directory using the `Write` or `Edit` tool
- Use `##` and `###` headings for all sections
- Use markdown tables for leaderboards and data grids
- Use `**bold**` for key values and signal labels
- Replace charts with ranked text summaries
- Company links as markdown links: `[Company Name](https://prontonlp.prontonlp.com/#/ref/$COMPANY{id})`
- Only include sections the user asked for
- After writing the file, tell the user the filename and open it

### Sections to include:

| Section | Include when |
|---------|-------------|
| **Highlights of the Week** (leaderboard cards in a responsive grid) | User asked for movers or a broad overview |
| **Trending Topics** | User asked for trends or full report |
| **Voice of the Market** (Executives + Analysts) | User asked for speakers or full report |

Each section is independently removable. The grid/flex layout must reflow cleanly.

---

## Company Link Format

```html
<a href="https://prontonlp.prontonlp.com/#/ref/$COMPANY{id}" class="co-link">{name}</a>
```

where `{id}` is the numeric company `id` field from the tool response (prefix with `$COMPANY`).

---

## Delivery

See `examples/sample-delivery.md` for concrete delivery examples.

After generating the HTML, summarize key findings:
- **Time period**: exact dates covered (and any date range expansion applied)
- **Companies**: count and filters applied
- **Top stock mover**: name, ticker, % change (from the `stockChange` leaderboard)
- **Notable signals**: companies appearing across multiple leaderboards (consistent outperformers)
- **Potential Buy signals**: companies from `underperforming` category with strong investment scores
- **Top trend** *(if trends included)*: #1 topic and its change %
- **Most bullish / bearish** executive and analyst *(if speakers included)*
- If Movers-only, mention that asking for a **full report** will also surface Trending Topics and Voice of the Market.
