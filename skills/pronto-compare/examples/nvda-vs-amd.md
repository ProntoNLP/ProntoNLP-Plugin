# Example: NVDA vs AMD Comparison (Company vs Company)

**User prompt:** "Compare NVDA vs AMD"

---

## Step 1: Parse Entities

| Entity | Type | Color | API identifier |
|--------|------|-------|---------------|
| NVDA (NVIDIA Corporation) | Company | `#3B82F6` (blue) | ticker: NVDA |
| AMD (Advanced Micro Devices) | Company | `#8B5CF6` (purple) | ticker: AMD |

- Mode: Company vs Company → all 9 scoring dimensions
- Period: Past Year (default)
- Output file: `NVDA-vs-AMD-<YYYYMMDD>.html`

---

## Step 2: Batch 1 — Foundation (both companies simultaneously)

```
getCompanies(companyNameOrTicker: "NVDA")
getCompanies(companyNameOrTicker: "AMD")
```

**Saved:**
- NVDA: companyId = 1001, sector = Information Technology, subSector = Semiconductors
- AMD:  companyId = 1002, sector = Information Technology, subSector = Semiconductors

---

## Step 3: Batch 2 — Core Data (all calls for both companies simultaneously)

```
getDocuments(companiesIds: ["1001", "1002"], documentTypes: ["Earnings Calls"], size: 4, excludeFutureDocuments: true)  → 1 call, both companies

getStockChange(companiesIds: ["1001", "1002"], dateRange: {gte: "2026-01-01", lte: "now"})  → YTD both
getStockChange(companiesIds: ["1001", "1002"], dateRange: {gte: "now-6M/d",   lte: "now"})  → 6M both
getStockChange(companiesIds: ["1001", "1002"], dateRange: {gte: "now-1y/d",   lte: "now"})  → 1Y both

getCompanyConsensus(companiesIds: ["1001", "1002"], metrics: ["revenue", "epsGaap", "ebitda", "freeCashFlow"], timeframeInterval: "quarter")  → 1 call, both companies

getTrends(companiesIds: ["1001"], documentTypes: ["Earnings Calls"], dateRange: {gte: "now-1y/d", lte: "now"}, limit: 10)
getTrends(companiesIds: ["1002"], documentTypes: ["Earnings Calls"], dateRange: {gte: "now-1y/d", lte: "now"}, limit: 10)
```

**Saved from Batch 2:**

| | NVDA | AMD |
|--|------|-----|
| transcriptIds | [t_n1, t_n2, t_n3, t_n4] | [t_a1, t_a2, t_a3, t_a4] |
| Call dates | Apr 28 / Jul 31 / Oct 30 / Jan 29 | Apr 30 / Jul 30 / Oct 29 / Jan 28 |
| Stock YTD | +38.4% | −12.3% |
| Stock 6M | +22.1% | −8.7% |
| Stock 1Y | +61.8% | −4.1% |
| Revenue fwd | $48.2B | $8.9B |
| EPS GAAP fwd | $2.94 | $1.12 |
| EBITDA fwd | $29.7B | $3.2B |
| FCF fwd | $26.1B | $2.8B |
| Top topics | AI Accelerators, Data Center, Sovereign AI | AI Accelerators, PC Recovery, MI300 Ramp |

---

## Step 4: Batch 3 — Deep Analysis (all calls for both companies simultaneously)

