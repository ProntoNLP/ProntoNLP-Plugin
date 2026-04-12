---
name: pronto-topic-intelligence
description: "Performs topic-based research across the entire market — how a keyword or theme shows up across sectors, companies, and documents. Produces an HTML report with a related-sectors chart, company and document tables, key quotes, synthesized Themes with evidence, and a forward-looking Conclusion. Use when the user wants topic intelligence, macro-style narrative on a theme, or market-wide discussion of a concept. Triggers on phrases like: 'how is [topic] discussed across sectors', 'which companies talk about [topic] the most', 'topic intelligence on [keyword]', 'hits for [topic] in earnings calls', 'themes around [topic]', 'executive summary on [topic]'. Do not use for a single named company — use the company intelligence skill. Do not use for a sector overview — use the sector intelligence skill."
metadata:
  author: ProntoNLP
  version: 2.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Topic Intelligence Report Generator

> ⚠️ **OUTPUT RULE — READ FIRST:**
> Before rendering, detect the environment: if the `Bash` tool is available in this session, write the report as an **HTML file**. If `Bash` is NOT available, output as **inline HTML** rendered directly in the chat. Same HTML format either way — the only difference is inline vs written to file.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `getTermHeatmap`, `deepResearch`, or any interactive visualization tool from this skill. These are user-triggered only. **Do not call `getTermHeatmap` under any circumstance for this skill.** Only call the tools explicitly listed in the steps below.

> 🔑 **ORG RULE:** Call `getOrganization` once in Step 1. Save the returned `org` value and use it everywhere company links appear: `https://{org}.prontonlp.com/#/ref/...`

> 📌 **API REALITY:** MCP `getAnalytics` does **not** accept `topicSearchQuery`. Topic-wide aggregates come from **`searchSectors`** (which uses the analytics backend with your topic). Do **not** call `getAnalytics` with `topicSearchQuery`. Do **not** use `getTopMovers` for topic scoping — it has no `topicSearchQuery` parameter.

---

## Step 0: Parse the Topic

Extract the **subject phrase** the user is asking about (the topic itself — e.g. `war with Iran`, `inflation`, `AI regulation`).

- Store **`topicExact`**: the topic **exactly as the user stated it** — same wording, casing, and punctuation. **Do not** rewrite it as a “positive” or “negative” angle; **do not** assume the topic has a sentiment valence. This string is what you pass to the search subagent (Step 3) and should be the default for `topicSearchQuery` in MCP calls.
- If recall is poor with `topicExact` alone, you may retry tools with a cautious normalization (synonyms, trimmed articles) — but **always** pass **`topicExact`** unchanged to the subagent.

Use **`topicExact`** for report titles and for consistency across `searchSectors`, `searchTopCompanies`, and Step 3.

---

## Step 1: Data Collection — First Parallel Batch

Fire **simultaneously** (same `documentTypes` and date range unless the user specified otherwise):

### 1a. getOrganization

```
getOrganization → save org
```

### 1b. searchSectors — Full period (Related Sectors + totals)

Use **`topicSearchQuery`** (semantic) with **`topicExact`** first, **or** `searchQueries: ["<topicExact>"]` (keyword), not both unless you have a reason.

```
searchSectors(
  topicSearchQuery: "<topicExact>",
  documentTypes: ["Earnings Calls"],
  sinceDay: <range start>,
  untilDay: <range end>
)
```

→ Returns `sectors[]` with `name`, `total` (hits), `totalPositives`, `totalNegatives`, `totalNeutrals`, `score`, etc.

**Compute:**
- **Total hits (meta line):** Sum of `total` across all returned sectors (or state the methodology if partial data).
- **Optional blended sentiment:** Weighted average of sector `score` by sector `total`:  
  `sum(score * total) / sum(total)` over sectors that have both fields — use only when valid; otherwise describe sentiment qualitatively.

### 1c. searchTopCompanies

```
searchTopCompanies(
  topicSearchQuery: "<topicExact>",
  documentTypes: ["Earnings Calls"],
  sinceDay: <same as above>,
  untilDay: <same as above>
)
```

→ **Effective cap: at most 20 companies** are returned by the API regardless of any `limit` parameter. Save `companyId`, `companyName`, **`ticker`** (symbol), **`sentiment`** (display column **sentimentScore**), and semantic **`score`** or keyword **`hitsCount`** for the **Hits** column (whichever the response provides).

---

## Step 2: Top Documents — getCompanyDocuments (parallel)

After `searchTopCompanies` returns, take the **top 10–15 companies** by hits/relevance (fewer if fewer returned).

For **each** company **in parallel**:

