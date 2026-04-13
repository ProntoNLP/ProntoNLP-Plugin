---
name: pronto-topic-research
description: "Performs qualitative topic-based research across the market — how a keyword or theme shows up across documents. Produces an HTML report with an Executive Summary, Themes with verbatim quotes as evidence, and a Conclusion. Use when the user wants topic intelligence, macro-style narrative on a theme, or market-wide discussion of a concept. Triggers on phrases like: 'how is [topic] discussed', 'top themes around [topic]', 'executive summary on [topic]'. Do not use for a single named company — use the company intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Topic Research Report Generator

> ⚠️ **OUTPUT RULE — READ FIRST:**
> You must write the report as an **HTML file** using your file writing tool. Do not output the HTML inline in the chat. Write the full HTML to `[topic]-topic-report.html`, then tell the user the file is ready.

> 🔑 **ORG RULE:** Call `getOrganization` once in Step 1. Save the returned `org` value and use it everywhere links appear: `https://{org}.prontonlp.com/#/ref/...`

---

## Step 0: Parse the Topic

Extract the **subject phrase** the user is asking about (the topic itself).

- Formulate a **`topicSearchQuery`**: the core concept the user is researching (e.g. `war with Iran`, `inflation`, `AI regulation`). You may rephrase or clean it up for better searchability rather than using their exact wording.
- Use **`topicSearchQuery`** for report titles and for the subagent search queries.

---

## Step 1: Initial Setup

Call this before data collection to get the organization for citation links:
```
getOrganization → save org
```

---

## Step 2: Parallel Data Collection

Prior to engaging the themes broker, execute all data collection in one parallel batch: the 5 trend tools + the search agent.
> ⚠️ **CRITICAL TOOL/AGENT RULE**: Use ONLY the specific tools/agent listed below for this step.

1. `getTrendOvertime`
2. `getTrendRelatedSectors`
3. `getTrendWordsByCompany`
4. `getTrendWordsByDocument`
5. `getTrendNetwork`
6. `pronto-search-summarizer` (as subagent: `prontonlp-plugin:pronto-search-summarizer`)

Ensure you pass the following params natively to **ALL** 5 tools: `topicSearchQuery`, `documentTypes: ["Earnings Calls"]`, `dateRange: { gte: <sinceDay>, lte: <untilDay> }`, and `corpus: ["S&P Transcripts"]`.
For `getTrendOvertime`, always pass `timeframeInterval: "quarter"`.

Date default rules are strict and must always be passed explicitly:
- For `getTrendOvertime`: default `dateRange.gte` = 15 months ago, `dateRange.lte` = today.
- For all other tools: default `dateRange.gte` = 90 days ago, `dateRange.lte` = today.
- If the user explicitly gives a timeframe, honor it and still pass `dateRange` (both `gte` and `lte`) to every tool.

For the `pronto-search-summarizer` call in this same parallel batch, use:
- `description: "Search best sentences from parameters"`
- Prompt:
  ```
  org: [org from getOrganization]
  topicSearchQuery: <topicSearchQuery>
  sinceDay: <range start>
  untilDay: <range end>
  documentTypes: ["Earnings Calls"]
  instruction: Return ONLY the best actual sentences (verbatim evidence), not raw JSON and not extra metadata blocks. Retrieve as many relevant/high-quality sentences as possible for this topic, prioritize the most important and most interesting ones, and exclude weak/off-topic/bad sentences. Output must be plain text, one sentence per line, no bullets/no numbering/no headers, and each line must end with exactly one citation link in this format: [Link: https://{org}.prontonlp.com/#/ref/<FULL_ID>].
  ```

Save the agent output as `searchResults`, and write it to `[topic]-search-results.txt` so the text results are available for viewing.

Do not artificially offset the dates beyond these rules. Keep all Step 2 outputs in context for synthesis.

---

## Step 3: Themes Broker Agent
Delegate to **ONE** `pronto-themes-broker` agent next (use `subagent_type: prontonlp-plugin:pronto-themes-broker`).

Use this exact agent-call metadata:
- `description: "Themes broker synthesis from search results"`

Prompt format (`searchResults`-first input; no topic request):
```
org: [org from getOrganization]
sinceDay: <range start>
untilDay: <range end>
documentTypes: ["Earnings Calls"]
corpus: ["S&P Transcripts"]
searchResults:
<paste the full output from Step 2 search agent>
```

