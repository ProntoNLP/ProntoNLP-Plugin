# Example: Information Technology vs Health Care (Sector vs Sector)

**User prompt:** "Compare the tech sector vs healthcare"

---

## Step 1: Parse Entities

| Entity | Type | Color | API identifier |
|--------|------|-------|---------------|
| "tech sector" | Sector | `#3B82F6` (blue) | `Information Technology` |
| "healthcare" | Sector | `#8B5CF6` (purple) | `Health Care` |

- Mode: Sector vs Sector → 7 scoring dimensions (no company-only dimensions)
- Period: Past Year (default)
- Output file (Cowork): `tech-vs-healthcare-report.html`

**No Batch 1 API calls needed** — both entities are sectors. Normalize names only:
- "tech sector" → `Information Technology`
- "healthcare" → `Health Care`

---

## Step 2: Batch 1 — Foundation

No API calls. Both entities confirmed as sectors with exact API strings saved.

---

## Step 3: Batch 2 — Core Data (all calls for both sectors simultaneously)

```
getAnalytics(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06")

getAnalytics(sectors: ["Health Care"], documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06")

getTrends(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06", limit: 10)

getTrends(sectors: ["Health Care"], documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-06", untilDay: "2026-04-06", limit: 10)

getTopMovers(sectors: ["Information Technology"], documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay: "2025-04-06", untilDay: "2026-04-06")

getTopMovers(sectors: ["Health Care"], documentTypes: ["Earnings Calls"],
  sortBy: ["investmentScore", "sentimentScore", "stockChange", "investmentScoreChange", "sentimentScoreChange"],
  limit: 10, sinceDay: "2025-04-06", untilDay: "2026-04-06")
```

**Saved from Batch 2:**

| Field | Information Technology | Health Care |
|-------|----------------------|-------------|
| Sentiment Score | 0.48 | 0.31 |
| Investment Score | [raw from API] | [raw from API] |
| Sentiment Direction | RISING (+0.06 YoY) | FALLING (−0.04 YoY) |
| Investment Direction | RISING | FLAT |
| Top Mover YTD | NVDA +61.8% | LLY +28.4% |
| Top by Investment | NVDA, MSFT, AAPL [raw scores] | LLY, ABBV, UNH [raw scores] |
| Top by Sentiment | NVDA (0.67), MSFT (0.58), AVGO (0.54) | LLY (0.52), ABBV (0.46), ISRG (0.44) |
| Positive Events (top) | GrowthDriver (312), CapexExpansion (187), ProductLaunch (144) | DrugApproval (98), RevenueGrowth (76), PartnershipAnnouncement (54) |
| Negative Events (top) | RiskFactor (98), MarginPressure (76) | RegulatoryRisk (112), PricingPressure (89), ClinicalFailure (43) |
| Top Aspects | AI Infrastructure, Cloud Services, Semiconductor Supply Chain | GLP-1/Obesity Drugs, Biosimilar Competition, Medicare Pricing |
| Fastest-Rising Topic | AI Agents +84% | GLP-1 Momentum +127% |
| Fastest-Declining Topic | PC Market −18% | COVID-Related Revenue −41% |
| Underperformers | INTC (score rising, stock −28.4%) | CVS (score flat, stock −19.2%) |

---

## Step 4: Batch 3 — Deep Analysis (all calls for both sectors simultaneously)

For sectors: use the top company from each sector's `getTopMovers` result.

IT Sector top company = NVDA | Health Care top company = LLY

