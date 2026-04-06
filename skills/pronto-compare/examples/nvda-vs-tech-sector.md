# Example: NVDA vs Information Technology Sector (Company vs Sector)

**User prompt:** "How does NVDA compare to the tech sector?"

---

## Step 1: Parse Entities

| Entity | Type | Color | API identifier |
|--------|------|-------|---------------|
| NVDA (NVIDIA Corporation) | Company | `#3B82F6` (blue) | ticker: NVDA |
| "tech sector" | Sector | `#8B5CF6` (purple) | `Information Technology` |

- Mode: Mixed (Company + Sector) → 7 universal dimensions + 2 company-only (N/A for sector)
- Period: Past Year (default)
- Output file (Cowork): `NVDA-vs-tech-report.html`

**Note to renderer:** The comparison is mixed — acknowledge in verdict that this is not apples-to-apples. Company carries single-stock risk; sector provides breadth.

---

## Step 2: Batch 1 — Foundation

**Company (NVDA):** API call needed
```
getCompanyDescription(companyNameOrTicker: "NVDA")
```
→ Saved: companyId = 1001, sector = Information Technology, subSector = Semiconductors

**Sector (Information Technology):** No API call — normalize name only
→ Saved: entity type = sector, exact API string = `"Information Technology"`

---

## Step 3: Batch 2 — Core Data (all calls simultaneously)

### NVDA (company):
```
getCompanyDocuments("NVIDIA", documentTypes: ["Earnings Calls"], limit: 4)
  → [t_n1: Apr 28, t_n2: Jul 31, t_n3: Oct 30, t_n4: Jan 29]

getStockChange(companyId: 1001, sinceDay: "2026-01-01", untilDay: "2026-04-06")  → +38.4% YTD
getStockChange(companyId: 1001, sinceDay: "2025-10-06", untilDay: "2026-04-06") → +22.1% 6M
getStockChange(companyId: 1001, sinceDay: "2025-04-06", untilDay: "2026-04-06") → +61.8% 1Y

getPredictions(companyId: 1001, metric: "revenue")       → $48.2B fwd
getPredictions(companyId: 1001, metric: "epsGaap")        → $2.94 fwd
getPredictions(companyId: 1001, metric: "ebitda")         → $29.7B fwd
getPredictions(companyId: 1001, metric: "freeCashFlow")   → $26.1B fwd

getTrends(companyName: "NVIDIA", documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06", limit: 10)
  → AI Accelerators (+91%), Data Center (+68%), Sovereign AI (+44%), Export Controls (−12%)
```

### Information Technology (sector):
```
getAnalytics(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → sentimentScore: 0.48, investmentScore: [raw from API], direction: RISING
  → top positive events: GrowthDriver (312 hits), CapexExpansion (187 hits)
  → top negative events: RiskFactor (98 hits), MarginPressure (76 hits)
  → top aspects: AI Infrastructure, Cloud Services, Semiconductor Supply Chain

getTrends(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06", limit: 10)
  → AI Agents (+84%), Data Center Infrastructure (+61%), Cloud Margins (+38%), PC Market (−18%)

getTopMovers(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → Top by investment score: NVDA, MSFT, AAPL, AVGO, ORCL [raw scores from API]
  → Top by stock change: NVDA (+61.8%), AVGO (+38.2%), MSFT (+22.4%)
  → Top by sentiment: NVDA (0.67), MSFT (0.58), AVGO (0.54)
  → Underperformers (high score + weak stock): INTC (−28.4%), AMD (−12.3%)
```

**Saved from Batch 2:**