```
getCompanyDocuments(
  companyName: "<exact companyName from searchTopCompanies>",
  documentTypes: ["Earnings Calls"],
  excludeFutureDocuments: true
)
```

The API returns documents **newest first**. From each response, keep only the **first 1–2** rows per company before merging (reduces table bloat).

→ Flatten all kept rows. **Dedupe** by `documentID`. Sort by `date` descending. Keep the **top 15–25** rows for the HTML table.

**Table columns:** Company | Title | Date | Document ID (use `documentID` from the tool; users can chain to `search` / other tools — do not invent document URLs).

---

## Step 3: Quote Collection — Search Agent

Delegate to **ONE** `pronto-search-summarizer` (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):

```
"org: [org from getOrganization]

**Topic (exact string — use verbatim in every search; do not rephrase, do not treat as inherently positive or negative):**
<topicExact>

Collect evidence for a market-wide topic report including Themes with verbatim quotes.

The topic is neutral — it is not 'bullish' or 'bearish' as a label. Do **not** use sentiment: positive / sentiment: negative filters scoped to the topic. Use `topicSearchQuery` set to the exact topic string above (preferred) or equivalent per your search tool.

Run these searches (match the report date range if the caller specified one):
1. Broad statements discussing the topic — topicSearchQuery: <topicExact>, documentTypes: ['Earnings Calls'], size: 16
2. Additional coverage with sector diversity — same topicSearchQuery; vary `sectors` across calls or paginate; total size across calls ~16
3. Analyst questions on the topic — topicSearchQuery: <topicExact>, sections: ['EarningsCalls_Question'], size: 12
4. If results are thin, one cautious broader pass (e.g. searchQuery) — only when needed; keep topic anchored to the exact string when possible

Requirements:
- Return **verbatim** quote text (short clauses or 1–2 sentences each).
- Every quote: speaker name, role (if available), company, date, and source link / sentence id if available.
- Cover **at least 5 distinct sectors** across the combined results when the data allows.

Organize output for the report under headings such as **Representative commentary**, **Analyst questions**, and **By sector cluster** — not as 'bullish vs bearish on the topic' unless you are describing the *content* of specific quotes."
```

→ Save quotes with full attribution. **No fabrication** — Themes evidence must come only from these results or from explicit `search` follow-ups you run yourself.

---

## Step 4: Compile the Report

### Output Format — Environment-Aware

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | HTML written to file |

### HTML rules (apply to BOTH environments)

- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- **Value coloring rule — applies to every numeric value, score, and % change:**
  - Value **> 0** (positive sentiment, positive change): text color `#1D9E75` (green)
  - Value **< 0** (negative sentiment, negative change): text color `#D85A30` (red)
  - Value **= 0**: default inherited text color
- **Score display rule:** Show numeric scores **as returned** — never multiply, never append "/10". **`searchTopCompanies` `sentiment` (column sentimentScore)** may be a signed scale (e.g. -1 to 1) or another range per environment — do not rescale. Other sentiment fields may be **0.0–1.0** where documented. Percentage changes from tools use a **`%`** suffix. Any negative number **must** render in red `#D85A30`.
- **Company link format:**
  ```html
  <a href="https://{org}.prontonlp.com/#/ref/$COMPANY{id}" class="co-link">{name}</a>
  ```
  Use numeric `companyId` from `searchTopCompanies` (strip `$COMPANY` prefix if already present in ids — match your environment’s ID format).
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants — never reference external files

### claude.ai delivery

Output the HTML fragment directly inline in the chat response.

### Claude Cowork delivery

Write the full HTML to `[topic]-topic-report.html` using the `Write` tool, then tell the user the filename.

---

## Report Structure (Highlights-style where MCP-supported — no Hits Overtime chart)

### Title / meta

```
# [topicExact] — Topic Intelligence Report
Generated: [Date] | Period: [stated range] | Hits (market total, methodology): [N]
```

Use **Hits**, never “Mentions.” The **N** must match the disclosed rule (e.g. sum of sector `total` over full-period `searchSectors`).

---

### Section 1: Executive Summary

Write **2–4 paragraphs** in a **macro / market-narrative** style (see quality bar: cross-sector and geography, near-term vs medium-term dynamics, uncertainty and policy or operational drivers). **Do not invent statistics.** Only use numbers that come from tools (totals, sector rankings, company counts).

You may describe sentiment **qualitatively** or use the weighted sector score **if** you computed it from real sector data.

---

### Section 2: Charts and tables (Chart.js + HTML tables)

Present in this **order**:

1. **Chart — Related sectors**  
   - **Horizontal bar chart** — top sectors by `total` from full-period `searchSectors` (truncate to top 10–15 if crowded).  
   - Dataset label: `Hits` or `Topic hits by sector`.

