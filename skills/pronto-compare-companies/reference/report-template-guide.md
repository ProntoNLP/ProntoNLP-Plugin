# Comparison Report Template Guide

---

## Report Modes

| Mode | Use when | Sections |
|------|----------|---------|
| **Full Comparison** (default) | General "compare X vs Y" request | All 8 |
| **Quick Comparison** | "quick comparison", "brief overview" | 1, 3, 8 (Scorecard, Stock, Verdict) |
| **Sentiment Focus** | "which has better sentiment", "earnings comparison" | 1, 2, 5, 8 |
| **Financial Focus** | "financials comparison", "which has better numbers" | 1, 3, 4, 8 |

Default to **Full Comparison** unless user signals narrower scope.

---

## HTML Layout Principles

### Company color coding
Assign each company a distinct accent color. Use consistently across all charts and tables.

```
Company A → blue:   #3B82F6
Company B → purple: #8B5CF6
Company C → orange: #F59E0B
Company D → teal:   #14B8A6
Company E → pink:   #EC4899
```

### Scorecard row coloring
- **Winner cell**: green background `#dcfce7`, text `#15803d`, bold
- **Loser cell** (only when 2 companies): red background `#fee2e2`, text `#b91c1c`
- **Middle** (3+ companies): neutral — only winner gets the green highlight
- **Winner column**: add a trophy icon `🏆` in the Winner cell

### Quarter cards in Section 2
Use the same CSS grid layout as company-intelligence but add a colored top border per company:

```html
<style>
  .company-block { margin-bottom: 32px; }
  .company-label {
    font-size: 14px;
    font-weight: 700;
    padding: 8px 0;
    border-bottom: 3px solid <company-color>;
    margin-bottom: 12px;
    color: var(--color-text-primary);
  }
  .qtr-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 12px;
  }
  .qtr-card {
    border: 1px solid var(--color-border-tertiary);
    border-radius: var(--border-radius-lg);
    padding: 14px;
    background: var(--color-background-primary);
    min-width: 0;
  }
  .qtr-card.leader { border-color: #1D9E75; border-width: 2px; }
</style>
```

Render one `company-block` per company, each containing its quarter cards. The block with the highest average sentiment score gets the `leader` class on its cards.

---

## Section-by-Section Guide

### Section 1: Overall Scorecard

One HTML table, one column per company + Winner column.

```
Rows: Sentiment Score | Sentiment Direction | Investment Score |
      Stock YTD | Stock 6M | Analyst Sentiment |
      Exec Sentiment | Exec-Analyst Gap | Revenue Growth |
      EPS (fwd) | Risk Level | Overall Wins
```

Rules:
- Always show direction arrows inline: `0.38 ↑` for RISING, `0.31 ↓` for FALLING
- "Risk Level": Low / Medium / High — judge from number and severity of risk factors
- "Overall Wins" row: bold, show count e.g. "5 / 9", winner gets `🏆`
- If only 2 companies: color winner green AND loser red. If 3+: only color winner green.

---

### Section 2: Earnings Sentiment — Quarter Over Quarter

One block per company (stacked vertically), each with 1–4 quarter cards.

Show under each block:
- "Sentiment: RISING from X.XX (Q1) to X.XX (Q4)" or FALLING
- "Investment: RISING / FALLING"
- "Stock reacted positively to N of M calls"

After all blocks, add a callout box:
```
📊 Comparison: [Company A] sentiment is RISING while [Company B] is FALLING — diverging trajectories.
```
(Only add this if directions actually differ — if same direction, compare magnitude instead.)

---

### Section 3: Stock Performance Comparison

Chart 1 — Grouped bar chart (one group per period: YTD, 6M, 1Y; one bar per company per group).

Below chart: table showing exact % values.

| Period | [Company A] | [Company B] | [Company C] | Leader |
|--------|------------|------------|------------|--------|
| YTD    | +X%        | −X%        | +X%        | 🏆 A  |
| 6M     | +X%        | +X%        | +X%        | 🏆 C  |
| 1Y     | +X%        | +X%        | −X%        | 🏆 A  |

---

### Section 4: Financial Outlook Comparison

Table with one column per company. Highlight the highest value in each row (green bold).

| Metric | [A] | [B] | [C] | Leader |
|--------|-----|-----|-----|--------|
| Revenue (fwd, $B) | | | | |
| EPS GAAP (fwd) | | | | |
| EBITDA (fwd, $B) | | | | |
| FCF (fwd, $B) | | | | |

If fiscal years differ between companies, note: "Note: [Company A] fiscal year ends in September."

---

### Section 5: Analyst & Executive Sentiment

Chart 2 — Grouped bar: CEO / CFO / Exec Avg / Analyst Avg, one group per company.

Table:
| Speaker | [A] | [B] | [C] |
|---------|-----|-----|-----|
| CEO     | X.XX | X.XX | X.XX |
| CFO     | X.XX | X.XX | X.XX |
| Exec Avg | X.XX | X.XX | X.XX |
| Analyst Avg | X.XX | X.XX | X.XX |
| Exec-Analyst Gap | +X.XX | −X.XX | +X.XX |

Gap interpretation row: "+0.12 = management more optimistic than street" etc.

---

### Section 6: Trending Topics

Three lists side by side (one per company):

```
[Company A]         [Company B]         [Company C]
1. AI Agents        1. Cloud Migration  1. AI Agents
2. Margins          2. AI Agents        2. Supply Chain
3. Tariffs          3. Interest Rates   3. Margins
```

Below: flag shared and unique topics.

---

### Section 7: Risk Comparison

Table with risk factors. Use ✅ (present) and — (not mentioned).

| Risk | [A] | [B] | [C] | Type |
|------|-----|-----|-----|------|
| Tariff exposure | ✅ | ✅ | — | Systemic |
| Margin compression | ✅ | — | ✅ | Systemic |
| Regulatory risk | — | ✅ | — | Idiosyncratic |

---

### Section 8: Verdict

3–4 paragraphs:
1. "Overall leader: [Company] — wins N of M dimensions. Strengths: ..."
2. "Most undervalued signal: [Company] — high investment score (X.X) but stock only up X% YTD. Gap may close."
3. "Highest risk: [Company] — [top risk] is idiosyncratic and not shared by peers."
4. "Bottom line: If you had to pick one — [Company], because [2–3 sentence rationale]."

---

## Charts Reference

| Chart | Section | Type | Data |
|-------|---------|------|------|
| Chart 1 | Section 3 | Grouped bar | stockChangeYTD/6M/1Y per company |
| Chart 2 | Section 5 | Grouped bar | CEO/CFO/ExecAvg/AnalystAvg per company |
| Chart 3 | Section 2 | Multi-line | sentimentScore Q1–Q4 per company |
| Chart 4 | Section 2 | Multi-line | investmentScore Q1–Q4 per company |

All charts inline — no file writing. Load Chart.js once at top of HTML output.

---

## Formatting Rules

- Company names in column headers: use ticker if available (e.g. "NVDA" not "NVIDIA Corporation")
- Direction arrows: ↑ for RISING (green), ↓ for FALLING (red)
- Sentiment scores: 2 decimal places (e.g. 0.38)
- Investment scores: 1 decimal place (e.g. 6.8)
- Stock changes: 1 decimal place with sign (e.g. +12.4%, −3.1%)
- Never show a row with all N/A — if data is fully missing for all companies, skip the row and note it in a footnote
