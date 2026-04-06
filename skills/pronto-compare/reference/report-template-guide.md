# pronto-compare — Report Template Guide

---

## Comparison Modes

| Mode | Triggered by | Scoring dimensions | Sections shown |
|------|-------------|-------------------|----------------|
| **Company vs Company** | All entities are companies | 9 | All 8 |
| **Sector vs Sector** | All entities are sectors | 7 | 1, 2 (sector cards), 3, 5 (sector voice), 6, 7, 8 — Section 4 OMITTED |
| **Mixed** | At least 1 company + at least 1 sector | 7 universal + 2 company-only (N/A for sectors) | All 8; company-only rows show N/A for sector columns |

Default to **Full Comparison** unless user signals narrower scope.

---

## Entity Color Coding

Assign each entity a distinct accent color. Use consistently across all charts, scorecard columns, and section headers.

```
Entity A → blue:   #3B82F6
Entity B → purple: #8B5CF6
Entity C → orange: #F59E0B
Entity D → teal:   #14B8A6
Entity E → pink:   #EC4899
```

---

## Scorecard Row Coloring

### Cell background (winner/loser)
- **Winner cell**: green background `#dcfce7`, text `#15803d`, bold
- **Loser cell** (2 entities only): red background `#fee2e2`, text `#b91c1c`
- **Middle** (3+ entities): neutral — only winner gets green highlight
- **N/A cell** (sector in company-only row): neutral, text `var(--color-text-tertiary)`, labeled "N/A — Sector"
- **Tie row**: — (em dash) in Winner column, no color applied

### Value text coloring (inside each cell — independent of winner/loser background)
Apply color to the numeric value itself, regardless of which cell it's in:
- **Positive value** (value **> 0** — `+X%`, positive sentiment, positive stock change): `color: #1D9E75` (green)
- **Negative value** (value **< 0** — `−X%`, negative sentiment, negative stock change): `color: #D85A30` (red)
- **Zero** (value **= 0**): no color — use default inherited text color
- **N/A**: `color: var(--color-text-tertiary)`

Example: a loser cell showing `−12.3%` gets red background (loser) AND red text on the number. A winner cell showing `+38.4%` gets green background AND green text. A non-winner cell in a 3+ comparison showing `+22.1%` gets neutral background but still green text on the positive number.

### Winner column — name the actual entity on every row
- **Every dimension row**: `🏆 [EntityName]` — use the actual ticker or sector name, never a placeholder letter
  - e.g. `🏆 NVDA`, `🏆 IT Sector`, `🏆 Health Care`
- **Direction-only rows**: name the RISING entity if they differ; use `—` if both have the same direction
- **Overall Wins row**: `🏆 [EntityName] (N wins)` — bold

---

## Section 1: Overall Scorecard

One HTML table, one column per entity + Winner column.

**Rows for Company vs Company:**
```
Sentiment Score | Sentiment Direction | Investment Score | Investment Direction |
Stock YTD | Stock 6M | Earnings Reaction | Analyst Sentiment |
Exec Sentiment | Exec-Analyst Gap | Revenue (fwd) | EPS (fwd) | Risk Profile | Overall Wins
```

**Rows for Sector vs Sector:**
```
Sentiment Score | Sentiment Direction | Investment Score | Investment Direction |
Stock Performance (top mover) | Theme Momentum | Risk Profile | Overall Wins
```

**Rows for Mixed (Company + Sector):**
All universal rows first, then company-only rows with N/A for sector columns:
```
Sentiment Score | Investment Score | Sentiment Direction | Investment Direction |
Stock Performance | Theme Momentum | Risk Profile |
Earnings Reaction [company-only: N/A for sectors] |
Financial Outlook [company-only: N/A for sectors] |
Overall Wins
```

**Always show direction arrows inline**: `0.48 ↑` for RISING (green `#1D9E75`), `0.31 ↓` for FALLING (red `#D85A30`), `0.38 →` for FLAT (neutral)

**Stock / % change values**: color the number itself — `+38.4%` green, `−12.3%` red — in every cell regardless of whether it's the winner cell or not

---

## Section 2: Quarter Cards (Companies) / Sector Summary Cards (Sectors)

