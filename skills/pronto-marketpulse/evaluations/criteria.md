# Evaluation Criteria — pronto-marketpulse

---

## Overview

This file defines what a correct, high-quality response from `pronto-marketpulse` looks like. Use these criteria when reviewing outputs or running structured evaluations.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on broad market queries | "what's moving in the market", "market recap", "top movers" activates skill |
| Triggers on leaderboard queries | "most bullish companies", "biggest sentiment shifts", "highest investment scores" activates skill |
| Triggers on earnings season queries | "earnings season highlights", "what large caps are outperforming" activates skill |
| Does NOT trigger for single company | "tell me about NVDA" does NOT activate — routes to company intelligence |
| Does NOT trigger for single sector | "analyze the tech sector" does NOT activate — routes to sector intelligence |
| Default date range applied correctly | No time frame specified → past 7 days |
| User-specified time frame honored | "past month", "last 30 days" → correct date range computed |

---

## 2. Section Selection

| Criterion | Pass condition |
|-----------|---------------|
| Movers-only for price/score queries | "top movers", "what's moving" → leaderboards only; no trends or speakers |
| Full report for narrative queries | "market recap", "what happened this week" → leaderboards + trends + speakers |
| Trends-only when requested | "what topics are trending" → trends section only |
| Speakers-only when requested | "what are executives saying" → speakers section only |
| Movers-only report prompts full report upsell | At end: tells user they can ask for a full report |

---

## 3. Market Cap Filter

| Criterion | Pass condition |
|-----------|---------------|
| Default is `$300M+` | No filter specified → 4-element array: Small + Mid + Large + Mega |
| `marketCaps` always passed as array | Never a plain string |
| "large caps" → `$10B+` | `["Large ($10bln - $200bln)", "Mega ($200bln & more)"]` |
| "mega cap" → `$200B+` | `["Mega ($200bln & more)"]` |
| Sector/country filter applied alongside market cap | Both filters present in the call |
| `getTrends` called without `marketCaps` | `getTrends` never receives a `marketCaps` parameter |

---

## 4. Data Collection

| Criterion | Pass condition |
|-----------|---------------|
| All Step 2 calls fire simultaneously | `getOrganization`, `getTopMovers`, `getTrends`, `getSpeakers` all in one parallel batch |
| `getTopMovers` uses single call with `sortBy` array | All needed criteria in one call — not one call per criterion |
| All 7 sort criteria fetched for full report | `stockChange`, `investmentScore`, `investmentScoreChange`, `sentimentScore`, `sentimentScoreChange`, `aspectScore`, `marketcap` |
| Speaker calls: bullish and bearish | Both `sortOrder: "desc"` and `sortOrder: "asc"` called for executives and analysts |
| Sparse data widened | Leaderboard with <5 companies → date range widened 7 days and re-called |
| `potentialBuy` signal computed | Cross-filter: high `investmentScore.topMovers` ∩ `stockChange.underperforming` |
| Company count deduplicated | Master list built by `id` across all arrays |

---

## 5. HTML Output

| Criterion | Pass condition |
|-----------|---------------|
| Output is a saved HTML file | Renderer writes a standalone `.html` file — not inline markdown |
| Filename includes date stamp | `market-pulse-<YYYYMMDD>.html` format |
| Standalone HTML document | File contains DOCTYPE, `<html>`, `<head>`, `<body>` — not a fragment |
| Leaderboard cards present | One card per fetched criterion; correct title per leaderboard mapping |
| Sentiment Shift card has bullish and bearish lists | `topMovers` (bullish) + `underperforming` (bearish) both present |
| Signal badges applied | `Potential Buy`, `Watch`, `Caution` badges rendered per renderer conventions |
| Trends section present (when fetched) | Bar chart or table with name, score, hits, change |
| Speakers section present (when fetched) | Exec and analyst tables with bullish/bearish split |
| Company links well-formed | Links use `https://{org}.prontonlp.com/#/ref/$COMPANY{id}` format |

---

## 6. Visual Design

| Criterion | Pass condition |
|-----------|---------------|
| Signal colors correct | Positive: `#6AA64A`, Negative: `#ED4545` |
| Platform CSS tokens used | `var(--text-primary)`, `var(--bg-card)` etc. — not hardcoded layout colors |
| Leaderboard cards in responsive grid | Cards laid out with `grid-template-columns: repeat(auto-fit, ...)` or equivalent |
| Date range expansion noted | If date was widened for sparse data, report surface it |

---

## 7. Delivery Summary

| Criterion | Pass condition |
|-----------|---------------|
| Time period stated | Date range + any expansion noted |
| Company count stated | Total deduplicated companies |
| Top stock performer named | Company with highest `stockChange` named |
| Consistent outperformers called out | Companies appearing in multiple leaderboards identified |
| Potential Buy signals surfaced | High investment score + falling stock companies named |
| Top trend named (if trends fetched) | #1 trend by score explicitly mentioned |
| Most bullish/bearish exec and analyst named (if speakers fetched) | Names and firms stated |

---

## 8. Error Handling

| Criterion | Pass condition |
|-----------|---------------|
| `getTopMovers` returns <5 for a criterion | Widens date range 7 days; re-calls that criterion only; notes expansion |
| No trends data returned | Omits trends section; notes it |
| No speaker data returned | Omits speakers section; notes it |
| No companies match filters | Notes the filter was too narrow; suggests widening |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering criteria
- **All** section selection criteria
- **All** market cap filter criteria
- **≥ 6 of 7** data collection criteria
- **All** applicable HTML output sections
- **≥ 3 of 4** visual design criteria
- **All** delivery summary criteria (for sections included)
- **≥ 3 of 4** error handling criteria (only evaluated when errors occur)
