# Evaluation Criteria — pronto-company-intelligence

---

## Overview

This file defines what a correct, high-quality response from `pronto-company-intelligence` looks like. Use these criteria when reviewing outputs or running structured evaluations.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on ticker or company name | "tell me about NVDA", "Apple earnings analysis" activates skill |
| Does NOT trigger for comparisons | "NVDA vs AMD" does NOT activate — routes to compare |
| Does NOT trigger for market overview | "what's happening in the market" does NOT activate — routes to market pulse |
| Does NOT trigger for sector queries | "analyze the tech sector" does NOT activate — routes to sector intelligence |

---

## 2. Data Collection

| Criterion | Pass condition |
|-----------|---------------|
| `getCompanyDescription` called first | Fired before any batch requiring `companyId` |
| `companyId` passed to all stock/prediction tools | Never hardcoded — always from `getCompanyDescription` |
| `getAnalytics` called per quarter | One call per transcript (Q1, Q2, Q3, Q4 separately) — not one aggregate call |
| `getCompanyDocuments` `documentIDs` used | Per-quarter `getAnalytics` uses document IDs from `getCompanyDocuments` |
| Competitor `companyId`s retrieved | `getCompanyCompetitors` called; competitor IDs used in `getStockChange` |
| `getSpeakers` called for CEO and CFO separately | Two calls: `Executives_CEO` and `Executives_CFO` |
| Forecast search per earnings call | `search` called with `documentID` filter per quarter |
| Date ranges within 1-year analytics limit | No single `getAnalytics` call spans more than 12 months |
| All independent tools fired in parallel | No sequential calls where parallel execution was possible |

---

## 3. Insight Quality

| Criterion | Pass condition |
|-----------|---------------|
| Sentiment direction stated explicitly | Executive summary says "RISING" / "FALLING" / "FLAT" with score |
| Investment score direction stated | Executive summary states direction for investment score |
| Stock reaction to earnings stated | How stock moved post-earnings named for each quarter |
| Forecast tone direction stated | "IMPROVING" / "DETERIORATING" explicitly stated |
| CEO vs CFO comparison present | Report shows ABOVE/BELOW label for CEO relative to CFO |
| Exec vs analyst gap calculated | Report states whether executives are MORE POSITIVE or MORE NEGATIVE than analysts |
| Most bullish and bearish analysts named | Both identified by name and firm |
| Divergences flagged | Sentiment rising + stock falling (or vice versa) explicitly called out |
| Risk factors prioritized by severity | Not a flat list — ranked or tiered |

---

## 4. Tool Usage

| Criterion | Pass condition |
|-----------|---------------|
| Independent tools called in parallel | No sequential waits where parallel was possible |
| `getTrends` called with `companyName` | Never called without scoping to the company |
| Competitor calls made per competitor | One `getStockChange` per competitor — not batched into one call |
| No external skills invoked | Only native MCP tools called — no skill-calling-skill |

---

## 5. HTML Output

| Criterion | Pass condition |
|-----------|---------------|
| Output is a saved HTML file | Renderer writes a standalone `.html` file — not inline markdown |
| Filename includes date stamp | `<TICKER>-report-<YYYYMMDD>.html` format |
| Standalone HTML document | File contains DOCTYPE, `<html>`, `<head>`, `<body>` — not a fragment |
| All 9 sections present | Header, KPI grid, quarter cards, stock chart, competitors, trends, events, speakers, risk/verdict |
| Signal colors correct | Positive: `#6AA64A`, Negative: `#ED4545` — no other green or red values used for signals |
| Charts present and correct | Each chart matches the spec in the renderer (type, data fields, colors) |
| Citation links well-formed | Every quote link uses `https://{org}.prontonlp.com/#/ref/<FULL_ID>` |
| Quotes attributed correctly | Speaker name, role, company, and date present for every quote |

---

## 6. Formatting

| Criterion | Pass condition |
|-----------|---------------|
| Sentiment scores: 2 decimal places | 0.48, not 0.5 or 0.480 |
| Investment scores: raw API value | Never rounded, never assumed to be on 0–10 scale |
| Stock changes: 1 decimal place with sign | +61.8%, −12.3% |
| Quarter-over-quarter table present | Direction columns included |
| No fabricated data | Missing metric → "N/A", never invented |

---

## 7. Error Handling

| Criterion | Pass condition |
|-----------|---------------|
| Company not found | Tries ticker alternative; notes issue; continues |
| Fewer than 4 quarters of data | Shows available quarters; notes the gap |
| No predictions available | Shows "N/A" — never fabricates |
| No analyst data | N/A in analyst rows; row not skipped |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering criteria
- **≥ 8 of 9** data collection criteria
- **≥ 8 of 9** insight quality criteria
- **All** tool usage criteria
- **All** HTML output criteria
- **All** formatting criteria
- **≥ 3 of 4** error handling criteria (only evaluated when errors occur)
