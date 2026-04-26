# Evaluation Criteria — pronto-topic-research

---

## Overview

This file defines what a correct, high-quality response from `pronto-topic-research` looks like. Use these criteria when reviewing outputs or running structured evaluations.

---

## 1. Skill Triggering

| Criterion | Pass condition |
|-----------|---------------|
| Triggers on topic/theme research requests | "how is AI regulation discussed", "top themes around inflation" activates skill |
| Triggers on macro narrative questions | "executive summary on supply chain disruptions" activates skill |
| Does NOT trigger for single named company | "tell me about NVIDIA" does NOT activate — routes to company intelligence |
| Does NOT trigger for market overview | "what's happening in the market" does NOT activate — routes to market pulse |

---

## 2. Data Collection

| Criterion | Pass condition |
|-----------|---------------|
| All 5 trend tools called in parallel | `getTrendOvertime`, `getTrendRelatedSectors`, `getTrendWordsByCompany`, `getTrendWordsByDocument`, `getTrendNetwork` all fired simultaneously |
| `pronto-search-summarizer` called in same parallel batch | Fired alongside the 5 trend tools — not after |
| `getTrendOvertime` uses 15-month window | `gte` = 15 months ago when user provides no timeframe |
| All other trend tools use 90-day window | `gte` = 90 days ago for the 4 remaining trend tools |
| `getTrendOvertime` passes `timeframeInterval: "quarter"` | Never omitted |
| All trend tools pass `dateRange` explicitly | Both `gte` and `lte` present on every call |
| All trend tools pass `documentTypes: ["Earnings Calls"]` | Exact string — no variation |
| All trend tools pass `corpus: ["S&P Transcripts"]` | Exact string — never omitted |
| No `searchSectors` called | Only the 5 listed native trend tools + search-summarizer subagent used |

---

## 3. Search-Summarizer Agent Protocol

| Criterion | Pass condition |
|-----------|---------------|
| Agent prompt requests verbatim sentences only | No JSON, no metadata, no bullets, no headers |
| One citation per line | Each sentence ends with `[Link: https://{org}.prontonlp.com/#/ref/<FULL_ID>]` |
| Weak/off-topic results excluded | Agent instruction explicitly says to exclude low-quality sentences |
| Output saved as `searchResults` | Agent output stored for passing to themes broker |

---

## 4. Themes Broker

| Criterion | Pass condition |
|-----------|---------------|
| `pronto-themes-broker` receives full `searchResults` | Complete agent output from Step 2 passed verbatim |
| Broker returns Executive Summary, Themes, and Conclusion | All three sections present in broker output |
| Broker synthesis not fabricated | Themes and evidence come solely from the search results, not invented |
| Broker does not spawn subagents or invoke skills | Synthesis-only — no recursion |

---

## 5. HTML Output

| Criterion | Pass condition |
|-----------|---------------|
| Output is a saved HTML file | Renderer writes a standalone `.html` file — not inline markdown |
| Filename includes date stamp | `<topic-slug>-research-<YYYYMMDD>.html` format |
| Standalone HTML document | File contains DOCTYPE, `<html>`, `<head>`, `<body>` — not a fragment |
| "Hits Overtime" section present | Exact title — never "Mentions" or "Trends" |
| Line chart present with 3 series | Total hits, positive hits, negative hits — correct colors |
| Related Sectors table present | Name, hits, score columns |
| Related Companies table present | Name, ticker, score, sentiment breakdown, hits |
| Related Documents table present | Name, date, company, sentiment breakdown, hits |
| Related Keywords table present | Name, hits, score, explanation for each row |
| Themes section present | At least 3 themes; each with title, insight, market implications, evidence |
| Evidence quotes linked | Each quote links to `https://{org}.prontonlp.com/#/ref/<FULL_ID>` |
| Executive Summary present | Verbatim from themes broker — not rewritten |
| Conclusion present | Verbatim from themes broker — not rewritten |

---

## 6. Visual Design

| Criterion | Pass condition |
|-----------|---------------|
| Platform color tokens used | `var(--text-primary)`, `var(--bg-card)`, `var(--signal-positive)` etc. |
| Signal colors correct | Positive: `#6AA64A`, Negative: `#ED4545` |
| Chart tooltips show positive/negative breakdown | Hovering a data point reveals the split |
| Company/document links formatted correctly | Links use `https://{org}.prontonlp.com/#/ref/<FULL_ID>` |

---

## 7. Formatting

| Criterion | Pass condition |
|-----------|---------------|
| Topic search query used consistently | Same query string in report title and all tool calls |
| Scores displayed to 2 decimal places | 0.94, not 0.9 or 0.940 |
| Hits displayed as integers | 2134, not 2,134.0 |
| Explanations present for all keywords | No keyword row with a blank explanation cell |
| No fabricated data | All values from tool responses; if missing, state "N/A" |

---

## Scoring Summary

A response passes evaluation if it meets:
- **All** triggering criteria
- **All** data collection criteria
- **All** search-summarizer protocol criteria
- **All** themes broker criteria
- **All** HTML output criteria
- **≥ 3 of 4** visual design criteria
- **All** formatting criteria