```
searchTopCompanies(sectors: ["Information Technology"], eventTypes: ["GrowthDriver"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → NVDA (#1, 0.71), MSFT (#2, 0.63), AVGO (#3, 0.58)

searchTopCompanies(sectors: ["Information Technology"], eventTypes: ["RiskFactor"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → INTC (#1, −0.31), AMD (#2, −0.18), QCOM (#3, −0.14)

searchTopCompanies(sectors: ["Health Care"], eventTypes: ["DrugApproval"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → LLY (#1, 0.68), ABBV (#2, 0.54), REGN (#3, 0.49)

searchTopCompanies(sectors: ["Health Care"], eventTypes: ["RegulatoryRisk"],
  limit: 5, sinceDay: "2025-04-06", untilDay: "2026-04-06")
  → CVS (#1, −0.24), CI (#2, −0.19), HUM (#3, −0.14)

getSpeakers("NVIDIA", speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10, documentTypes: ["Earnings Calls"])
  → Most bullish exec in IT sector leader: Jensen Huang, CEO, NVDA (0.81)

getSpeakerCompanies("NVIDIA", speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → Most bullish analyst firm covering IT sector leader: Goldman Sachs (0.59)

getSpeakers("Eli Lilly", speakerTypes: ["Executives"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10, documentTypes: ["Earnings Calls"])
  → Most bullish exec in Healthcare sector leader: David Ricks, CEO, LLY (0.62)

getSpeakerCompanies("Eli Lilly", speakerTypes: ["Analysts"],
  sortBy: "sentiment", sortOrder: "desc", limit: 10)
  → Most bullish analyst firm covering HC sector leader: Morgan Stanley (0.54)
```

**Saved from Batch 3:**

| Field | Information Technology | Health Care |
|-------|----------------------|-------------|
| Top Growth Companies | NVDA, MSFT, AVGO | LLY, ABBV, REGN |
| Top Risk Companies | INTC, AMD, QCOM | CVS, CI, HUM |
| Most Bullish Exec (sector leader) | Jensen Huang, CEO, NVDA (0.81) | David Ricks, CEO, LLY (0.62) |
| Most Bullish Analyst Firm | Goldman Sachs (0.59) | Morgan Stanley (0.54) |

---

## Step 5: Batch 4 — Quotes (both sectors simultaneously)

Using top company per sector as the representative voice:

**Claude Cowork** (`Bash` available) — `pronto-search-summarizer` via Agent tool, all 4 in parallel:
```
pronto-search-summarizer: "Find bullish executive quotes from NVIDIA about AI infrastructure growth and momentum. SpeakerTypes: Executives. Sentiment: positive. Size: 3"
→ "The infrastructure buildout for AI is just beginning..." — Jensen Huang, CEO, NVDA

pronto-search-summarizer: "Find bearish and risk quotes from NVIDIA about sector risks and headwinds. Sentiment: negative. Size: 3"
→ "Export restrictions create meaningful headwinds..." — Colette Kress, CFO, NVDA

pronto-search-summarizer: "Find bullish executive quotes from Eli Lilly about GLP-1 growth, obesity drugs, and pipeline momentum. SpeakerTypes: Executives. Sentiment: positive. Size: 3"
→ "GLP-1 demand continues to outpace our manufacturing capacity..." — David Ricks, CEO, LLY

pronto-search-summarizer: "Find bearish and risk quotes from Eli Lilly about pricing regulation and challenges. Sentiment: negative. Size: 3"
→ "Medicare pricing negotiations create long-term uncertainty for our portfolio..." — Anat Ashkenazi, CFO, LLY
```

**Fallback (only if agent fails in Claude Cowork, or direct path in claude.ai) — `search` MCP tool directly, all 4 in parallel:**
```
search("NVIDIA", sentiment: "positive", speakerTypes: ["Executives"], topicSearchQuery: "sector growth momentum AI infrastructure", size: 3)
search("NVIDIA", sentiment: "negative", topicSearchQuery: "sector risk challenge headwind", size: 3)
search("Eli Lilly", sentiment: "positive", speakerTypes: ["Executives"], topicSearchQuery: "sector growth momentum GLP-1 obesity pipeline", size: 3)
search("Eli Lilly", sentiment: "negative", topicSearchQuery: "pricing regulatory challenge headwind", size: 3)
```

---

