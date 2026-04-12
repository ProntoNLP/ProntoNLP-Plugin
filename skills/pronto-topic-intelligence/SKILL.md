---
name: pronto-topic-intelligence
description: "Performs topic-based research across the entire market — analyzing how a specific keyword, theme, or concept is discussed across sectors, companies, and time periods. Use when the user asks about a topic's market-wide presence, sentiment, or comparative analysis. Triggers on phrases like: 'how is [topic] mentioned across sectors', 'which companies mention [topic] the most', 'how is [topic] perceived across the market', 'positive vs negative mentions of [topic]', 'how often do companies talk about [topic]', 'what sectors discuss [topic] the most', 'sentiment breakdown for [topic]', '[topic] in earnings calls', 'topic intelligence on [keyword]'. Do not use for a single named company — use the company intelligence skill. Do not use for a sector overview — use the sector intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.0.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Topic Intelligence Report Generator

> ⚠️ **OUTPUT RULE — READ FIRST:**
> Before rendering, detect the environment: if the `Bash` tool is available in this session, write the report as an **HTML file**. If `Bash` is NOT available, output as **inline HTML** rendered directly in the chat. Same HTML format either way — the only difference is inline vs written to file.

> ⛔ **TOOL RESTRICTION:** Never call `getMindMap`, `deepResearch`, or any interactive visualization tool from this skill. These are user-triggered only. Only call the tools explicitly listed in the batches below.

> 🔑 **ORG RULE:** Call `getOrganization` once in Step 1. Save the returned `org` value and use it everywhere company or quote links appear: `https://{org}.prontonlp.com/#/ref/...`

---

## Step 0: Parse the Topic

Extract the core topic/keyword from the user's request. Normalize it:
- Strip articles (a, an, the)
- Lowercase for matching
- Preserve the original phrasing for display

Store as `topic` for all subsequent calls.

---

## Step 1: Data Collection — All Batches in Parallel

Fire all applicable calls simultaneously. Use the topic/keyword in all calls.

### 1a. getOrganization — Always call first (in parallel with the rest)

```
getOrganization    → save org (used for all citation and company links)
```

### 1b. getAnalytics — Topic Sentiment Across Market

```
getAnalytics(
  topicSearchQuery: "<topic>",
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "eventTypes", "aspects", "patternSentiment"],
  sinceDay: <1Y ago>,
  untilDay: <today>
)
```
→ Save: overall sentiment score, investment score, top event types, top aspects

### 1c. searchSectors — Topic Distribution by Sector

```
searchSectors(
  searchQueries: ["<topic>"],
  documentTypes: ["Earnings Calls"],
  sinceDay: <1Y ago>,
  untilDay: <today>
)
```
→ Save: sectors ranked by topic frequency, sentiment per sector

### 1e. searchTopCompanies — Companies Discussing the Topic

```
searchTopCompanies(
  topicSearchQuery: "<topic>",
  documentTypes: ["Earnings Calls"],
  limit: 30,
  sinceDay: <1Y ago>,
  untilDay: <today>
)
```
→ Save: top companies by topic mention count, sentiment per company

### 1f. getAnalytics (quarterly) — Sentiment Over Time

```
getAnalytics(
  topicSearchQuery: "<topic>",
  documentTypes: ["Earnings Calls"],
  analyticsType: ["scores", "patternSentiment"],
  sinceDay: <1Y ago>,
  untilDay: <today>
)
```
→ Save: quarterly sentiment trend for Chart 1 (line chart over time)

---

## Step 2: Keyword Heatmap (REQUIRED - call as separate tool)

After completing data collection, call the heatmap as a **separate tool call** (NOT embedded in the report):

```
getTermHeatmap(
  topicSearchQuery: "<topic>",
  documentTypes: ["Earnings Calls"],
  sinceDay: <1Y ago>,
  untilDay: <today>
)
```

This displays the interactive heatmap visualization **BEFORE** the HTML report. The heatmap is a standalone visualization, not part of the report HTML.

Reference the heatmap results in Section 2 of your report text, but do not embed it in the HTML.

---

## Step 3: Quote Collection — Use Search Agent

Delegate to ONE `pronto-search-summarizer` (subagent_type: `prontonlp-plugin:pronto-search-summarizer`):