### Company block (per company entity):
```html
<div class="co-section">
  <div class="co-label">
    <span class="co-dot" style="background:[company-color]"></span>
    [TICKER] <span style="font-size:11px;color:var(--color-text-tertiary)">Company</span>
  </div>
  <div class="qtr-grid">
    <!-- one .qtr-card per quarter: Q1, Q2, Q3, Q4 -->
  </div>
  <div class="entity-summary">
    Sentiment: RISING from X.XX (Q1) to X.XX (Q4) |
    Investment: RISING/FALLING |
    Stock reacted positively to N of M calls
  </div>
</div>
```

Quarter card CSS:
```css
.co-section { margin-bottom: 32px; }
.co-label { font-size: 13px; font-weight: 700; color: var(--color-text-secondary); margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }
.co-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.qtr-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 14px; }
.qtr-card { border: 1px solid var(--color-border-tertiary); border-radius: var(--border-radius-md); padding: 14px; background: var(--color-background-primary); }
.qtr-card.leader { border-color: #1D9E75; border-width: 2px; }
.qtr-header { font-size: 11px; font-weight: 600; color: var(--color-text-tertiary); margin-bottom: 10px; }
.qtr-metric { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 5px; }
.up { color: #1D9E75; } .down { color: #D85A30; }
```

### Sector block (per sector entity):
```html
<div class="co-section">
  <div class="co-label">
    <span class="co-dot" style="background:[sector-color]"></span>
    [Sector Name] <span style="font-size:11px;color:var(--color-text-tertiary)">Sector</span>
  </div>
  <div class="sector-summary-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;">
    <div class="sector-card" style="border:1px solid var(--color-border-tertiary);border-radius:var(--border-radius-md);padding:14px;background:var(--color-background-primary);">
      <div style="font-size:11px;color:var(--color-text-tertiary);margin-bottom:6px;">Sentiment Score</div>
      <div style="font-size:18px;font-weight:700;color:var(--color-text-primary);">X.XX <span class="up">↑</span></div>
      <div style="font-size:11px;color:#1D9E75;">RISING</div>
    </div>
    <!-- investment score card, top mover card, fastest-rising theme card, dominant positive event card, dominant negative event card -->
  </div>
</div>
```

### Comparison callout (after all entity blocks):
```html
<div style="background:var(--color-background-secondary);border-left:3px solid #3B82F6;padding:12px 16px;border-radius:var(--border-radius-md);margin-top:16px;font-size:13px;color:var(--color-text-primary);">
  📊 Comparison: [Entity A] sentiment is <strong>RISING</strong>, [Entity B] sector sentiment is <strong>FALLING</strong> — diverging trajectories.
</div>
```

---

## Section 3: Stock Performance

**Chart 1** — Grouped bar chart.
- Companies: YTD / 6M / 1Y for each company
- Sectors: Top mover YTD only (label bar as "[Top Company] — sector leader")
- Mixed: show all entities; footnote clarifies any sector proxy values

Table below chart. Footnote if sector values are top-mover proxies.

---

## Section 4: Financial Outlook (skip if all entities are sectors)

Table: one column per entity.

| Metric | [Company A] | [Sector B] | [Company C] |
|--------|------------|------------|------------|
| Revenue (fwd) | $XB | N/A — Sector | $XB |
| EPS GAAP (fwd) | X.XX | N/A — Sector | X.XX |
| EBITDA (fwd) | $XB | N/A — Sector | $XB |
| FCF (fwd) | $XB | N/A — Sector | $XB |

Highlight highest value per row in green. If all companies in a row are N/A, omit the row.

If ALL entities are sectors, omit this section entirely with a footnote: "Financial forecasts are not available at the sector level. See individual company reports for per-company estimates."

---

## Section 5: Speaker Sentiment

**Chart 2** — Grouped bar. Use available scores per entity.

| Speaker | [Company A] | [Sector B] | [Company C] |
|---------|------------|------------|------------|
| CEO | X.XX | N/A | X.XX |
| CFO | X.XX | N/A | X.XX |
| Exec Avg | X.XX | X.XX (sector leader) | X.XX |
| Analyst Avg | X.XX | N/A | X.XX |
| Exec-Analyst Gap | +X.XX | — | +X.XX |
| Most Bullish Analyst Firm | [Firm] (X.XX) | [Firm] (sector leader) | [Firm] (X.XX) |

