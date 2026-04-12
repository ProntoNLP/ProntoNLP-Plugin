# Sector Intelligence — Report Template Guide

---

## Report Modes

| Mode | Use when | Batches | Sections |
|------|----------|---------|---------|
| **Full Report** (default) | "analyze tech sector", "sector report on healthcare" | 5 | All 8 |
| **Movers Report** | "top movers in financials", "what's performing in energy" | 2 | 1–2 |
| **Theme Analysis** | "what are tech companies talking about", "AI in semiconductors" | 3 | 1, 4–6 |
| **Sentiment Report** | "sentiment in real estate", "how bullish is the sector" | 3 | 1, 3, 6–7 |

Default to **Full Report** unless the user signals a narrower scope.

---

## HTML Layout Principles

### Design tokens (mandatory)
```css
var(--color-text-primary)        /* main text */
var(--color-text-secondary)      /* muted/label text */
var(--color-text-tertiary)       /* dim text */
var(--color-background-primary)  /* card/surface background */
var(--color-background-secondary)/* subtle background / row stripes */
var(--color-border-tertiary)     /* borders and dividers */
var(--font-sans)                 /* body font */
var(--border-radius-lg)          /* card border radius */
var(--border-radius-md)          /* inner element radius */
```

### Signal colors (hardcoded)
```css
green: #1D9E75   /* positive sentiment, RISING, buy signals */
red:   #D85A30   /* negative sentiment, FALLING, risk signals */
```

### Leaderboard card layout

Each leaderboard in Section 2 is a card with a title, rank number, and a mini-table of companies:

```html
<div class="leaderboard-card">
  <div class="card-header">
    <span class="card-title">Top by Investment Score</span>
    <span class="card-period">Past Year</span>
  </div>
  <table class="rank-table">
    <thead>
      <tr><th>#</th><th>Company</th><th>Ticker</th><th>Score</th><th>Δ</th></tr>
    </thead>
    <tbody>
      <tr class="rank-row">
        <td class="rank-num">1</td>
        <td><a href="..." class="co-link">Company Name</a></td>
        <td class="ticker">TICK</td>
        <td class="score-cell">0.87</td>
        <td class="delta positive">+0.3</td>
      </tr>
    </tbody>
  </table>
</div>
```

Grid all leaderboard cards: `display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px;`

### Signal badges

Use inline badges for direction labels:

```html
<span class="badge rising">RISING ↑</span>
<span class="badge falling">FALLING ↓</span>
```

```css
.badge { padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 700; }
.badge.rising  { background: #dcfce7; color: #15803d; }
.badge.falling { background: #fee2e2; color: #b91c1c; }
```

### Company link format

`{org}` is retrieved by calling `getOrganization` in Batch 1. Never hardcode it.

```html
<a href="https://{org}.prontonlp.com/#/ref/$COMPANY{id}" class="co-link">{name}</a>
```

where `{id}` is the numeric `id` field from the tool response.

---

## Section-by-Section Guide

### Title Block

```
# [Sector Name] — Sector Intelligence Report
Generated: [Date] | Period: [sinceDay] to [untilDay]
Companies analyzed: [N] | Document type: Earnings Calls
```

---

### Section 1: Executive Summary

2–3 paragraphs. Must explicitly state:

1. **Sector direction** — "Sector sentiment is RISING / FALLING — average score: X.XX (investment score: X.X)"
2. **Top performers** — name the top 3 by investment score; name the bottom 3 laggards
3. **Dominant theme** — the single topic or event driving the sector right now
4. **Divergence signal** — most notable `underperforming` company (high score + falling stock)
5. **3-point thesis** — three concise bullet conclusions about the sector outlook

---

### Section 2: Sector Movers

One leaderboard card per criterion, laid out in a responsive grid.

