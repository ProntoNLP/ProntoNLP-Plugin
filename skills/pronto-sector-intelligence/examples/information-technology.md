# Example: Information Technology Sector Report

**User prompt:** "Analyze the tech sector"

---

## Step 0: Identify Sector & Mode

- User said "tech" → mapped to `Information Technology`
- No narrow scope signal → **Full Report** mode (all 8 sections, 5 batches)
- Date range: past year (default for Full Report)
  - `sinceDay`: 2025-04-05
  - `untilDay`: 2026-04-05
- Human-readable label: "Past Year"

---

## Step 1: Date Range

```
sinceDay: 2025-04-05
untilDay: 2026-04-05
Period label: "Past Year (Apr 2025 – Apr 2026)"
```

---

## Step 2: Batch 1 — Foundation (all fired simultaneously)

### Call A: `getTopMovers`
```json
{
  "sectors": ["Information Technology"],
  "documentTypes": ["Earnings Calls"],
  "sortBy": ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  "limit": 10,
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```

**Saved from response:**
- Top by investment score: NVDA, MSFT, AAPL, AVGO, ORCL (use raw scores from API)
- Top by stock change: NVDA (+61.8%), AVGO (+38.2%), MSFT (+22.4%)
- Underperforming (high investment, weak stock): INTC (stock −28.4%), AMD (stock −12.3%) — use raw scores from API
- Top sentiment: NVDA (0.67), MSFT (0.58), AVGO (0.54)
- Top companies for Batch 3: NVDA, MSFT, AAPL

### Call B: `getTrends`
```json
{
  "sectors": ["Information Technology"],
  "documentTypes": ["Earnings Calls"],
  "sortBy": "score",
  "sortOrder": "desc",
  "limit": 20,
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```

**Saved from response:**
- Top trends: AI Agents (+84%), Data Center Infrastructure (+61%), Cloud Margins (+38%), Sovereign AI (+29%), Cybersecurity (+22%)
- Declining: PC Market (−18%), Legacy Enterprise (−12%)
- Top topic for Batch 2: "AI Agents"

### Call C: `getAnalytics`
```json
{
  "sectors": ["Information Technology"],
  "documentTypes": ["Earnings Calls"],
  "analyticsType": ["scores", "eventTypes", "aspects", "patternSentiment", "importance"],
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```

**Saved from response:**
- Sentiment score: 0.48 (RISING, +0.06 vs prior year)
- Investment score: [raw value from API] (RISING)
- Positive pattern: +0.61
- Negative pattern: −0.24
- Top positive events: GrowthDriver (312 hits), CapexExpansion (187 hits), ProductLaunch (144 hits)
- Top negative events: RiskFactor (98 hits), MarginPressure (76 hits), Restructuring (41 hits)
- Top aspects: AI Infrastructure, Cloud Services, Semiconductor Supply Chain

---

## Step 3: Batch 2 — Topic & Event Breakdown (fired simultaneously)

