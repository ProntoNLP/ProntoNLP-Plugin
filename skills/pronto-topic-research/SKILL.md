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

Prior to engaging the broker agent, you must execute exactly the following data collection tools in parallel. Use EXACTLY these tool names:
> ⚠️ **CRITICAL TOOL RULE**: Do **NOT** use `searchSectors`, `searchTopCompanies`, `search`, or `getTrends`. You must use ONLY the specific tools listed below.

Ensure you pass the `topicSearchQuery` and the `documentTypes: ["Earnings Calls"]` filter to **ALL** 5 tools natively. For the date filters (`sinceDay` and `untilDay`), apply them as follows:

1. `getTrendOvertime` (Run this exactly ONCE. Modify its `sinceDay` to be precisely 1 year *before* the chosen `sinceDay`. Example: if `sinceDay` is 90 days ago (Jan 12 2026 for instance), stretch it to Jan 12 2025. This ensures the output captures the prior year + the current 90 day window simultaneously).
2. `getTrendRelatedSectors`
3. `getTrendWordsByCompany`
4. `getTrendWordsByDocument`
5. `getTrendNetwork`

Keep these results in your context so they are naturally available for the next step.

---

## Step 3: Data Collection — Broker Agent

Delegate to **ONE** `pronto-broker.md` agent (use `subagent_type: prontonlp-plugin:pronto-broker.md`). 

> ⚠️ **CRITICAL AGENT PROMPT RULE**: You MUST NOT include any instructions, explanations, rules, or narrative text (e.g., "Generate an Executive Summary" or "You are a broker analyst") in the agent prompt. The prompt you pass to the agent must strictly and EXCLUSIVELY be the 5 raw parameters. Zero extra words.

Your exact prompt string to the agent must look like this and nothing else:
```
org: [org from getOrganization]
topicSearchQuery: <topicSearchQuery>
sinceDay: <range start>
untilDay: <range end>
documentTypes: ["Earnings Calls"]
```
untilDay: <range end>
documentTypes: ["Earnings Calls"]"
```

→ The `pronto-broker.md` agent will automatically gather all needed evidence and will output a fully formatted, beautiful thematic research report. You do not need to instruct it on the structure, it already knows exactly what to do.

---

## Step 4: Compile the HTML Report

Generate the final HTML file by merging the **complete narrative output** from the `pronto-broker` agent with the **data gathered in Step 2**.

### Final Report Structure
Your output MUST follow this exact structure:

1. **TITLE**:
   ```html
   <h1 class="title">Topic Research: [Topic]</h1>
   <p class="subtitle">Generated: [Date] | Period: [sinceDay] to [untilDay] | Total Hits: [Total hits from getTrendOvertime]</p>
   ```
2. **Executive Summary**: Embed the Executive Summary from the broker agent.
3. **GRAPHS**:
   - Add `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`.
   - **Hits Overtime** (from `getTrendOvertime`): Create a `<canvas>` element. Use Chart.js to render a **Line Chart**. X-axis = Quarters/Dates. Y-axis = Hits.
     - **Colors:** Total = Blue (`#2563eb`), Positive = Green (`#1D9E75`), Negative = Red (`#D85A30`).
     - **Prior Trend vs Current:** Remember that `getTrendOvertime` returned a continuous array covering both the prior year and current window. Use JavaScript `slice` methods natively in the Chart.js dataset config to partition the prior year data from the current data. Map the Prior Year trajectory horizontally onto the same X-axis as the current span, rendering it as a dotted overlapping line (`borderDash: [5, 5]`), contrasting with the solid current line.
     - **Tooltip:** Show Total Hits, Positive Hits, and Negative Hits (do not show neutral).
     - **Must be titled exactly "Hits Overtime" without any mention of "Mentions".**
   - **Related Sectors** (from `getTrendRelatedSectors`): Create a `<canvas>` element. Use Chart.js to render a **Bar Chart**. The chart title must be "Related Sectors".
4. **TABLES**:
   - **Related Companies** (from `getTrendWordsByCompany`): Write an `<h2>Related Companies</h2>`. Then HTML `<table>`. Columns: *Company Name, Symbol (Ticker), Score, Sentiment (Positive/Negative/Neutral counts), Hits (total)*.
   - **Related Documents** (from `getTrendWordsByDocument`): Write an `<h2>Related Documents</h2>`. Then HTML `<table>`. Columns: *Document Name, Date, Sentiment (Positive/Negative/Neutral counts), Hits*.
   - **Related Keywords** (from `getTrendNetwork`): Write an `<h2>Related Keywords</h2>`. Then HTML `<table>`. Columns: *Name of keyword, Hits, Score, Explanation*. Write a 1-sentence explanation for the keyword if omitted.
5. **THEMES**: Embed the Themes section from the broker agent. **ALWAYS** convert the citation links into anchor tags that open in a new tab: `<a href="..." target="_blank" class="co-link">{ID}</a>`.
6. **CONCLUSION**: Embed the Conclusion section from the broker agent.

### HTML Formatting Rules

- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks.
- **Strict Light Mode CSS Styles:** Inject this exact CSS block directly into your response to make the report exceptionally pretty in light mode:
  ```css
  <style>
    body { font-family: -apple-system, sans-serif; background: #ffffff; color: #1e293b; padding: 20px; max-width: 1200px; margin: 0 auto; }
    .title { color: #0f172a; border-bottom: 2px solid #1D9E75; padding-bottom: 8px; margin-bottom: 4px; }
    .subtitle { color: #64748b; font-size: 14px; margin-top: 0; margin-bottom: 24px; }
    h2, h3 { color: #1D9E75; margin-top: 24px; font-weight: 600; }
    .graphs-container, .tables-container { margin-bottom: 32px; }
    canvas { width: 100% !important; max-height: 350px; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; margin-bottom: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    table { width: 100%; border-collapse: separate; border-spacing: 0; background: #ffffff; border-radius: 8px; overflow: hidden; border: 1px solid #e2e8f0; margin-bottom: 24px; text-align: left; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    th { background: #f8fafc; color: #475569; padding: 12px; border-bottom: 1px solid #e2e8f0; font-weight: 600; }
    td { padding: 12px; border-bottom: 1px solid #e2e8f0; color: #1e293b; }
    .co-link { color: #2563eb; text-decoration: none; font-weight: 500; }
    .co-link:hover { text-decoration: underline; }
  </style>
  ```
- **Chart.js Light Mode Defaults:** In your `<script>`, ensure default colors are light mode friendly (`Chart.defaults.color = '#475569'; Chart.defaults.borderColor = '#e2e8f0';`).

Write the full HTML to `[topic]-topic-research.html` using your tool to write files.

---

## Date Handling

```
Default:             sinceDay = 90 days ago,  untilDay = today
Past year:           sinceDay = 1 year ago,   untilDay = today
Past 6 months:       sinceDay = 6 months ago, untilDay = today
YTD:                 sinceDay = Jan 1,         untilDay = today
```

Default to **past 90 days**.

---

## Best Practices

1. **Write to HTML file.** Do not print the entire HTML inline.
2. **Never fabricate data.** Rely solely on the output from `pronto-broker`.
3. **Use "Hits"** everywhere rather than "Mentions" for occurrences of the topic if you add any extra text manually.