→ The `pronto-themes-broker` agent must return only a **themes broker summary** from `searchResults` (e.g., Executive Summary, Themes, Conclusion content). It must not invoke any other skill/agent/tool.

---

## Step 4: Compile the HTML Report

Generate the final HTML file by merging the **themes broker summary output** from Step 3 with the **data gathered in Step 2**.

### Final Report Structure
Your output MUST follow this exact structure:

1. **TITLE**:
   ```html
   <h1 class="title">Topic Research: [Topic]</h1>
   <p class="subtitle">Generated: [Date] | Period: [Period string, e.g. "Last 90 Days"]</p>
   ```
   *Note: Extract the period name from the user's prompt (or use the default).
2. **Executive Summary**: Embed the Executive Summary from the broker agent.
3. **GRAPHS**:
   - Add `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`.
   - **Hits Overtime** (from `getTrendOvertime`): Create a `<canvas>` element. Use Chart.js to render a **Line Chart**. X-axis = Quarters/Dates. Y-axis = Hits.
     - **Colors:** Total = Blue (`#338FEB`), Positive = Green (`#6AA64A`), Negative = Red (`#ED4545`).
     - **Tooltip:** Show Total Hits, Positive Hits, and Negative Hits (do not show neutral).
     - **Constraint:** Must be titled exactly "Hits Overtime". Ensure the word "Mentions" and the word "Trends" NEVER appear in this report anywhere.
   - **Related Sectors** (from `getTrendRelatedSectors`): Create a `<canvas>` element. Use Chart.js to render a **Bar Chart**. The chart title must be "Related Sectors".
4. **TABLES**:
   - **Related Companies** (from `getTrendWordsByCompany`): Write an `<h2>Related Companies</h2>`. Then HTML `<table>`. Columns: *Company Name, Symbol (Ticker), Score, Sentiment (Positive/Negative/Neutral counts), Hits (total)*.
   - **Related Documents** (from `getTrendWordsByDocument`): Write an `<h2>Related Documents</h2>`. Then HTML `<table>`. Columns: *Document Name, Date, Sentiment (Positive/Negative/Neutral counts), Hits*.
   - **Related Keywords** (from `getTrendNetwork`): Write an `<h2>Related Keywords</h2>`. Then HTML `<table>`. Columns: *Name of keyword, Hits, Score, Explanation*. Write a 1-sentence explanation for the keyword if omitted.
5. **THEMES**: Embed the Themes section from the broker agent. **ALWAYS** convert the citation links into anchor tags that open in a new tab: `<a href="..." target="_blank" class="co-link">{ID}</a>`.
6. **CONCLUSION**: Embed the Conclusion section from the broker agent.

### HTML Formatting Rules

- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks.
- Use a clean section-first layout (similar philosophy to company-intelligence):
  - Title block
  - Executive Summary section
  - Charts section
  - Tables section
  - Themes section
  - Conclusion section
- Keep styling modern and readable in light mode with subtle cards, spacing, and clear typography. Do not over-constrain with rigid pixel-perfect CSS; prioritize a polished, professional report layout.
- Use semantic wrappers (`section`, `header`, `article`) so the structure remains maintainable.
- **Chart.js Light Mode Defaults:** In your `<script>`, ensure default colors are light mode friendly (`Chart.defaults.color = '#475569'; Chart.defaults.borderColor = '#e2e8f0';`).

Write the full HTML to `[topic]-topic-research.html` using your tool to write files.

---

## Date Handling

```
Past 90 days:        sinceDay = 90 days ago,   untilDay = today
Past year:           sinceDay = 1 year ago,    untilDay = today
Past 6 months:       sinceDay = 6 months ago,  untilDay = today
YTD:                 sinceDay = Jan 1,         untilDay = today
```

Default to **Past 90 days** for all requests, EXCEPT for `getTrendOvertime` where `sinceDay` defaults to **15 months** ago.

Always pass `dateRange` (both `gte` and `lte`) on every request, even when using defaults. Always set `corpus: ["S&P Transcripts"]` for every tool request natively.

---

## Best Practices

1. **Write to HTML file.** Do not print the entire HTML inline.
2. **Never fabricate data.** Rely solely on the output from `pronto-themes-broker`.
3. **Use "Hits"** everywhere rather than "Mentions" for occurrences of the topic if you add any extra text manually.