## Step 6: Scoring Matrix (Sector vs Sector — 7 dimensions)

| Dimension | Information Technology | Health Care | Winner |
|-----------|----------------------|-------------|--------|
| Sentiment Score | 0.48 | 0.31 | 🏆 IT |
| Investment Score | [raw] ↑ RISING | [raw] FLAT | 🏆 IT* |
| Sentiment Direction | RISING (+0.06) | FALLING (−0.04) | 🏆 IT |
| Investment Direction | RISING | FLAT | 🏆 IT |
| Stock Performance | +61.8% (NVDA, top mover) | +28.4% (LLY, top mover) | 🏆 IT |
| Theme Momentum | AI Agents +84% | GLP-1 Momentum +127% | 🏆 Health Care |
| Risk Profile | RiskFactor (98 hits) — moderate | RegulatoryRisk (112 hits) — elevated | 🏆 IT |
| **Overall Wins** | **6 / 7** | **1 / 7** | **🏆 Information Technology** |

*Investment score: compare raw values from API — IT leads on raw score

**Divergence signals:**
- INTC in IT: investment score RISING despite stock −28.4% → potential undervalued signal within the IT sector
- CVS in Healthcare: score flat despite stock −19.2% → no bullish divergence signal

**Notable:** Health Care's fastest-rising theme (GLP-1 +127%) significantly outpaces IT's fastest-rising theme (AI Agents +84%) — healthcare narrative momentum is stronger for its top theme, even though overall sector sentiment lags.

---

## Topic & Risk Overlap

**Shared themes:** None — IT and Healthcare are in distinct thematic universes

**Unique to IT:** AI Agents, Data Center Infrastructure, Cloud Margins, Semiconductor Supply Chain

**Unique to Health Care:** GLP-1/Obesity Drugs, Biosimilar Competition, Medicare Pricing Reform, Clinical Trial Results

**Systemic cross-sector risk:** Tariff exposure — present in both IT (hardware components) and Health Care (pharma supply chain)

**Idiosyncratic to IT:** AI chip export controls — not relevant to Healthcare

**Idiosyncratic to Health Care:** Drug pricing regulation — not relevant to IT

---

## Report Output Structure

Title: `Information Technology vs Health Care — Comparison Report | 2 Sectors | Past Year`

- **Section 1:** Scorecard — IT wins 6 of 7 dimensions; both cells colored (IT green, HC red — 2-entity rule); no company-only rows (no "N/A — Sector" cells needed, all-sector comparison)
- **Section 2:** NO quarter cards (no earnings call transcripts for sectors). Two sector summary cards side by side: IT card (blue) showing 0.48 RISING, top mover NVDA +61.8%, AI Agents +84%; HC card (purple) showing 0.31 FALLING, top mover LLY +28.4%, GLP-1 +127%
- **Section 3:** Chart 1 grouped bar — IT top mover vs HC top mover; footnote clarifies these are sector-representative companies, not sector indices
- **Section 4:** OMITTED — no financial forecasts available at sector level
- **Section 5:** Speaker chart — Jensen Huang (IT sector voice) vs David Ricks (HC sector voice); Goldman Sachs vs Morgan Stanley as top analyst firms
- **Section 6:** Topics — fully divergent; no shared themes flagged; Tariff exposure as the only cross-sector risk signal; GLP-1 callout as healthcare's outlier high-growth theme
- **Section 7:** Risk table — Export Controls ✅ IT / — HC; Regulatory Risk — IT / ✅ HC; Pricing Pressure ✅ IT (margins) / ✅ HC (drug pricing); Tariff Exposure ✅ IT / ✅ HC → Systemic cross-sector
- **Section 8:** Verdict — IT leads 6 of 7 dimensions; Healthcare's standout is GLP-1 momentum (+127% fastest-rising theme in any sector comparison); IT is the momentum sector, Healthcare the defensive/biotech optionality play; bottom line: IT sector for near-term momentum, Healthcare for thematic diversification
