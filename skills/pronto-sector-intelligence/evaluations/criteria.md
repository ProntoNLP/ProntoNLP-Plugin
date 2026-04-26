# Evaluation Criteria — pronto-sector-intelligence

---

## Overview

This file defines what a correct, high-quality response from `pronto-sector-intelligence` looks like. Use these criteria when reviewing outputs or running structured evaluations.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on explicit sector names | "analyze the tech sector", "healthcare industry report" activates skill |
| Triggers on informal sector language | "what's happening in financials", "energy outlook" activates skill |
| Triggers on sub-sector queries | "sentiment in semiconductors", "AI across information technology" activates skill |
| Triggers on cross-sector sentiment questions | "which sectors are most bullish" activates skill |
| Does NOT trigger for single named company | "tell me about Apple" does NOT activate this skill |
| Does NOT trigger for compare queries | "compare Apple vs Google" does NOT activate this skill |
| Correct sector string used | User says "tech" → skill uses `"Information Technology"` (exact string), not "Tech" or "Technology" |
| Sub-sector format correct | User says "semiconductors" → `"Information Technology-Semiconductors and Semiconductor Equipment"` |

---

## 2. Report Mode Selection

| Criterion | Pass condition |
|-----------|---------------|
| Full Report for broad queries | "analyze the healthcare sector" → all 8 sections, 5 batches |
| Movers Report for performance queries | "top movers in financials" → Sections 1–2 only |
| Theme Analysis for topic queries | "what are tech companies talking about" → Sections 1, 4–6 |
| Sentiment Report for sentiment queries | "how bullish is real estate" → Sections 1, 3, 6–7 |
| Only requested sections rendered | Movers-only response contains no trending topics or speaker sections |

---

## 3. Parallel Execution

| Criterion | Pass condition |
|-----------|---------------|
| Batch 1 fires simultaneously | `getTopMovers`, `getTrends`, `getAnalytics` all invoked in parallel |
| Batch 2 fires simultaneously | All `searchTopCompanies` calls and `searchSectors` fire in parallel |
| Batch 3 fires simultaneously | All `getSpeakers` and `getSpeakerCompanies` calls fire in parallel |
| Batch 4 fires simultaneously | All `search` calls fire in parallel |
| Batches run in sequence | Batch 2 starts only after Batch 1 completes; Batch 3 after Batch 1; etc. |
| `getTrends` has no `query` param | `getTrends` is never called with a `query` or `topicSearchQuery` field |
| `searchTopCompanies` one event per call | Never merges multiple event types into one `searchTopCompanies` call |
| `sectors` always an array | `sectors: ["Information Technology"]` — never `sectors: "Information Technology"` |

---

## 4. Key Signals Extracted

| Criterion | Pass condition |
|-----------|---------------|
| Sector direction stated | Report explicitly says "Sector sentiment is RISING / FALLING — average score: X.XX" |
| Investment leaders named | Top 3 companies by investment score named with their scores |
| Dominant positive event identified | Top positive event type named with hit count |
| Dominant negative event identified | Top negative event type named |
| Fastest-rising theme called out | #1 topic by positive `change` % named |
| Undervalued signal flagged | At least one `underperforming[investmentScore]` company highlighted (high score + falling stock) |
| Most bullish exec named | "Most bullish executive: [Name], [Role] at [Company] (score: X.XX)" |
| Most bearish analyst named | "Most bearish analyst: [Name] from [Firm] (score: X.XX)" |
| Analyst firm ranking present | Most bullish and most bearish analyst firms identified |

---

## 5. HTML Output

| Criterion | Pass condition |
|-----------|---------------|
| Output is a saved HTML file | Renderer writes a standalone `.html` file — not inline markdown |
| Filename includes date stamp | `<sector-slug>-report-<YYYYMMDD>.html` format |
| Standalone HTML document | File contains DOCTYPE, `<html>`, `<head>`, `<body>` — not a fragment |
| Chart.js loaded exactly once | CDN script tag appears exactly one time |
| Section 1 — Executive Summary | 2–3 paragraphs; direction, top performers, divergence signal, 3-point thesis |
| Section 2 — Leaderboard cards | At least 6 leaderboard cards in responsive grid; Chart 1 and Chart 2 present |
| Section 3 — Sentiment & Investment | Metrics table with direction badges; Chart 3 present; aspects listed |
| Section 4 — Trending Topics | Full topic table (top ≥15); Chart 4 and Chart 5 present; fastest-rising callout |
| Section 5 — Event Analysis | Positive and negative event tables; Chart 6 and Chart 7; per-event company rankings |
| Section 6 — Company Rankings | Per-theme company ranking table; Chart 8; cross-sector comparison |
| Section 7 — Speaker Voice | Exec/analyst sentiment; Chart 9; explicit bullish/bearish exec and analyst firm statements |
| Section 8 — Risk Themes | Risk exposure table; bearish quotes; highlighted risk callout |

---

## 6. Visual Design

| Criterion | Pass condition |
|-----------|---------------|
| CSS design tokens used | `var(--text-primary)`, `var(--bg-page)` etc. — not hardcoded colors for layout |
| Signal colors correct | Green `#6AA64A`, red `#ED4545` for RISING/FALLING and positive/negative signals |
| RISING badge green, FALLING badge red | Direction badges use correct background colors |
| Company links formatted correctly | Links use `https://{org}.prontonlp.com/#/ref/$COMPANY{id}` format |
| Leaderboard cards in responsive grid | `grid-template-columns: repeat(auto-fit, minmax(...))` or equivalent |
| Potential Buy Signals card present | Shows high-score companies with falling stock |

---

## 7. Formatting

| Criterion | Pass condition |
|-----------|---------------|
| Sentiment scores: 2 decimal places | 0.48, not 0.5 or 0.480 |
| Investment scores: display raw value from API as-is | Do not assume a scale |
| Stock changes with sign | +38.4%, −12.3% |
| Trend change with sign and % | +84%, −18% |
| Quotes cited correctly | `"[text]" — [Name], [Role], [Company] ([Date])` format |
| Sector name mapped correctly | User input properly normalized to exact valid sector string |
| No fabricated data | All values come from tool responses; if missing, state "N/A" or note it |

---

## 8. Error Handling

| Criterion | Pass condition |
|-----------|---------------|
| Sector name not recognized | Tries top-level sector if sub-sector fails; notes mapping used |
| Fewer than 5 companies in `getTopMovers` | Widens date range and retries; notes the expansion |
| `getAnalytics` returns no event types | Tries without `documentTypes` filter; notes it |
| `searchTopCompanies` empty for event type | Skips that event; notes it; proceeds with remaining |
| `getTrends` fewer than 10 results | Widens date range; removes `documentTypes` filter |
| `getSpeakers` returns no results | Tries without date filter; if still empty, states "No speaker data available" |
| No quotes from `search` | States "No matching quotes found" — never fabricates |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering criteria
- **All** parallel execution criteria
- **≥ 8 of 9** key signals extracted
- **All** applicable HTML output sections for the report mode
- **≥ 5 of 6** visual design criteria
- **All** formatting criteria
- **≥ 5 of 7** error handling criteria (only evaluated when errors occur in the test run)
