# HTML Report — Content & Section Requirements

This file defines **what** must appear in the report, not how it should look. The visual design — layout, colors, typography, interactive behavior — is Claude's to decide.

---

## Core Architectural Rule: Modular Sections

**Sections are optional and independently removable.** The HTML must be structured so that any section can be absent without breaking the layout. Use a flex or CSS grid wrapper — never assume a fixed number of sections exists. If a section's data was not fetched or not requested, simply do not render it.

```html
<main class="dashboard">
  <!-- Only render sections that were requested -->
  <!-- Each section is a flex/grid item that reflows when siblings are absent -->
</main>
```

---

## Output Format

Output an **inline HTML fragment** in your response — no `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags. Start with a `<style>` block, then the HTML content. This renders inline in the chat.

Use Claude's native CSS tokens for theming. Hardcode signal colors only: green `#1D9E75`, red `#D85A30`.

---

## Required Data Constants (embedded in `<script>`)

All data must be embedded inline — no runtime fetching.

- `LEADERBOARDS` — object keyed by sort criterion, each containing arrays of company objects. Keys match the `sortBy` values passed to `getTopMovers`: `stockChange`, `investmentScore`, `investmentScoreChange`, `sentimentScore`, `sentimentScoreChange`, `aspectScore`, `marketcap`. Only include keys for criteria that were actually fetched.
- `TRENDS` *(if fetched)* — array of trend objects: `name`, `explanation`, `score`, `hits`, `change`
- `EXEC_BULLISH`, `EXEC_BEARISH`, `ANALYST_BULLISH`, `ANALYST_BEARISH` *(if fetched)* — speaker arrays: `name`, `company`, `companyId`, `sentimentScore`, `numOfSentences`

Company object fields in `LEADERBOARDS`: `id`, `ticker`, `name`, `sector`, `subSector`, `stockChange`, `investmentScore`, `investmentScoreChange`, `sentimentScore`, `sentimentScoreChange`, `aspectScore`, `marketCap`, `category`

---

## Header (always present)

Must show:
- Title "Market Pulse" + exact date range
- Summary stats: total unique companies across all leaderboards · filters applied (market cap tier, document type, country/sector if filtered)
- Any date-range expansions or relaxed filters noted prominently

---

## Section: Highlights of the Week *(when movers data is present)*

Render as a **responsive grid of leaderboard cards**. Each leaderboard is a card. The grid reflows cleanly for any number of cards (1, 3, all 7).

**One card per sort criterion fetched.** Only render cards for criteria that were actually requested.

### Leaderboard cards:

| Criterion | Card title | Primary column | Source |
|-----------|-----------|----------------|--------|
| `stockChange` | Top Stock Movers | Stock Δ (%, green/red) | `topMovers` |
| `investmentScore` | Highest Investment Score | Investment Score | `topMovers` |
| `investmentScoreChange` | Biggest Investment Gain | Investment Score Δ | `topMovers` |
| `sentimentScore` | Most Positive Sentiment | Sentiment Score | `topMovers` |
| `sentimentScoreChange` | Biggest Sentiment Shift | Sentiment Δ — two sub-tables: Most Bullish (`topMovers`) on top, Most Bearish (`underperforming`) below | both |
| `aspectScore` | Top Aspect Score | Aspect Score | `topMovers` |
| `marketcap` | Largest Companies | Market Cap | `topMovers` |

**Each card shows:**
- Card title + date range label
- Compact table: rank · Company (linked) · Ticker · primary metric (highlighted) · 1–2 secondary context columns
- Top 10 rows only
- Market cap formatted as `$1.2T`, `$45.3B`, `$3.1B`, `$850M`
- Delta columns: positive in green, negative in red

**Signal badges** (show on any card where applicable):
- `Potential Buy` — `category === "underperforming"` (stock down, strong fundamentals)
- `Watch` — `investmentScoreChange > 20`
- `Caution` — `investmentScoreChange < -20`

Cards should be sortable by column click.

---

## Section: Trending Topics *(only when trends data is present)*

Top 20 trends sorted by `score` descending.

Each trend: name · significance bar (`score` 0–1) · mention count (`hits`) · explanation · direction indicator (`change > 0` = rising ▲, `< 0` = fading ▼).

---

## Section: Voice of the Market *(only when speaker data is present)*

Executives and Analysts in separate subsections. Within each: Most Bullish and Most Bearish (toggle or side-by-side).

Per speaker row: name · company (linked) · sentiment score on a −1 to +1 visual scale · sentence count.

---

## Footer (always present)

Must include: data source (ProntoNLP) · filters applied · exact date range · unique company count · generation timestamp.

---

## Company Link Format

`{org}` is retrieved by calling `getOrganization` at the start of the skill. Never hardcode it.

```html
<a href="https://{org}.prontonlp.com/#/ref/$COMPANY{id}">{name}</a>
```

where `{id}` is the numeric `id` field from the company object (prefix with `$COMPANY`).