For sectors: label exec row value as "Exec Avg (sector leader)" and analyst firm row as "Most bullish firm covering sector leader".

---

## Section 6: Trending Topics

Side-by-side topic lists, one per entity. Flag overlapping themes below.

```
[Entity A]              [Entity B]              [Entity C]
1. Topic X ↑+84%       1. Topic X ↑+61%        1. Topic Y ↑+42%
2. Topic Y ↑+38%       2. Topic Z ↑+29%        2. Topic X ↑+18%
3. Topic Z ↑+22%       3. Topic W ↑+17%        3. Topic Z ↑+11%
```

Below the lists:
- **Shared across all:** [Topic] → 🔵 Macro theme
- **Shared by 2:** [Topic] in [A] and [B] → Emerging convergence
- **Unique to [Entity]:** [Topic] → [Entity] narrative
- **Systemic risk topic (2+):** [Topic] → ⚠️ Sector-wide risk

---

## Section 7: Risk Comparison

Table: ✅ (present) / — (not present) per entity.

| Risk | [A] | [B] | [C] | Type |
|------|-----|-----|-----|------|
| [Risk name] | ✅ | ✅ | — | Systemic |
| [Risk name] | — | ✅ | — | Idiosyncratic |

Source:
- Companies: risks from `getCompanyDescription` + negative events from per-quarter `getAnalytics`
- Sectors: dominant negative event types from sector-level `getAnalytics`

---

## Section 8: Verdict

**3–4 paragraphs:**

1. **Overall leader** — "Overall leader: [Entity] wins N of M scored dimensions. Key strengths: [2–3 points]."
2. **Divergence / re-rating signal** — "[Entity] shows a potential undervalued signal: investment score RISING but stock only +X% YTD. Gap may close if [catalyst]."
3. **Highest risk** — "[Entity] carries the most concentrated risk: [top risk] is idiosyncratic and not shared by [peers/sectors]."
4. **Bottom line** — "If you had to pick one: [Entity] — because [2–3 sentence rationale]."

**For mixed company-vs-sector comparisons**, add context paragraph:
> "Note: comparing [Company] to the [Sector] sector is not a direct apples-to-apples comparison. [Company] carries single-stock concentration risk while [Sector] provides breadth across [N] companies. On the metrics available for both, [Company] leads on [dimensions], suggesting meaningful alpha vs the sector average."

---

## Charts Reference

| Chart | Section | Type | Data |
|-------|---------|------|------|
| Chart 1 | 3 | Grouped bar | Stock % change per entity (YTD/6M/1Y for companies; top mover YTD for sectors) |
| Chart 2 | 5 | Grouped bar | Speaker scores per entity (CEO/CFO/Exec/Analyst where available) |
| Chart 3 | 2 | Multi-line | Sentiment score trend (companies: Q1–Q4 per quarter; sectors: single aggregate point labeled "Sector Avg") |
| Chart 4 | 2 | Multi-line | Investment score trend (same logic) |

Load Chart.js once. All data inline JS. No external files.

---

## Formatting Rules

- Entity names in column headers: use ticker for companies (e.g. "NVDA"), short sector name for sectors (e.g. "IT Sector")
- Label entity type after name in headers: "NVDA (Company)" | "Info Tech (Sector)"
- Direction arrows: ↑ for RISING (green `#1D9E75`), ↓ for FALLING (red `#D85A30`), → for FLAT (neutral)
- Sentiment scores: 2 decimal places (e.g. 0.48)
- Investment scores: display raw value from API — do not assume a scale
- Stock changes: 1 decimal place with sign (e.g. +61.8%, −12.3%)
- Topic change: integer with sign (e.g. +84%, −18%)
- Sector stock values: always footnote if using top-mover proxy rather than sector index
- N/A cells for company-only rows in sector columns: text "N/A — Sector", styled in `var(--color-text-tertiary)`
- Never show a row with all N/A values across all entities — skip it and add footnote
- Never fabricate data — missing metric = N/A, never invented
