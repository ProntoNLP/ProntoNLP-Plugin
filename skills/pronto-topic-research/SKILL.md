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

Prior to engaging the broker agent, you must execute the following data collection tools in parallel. Ensure you pass the `topicSearchQuery` and any corresponding date filters (like `sinceDay` and `untilDay`) to each tool:

1. `getTrendOvertime` (to gather topic trends over time)
2. `getTrendRelatedSectors` (to gather related sectors)
3. `getTrendWordsByCompany` (to gather related companies)
4. `getTrendWordsByDocument` (to gather related documents)
5. `getTrendNetwork` (to gather related words)

Keep these results in your context so they are naturally available for the next step.

---

## Step 3: Data Collection — Broker Agent

Delegate to **ONE** `pronto-broker.md` agent (use `subagent_type: prontonlp-plugin:pronto-broker.md`):

```
"org: [org from getOrganization]
topicSearchQuery: <topicSearchQuery>
sinceDay: <range start>
untilDay: <range end>

Please generate a broker research report on this topic."
```

→ The `pronto-broker.md` agent will automatically gather all needed evidence and will output a fully formatted, beautiful thematic research report. You do not need to instruct it on the structure, it already knows exactly what to do.

---

## Step 4: Compile the HTML Report

Generate an HTML file based on the **complete output** from the `pronto-broker` agent. Convert the markdown report into HTML.

### HTML rules (apply to ALL environments)

- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks (if any).
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- **Citation link format:** Ensure the citation links from the broker report are converted into HTML `<a>` tags:
  ```html
  <a href="https://{org}.prontonlp.com/#/ref/<FULL_ID>" class="co-link">{ID}</a>
  ```

Write the full HTML to `[topic]-topic-research.html` using your tool to write files.

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

## Best Practices

1. **Write to HTML file.** Do not print the entire HTML inline.
2. **Never fabricate data.** Rely solely on the output from `pronto-broker`.
3. **Use "Hits"** everywhere rather than "Mentions" for occurrences of the topic if you add any extra text manually.
