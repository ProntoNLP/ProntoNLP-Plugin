# Topic Intelligence — Tool Cheatsheet

## Tools Used

Topic intelligence uses these ProntoNLP tools. **Do not** call `getTermHeatmap`, `getMindMap`, `deepResearch`, or **`getTrends`** from this skill.

---

## 1. getOrganization

**Purpose:** Resolve `org` for all `https://{org}.prontonlp.com/#/ref/...` company links.

```
getOrganization()
```

---

## 2. searchSectors — Sector hits + sentiment (topic-scoped)

**Purpose:** Sector breakdown for the topic; drives **Related Sectors** bar chart, sector table, and **total hits** (sum of `total`). One **full-period** call per report (do **not** synthesize an overtime line chart from repeated `searchSectors` by quarter — that is not reliable for this skill).

**Full period (example):**

```json
{
  "topicSearchQuery": "<topicExact>",
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response:** `sectors[]` with `name`, `total` (hits), `totalPositives`, `totalNegatives`, `totalNeutrals`, `score`, etc.

**Report usage:** Horizontal bar chart, optional sector table, meta **Hits** = sum of `total` over sectors.

**Note:** MCP `getAnalytics` does **not** accept `topicSearchQuery`. Use **`searchSectors`** for topic-wide sector analytics.

---

## 3. searchTopCompanies — Related companies table

**Purpose:** Top companies discussing the topic (semantic or keyword flow inside API).

```json
{
  "topicSearchQuery": "<topicExact>",
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response:** Up to **20** companies (API cap). Fields: `companyId`, `companyName`, `ticker` (symbol; may be empty string), `sentiment` (show in HTML as column **sentimentScore**), plus either semantic `score` or keyword `hitsCount` for the **Hits** column.

**Report usage:** Related companies table (≤20 rows) — columns **Company Name** | **Symbol** | **sentimentScore** | **Hits**.

---

## 4. getCompanyDocuments — Rows for Top documents table

**Purpose:** Latest document(s) per top company; batch after `searchTopCompanies`.

```json
{
  "companyName": "<name from searchTopCompanies>",
  "documentTypes": ["Earnings Calls"],
  "excludeFutureDocuments": true
}
```

Call **in parallel** for **10–15** top companies. Responses are newest-first — take **1–2** documents per company, then flatten, dedupe by `documentID`, sort by `date` desc, keep **15–25** rows.

**Report usage:** Top documents table (Company | Title | Date | Document ID).

---

## 5. pronto-search-summarizer — Quotes + theme evidence

**subagent_type:** `prontonlp-plugin:pronto-search-summarizer`

Use the task template in **SKILL.md Step 3**: pass **`topicExact`** verbatim; **no** sentiment: positive/negative filters on the topic; larger `size`; verbatim quotes for Themes.

---

## ID / Data Flow

```
topicExact
  ├── getOrganization → org
  ├── searchSectors (full period) → sectors, total hits meta, sectors chart
  ├── searchTopCompanies → company table → company names for getCompanyDocuments
  ├── getCompanyDocuments ×10–15 → top documents table
  └── pronto-search-summarizer → Key Quotes + Themes evidence
```

---

## Date Handling

| Scope | sinceDay | untilDay |
|-------|----------|----------|
| Default (past year) | 1 year ago | today |
| Past quarter | 90 days ago | today |
| Past 6 months | 6 months ago | today |
| YTD | Jan 1 current year | today |

---

## Quick Parameter Reference

**Document types:** `Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day` | …

**Topic string:** Prefer **`topicExact`** (user’s exact wording) for `topicSearchQuery` in `searchSectors` and `searchTopCompanies`.