```
getAnalytics(companiesIds: ["1001"], transcriptsIds: ["t_n1"], analyticsType: ["scores","eventTypes","aspects","patternSentiment"])
getAnalytics(companiesIds: ["1001"], transcriptsIds: ["t_n2"], ...)
getAnalytics(companiesIds: ["1001"], transcriptsIds: ["t_n3"], ...)
getAnalytics(companiesIds: ["1001"], transcriptsIds: ["t_n4"], ...)
getAnalytics(companiesIds: ["1002"], transcriptsIds: ["t_a1"], ...)
getAnalytics(companiesIds: ["1002"], transcriptsIds: ["t_a2"], ...)
getAnalytics(companiesIds: ["1002"], transcriptsIds: ["t_a3"], ...)
getAnalytics(companiesIds: ["1002"], transcriptsIds: ["t_a4"], ...)

getStockPrices(companiesIds: ["1001"], dateRange: {gte: "2025-04-26", lte: "2025-05-03"}, interval: "day") → NVDA Q1 reaction
getStockPrices(companiesIds: ["1001"], dateRange: {gte: "2025-07-29", lte: "2025-08-05"}, interval: "day") → NVDA Q2 reaction
getStockPrices(companiesIds: ["1001"], dateRange: {gte: "2025-10-28", lte: "2025-11-04"}, interval: "day") → NVDA Q3 reaction
getStockPrices(companiesIds: ["1001"], dateRange: {gte: "2026-01-27", lte: "2026-02-03"}, interval: "day") → NVDA Q4 reaction
getStockPrices(companiesIds: ["1002"], dateRange: {gte: "2025-04-28", lte: "2025-05-05"}, interval: "day") → AMD Q1 reaction
getStockPrices(companiesIds: ["1002"], dateRange: {gte: "2025-07-28", lte: "2025-08-04"}, interval: "day") → AMD Q2 reaction
getStockPrices(companiesIds: ["1002"], dateRange: {gte: "2025-10-27", lte: "2025-11-03"}, interval: "day") → AMD Q3 reaction
getStockPrices(companiesIds: ["1002"], dateRange: {gte: "2026-01-26", lte: "2026-02-02"}, interval: "day") → AMD Q4 reaction

getSpeakers(entityType: "speaker", companiesIds: ["1001"], speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1001"], speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1001"], speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1001"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "company", companiesIds: ["1001"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
getSpeakers(entityType: "speaker", companiesIds: ["1002"], speakerTypes: ["Executives"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1002"], speakerTypes: ["Executives_CEO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1002"], speakerTypes: ["Executives_CFO"], limit: 3, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "speaker", companiesIds: ["1002"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 20, documentTypes: ["Earnings Calls"])
getSpeakers(entityType: "company", companiesIds: ["1002"], speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc", limit: 10)
getDocumentSummary(focus: "key risks and risk factors mentioned by management", transcriptsIds: ["t_n4", "t_a4"], corpus: ["S&P Transcripts"])  → 1 call, both latest transcripts
```

**Saved from Batch 3:**

| | NVDA | AMD |
|--|------|-----|
| Sentiment Q1–Q4 | 0.52 / 0.58 / 0.61 / 0.67 | 0.41 / 0.38 / 0.43 / 0.39 |
| Sentiment Direction | RISING | FALLING |
| Investment Q1–Q4 | [raw API values] | [raw API values] |
| Investment Direction | RISING | FALLING |
| Stock Reaction Q1–Q4 | +4.2% / +6.1% / +8.3% / +5.7% | +1.8% / −2.3% / +0.9% / −1.4% |
| Positive Call Count | 4 of 4 | 2 of 4 |
| Exec Avg Sentiment | 0.61 | 0.44 |
| Analyst Avg Sentiment | 0.54 | 0.38 |
| CEO Sentiment | 0.68 | 0.48 |
| CFO Sentiment | 0.59 | 0.41 |
| Exec-Analyst Gap | +0.07 | +0.06 |
| Most Bullish Analyst | Sarah Chen, Goldman Sachs (0.72) | Priya Kapoor, Morgan Stanley (0.61) |
| Most Bearish Analyst | Mark Torres, Bernstein (0.31) | David Lee, UBS (0.18) |

---

## Step 5: Batch 4 — Quotes (all 6 simultaneously)

