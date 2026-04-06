# Evaluation Criteria — pronto-compare

---

## Overview

This file defines what a correct, high-quality response from `pronto-compare` looks like. Use these criteria when reviewing outputs or running structured evaluations. The skill supports company-vs-company, sector-vs-sector, and mixed comparisons.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on company vs company | "NVDA vs AMD", "Apple vs Microsoft" activates skill |
| Triggers on sector vs sector | "tech vs healthcare", "IT vs financials" activates skill |
| Triggers on company vs sector | "NVDA vs the tech sector", "how does Apple compare to consumer staples" activates skill |
| Triggers on mixed multi-entity | "NVDA, AMD, and the semiconductor sector" activates skill |
| Triggers on informal phrasing | "who wins between Tesla and Rivian", "which sector leads — IT or energy" activates skill |
| Does NOT trigger for single company | "tell me about NVIDIA" does NOT activate — routes to company intelligence |
| Does NOT trigger for single sector | "analyze the tech sector" does NOT activate — routes to sector intelligence |
| Does NOT trigger for market overview | "what's happening in the market" does NOT activate — routes to market pulse |
| Sector name normalized correctly | "tech" → `Information Technology`, "healthcare" → `Health Care` |
| Sub-sector normalized correctly | "semiconductors" → `Information Technology-Semiconductors and Semiconductor Equipment` |
| Asks to narrow when >5 entities | User requests 6+ entities → skill asks to narrow to 5 or fewer |

---

## 2. Entity Classification

| Criterion | Pass condition |
|-----------|---------------|
| Each entity classified as company or sector | Every entity gets a clear `type: company` or `type: sector` label before any batch |
| Company entities call `getCompanyDescription` in Batch 1 | One call per company fired simultaneously |
| Sector entities require no Batch 1 API call | Sector name is normalized only — no API call wasted |
| Mode determined correctly | All-company → company mode; all-sector → sector mode; mixed → mixed mode |
| Correct scoring dimensions applied | Company vs company: 9 dims; sector vs sector: 7 dims; mixed: 7 universal + 2 company-only |

---

## 3. Data Collection (Batches 1–4)

| Criterion | Pass condition |
|-----------|---------------|
| Batch 1 fires company descriptions simultaneously | `getCompanyDescription` called for all company entities at once; no call for sector entities |
| Batch 2 fires all entities simultaneously | Company batch 2 calls + sector batch 2 calls all in one parallel batch |
| Batch 3 fires all entities simultaneously | All `getAnalytics`, `getStockPrices`, `getSpeakers`, `getSpeakerCompanies`, `searchTopCompanies` in one parallel batch |
| Batch 4 fires all entities simultaneously | All `search` calls for companies and sectors in one parallel batch |
| `companyId` saved and used correctly | Company `companyId` from Batch 1 passed to all stock calls in Batches 2–3 |
| Per-quarter analytics for companies | `getAnalytics` called once per transcript (Q1, Q2, Q3, Q4 separately) — not one aggregate call |
| Sector uses `sectors` array (not string) | `sectors: ["Information Technology"]` — never `sectors: "Information Technology"` |
| `getTrends` has no query param | `getTrends` never called with `query` or `topicSearchQuery` |
| `searchTopCompanies` — one event type per call | Never combined multiple event types in one call |
| Sector representative for speakers | `getSpeakers` and `getSpeakerCompanies` called on sector's top company (from `getTopMovers`) |
| No external skills invoked | Only MCP tools called directly — no skill-calling-skill |

---

## 4. Scoring & Synthesis

| Criterion | Pass condition |
|-----------|---------------|
| Correct number of dimensions scored | 9 for company-vs-company; 7 for sector-vs-sector; 7 universal + 2 company-only for mixed |
| Explicit winner per dimension | Every scoreable row has a `🏆` winner |
| N/A shown for company-only rows in sector columns | Sector columns show "N/A — Sector" in Earnings Reaction and Financial Outlook rows |
| Win tally computed | "Overall Wins" row shows count (e.g. "6 / 7") |
| Overall leader named explicitly | "Overall leader: [Entity] — wins N of M dimensions" |
| Tie-breaker applied | If tied on win count, higher investment score wins |
| Divergence signal identified | Flags any entity with rising investment score + weak stock (undervalued signal) |
| Sentiment direction computed | RISING / FALLING / FLAT stated per entity |
| Investment direction computed | RISING / FALLING / FLAT stated per entity |
| Topic overlap computed | Shared topics = macro themes; unique topics = entity narrative; 2+ entities sharing risk = systemic |
| Mixed comparison context | Verdict acknowledges company vs sector is not apples-to-apples; explains concentration vs breadth trade-off |