2. **Table — Related companies** (`searchTopCompanies`)  
   - Columns **in this order:** **Company Name** (linked) | **Symbol** (`ticker`; show `—` if empty) | **sentimentScore** (from API field `sentiment`, formatted as returned — apply green/red coloring per value rules) | **Hits** (`hitsCount` for keyword flow, or `score` for semantic / `topicSearchQuery` flow — keep column title **Hits** in both cases).  
   - Do **not** promise more than **20** rows.

3. **Table — Top documents** (`getCompanyDocuments` pipeline)  
   - Columns: **Company** | **Title** | **Date** | **Document ID**

**Do not** add a hits-over-time or overtime line chart — MCP data for this skill does not support an accurate time series comparable to the in-app Highlights widget.

**Example Chart.js — horizontal sectors:**

```javascript
{
  type: 'bar',
  data: {
    labels: [sector names],
    datasets: [{
      label: 'Hits',
      data: [totals...],
      backgroundColor: '#3B82F6'
    }]
  },
  options: { indexAxis: 'y' }
}
```

**Optional small table after the sectors chart** — sectors with Hits (`total`), Sentiment (`score`), and optional positive/negative/neutral counts from `totalPositives` / `totalNegatives` / `totalNeutrals` when present. **No “Dominant Aspect” column** (aspects removed).

---

### Section 3: Key Quotes

From the search agent — group as **Representative commentary**, **Analyst questions**, and **Other angles** (or by sector), matching how the subagent organized results. Full attribution and links/ids as provided. **Do not** force a “bullish vs bearish on the topic” layout unless the quotes clearly support that framing.

---

### Section 4: Themes

**3–6 themes.** Each theme **must** follow this structure:

- **Theme N: [Short title]**
- **Insight:** One short paragraph — synthesis only, no fake numbers.
- **Relevant Evidence:**  
  - Bullet list of **verbatim** quotes from Step 3 (or your own `search` results).  
  - Each line ends with **(Company Name)**.  
  - **Never** invent or paraphrase-as-if-verbatim.
- **Market Implications:** One short paragraph — clearly framed as **interpretation** grounded in the evidence above.

Themes should **cluster** the evidence (e.g. by mechanism, sector angle, or risk channel), not repeat the Executive Summary verbatim.

---

### Section 5: Conclusion

- Opening **synthesis** paragraph (evidence-grounded).
- **Key takeaways for market direction** — separate **Near-term**, **Medium-term**, **Long-term** subsections (bullet lists are fine). Use **conditional** language; no fabricated KPIs or tickers.
- **Critical monitoring indicators** — bullet list of **observable** items tied to the topic (macro series, policy cues, corporate guidance themes, etc.).
- **Portfolio positioning** — **Overweight / Underweight / Neutral** bullets as **hypotheses** derived from the report’s evidence, not personalized investment advice.

---

## Charts Summary

| Chart / table | Type | Data source |
|---------------|------|-------------|
| Related sectors | Horizontal bar | Full-period `searchSectors` |
| Related companies | Table | `searchTopCompanies` (≤20 rows) |
| Top documents | Table | Batched `getCompanyDocuments` |

---

## Date Handling

```
Past year (default): sinceDay = 1 year ago,   untilDay = today
Past quarter:        sinceDay = 90 days ago,  untilDay = today
Past 6 months:       sinceDay = 6 months ago, untilDay = today
YTD:                 sinceDay = Jan 1,         untilDay = today
```

Default to **past year**.

---

## Error Handling

| Problem | What to do |
|---------|------------|
| Topic sparse or empty | Try synonyms or broader terms; state limitations |
| `searchSectors` empty | Rely on `searchTopCompanies` and quotes; note limited sector view |
| No quotes from search agent | State explicitly; shrink Themes or skip Themes with a warning — **never fabricate** |
| `getCompanyDocuments` fails for some names | Skip those companies; continue with available documents |
| Fewer than 5 companies | Note small sample; still deliver what the data supports |

---

## Best Practices

1. **Detect environment first** — inline HTML vs file.
2. **Never call `getTermHeatmap`** from this skill.
3. **Hits terminology** everywhere in UI copy (charts, tables, meta).
4. **Themes and Conclusion** must remain **grounded** in tool outputs and attributed quotes.
5. **Never fabricate data** — if a tool returns nothing, say so honestly.
6. Use **`topicExact`** for the subagent and prefer it for `topicSearchQuery` across tools.

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Tool parameter reference for topic analysis |
| `examples/inflation-topic.md` | Worked example |
| `evaluations/criteria.md` | Evaluation rubric |
