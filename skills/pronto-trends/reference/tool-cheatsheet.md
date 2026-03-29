# Trends Tools — Cheatsheet

Quick reference for parameters, output fields, and formatting for keyword/topic trend tools.

---

## Tools in This Skill

| Tool | Purpose |
|------|---------|
| `getTrends` | Trending keywords and topics — score, hit count, % change over time |
| `getMindMap` | Concept relationship graph for a topic |
| `getTermHeatmap` | Term frequency across companies and time periods |

---

## getTrends — Params & Output

**Key params:**
| Param | Notes |
|-------|-------|
| `companyName` | Scope to a specific company's documents |
| `sectors` | Scope to a sector (e.g. `["Information Technology"]`) |
| `sinceDay` / `untilDay` | Date range — keep within 1 year |
| `sortBy` | Always `"score"` |
| `sortOrder` | Always `"desc"` |
| `limit` | Always `20` |

**Output fields per trend:**
| Field | Meaning |
|-------|---------|
| `name` | Topic / keyword label |
| `score` | Relevance score — higher = more prominent |
| `hits` | Number of document mentions |
| `change` | % change vs prior period — positive = RISING, negative = DECLINING |

**Direction labels:**

| % Change | Label |
|----------|-------|
| Positive | RISING ↑ |
| Negative | DECLINING ↓ |

Always call out the fastest-rising themes (highest positive % change) as emerging narratives.

---

## getMindMap — Params & Output

**Key params:**
| Param | Notes |
|-------|-------|
| `topic` | The concept to map (e.g. "AI", "supply chain", "tariffs") |
| `sinceDay` / `untilDay` | Date range |
| `sectors` | Optional sector filter |

**Output:** A graph structure with nodes and edges. Convert to nested markdown list:

```markdown
**AI**
- Machine Learning
  - Large Language Models
  - Computer Vision
- Data Infrastructure
  - Cloud Computing
  - Edge Computing
- Applications
  - Drug Discovery
  - Fraud Detection
```

---

## getTermHeatmap — Params & Output

**Key params:**
| Param | Notes |
|-------|-------|
| `term` | The keyword to track (e.g. "tariff", "inflation", "AI") |
| `companyNames` / `sectors` | Scope |
| `sinceDay` / `untilDay` | Date range |

**Output:** Frequency counts per company per time period. Present as:

| Term | Company | Quarter | Frequency |
|------|---------|---------|-----------|
| tariff | Apple | Q1 2025 | 47 |
| tariff | NVIDIA | Q1 2025 | 12 |

Sort by frequency descending. Flag spikes — companies where frequency jumped significantly vs prior period.

---

## Date Helpers

```
Past quarter:   sinceDay = 90 days ago,   untilDay = today
Past 6 months:  sinceDay = 6 months ago,  untilDay = today
Past year:      sinceDay = 1 year ago,    untilDay = today
```

---

## Citation URL

```
https://dev.prontonlp.com/#/ref/<FULL_ID>
```
