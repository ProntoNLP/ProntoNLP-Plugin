# Evaluation Criteria — pronto-compare-companies

---

## Overview

This file defines what a correct, high-quality response from `pronto-compare-companies` looks like. Use these criteria when reviewing outputs or running structured evaluations.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on "compare X vs Y" | Skill activates without user having to say "use the compare skill" |
| Triggers on ticker comparisons | "NVDA vs AMD", "AAPL vs MSFT vs GOOGL" activates skill |
| Triggers on 3+ companies | "compare Apple, Google, and Microsoft" activates skill |
| Does NOT trigger for single company | "tell me about Apple" does NOT activate this skill |
| Does NOT trigger for sector queries | "compare tech sector vs financials" does NOT activate this skill |
| Asks to narrow down when >5 companies | User asks for 6+ companies → skill asks to narrow to 5 or fewer |

---

## 2. Data Collection (Batches 1–4)

| Criterion | Pass condition |
|-----------|---------------|
| Batch 1 fires all companies simultaneously | `getCompanyDescription` called for all companies at once |
| Batch 2 fires all companies simultaneously | `getCompanyDocuments`, `getStockChange` ×3, `getPredictions` ×4, `getTrends` for all companies at once |
| Batch 3 fires all companies simultaneously | `getAnalytics` ×4 per company, `getStockPrices` ×4 per company, `getSpeakers` ×4, `getSpeakerCompanies` for all companies at once |
| Batch 4 fires all companies simultaneously | `search` ×3 per company for all companies at once |
| companyId saved immediately | `companyId` from Batch 1 passed correctly to all stock calls in Batches 2–3 |
| Per-quarter analytics | `getAnalytics` called separately per quarter using `documentIDs`, not one aggregate call |
| All required metrics captured | Sentiment Q1–Q4, investment Q1–Q4, stock reaction Q1–Q4, stock YTD/6M/1Y, revenue/EPS/EBITDA/FCF, exec avg, analyst avg, CEO, CFO, gap, topics, risks |
| Missing company handled | If company not found, tries ticker; notes issue; continues with remaining |
| No external skills called | Uses MCP tools directly — does not call pronto-company-intelligence |

---

## 3. Scoring & Synthesis (Step 3)

| Criterion | Pass condition |
|-----------|---------------|
| All 9 dimensions scored | Sentiment, investment, stock, earnings reaction, analyst, revenue, EPS, exec confidence, risk |
| Explicit winner per dimension | Every row in scorecard has a winner (🏆) |
| Win tally computed | "Overall Wins" row shows count (e.g. "5 / 9") |
| Overall leader named | Explicitly states "Overall leader: [Company] — wins N of M dimensions" |
| Tie-breaker applied | If two companies tie on wins, higher investment score wins |
| Divergence signal identified | Flags if a company has high investment score but poor stock performance (undervalued signal) |
| Topic overlap computed | Shared topics flagged as macro themes; unique topics flagged as company-specific |
| Risk classification | Systemic risks (appear in 2+ companies) vs idiosyncratic risks (appear in 1) |

---

## 4. Report Structure (Step 4)

| Criterion | Pass condition |
|-----------|---------------|
| Output is HTML only | Response contains zero markdown tables, zero plain text paragraphs, zero code blocks |
| No DOCTYPE / html / head / body tags | Fragment only — starts with `<style>` |
| Chart.js loaded once | `<script src="https://cdn.jsdelivr.net/npm/chart.js">` appears exactly once |
| All 8 sections present | Scorecard, Earnings QoQ, Stock, Financial, Analyst/Exec, Topics, Risk, Verdict |
| Section 1 — Scorecard | One column per company + Winner column; all metric rows present |
| Section 2 — QoQ cards | One company-block per company; quarter cards rendered; direction trend shown |
| Section 3 — Stock chart | Chart 1 present; grouped bar by period (YTD/6M/1Y); table below chart |
| Section 4 — Financials | Revenue/EPS/EBITDA/FCF table; highest value highlighted green |
| Section 5 — Analyst/Exec | Chart 2 present; CEO/CFO/Exec/Analyst grouped bar; gap table with interpretation |
| Section 6 — Topics | Shared topics flagged; unique topics identified |
| Section 7 — Risks | ✅ / — table; systemic vs idiosyncratic labels |
| Section 8 — Verdict | 3–4 paragraphs; leader, undervalued signal, highest risk, bottom-line pick |
| Charts 3 & 4 | Multi-line sentiment and investment score trends per company in Section 2 |

---

## 5. Visual Design

| Criterion | Pass condition |
|-----------|---------------|
| Company colors consistent | Each company has its assigned color (A=blue, B=purple, C=orange…) used throughout |
| CSS design tokens used | `var(--color-text-primary)`, `var(--color-background-primary)` etc. used (not hardcoded) |
| Green/red signal colors correct | Winner cells use `#dcfce7` / `#15803d`; loser cells use `#fee2e2` / `#b91c1c` |
| Direction arrows shown | ↑ green for RISING, ↓ red for FALLING inline with scores |
| 2-company rule applied | With 2 companies, both winner=green and loser=red; with 3+, only winner=green |
| Trophy icon | 🏆 appears in winner cells |

---

## 6. Formatting

| Criterion | Pass condition |
|-----------|---------------|
| Sentiment scores: 2 decimal places | 0.38, not 0.4 or 0.380 |
| Investment scores: display raw value from API as-is | Do not round or truncate |
| Stock changes: 1 decimal place with sign | +12.4%, −3.1% |
| Tickers used in headers | Column headers use NVDA not NVIDIA Corporation |
| No all-N/A rows | If all companies have no data for a metric, row is omitted with footnote |
| No fabricated data | Any missing metric shown as "N/A", never invented |

---

## 7. Error Handling

| Criterion | Pass condition |
|-----------|---------------|
| Fewer than 4 quarters | Available quarters shown; gap noted |
| No analyst data for one company | N/A shown in analyst rows; row not skipped |
| Different fiscal years | Fiscal year mismatch noted in financial section |
| Company not found | Tried ticker alternative; noted in report; other companies proceed |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering criteria
- **All** data collection criteria
- **≥ 8 of 9** scoring/synthesis criteria
- **All** 8 sections present in the HTML output
- **≥ 4 of 5** visual design criteria
- **All** formatting criteria
- **≥ 3 of 4** error handling criteria (only relevant when errors occur)