| Field | NVDA (Company) | Information Technology (Sector) |
|-------|---------------|--------------------------------|
| Sentiment Score | [from Batch 3 per quarter] | 0.48 (aggregate) |
| Investment Score | [from Batch 3 per quarter] | [raw from API] (aggregate) |
| Direction | [computed in Batch 3] | RISING |
| Stock YTD | +38.4% | +61.8% (top mover: NVDA) |
| Stock 6M | +22.1% | N/A at sector level |
| Stock 1Y | +61.8% | N/A at sector level |
| Revenue fwd | $48.2B | N/A |
| Fastest-rising topic | AI Accelerators +91% | AI Agents +84% |
| Top company | N/A | NVDA (#1 by investment score) |

---

## Step 4: Batch 3 — Deep Analysis (all calls simultaneously)

### NVDA (company) — per-quarter analytics:
```
getAnalytics("NVIDIA", documentIDs: ["t_n1"], analyticsType: ["scores","eventTypes","aspects","patternSentiment"])
getAnalytics("NVIDIA", documentIDs: ["t_n2"], ...)
getAnalytics("NVIDIA", documentIDs: ["t_n3"], ...)
getAnalytics("NVIDIA", documentIDs: ["t_n4"], ...)

getStockPrices(companyId: 1001, fromDate: "2025-04-26", toDate: "2025-05-03", interval: "day") → Q1 reaction
getStockPrices(companyId: 1001, fromDate: "2025-07-29", toDate: "2025-08-05", interval: "day") → Q2 reaction
getStockPrices(companyId: 1001, fromDate: "2025-10-28", toDate: "2025-11-04", interval: "day") → Q3 reaction
getStockPrices(companyId: 1001, fromDate: "2026-01-27", toDate: "2026-02-03", interval: "day") → Q4 reaction

getSpeakers("NVIDIA", speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers("NVIDIA", speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers("NVIDIA", speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers("NVIDIA", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakerCompanies("NVIDIA", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
```

### Information Technology (sector) — use top company (NVDA from getTopMovers):
```
searchTopCompanies(sectors: ["Information Technology"], eventTypes: ["GrowthDriver"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → NVDA (#1, 0.71), MSFT (#2, 0.63), AVGO (#3, 0.58)

searchTopCompanies(sectors: ["Information Technology"], eventTypes: ["RiskFactor"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → INTC (#1, −0.31), AMD (#2, −0.18), QCOM (#3, −0.14)

getSpeakers("NVIDIA", speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10, documentTypes: ["Earnings Calls"])
  → Most bullish exec in sector leader: Jensen Huang, CEO, NVDA (0.81)

getSpeakerCompanies("NVIDIA", speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → Most bullish analyst firm covering sector leader: Goldman Sachs (0.59)
```

**Saved from Batch 3:**

| Field | NVDA (Company) | IT Sector |
|-------|---------------|-----------|
| Sentiment Q1–Q4 | 0.52 / 0.58 / 0.61 / 0.67 | 0.48 (single aggregate) |
| Sentiment Direction | RISING | RISING |
| Investment Q1–Q4 | [raw per quarter] | [raw aggregate] |
| Investment Direction | RISING | RISING |
| Stock Reaction | Q1:+4.2% Q2:+6.1% Q3:+8.3% Q4:+5.7% | N/A (sector-level) |
| Positive Call Count | 4 of 4 | N/A |
| Exec Avg Sentiment | 0.61 | 0.81 (sector leader Jensen Huang) |
| Analyst Avg Sentiment | 0.54 | N/A (sector-aggregate not available) |
| Most Bullish Analyst Firm | Goldman Sachs (0.72) | Goldman Sachs (0.59 sector avg) |
| Top Growth Driver Companies | — | NVDA, MSFT, AVGO |
| Top Risk Companies | — | INTC, AMD, QCOM |

---

## Step 5: Batch 4 — Quotes (all simultaneously)

### NVDA (company):
```
search("NVIDIA", sentiment: "positive", speakerTypes: ["Executives"], topicSearchQuery: "growth outlook guidance", size: 3)
search("NVIDIA", sentiment: "negative", topicSearchQuery: "risk challenge headwind", size: 3)
search("NVIDIA", sections: ["EarningsCalls_Question"], size: 3)
```

### IT Sector (use top company — NVDA already covered above; use MSFT as second voice):
```
search("Microsoft", sentiment: "positive", speakerTypes: ["Executives"], topicSearchQuery: "sector growth momentum cloud AI", size: 3)
search("Microsoft", sentiment: "negative", topicSearchQuery: "sector risk headwind challenge", size: 3)
```

**Saved quotes:**
- NVDA bullish: "We are seeing accelerating demand for our Blackwell architecture across every geography" — Jensen Huang, CEO, NVDA
- NVDA risk: "Export restrictions create meaningful headwinds in markets we expected to grow significantly" — Colette Kress, CFO, NVDA
- IT Sector representative: "Copilot is now embedded in every Microsoft product and driving measurable productivity gains" — Satya Nadella, CEO, MSFT

---

## Step 6: Scoring Matrix (Mixed — 7 universal + 2 company-only)

| Dimension | NVDA (Company) | IT Sector | Winner |
|-----------|---------------|-----------|--------|
| Sentiment Score | 0.67 | 0.48 | 🏆 NVDA |
| Investment Score | [raw] ↑ RISING | [raw] ↑ RISING | 🏆 NVDA* |
| Sentiment Direction | RISING | RISING | — (both RISING) |
| Investment Direction | RISING | RISING | — (both RISING) |
| Stock Performance | +38.4% YTD | +61.8% (top mover†) | 🏆 IT Sector† |
| Theme Momentum | AI Accelerators +91% | AI Agents +84% | 🏆 NVDA |
| Risk Profile | Focused (3 risks, mostly systemic) | Broad (98 RiskFactor hits across sector) | 🏆 NVDA‡ |
| Earnings Reaction *(co. only)* | 4 of 4 positive | N/A — Sector | 🏆 NVDA |
| Financial Outlook *(co. only)* | Rev $48.2B, EPS $2.94 | N/A — Sector | 🏆 NVDA |
| **Overall Wins** | **6** | **1** | **🏆 NVDA** |

*Investment score comparison: NVDA raw score vs sector aggregate raw score — NVDA leads
†Top mover in IT sector is NVDA itself (+61.8%) — sector score reflects NVDA's own performance
‡NVDA has concentrated risk but is a single-company position; sector risk is distributed

**Note:** NVDA being the top company in the IT sector means these metrics are not fully independent — NVDA is the largest driver of the sector's performance.

---

## Topic & Risk Overlap

**Shared themes:** AI infrastructure present in both NVDA topics AND IT sector top aspects → **Macro theme**

**Unique to NVDA:** Sovereign AI, Export Controls (company-specific risk)

**Unique to IT Sector:** PC Market decline, Cloud Margins pressure, INTC/AMD as risk concentration

**Sector-wide risk for IT:** Export controls → systemic (affects NVDA as well)

**Idiosyncratic to NVDA within the sector:** Single-stock concentration risk; strong alpha vs sector average

---

## Report Output Structure

Title: `NVDA vs Information Technology — Comparison Report | 1 Company / 1 Sector | Past Year`

- **Section 1:** Scorecard — NVDA wins 6 of 7 scored dimensions; sector wins on stock performance (footnote: NVDA IS the top mover); N/A cells shown for earnings reaction and financial outlook in sector column
- **Section 2:** NVDA quarter cards (blue label, "Company") + IT sector summary card (purple label, "Sector") with aggregate sentiment, investment, top mover, fastest-rising theme
- **Section 3:** Chart 1 grouped bar — NVDA vs IT sector top mover (footnote: values are the same because NVDA is the sector leader)
- **Section 4:** Financial table — NVDA shows $48.2B revenue / $2.94 EPS; IT Sector column shows N/A with note "Financial forecasts apply to individual companies only"
- **Section 5:** Speaker chart — NVDA CEO/CFO/Exec/Analyst; IT Sector shows sector leader (Jensen Huang) and Goldman Sachs as most bullish firm
- **Section 6:** Topics — AI infrastructure as shared macro theme; Sovereign AI as NVDA-specific; PC Market as sector headwind not relevant to NVDA
- **Section 7:** Risk table — Export Controls ✅ both; PC Market softness: — NVDA / ✅ IT Sector (via AMD/INTC exposure)
- **Section 8:** Verdict — NVDA outperforms the sector significantly on sentiment (+0.67 vs +0.48) and investment score; interesting note that NVDA IS the sector's top performer so the comparison illustrates NVDA's alpha vs the sector average; for single-stock investors NVDA is the clear pick; sector ETF provides diversification but lower alpha