| Card title | Data source | Primary field | Source array |
|-----------|------------|--------------|-------------|
| Top by Investment Score | `getTopMovers[investmentScore]` | `investmentScore` | `topMovers` |
| Biggest Investment Gain | `getTopMovers[investmentScoreChange]` | `investmentScoreChange` | `topMovers` |
| Most Positive Sentiment | `getTopMovers[sentimentScore]` | `sentimentScore` | `topMovers` |
| Biggest Sentiment Shift — Most Bullish | `getTopMovers[sentimentScoreChange]` | `sentimentScoreChange` | `topMovers` |
| Biggest Sentiment Shift — Most Bearish | `getTopMovers[sentimentScoreChange]` | `sentimentScoreChange` | `underperforming` |
| Top Stock Performers | `getTopMovers[stockChange]` | `stockChange` | `topMovers` |
| 🔍 Potential Buy Signals | `getTopMovers[investmentScore]` | cross `underperforming` | high score + falling stock |

The **Sentiment Shift** card renders as one card with two sub-tables (Most Bullish on top, Most Bearish below) from the single `sentimentScoreChange` result.

The **Potential Buy Signals** card shows companies from `underperforming[investmentScore]` — these have high fundamental scores but their stock is underperforming. Mark with 🔍 icon.

---

### Section 3: Sector Sentiment & Investment Scores

From `getAnalytics`. Render a summary metrics row + aspect table:

**Metrics table:**

| Metric | Score | Direction | Interpretation |
|--------|-------|-----------|---------------|
| Sentiment Score | X.XX | RISING ↑ / FALLING ↓ | e.g. "Notably positive — above +0.10 threshold" |
| Investment Score | X.X | RISING ↑ / FALLING ↓ | e.g. "Investment score rising — sector gaining momentum" |
| Positive Pattern | +X.XX | — | e.g. "Strong positive language in guidance" |
| Negative Pattern | −X.XX | — | e.g. "Risk language present but not dominant" |

**Thresholds for interpretation:**
- Sentiment > +0.10 → "notably positive"
- Sentiment < −0.10 → "notably negative"
- Investment score: use relative comparison (higher = more attractive) — do not apply fixed thresholds. Note direction (RISING/FALLING) and compare to prior period.

**Top aspects table:**

| Aspect | Sentiment | Signal |
|--------|-----------|--------|
| [aspect name] | +X.XX | POSITIVE |

Include top 5 aspects by score magnitude.

---

### Section 4: Trending Topics

From `getTrends`. Render a two-part layout:

**Part A — Full topic table (top 20):**

| # | Topic | Score | Hits | Change | Direction |
|---|-------|-------|------|--------|-----------|
| 1 | [topic] | X | X | +X% | RISING ↑ |

Color the Change cell: green if positive, red if negative.

**Part B — Callout boxes:**

```html
<div class="trend-callouts">
  <div class="callout rising">
    🚀 Fastest rising: [Topic 1] (+X%), [Topic 2] (+X%), [Topic 3] (+X%)
  </div>
  <div class="callout falling">
    📉 Fastest declining: [Topic 1] (−X%), [Topic 2] (−X%)
  </div>
</div>
```

---

### Section 5: Event Analysis

From `getAnalytics.eventTypes` + `searchTopCompanies` per event.

**Part A — Event dominance table:**

| # | Event | Count | Sentiment | Type |
|---|-------|-------|-----------|------|
| 1 | GrowthDriver | X | +X.XX | Positive |
| 2 | RiskFactor | X | −X.XX | Negative |

Show top 5 positive events and top 5 negative events.

**Part B — Per-event company rankings:**

For each of the top 3 positive events and top 2 negative events, show a mini-ranking of the companies most exposed:

```
[Event: GrowthDriver] — Companies most exposed:
1. [Company A] (score: +X.XX, mentions: N)
2. [Company B] ...
```

---

### Section 6: Company Rankings by Theme

From `searchTopCompanies` per top topic. For each of the top 2 themes:

| Rank | Company | Sector | Sentiment Score | Mentions | Signal |
|------|---------|--------|----------------|---------|--------|
| 1 | [name] | [sector] | +X.XX | X | LEADING |