---

## 5. Report Structure

| Criterion | Pass condition |
|-----------|---------------|
| Output is HTML only | Zero markdown tables, zero plain text paragraphs, zero code blocks in response |
| No DOCTYPE / html / head / body tags | Fragment starts with `<style>` |
| Chart.js loaded exactly once | CDN script tag appears exactly one time |
| Section 1 — Scorecard | One column per entity + Winner column; correct rows for mode; N/A cells for sector in company-only rows |
| Section 2 — Quarter cards for companies | Companies show Q1–Q4 quarter cards; sectors show sector summary cards (not quarter cards) |
| Section 2 — Sector summary cards | Sector entities show: sentiment score, investment score, top mover, fastest-rising theme, dominant events |
| Section 3 — Stock performance | Chart 1 present; companies show YTD/6M/1Y; sectors show top-mover YTD with footnote |
| Section 4 — Financials | Present for company modes; OMITTED if all entities are sectors |
| Section 5 — Speaker sentiment | Companies show CEO/CFO/Exec/Analyst; sectors show sector leader exec + analyst firm |
| Section 6 — Topics | Overlap flagged; unique topics called out per entity; systemic risk topics marked |
| Section 7 — Risk table | ✅ / — per entity per risk; Type column shows Systemic or Idiosyncratic |
| Section 8 — Verdict | 3–4 paragraphs; leader, divergence signal, highest risk, bottom-line pick; mixed comparison adds context paragraph |

---

## 6. Visual Design

| Criterion | Pass condition |
|-----------|---------------|
| Entity colors consistent | Each entity uses its assigned color throughout all charts, cards, and headers |
| Entity type labeled | "(Company)" or "(Sector)" appears after entity name in headers and section labels |
| CSS design tokens used | `var(--color-text-primary)` etc. used for layout — not hardcoded |
| Signal colors correct | `#1D9E75` for RISING/positive; `#D85A30` for FALLING/negative |
| 2-entity rule: winner green + loser red | With 2 entities, both winner=green AND loser=red in scorecard |
| 3+ entity rule: winner green only | No red loser cells with 3+ entities |
| N/A cells styled correctly | Sector N/A cells use neutral styling (`var(--color-text-tertiary)`) — not green or red |

---

## 7. Formatting

| Criterion | Pass condition |
|-----------|---------------|
| Sentiment scores: 2 decimal places | 0.48, not 0.5 or 0.480 |
| Investment scores: raw API value | Never rounded, never assumed to be on 0–10 scale |
| Stock changes: 1 decimal place with sign | +61.8%, −12.3% |
| Topic change: integer with sign | +84%, −18% |
| Tickers used in company headers | "NVDA" not "NVIDIA Corporation" |
| Sector names in sector headers | "IT Sector" not "Information Technology" in narrow headers |
| Sector stock values footnoted | Any top-mover proxy is labeled as "[Company] — sector leader" |
| No all-N/A rows | If all entities lack data for a metric, row is omitted with footnote |
| No fabricated data | Missing metric → "N/A", never invented |

---

## 8. Error Handling

| Criterion | Pass condition |
|-----------|---------------|
| Company not found | Tries ticker alternative; notes issue; continues with remaining entities |
| Sector name not recognized | Tries top-level sector if sub-sector fails; notes mapping used |
| Fewer than 4 quarters for a company | Shows available quarters; notes the gap |
| No predictions for a company | Shows "N/A" — never fabricates |
| No analyst data for a company | N/A shown in analyst rows; row not skipped |
| `getTopMovers` returns <3 companies for sector | Widens date range; removes `documentTypes` filter |
| All-sector comparison with financial rows | Section 4 omitted entirely — not shown with all N/A |
| More than 5 entities | Asks user to narrow to 5 or fewer — does not attempt 6+ |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering and entity classification criteria
- **All** data collection criteria
- **≥ 9 of 11** scoring and synthesis criteria
- **All** applicable report sections for the comparison mode
- **≥ 6 of 7** visual design criteria
- **All** formatting criteria
- **≥ 6 of 8** error handling criteria (only evaluated when errors occur)
