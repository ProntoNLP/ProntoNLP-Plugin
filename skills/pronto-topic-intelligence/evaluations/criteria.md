# Topic Intelligence — Evaluation Criteria

## Triggering

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Topic detection | Correctly identifies the topic keyword from the user's request | 15% |
| Synonym handling | Handles variations (e.g., "inflation" vs "rising prices" vs "cost pressures") | 10% |

---

## Data Collection

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Parallel execution | Fires all independent calls simultaneously | 15% |
| Tool coverage | Uses all 6 tools appropriately for topic analysis | 15% |
| Date handling | Applies correct date range (default: past year) | 5% |

---

## Keyword Heatmap

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Heatmap trigger | Calls `getTermHeatmap` before rendering | 10% |
| Heatmap inclusion | Displays heatmap in Section 2 of report | 5% |

---

## Visualization

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Chart 1 — Sentiment over time | Line chart showing quarterly sentiment trend | 5% |
| Chart 2 — Sentiment breakdown | Doughnut/pie chart showing positive/negative/neutral | 5% |
| Data as inline JS | All chart data defined as JS constants | 2% |

---

## Quotes

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Search agent usage | Uses `pronto-search-summarizer` for quotes | 5% |
| Diverse perspectives | Shows bullish, bearish, and analyst quotes | 3% |
| Attribution | All quotes include speaker name, role, company, date | 2% |

---

## Output

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Environment detection | Correctly detects Bash availability for output format | 3% |
| HTML format | Proper HTML structure (style + content + scripts) | 3% |
| Value coloring | Green for positive, red for negative, no color for zero | 2% |

---

## Total: 100%

**Passing score:** 80%