**`pronto-search-summarizer`** (subagent_type: `prontonlp-plugin:pronto-search-summarizer`), all 6 in parallel:
```
"Find bullish executive quotes for NVIDIA about growth outlook and guidance. companiesIds: [1001]. speakerTypes: Executives. DLSentiment: ['positive']. documentTypes: Earnings Calls. size: 3"
"Find bearish and risk quotes for NVIDIA about risks, challenges, and headwinds. companiesIds: [1001]. DLSentiment: ['negative']. documentTypes: Earnings Calls. size: 3"
"Find notable analyst questions for NVIDIA. companiesIds: [1001]. sections: EarningsCalls_Question. documentTypes: Earnings Calls. size: 3"
"Find bullish executive quotes for AMD about growth outlook and guidance. companiesIds: [1002]. speakerTypes: Executives. DLSentiment: ['positive']. documentTypes: Earnings Calls. size: 3"
"Find bearish and risk quotes for AMD about risks, challenges, and headwinds. companiesIds: [1002]. DLSentiment: ['negative']. documentTypes: Earnings Calls. size: 3"
"Find notable analyst questions for AMD. companiesIds: [1002]. sections: EarningsCalls_Question. documentTypes: Earnings Calls. size: 3"
```

**Saved quotes:**
- NVDA bullish: "We are seeing accelerating demand for our Blackwell architecture across every geography" — Jensen Huang, CEO
- NVDA risk: "Export restrictions create meaningful headwinds in markets we expected to grow significantly" — Colette Kress, CFO
- AMD bullish: "MI300 demand is tracking ahead of expectations for the second consecutive quarter" — Lisa Su, CEO
- AMD risk: "PC market recovery remains uneven across consumer and commercial segments" — Jean Hu, CFO

---

## Step 6: Scoring Matrix (Company vs Company — 9 dimensions)

| Dimension | NVDA | AMD | Winner |
|-----------|------|-----|--------|
| Sentiment Trend | 0.67 ↑ RISING | 0.39 ↓ FALLING | 🏆 NVDA |
| Investment Score | [raw] ↑ RISING | [raw] ↓ FALLING | 🏆 NVDA |
| Stock YTD | +38.4% | −12.3% | 🏆 NVDA |
| Earnings Call Reaction | 4 of 4 | 2 of 4 | 🏆 NVDA |
| Analyst Consensus | 0.54 | 0.38 | 🏆 NVDA |
| Revenue (fwd) | $48.2B | $8.9B | 🏆 NVDA |
| EPS (fwd) | $2.94 | $1.12 | 🏆 NVDA |
| Exec Confidence | 0.61 | 0.44 | 🏆 NVDA |
| Risk Profile | 3 risks (systemic) | 3 risks (1 idiosyncratic) | 🏆 NVDA |
| **Overall Wins** | **9 / 9** | **0 / 9** | **🏆 NVDA** |

**Divergence signal:** AMD investment score is RISING despite stock down 12.3% YTD — potential undervalued signal if the MI300 data center ramp materializes.

---

## Topic & Risk Overlap

**Shared topics:** AI Accelerators — present in both companies' top lists → **Macro theme**

**Unique to NVDA:** Sovereign AI, Data Center
**Unique to AMD:** PC Recovery, MI300 Ramp

**Systemic risk:** Competition in AI accelerators affects both companies

**Idiosyncratic risk for AMD:** PC market softness — NVDA has no PC exposure

---

## Report Output Structure

Title: `NVDA vs AMD — Comparison Report | 2 Companies | Past Year`

- **Section 1:** Scorecard — NVDA wins 9/9; winner cells green, AMD cells red (2-company rule)
- **Section 2:** Quarter card rows — NVDA (blue label), AMD (purple label); Charts 3 & 4; callout: "📊 NVDA RISING (0.52→0.67), AMD FALLING (0.41→0.39)"
- **Section 3:** Chart 1 grouped bar — NVDA dominates all three periods; table below
- **Section 4:** Financial table — NVDA leads all four rows; revenue gap is 5.4×
- **Section 5:** Chart 2 — exec/analyst per company; Goldman Sachs most bullish firm for NVDA
- **Section 6:** Topics — AI Accelerators flagged as macro theme; PC Recovery as AMD-specific
- **Section 7:** Risk table — PC market softness ✅ AMD / — NVDA (idiosyncratic)
- **Section 8:** Verdict — NVDA leads all 9; AMD undervalued signal flagged; bottom line: NVDA
