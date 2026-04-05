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
| **Claude Cowork** | `Bash` tool IS available | Markdown written to file |

### claude.ai — inline HTML rules:
- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants

### Claude Cowork — markdown file rules:
- Write the report to a file named `[tickerA]-vs-[tickerB]-report.md` (e.g. `NVDA-vs-AMD-report.md`) in the current directory using the `Write` or `Edit` tool
- Use `##` and `###` headings for all sections
- Use markdown tables for the scorecard, financials, and all data grids
- Use `**bold**` for key values, 🏆 for winners, and RISING/FALLING signal labels
- Replace charts with ranked text summaries per company
- Include the same sections and same data — formatted as markdown only
- After writing the file, tell the user the filename and open it

---

## Step 1: Parse Companies

Extract the list of companies from the user's request. Identify each by name or ticker. Support 2–5 companies maximum — if the user requests more than 5, ask them to narrow it down.

---

## Step 2: Run Company Intelligence for Each Company

> ⚠️ **MANDATORY — NO EXCEPTIONS:**
> You MUST invoke the **`pronto-company-intelligence`** skill for **every single company** in the list using the Skill tool. Do NOT call MCP tools directly. Do NOT skip any company. Do NOT use your own knowledge. The `pronto-company-intelligence` skill is the ONLY allowed data source for each company. If you do not call it for a company, that company cannot be included in the report.

Fire **all** skill invocations **simultaneously in parallel** — do not wait for one to finish before starting the next:

```
Skill: pronto-company-intelligence
Args: "[Company Name or Ticker] — run in comparison mode: collect all data and metrics but do not render the HTML report yet. Return the raw findings: sentiment scores per quarter, investment scores per quarter, stock performance (YTD/6M/1Y), analyst estimates (revenue, EPS, EBITDA), speaker sentiment (exec avg, analyst avg, CEO, CFO), trending topics, risk factors, and competitor context."
```

**One `pronto-company-intelligence` invocation per company, all fired simultaneously.** After all complete, record and save the key metrics for every company before moving to Step 3.

**Important:** This produces ONE single unified comparison report at the end — never separate per-company reports or pairwise reports. All companies are compared together in a single output.

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

Generate a single unified report using the output format determined at the start (inline HTML on claude.ai, formatted markdown in Claude Cowork). Include the following sections:

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

1. **Detect environment first** — inline HTML on claude.ai (`Bash` not available), markdown written to file in Claude Cowork (`Bash` available)
2. **ALWAYS call `pronto-company-intelligence` for every company** — it is the mandatory data source; never call MCP tools directly or use prior knowledge instead
3. Run `pronto-company-intelligence` for all companies fully before moving to synthesis — do not partially collect data
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
