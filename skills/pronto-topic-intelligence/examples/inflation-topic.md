# Topic Intelligence Example: Inflation

## Request
"how is inflation mentioned across sectors"

---

## Step 1: Topic Parsing

**Topic:** `inflation`

---

## Step 2: Data Collection (all parallel)

### 2a. getAnalytics — Inflation Sentiment Across Market

```
getAnalytics(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07"
)
```
→ Sentiment: 0.34 (leaning negative) | Investment: 0.42 | Top event: RiskFactor (2,847 hits) | Top aspects: "cost pressures", "pricing power", "input costs"

### 2b. getTrends — Related Topic Trends

```
getTrends(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07",
  limit: 10
)
```
→ Related: "interest rates" (+18%), "cost pressures" (+12%), "pricing actions" (+8%), "supply chain" (-5%), "wages" (+6%)

### 2c. searchSectors — Inflation Distribution by Sector

```
searchSectors(
  searchQueries: ["inflation"],
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07"
)
```
→ 1. Consumer Discretionary (4,218 mentions) | 2. Consumer Staples (3,892) | 3. Industrials (3,104) | 4. Information Technology (2,891) | 5. Materials (2,456)

### 2d. searchTopCompanies — Companies Discussing Inflation

```
searchTopCompanies(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  limit: 20,
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07"
)
```
→ 1. Walmart (847 hits, sentiment: 0.28) | 2. Amazon (723 hits, sentiment: 0.31) | 3. Home Depot (612 hits, sentiment: 0.25) | 4. PepsiCo (598 hits, sentiment: 0.29) | 5. Costco (534 hits, sentiment: 0.33)

### 2e. getTopMovers — Sentiment Leaders on Inflation

```
getTopMovers(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  sortBy: ["sentimentScore", "investmentScore"],
  limit: 10,
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07"
)
```
→ Top by sentiment: Microsoft (0.71), Apple (0.68), Alphabet (0.65) — companies with strong pricing power

---

## Step 3: Keyword Heatmap (OPTIONAL — only if user explicitly requested)

*In this example, the user did NOT request the heatmap, so this step is skipped.*

If user had requested: "show me the heatmap for inflation"
```
getTermHeatmap(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-07",
  untilDay: "2026-04-07"
)
```

---

## Step 4: Quote Collection

**`pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):

```
"Find quotes about inflation across the market. Run these searches:
1. Most bullish/positive quotes about inflation — sentiment: positive, size: 5
2. Most bearish/negative quotes about inflation — sentiment: negative, size: 5
3. Notable analyst questions about inflation — sections: EarningsCalls_Question, size: 5
4. Quotes from different sectors about inflation — documentTypes: Earnings Calls, size: 5
Return all results with speaker name, role, company, and date."
```
→ See saved quotes below

**Saved quotes:**
- "We've seen inflation normalize in most categories, allowing us to hold margins while remaining competitive" — CFO, Consumer Staples
- "Input cost inflation remains our biggest headwind — we're taking pricing actions to offset" — CEO, Industrials
- "The market is underestimating our pricing power in an inflationary environment" — CFO, Technology

---

## Step 5: Compile Report

### Render as HTML (inline or file)

---

## Key Signals (before rendering)

| Signal | Value |
|--------|-------|
| Topic sentiment | 0.34 — leaning negative |
| Dominant event | RiskFactor (2,847 hits) |
| Top sector | Consumer Discretionary (4,218 mentions) |
| Top company | Walmart (847 hits) |
| Trend | Declining — mentions down 12% YoY |
| Related rising theme | Interest rates (+18%) |

---

## Report Preview (text summary)

### Executive Summary

Inflation remains a significant concern across the market, with an overall sentiment score of 0.34 — indicating negative perception. Consumer Discretionary and Consumer Staples lead discussions, with 4,218 and 3,892 mentions respectively. The dominant narrative centers on **cost pressures** and **pricing power**, with companies split between those absorbing costs (pressuring margins) and those passing costs through (risking volume).

**Key insight:** Companies with strong pricing power (tech giants) show positive sentiment (0.65+), while consumer-facing retailers show negative sentiment (0.25-0.33). The trend is toward moderation — inflation mentions declined 12% YoY, suggesting the market views inflation as a receding risk.

### Top Companies

| Company | Ticker | Sector | Hits | Sentiment |
|---------|--------|--------|------|-----------|
| Walmart | WMT | Consumer Discretionary | 847 | 0.28 |
| Amazon | AMZN | Consumer Discretionary | 723 | 0.31 |
| Home Depot | HD | Consumer Discretionary | 612 | 0.25 |
| PepsiCo | PEP | Consumer Staples | 598 | 0.29 |
| Costco | COST | Consumer Staples | 534 | 0.33 |

### Related Themes

| Theme | Change | Sentiment |
|-------|--------|-----------|
| Interest rates | +18% | negative |
| Cost pressures | +12% | negative |
| Pricing actions | +8% | positive |
| Wages | +6% | negative |
| Supply chain | -5% | positive |