```
"org: [org from getOrganization]

Find quotes about <topic> across the market. Run these searches:
1. Most bullish/positive quotes about <topic> — sentiment: positive, size: 5
2. Most bearish/negative quotes about <topic> — sentiment: negative, size: 5
3. Notable analyst questions about <topic> — sections: EarningsCalls_Question, size: 5
4. Quotes from different sectors about <topic> — documentTypes: Earnings Calls, size: 5
Return all results with speaker name, role, company, and date."
```

→ Save top quotes with attribution.

---

## Step 4: Compile the Report

### Output Format — Environment-Aware

**Detect the environment before rendering:**

| Environment | Detection | Output format |
|-------------|-----------|---------------|
| **claude.ai** | `Bash` tool is NOT available | Inline HTML fragment rendered in chat |
| **Claude Cowork** | `Bash` tool IS available | HTML written to file |

### HTML rules (apply to BOTH environments — only delivery differs):
- No `<!DOCTYPE html>`, no `<html>`, `<head>`, or `<body>` tags — output only a `<style>` block followed by HTML content and `<script>` blocks
- Use Claude's native CSS design tokens: `var(--color-text-primary)`, `var(--color-text-secondary)`, `var(--color-text-tertiary)`, `var(--color-background-primary)`, `var(--color-background-secondary)`, `var(--color-border-tertiary)`, `var(--font-sans)`, `var(--border-radius-lg)`, `var(--border-radius-md)`
- For green/red signal colors, hardcode: green `#1D9E75`, red `#D85A30`
- **Value coloring rule — applies to every numeric value, score, and % change:**
  - Value **> 0** (positive sentiment, positive change): text color `#1D9E75` (green)
  - Value **< 0** (negative sentiment, negative change): text color `#D85A30` (red)
  - Value **= 0**: no color — use default inherited text color
- **Score display rule:** Investment scores and sentiment scores are raw API values in the **0.0–1.0 range**. Display them exactly as returned — never multiply, never append "/10". `sentimentScoreChange` and `investmentScoreChange` are percentage changes — always display with a `%` suffix (e.g. `+4.2%`, `-1.8%`). Any negative number **must** render in red `#D85A30`.
- **Company link format:** Use `org` from `getOrganization` to build all company links:
  ```html
  <a href="https://{org}.prontonlp.com/#/ref/$COMPANY{id}" class="co-link">{name}</a>
  ```
  where `{id}` is the numeric company `id` field from the tool response.
- Load Chart.js once: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
- All chart data as inline JS constants — never reference external files

### claude.ai delivery:
- Output the HTML fragment directly inline in the chat response

### Claude Cowork delivery:
- Write the full HTML to a file named `[topic]-topic-report.html` (e.g. `inflation-topic-report.html`) using the `Write` tool
- After writing, tell the user the filename and open it

---

## Report Structure

### Title
```
# [Topic] — Topic Intelligence Report
Generated: [Date] | Period: Past Year | Mentions: [N]
```

---

### Section 1: Executive Summary

2–3 paragraphs explicitly stating:
- Overall topic sentiment (positive/negative/neutral) with score
- Which sectors are most engaged with the topic
- Top companies driving the conversation
- Trend direction (RISING/FALLING mentions)
- Key insight: what the data reveals about market perception

---

### Section 2: Keyword Heatmap (only if user explicitly requested)

**This section appears ONLY when the user explicitly requested the heatmap visualization.**

Display the `getTermHeatmap` visualization here. Include a brief interpretation of the heatmap patterns.

If the user did NOT request the heatmap: Skip this section entirely — do not include placeholders.

---

### Section 3: Sentiment Over Time (Chart 1)

**Line chart** showing topic sentiment trend over the past year (quarterly data points from `getAnalytics`).

Chart.js configuration:
```javascript
{
  type: 'line',
  data: {
    labels: ['Q1', 'Q2', 'Q3', 'Q4'],
    datasets: [{
      label: 'Topic Sentiment',
      data: [score1, score2, score3, score4],
      borderColor: '#3B82F6',
      tension: 0.3
    }]
  }
}
```

State: "Topic sentiment is [RISING/FALLING/STABLE] — from X.XX to X.XX over the past year"

---

### Section 4: Sector Distribution

**Horizontal bar chart** showing topic mention intensity by sector (from `searchSectors`).

