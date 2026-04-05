---
name: pronto-compare-companies
description: "Generates a unified side-by-side comparison report for two or more named companies or tickers — scoring each across sentiment, investment score, stock performance, analyst and executive sentiment, financial forecasts, trending topics, and risk factors to determine an overall leader. Use when the user wants to compare specific named companies or tickers against each other. Triggers on phrases like: '[company] vs [company]', 'compare [company] and [company]', 'which is better [company] or [company]', 'side by side comparison of [company] and [company]', '[company] versus [company]', 'who wins between [company] and [company]'. Supports 2 to 5 companies. Do not use for a single named company — use the company intelligence skill. Do not use for sector-wide or broad market questions."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Company Comparison Report Generator

Produces a side-by-side intelligence comparison of two or more named companies. For each company, it runs the full `pronto-company-intelligence` analysis, then synthesizes the results into a unified comparison report showing which company leads and lags on every dimension.

---

## Output Format — Environment-Aware

**Detect the environment before rendering:**

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | HTML written to file |

### HTML rules (apply to BOTH environments — only delivery differs):
- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named `[tickerA]-vs-[tickerB]-report.html` (e.g. `NVDA-vs-AMD-report.html`) using the `Write` tool
- After writing, tell the user the filename and open it

---

## Step 1: Parse Companies

Extract the list of companies from the user's request. Identify each by name or ticker. Support 2–5 companies maximum — if the user requests more than 5, ask them to narrow it down.

---

## Step 2: Invoke pronto-company-intelligence for Each Company

> ⚠️ **STOP — READ BEFORE DOING ANYTHING ELSE:**
> Do NOT call `getAnalytics`, `getCompanyDescription`, `getSpeakers`, `getStockPrices`, or ANY other MCP tool directly in this step.
> Do NOT search for tools. Do NOT use your own knowledge.
> You MUST use the **Skill tool** to invoke **`pronto-company-intelligence`** as an actual tool call for every company. This is the ONLY allowed action in this step.

**Invoke the Skill tool — one call per company, all fired simultaneously in parallel:**

Use the Skill tool with:
- `skill`: `pronto-company-intelligence`
- `args`: `"[Company Name or Ticker] — comparison mode: run your full data collection but do NOT render any report. Return all raw metrics: sentiment score per quarter (Q1–Q4) and direction (RISING/FALLING), investment score per quarter and direction, stock reaction per earnings call, YTD/6M/1Y stock %, revenue/EPS/EBITDA/FCF estimates, exec avg sentiment, analyst avg sentiment, CEO sentiment, CFO sentiment, exec-analyst gap, top 3 topics, top 3 risks, most bullish analyst, most bearish analyst."`

Example — for a NVDA vs AMD comparison, fire these two Skill tool calls at the same time:
- Skill tool → `pronto-company-intelligence`, args: `"NVDA — comparison mode…"`
- Skill tool → `pronto-company-intelligence`, args: `"AMD — comparison mode…"`

**After all Skill tool calls complete**, record the returned metrics for every company, then proceed to Step 3.

**This produces ONE single unified comparison report — never separate per-company reports.**

**Metrics to capture per company:**
- Sector and sub-sector
- Sentiment score per quarter (Q1–Q4) + overall direction (RISING/FALLING)
- Investment score per quarter + overall direction
- Stock reaction per earnings call (positive/negative, N of M calls)
- YTD / 6M / 1Y stock % change
- Revenue, EPS, EBITDA, FCF consensus estimates (forward)
- Executive avg sentiment score
- Analyst avg sentiment score
- Exec vs analyst gap
- CEO sentiment score
- CFO sentiment score
- Top 3 trending topics
- Top 3 risk factors
- Most bullish analyst name + score
- Most bearish analyst name + score

---

## Step 3: Synthesize & Score

After all companies are analyzed, score each company across every dimension and determine a winner per metric:

| Dimension | Winner determination |
|-----------|---------------------|
| Sentiment trend | Highest overall sentiment score AND RISING direction |
| Investment score | Highest investment score |
| Stock performance | Best YTD % change |
| Earnings call reaction | Most positive stock reactions (N of M) |
| Analyst consensus | Highest analyst avg sentiment |
| Financial outlook | Best consensus revenue + EPS growth |
| Exec confidence | Highest executive avg sentiment |
| Risk profile | Fewest/least severe risk factors |

Tally the wins per company across all dimensions. The company with the most wins is the **overall leader**.

**Always explicitly state:**
- "Winner on sentiment: [Company] (X.XX, RISING)"
- "Winner on investment score: [Company] (X.X)"
- "Winner on stock performance: [Company] (+X% YTD)"
- "Overall leader: [Company] — leads on N of M dimensions"
- "Key edge: [Company A] beats [Company B] on X but lags on Y"

---

## Step 4: Render the Comparison Report

Generate a single unified HTML report. On claude.ai output it inline in the chat; in Claude Cowork write it to `[tickerA]-vs-[tickerB]-report.html`. Include the following sections:

### Title
```
# [Company A] vs [Company B] [vs Company C...] — Comparison Report
Generated: [Date] | Companies: [N] | Period: Past Year
```

### Section 1: Overall Scorecard
A compact summary card per company showing all key metrics side by side. Highlight the winner of each row in green, loser in red.

| Metric | [Company A] | [Company B] | [Company C] | Winner |
|--------|------------|------------|------------|--------|
| Sentiment Score | X.XX ↑ | X.XX ↓ | X.XX ↑ | 🏆 A |
| Investment Score | X.X | X.X | X.X | 🏆 C |
| Stock YTD | +X% | −X% | +X% | 🏆 A/C |
| EPS Growth (fwd) | +X% | +X% | +X% | 🏆 B |
| Analyst Sentiment | X.XX | X.XX | X.XX | 🏆 A |
| Exec vs Analyst Gap | +X.XX | −X.XX | +X.XX | — |
| Risk Level | Low | High | Medium | 🏆 A |
| **Overall Wins** | **N** | **N** | **N** | **🏆 [Leader]** |

### Section 2: Earnings Sentiment — Quarter Over Quarter
For each company, show its quarter-by-quarter sentiment and investment score trend. Use the quarter card layout from company-intelligence (CSS grid, one card per quarter). Color code: leading company cards get a green border highlight.

Show all companies' quarter cards stacked or in a tabbed layout so they can be directly compared.

### Section 3: Stock Performance Comparison
Chart 1 — Side-by-side bar: YTD / 6M / 1Y % change for all companies (grouped bars per company, one group per period).

### Section 4: Financial Outlook Comparison
Table: Revenue / EPS / EBITDA / FCF forward estimates side by side for all companies. Highlight the highest value in each row.

### Section 5: Analyst & Executive Sentiment Comparison
Chart 2 — Grouped bar: CEO sentiment / CFO sentiment / Exec avg / Analyst avg per company.

Table: Exec vs analyst gap per company with interpretation (who is more over-optimistic vs more in line with the street).

### Section 6: Trending Topics — Overlap & Divergence
- Topics mentioned by ALL companies → shared macro themes
- Topics unique to one company → company-specific narratives
- Flag if one company is more exposed to a risk topic than others

### Section 7: Risk Comparison
Side-by-side risk factor table. Flag any risk that appears across multiple companies (systemic sector risk) vs risks unique to one company.

### Section 8: Verdict
3–4 paragraph synthesis:
- Which company leads overall and why
- Which company is the most undervalued (high investment score relative to stock performance)
- Which company carries the most risk
- Recommended focus: "If you had to pick one, [Company] — because..."

---

## Charts

| Chart | Content | Type |
|-------|---------|------|
| Chart 1 | Stock % change (YTD/6M/1Y) per company | Grouped bar, green/red |
| Chart 2 | CEO / CFO / Exec avg / Analyst avg sentiment per company | Grouped bar |
| Chart 3 | Sentiment score trend per quarter per company | Multi-line chart, one line per company |
| Chart 4 | Investment score trend per quarter per company | Multi-line chart |

Place each chart within its corresponding section.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Company not found in company-intelligence | Try ticker instead of name; note the issue and continue with remaining companies |
| Fewer than 4 quarters for a company | Note the gap; include available quarters only |
| More than 5 companies requested | Ask user to narrow down to 5 or fewer |
| One company has no analyst data | Show "N/A" for that company in analyst rows; do not skip the row |
| Metrics not directly comparable (different fiscal years) | Note the mismatch; compare on TTM basis where possible |

---

## Best Practices

1. **Detect environment first** — inline HTML on claude.ai (`Bash` not available), HTML written to `[tickerA]-vs-[tickerB]-report.html` file in Claude Cowork (`Bash` available)
2. **NEVER call MCP tools directly** — the Skill tool calling `pronto-company-intelligence` is the only allowed data source per company; no `getAnalytics`, no `getCompanyDescription`, no `getSpeakers`, nothing else
3. Run the `pronto-company-intelligence` Skill tool for every company before moving to synthesis — do not partially collect data
3. Always produce an explicit winner per dimension — never leave a row without a verdict
4. Surface divergences — a company that looks strong on sentiment but weak on financials is more interesting than a simple winner/loser
5. Never fabricate data — if a metric is missing for one company, show "N/A" honestly
6. Do not mention tool names in the report — describe actions instead

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Exact metrics to capture per company, scoring matrix, cross-company topic comparison logic, enum reference |
| `reference/report-template-guide.md` | HTML layout guide — company colors, scorecard coloring rules, section-by-section structure, chart placement, formatting rules |
| `examples/nvda-vs-amd.md` | Full worked example: NVDA vs AMD — parallel invocations, captured metrics table, scoring matrix, topic overlap analysis, report structure summary |
| `evaluations/criteria.md` | Evaluation rubric — triggering, data collection, scoring, HTML structure, visual design, formatting, and error handling criteria |
| `evals/evals.json` | 4 structured test cases with assertions: basic 2-company, 3-company, single-company (should NOT trigger), and cross-sector comparison |
