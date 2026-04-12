# Topic Intelligence — Evaluation Criteria

## Triggering

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Topic detection | Correctly identifies the topic keyword from the user's request | 15% |
| Synonym handling | Handles variations when primary topic is sparse | 10% |

---

## Data Collection

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Parallel execution | Fires independent calls in parallel (Step 1 batch, then documents batch, then subagent) | 15% |
| Tool coverage | Uses `getOrganization`, full-period `searchSectors`, `searchTopCompanies`, batched `getCompanyDocuments`, and `pronto-search-summarizer` as specified; passes **topicExact** to the subagent per SKILL.md | 20% |
| Date handling | Applies correct date range (default: past year) | 5% |
| No forbidden tools | Does **not** call `getTermHeatmap`, `getMindMap`, `deepResearch`, `getTrends`, or `getAnalytics` with `topicSearchQuery` | 5% |

---

## Visualization

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Sectors chart | Horizontal bar from full-period `searchSectors` | 12% |
| No false overtime chart | Does **not** add a hits-over-time line chart from quarterly `searchSectors` (explicitly out of scope) | 4% |
| Related companies table | ≤20 rows; columns **Company Name**, **Symbol** (`ticker`), **sentimentScore** (`sentiment`), **Hits** (`hitsCount` or `score`) | 4% |
| Top documents table | Built from `getCompanyDocuments` batch, deduped, 15–25 rows | 4% |
| Inline JS | Chart data as JS constants; Chart.js loaded once | 2% |

---

## Narrative — Themes & Conclusion

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Executive Summary | Macro-style, multi-paragraph; **no fabricated statistics** | 4% |
| Themes structure | 3–6 themes, each with Insight, verbatim Relevant Evidence, Market Implications | 5% |
| Quote grounding | Theme evidence quotes are verbatim and attributed; no invented quotes | 4% |
| Conclusion | Synthesis, horizon takeaways, monitoring indicators, portfolio framing — conditional and evidence-grounded | 3% |

---

## Quotes

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Search agent usage | Uses `pronto-search-summarizer` per SKILL.md Step 3 | 3% |
| Diverse perspectives | Broad commentary, analyst Q&A, and cross-sector coverage when data allows — **not** forced bullish/bearish framing on the topic | 2% |
| Attribution | Speaker, role, company, date, link/id as available | 2% |

---

## Output

| Criterion | Description | Weight |
|-----------|-------------|--------|
| Environment detection | Inline HTML vs file per Bash availability | 2% |
| HTML format | `<style>` + content + scripts; no full HTML document wrapper | 2% |
| Terminology | Uses **Hits** not “Mentions” in UI copy | 1% |
| Value coloring | Green/red rules for signed metrics per SKILL | 1% |

---

## Total: 100%

**Passing score:** 80%