### Call A: `searchTopCompanies` — GrowthDriver event
```json
{
  "sectors": ["Information Technology"],
  "eventTypes": ["GrowthDriver"],
  "limit": 10,
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```
Result: NVDA (#1, 0.71), MSFT (#2, 0.63), AVGO (#3, 0.58)

### Call B: `searchTopCompanies` — RiskFactor event
```json
{
  "sectors": ["Information Technology"],
  "eventTypes": ["RiskFactor"],
  "limit": 10,
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```
Result: INTC (#1, −0.31), AMD (#2, −0.18), QCOM (#3, −0.14)

### Call C: `searchTopCompanies` — AI Agents topic
```json
{
  "sectors": ["Information Technology"],
  "topicSearchQuery": "AI Agents",
  "limit": 10,
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```
Result: MSFT (#1, 0.68), GOOGL (#2, 0.61), NVDA (#3, 0.59)

### Call D: `searchSectors` — AI Agents & Data Center cross-sector
```json
{
  "searchQueries": ["AI Agents", "Data Center Infrastructure"],
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "2025-04-05",
  "untilDay": "2026-04-05"
}
```
Result: Information Technology leads by 3.2× vs next sector (Industrials); Healthcare is #3

---

## Step 4: Batch 3 — Speaker Intelligence (fired simultaneously, top 2 companies)

Calls for NVDA and MSFT:
- `getSpeakers` (Executives, desc) — NVDA
- `getSpeakers` (Analysts, desc) — NVDA
- `getSpeakers` (Executives, desc) — MSFT
- `getSpeakers` (Analysts, desc) — MSFT
- `getSpeakerCompanies` (Analysts, desc) — NVDA
- `getSpeakerCompanies` (Analysts, desc) — MSFT

**Saved from response:**
- Most bullish exec: Jensen Huang, CEO, NVDA (0.81)
- Most bearish analyst: David Lee, UBS (−0.12 for INTC, called from a separate check)
- Most bullish analyst firm: Goldman Sachs (avg 0.59)
- Most bearish analyst firm: Bernstein (avg 0.28)
- NVDA exec-analyst gap: +0.07 (exec avg 0.61, analyst avg 0.54)
- MSFT exec-analyst gap: +0.04 (exec avg 0.62, analyst avg 0.58)

---

## Step 5: Batch 4 — Supporting Quotes (fired simultaneously — environment-aware)

**Claude Cowork** (`Bash` available) — `pronto-search-summarizer` via Agent tool, all 4 in parallel:
```
pronto-search-summarizer: "Find bullish quotes about AI Agents for NVIDIA. Sentiment: positive. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
pronto-search-summarizer: "Find risk quotes about Export Controls for NVIDIA. Sentiment: negative. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
pronto-search-summarizer: "Find bullish quotes about AI Agents for Microsoft. Sentiment: positive. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
pronto-search-summarizer: "Find notable analyst questions for Microsoft. Sections: EarningsCalls_Question. Size: 3. SinceDay: 2025-04-06. UntilDay: 2026-04-06"
```

**Fallback (only if agent fails) — `search` MCP tool directly, all 4 in parallel:
```
search("NVIDIA", topicSearchQuery: "AI Agents", sentiment: "positive", size: 3, sinceDay: "2025-04-06", untilDay: "2026-04-06")
search("NVIDIA", topicSearchQuery: "Export Controls", sentiment: "negative", size: 3, sinceDay: "2025-04-06", untilDay: "2026-04-06")
search("Microsoft", topicSearchQuery: "AI Agents", sentiment: "positive", size: 3, sinceDay: "2025-04-06", untilDay: "2026-04-06")
search("Microsoft", sections: ["EarningsCalls_Question"], size: 3, sinceDay: "2025-04-06", untilDay: "2026-04-06")
```

**Saved quotes:**
- "We are seeing accelerating demand for our Blackwell architecture across every geography" — Jensen Huang, CEO, NVDA
- "Export restrictions create meaningful headwinds in a market we expected to grow significantly" — Colette Kress, CFO, NVDA
- "Copilot is now embedded in every Microsoft product and driving measurable productivity gains" — Satya Nadella, CEO, MSFT

---

## Key Signals (before rendering)

| Signal | Value |
|--------|-------|
| Sector direction | RISING — sentiment 0.48 (+0.06 YoY) |
| Investment leaders | NVDA, MSFT, AAPL (raw scores from API) |
| Top stock performer | NVDA +61.8% |
| Dominant positive event | GrowthDriver (312 hits) |
| Dominant negative event | RiskFactor (98 hits) |
| Fastest-rising theme | AI Agents (+84%) |
| Fastest-declining theme | PC Market (−18%) |
| Undervalued signal | INTC — score 0.58, stock down 28.4% |
| Most bullish exec | Jensen Huang, NVDA (0.81) |
| Most bullish analyst firm | Goldman Sachs (0.59 avg) |
| Most bearish analyst firm | Bernstein (0.28 avg) |

---

## Report Output Structure

The report renders as inline HTML with:

- **Header:** Information Technology — Sector Intelligence Report | Generated: Apr 5, 2026 | Period: Apr 2025 – Apr 2026
- **Section 1:** Executive Summary — sector RISING (0.48), NVDA/MSFT/AVGO lead; INTC undervalued signal; AI infrastructure thesis
- **Section 2:** 7 leaderboard cards in responsive grid — investment, investment gain, sentiment, sentiment shift (bullish/bearish split card), stock, buy signals; Chart 1 (investment bar) + Chart 2 (stock bar)
- **Section 3:** Metrics table (0.48 RISING, 0.72 RISING); Chart 3 (grouped bar); top aspects: AI Infrastructure, Cloud Services
- **Section 4:** Trending topics table (top 20); Chart 4 (score bar) + Chart 5 (change bar); callouts: AI Agents fastest rising (+84%), PC Market fastest declining (−18%)
- **Section 5:** Event analysis; Chart 6 (positive events) + Chart 7 (negative events); per-event company rankings (GrowthDriver → NVDA, MSFT, AVGO)
- **Section 6:** Company rankings by AI Agents theme; Chart 8 (company bar for AI Agents); cross-sector: IT leads AI discussion by 3.2× vs Industrials
- **Section 7:** Speaker analysis; Chart 9 (analyst sentiment bar); Jensen Huang most bullish exec (0.81); Goldman Sachs most bullish firm; gap tables for NVDA and MSFT
- **Section 8:** Risk themes — Export Controls (NVDA idiosyncratic), PC Market decline (systemic for PC-exposed companies); bearish analyst quotes; ⚠️ risk callout