Chart.js configuration:
```javascript
{
  type: 'bar',
  data: {
    labels: [sector names],
    datasets: [{
      label: 'Topic Mentions',
      data: [count per sector],
      backgroundColor: '#3B82F6'
    }]
  },
  options: { indexAxis: 'y' }
}
```

**Top sectors table:**

| Sector | Mentions | Sentiment | Dominant Aspect |
|--------|----------|-----------|-----------------|
| [Sector] | X | +X.XX / -X.XX | [aspect] |

---

### Section 5: Top Companies

**Data table** with company details (from `searchTopCompanies`):

| Company | Ticker | Country | Sector | Hits | Sentiment |
|---------|--------|---------|--------|------|-----------|
| [Name] | [Ticker] | [Country] | [Sector] | X | +X.XX / -X.XX |

Highlight the top 3 companies by mention count and the top 3 by positive sentiment.

---

### Section 6: Event Sentiment Breakdown (Chart 2)

**Pie/Doughnut chart** showing sentiment distribution (positive vs negative mentions).

```javascript
{
  type: 'doughnut',
  data: {
    labels: ['Positive', 'Negative', 'Neutral'],
    datasets: [{
      data: [positiveCount, negativeCount, neutralCount],
      backgroundColor: ['#1D9E75', '#D85A30', '#9CA3AF']
    }]
  }
}
```

---

### Section 7: Key Quotes

From the search agent — attributed quotes with source links:

**Bullish quotes about [topic]:**
- "[Quote]" — [Speaker], [Role], [Company] ([Date])
  [Source link]

**Bearish quotes about [topic]:**
- "[Quote]" — [Speaker], [Role], [Company] ([Date])
  [Source link]

**Analyst questions about [topic]:**
- "[Quote]" — [Speaker], [Role], [Company] ([Date])
  [Source link]

---

### Section 8: Top Aspects

From `getAnalytics` — what specific aspects of the topic are discussed:

| Aspect | Frequency | Sentiment | Companies |
|--------|-----------|-----------|-----------|
| [aspect] | X hits | +X.XX | [top company] |

---

## Charts Summary

| Chart | Type | Data Source | Section | Notes |
|-------|------|------------|---------|-------|
| Heatmap | Heatmap | getTermHeatmap | Section 2 | **OPTIONAL** — only when user explicitly requests |
| Chart 1 | Line | Quarterly sentiment over time | Section 3 | |
| Chart 2 | Doughnut | Positive/Negative/Neutral breakdown | Section 6 | |

Place charts within their corresponding section. All data as inline JS constants.

---

## Date Handling

```
Past year (default): sinceDay = 1 year ago,   untilDay = today
Past quarter:        sinceDay = 90 days ago,  untilDay = today
Past 6 months:       sinceDay = 6 months ago, untilDay = today
YTD:                 sinceDay = Jan 1,         untilDay = today
```

Default to **past year** for topic intelligence. Topic analysis benefits from longer time horizons to see trends.

---

## Error Handling

| Problem | What to do |
|---------|-----------|
| Topic not found in documents | Try synonyms or broader terms; note in report |
| No sentiment trend data | Show snapshot only; note insufficient data for trend |
| `searchSectors` returns empty | Try `searchTopCompanies` instead |
| No quotes from search agent | Note "No matching quotes found" — never fabricate |
| Very few companies (<5) | Note limited dataset; proceed with available data |

---

## Best Practices

1. **Detect environment first** — inline HTML on claude.ai, write HTML file in Claude Cowork
2. **Trigger keyword heatmap ONLY when user explicitly requests** — do NOT call getTermHeatmap automatically; it requires user request (e.g., "show me the heatmap", "include heatmap")
3. **Use search agent** for quotes — include diverse perspectives (bullish/bearish/analyst)
4. **Present both sides** — always show positive AND negative mentions of the topic
5. **Cite all quotes** with speaker name, role, company, and source link
6. **Never fabricate data** — if a tool returns nothing, say so honestly
7. **Use the topic consistently** in all calls — variations may yield different results

---

## Supporting Files

| File | Purpose |
|------|---------|
| `reference/tool-cheatsheet.md` | Complete tool parameter reference for topic analysis |
| `examples/inflation-topic.md` | Full worked example: inflation topic intelligence |
| `evaluations/criteria.md` | Evaluation rubric — triggering, data collection, visualization, quotes |
