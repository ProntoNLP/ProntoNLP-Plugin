# Topic Intelligence Example: Inflation

## Request

"how is inflation discussed across sectors"

---

## Step 0: Topic Parsing

**topicExact:** `inflation` — taken as the subject the user is asking about (exact token; for a phrase like `war with Iran`, pass that full string unchanged).

Use the same string for tools and for Step 3.

---

## Step 1: First Parallel Batch

### getOrganization

→ `org` saved for links.

### searchSectors — full period (example dates)

```
searchSectors(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-12",
  untilDay: "2026-04-12"
)
```

→ Sectors with `total`, `score`, sentiment counts. **Meta hits** = sum of `total` across sectors (example: ~45,000 — illustrative only). **Sectors chart** — horizontal bar by sector `total` (no overtime line chart).

### searchTopCompanies

```
searchTopCompanies(
  topicSearchQuery: "inflation",
  documentTypes: ["Earnings Calls"],
  sinceDay: "2025-04-12",
  untilDay: "2026-04-12"
)
```

→ Up to **20** rows. Table: **Company Name** | **Symbol** (`ticker`) | **sentimentScore** (`sentiment`) | **Hits** (`hitsCount` or `score`).

---

## Step 2: Top Documents — getCompanyDocuments

For **10–15** companies from `searchTopCompanies` (names must match tool output):

```
getCompanyDocuments(companyName: "Walmart", documentTypes: ["Earnings Calls"], excludeFutureDocuments: true)
// ... parallel for each selected company; keep newest 1–2 rows per company from each response
```

→ Flatten, dedupe by `documentID`, sort by `date` desc, keep top **20** rows for the table.

---

## Step 3: pronto-search-summarizer

Use the **exact task template in SKILL.md Step 3** with **topicExact:** `inflation` (verbatim) and `org` filled in.

→ No sentiment: positive/negative filters on the topic; organize as representative commentary / analyst questions / by sector.

---

## Step 4: Compile Report

Render per SKILL.md: Executive Summary → sectors chart → tables → Key Quotes → Themes → Conclusion.

---

## Key Signals (illustrative — real report uses tool values only)

| Signal | Source |
|--------|--------|
| Total hits (meta) | Sum of `total` from full-period `searchSectors` |
| Top sectors | Full-period `searchSectors` by `total` |
| Top companies | `searchTopCompanies` (≤20) |
| Documents | Batched `getCompanyDocuments` |

---

## Report Preview (abbreviated)

### Executive Summary (style reference)

Inflation remains a central cross-sector narrative in corporate commentary, with uneven emphasis across industries. Consumer-facing and input-cost-heavy sectors show sustained engagement, while the tone mixes operational mitigation (pricing, productivity) with caution on demand elasticity. Near-term discussion clusters on pass-through mechanics and margin defense; medium-term threads reference macro rates and cost normalization. Uncertainty around the persistence of cost pressure and the timing of central-bank response frames much of the dispersion in sentiment across companies.

### Chart / table order

1. Related sectors (horizontal bar)  
2. Related companies table  
3. Top documents table  

### Themes (structure example — quotes must be real in production)

**Theme 1: Pricing pass-through and margin defense**  
**Insight:** …  
**Relevant Evidence:**  
- "…" (Company A)  
- "…" (Company B)  
**Market Implications:** …  

**Theme 2: Cost inputs and supply chain**  
**Insight:** …  
**Relevant Evidence:** …  
**Market Implications:** …  

### Conclusion (structure reference)

Synthesis paragraph; **Near-term / Medium-term / Long-term** bullets; **Critical monitoring indicators**; **Overweight / Underweight / Neutral** framed as hypotheses from evidence — no fabricated tickers or KPIs.

---

## Removed from legacy skill (do not use here)

- `getTermHeatmap`  
- `getTrends`  
- Event sentiment doughnut (`patternSentiment` pie)  
- Top Aspects section  
- `getAnalytics(... topicSearchQuery ...)`  