Signal labels:
- `sentimentScore > +0.30` → LEADING (green badge)
- `0.10 ≤ sentimentScore ≤ 0.30` → POSITIVE
- `−0.10 < sentimentScore < 0.10` → NEUTRAL
- `sentimentScore < −0.10` → BEARISH (red badge)

Also show `searchSectors` output: which sectors are most active on the top theme, positioning the target sector vs peers.

---

### Section 7: Executive & Analyst Voice

From `getSpeakers` and `getSpeakerCompanies` (aggregated across top 2–3 companies).

**Always explicitly state:**
- "Most bullish executive: [Name], [Role] at [Company] (score: X.XX)"
- "Most bearish analyst: [Name] from [Firm] (score: −X.XX)"
- "[Firm] is the most bullish analyst firm | [Firm] is the most bearish"

**Exec vs Analyst gap table:**

| Company | Exec Avg | Analyst Avg | Gap | Interpretation |
|---------|----------|-------------|-----|----------------|
| [A] | +X.XX | +X.XX | +X.XX | "Management more optimistic than street" |

Gap interpretation rules:
- Gap > +0.10 → "Management significantly more optimistic than analysts"
- Gap 0 to +0.10 → "Management and analysts broadly aligned, slight management optimism"
- Gap < 0 → "Analysts more bullish than management — unusual signal"

---

### Section 8: Risk Themes

From `getAnalytics` negative events + `search` bearish quotes.

**Risk exposure table:**

| Risk Event | Count | Top Companies Exposed |
|-----------|-------|----------------------|
| [Risk name] | X | [Co A], [Co B] |

**Bearish analyst quotes:**

> "[Quote]" — [Name], [Firm], [Company] ([Date])

Include 2–3 quotes from `search` with `sentiment: "negative"` and `sections: ["EarningsCalls_Question"]`.

**Risk summary callout:**

```html
<div class="risk-callout">
  ⚠️ Key sector risk: [Risk] — mentioned by N of M companies analyzed.
  Most exposed: [Company].
</div>
```

---

## Charts Reference

All charts are inline HTML — load Chart.js once at the top: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`

| Chart | Section | Type | Data source | Color scheme |
|-------|---------|------|------------|-------------|
| Chart 1 | Section 2 | Horizontal bar | `getTopMovers[investmentScore].topMovers` — top 10 | Green bars |
| Chart 2 | Section 2 | Horizontal bar | `getTopMovers[stockChange]` — top 10 vs bottom 5 | Green (positive) / Red (negative) |
| Chart 3 | Section 3 | Grouped bar | `getAnalytics` sentimentScore + investmentScore | Blue + Green |
| Chart 4 | Section 4 | Horizontal bar | `getTrends` top 15 by score | Colored by change sign |
| Chart 5 | Section 4 | Horizontal bar | `getTrends` % change — RISING vs DECLINING | Green (positive) / Red (negative) |
| Chart 6 | Section 5 | Horizontal bar | `getAnalytics` eventTypes — top 10 positive | Green bars |
| Chart 7 | Section 5 | Horizontal bar | `getAnalytics` eventTypes — top 10 negative | Red bars |
| Chart 8 | Section 6 | Horizontal bar | `searchTopCompanies` per top theme | Gradient by sentiment |
| Chart 9 | Section 7 | Bar sorted desc | `getSpeakers[Analysts]` bullish to bearish | Green→Red gradient |

All chart data embedded as inline JS constants — never reference external files.

---

## Formatting Rules

- Sentiment scores: 2 decimal places (e.g. 0.38)
- Investment scores: display raw value from API as-is — do not assume a scale
- Stock changes: 1 decimal place with sign (e.g. +12.4%, −3.1%)
- Score change deltas: show sign (e.g. +0.07, −0.12)
- Direction arrows: ↑ green for RISING, ↓ red for FALLING
- Event counts: whole number
- Company names in leaderboards: use ticker if available
- Quotes: always cite as `"[text]" — [Name], [Role], [Company] ([Date])`
- Never show a row with all N/A — if data missing for all companies, skip and footnote
- Never fabricate data — if a tool returns nothing, say so
