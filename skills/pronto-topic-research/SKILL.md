---
name: pronto-topic-research
description: "Performs qualitative topic-based research across the market — how a keyword or theme shows up across documents. Produces an HTML report with an Executive Summary, Themes with verbatim quotes as evidence, and a Conclusion. Use when the user wants topic intelligence, macro-style narrative on a theme, or market-wide discussion of a concept. Triggers on phrases like: 'how is [topic] discussed', 'top themes around [topic]', 'executive summary on [topic]'. Do not use for a single named company — use the company intelligence skill."
metadata:
  author: ProntoNLP
  version: 1.1.0
  mcp-server: prontonlp-mcp-server
  category: finance
---

# Topic Research Report Generator

Produces a topic-focused research report. Centerpiece: **themes broker synthesis** of verbatim evidence across the market, layered with hits-overtime, related sectors, companies, documents, and keywords.

Data gathering and themes synthesis live here; final output is a regular standalone HTML report delegated to the `pronto-html-renderer` agent. This skill is not a live artifact.

> ⛔ **TOOL RESTRICTION:** Never call `showDocumentMindMap` or `deepResearch`. These are user-triggered only.

---

## Step 0: Parse the Topic

Extract the **subject phrase** the user is researching. Formulate a clean **`topicSearchQuery`** (e.g. `war with Iran`, `inflation`, `AI regulation`) — use it for the report title and for every subagent/tool query. You may rephrase for better searchability.

---

## Confirm Before Proceeding

After Step 0, **before calling any tools**, present a short summary and wait for the user to confirm.

Show the user:
- **Topic:** the `topicSearchQuery` as interpreted (e.g. "AI regulation")
- **Date range:** e.g. "Past 90 days — Jan 19 to Apr 19, 2026 · Overtime chart: past 15 months"
- **Source:** Earnings Calls · S&P Transcripts

Then ask: *"Ready to generate the topic research report. Reply **yes** to continue, or clarify anything above."*

**Do not call any tools until the user confirms.**

---

## Step 2: Parallel Data Collection

Execute all data collection in one parallel batch: 5 tool calls + the search summarizer agent.

**Required tools (only these):**
1. `getTopicOvertime`
2. `getSectors`
3. `getCompanies` with `companySearchMode: 'byDocuments'`
4. `getDocuments`
5. `getTopicNetwork`
6. `pronto-search-summarizer` (subagent)

**Common params (pass to all 5 calls):**
- `topicSearchQuery: <topicSearchQuery>`
- `documentTypes: ["Earnings Calls"]`
- `dateRange: { gte: <sinceDay>, lte: <untilDay> }`
- `corpus: ["S&P Transcripts"]`

**Tool-specific additions:**
- `getTopicOvertime`: additionally pass `timeframeInterval: "quarter"`
- `getCompanies`: additionally pass `companySearchMode: 'byDocuments'`

**Date defaults** (always pass `dateRange` explicitly):
- `getTopicOvertime`: `gte` = 15 months ago, `lte` = today.
- All other tools: `gte` = 90 days ago, `lte` = today.
- Honor any user-provided timeframe; still pass `gte` and `lte` to every tool.

**Search-summarizer call** (same parallel batch, `subagent_type: prontonlp-plugin:pronto-search-summarizer`):
```
description: "Search best sentences from parameters"

topicSearchQuery: <topicSearchQuery>
dateRange: { gte: <range start>, lte: <range end> }
documentTypes: ["Earnings Calls"]
instruction: Return ONLY the best verbatim sentences — no JSON, no metadata. Prioritize the most important and interesting sentences; exclude weak/off-topic. Plain text, one sentence per line, no bullets or headers. Output the text field verbatim — it already ends with [Source](url).
```

Save the agent output as `searchResults`.

---

## Step 3: Themes Broker Synthesis

Delegate to **one** `pronto-themes-broker` agent (`subagent_type: prontonlp-plugin:pronto-themes-broker`).

```
description: "Themes broker synthesis from search results"

dateRange: { gte: <range start>, lte: <range end> }
documentTypes: ["Earnings Calls"]
corpus: ["S&P Transcripts"]
searchResults:
<paste the full output from Step 2 search-summarizer>
```

The broker returns three sections only: **Executive Summary**, **Themes** (each with verbatim evidence + citation IDs), and **Conclusion**. The broker must not invoke any other tool.

---

## Step 4: Render

Delegate the HTML output to `pronto-html-renderer` (`subagent_type: prontonlp-plugin:pronto-html-renderer`). Do not render HTML here.

```
report_type: topic
filename: <topic-slug>-research-<YYYYMMDD>.html
title: "Topic Research: <topicSearchQuery>"
subtitle: "<dateRangeLabel> · Earnings Calls"
data:
  meta: { topic, dateRangeLabel, sinceDay, untilDay, companiesCovered }
  hitsOvertime:
    dates:         [ "Q1 2024", "Q2 2024", ... ]   # quarterly buckets
    totalHits:     [ ... ]
    positiveHits:  [ ... ]
    negativeHits:  [ ... ]
  relatedSectors:  [ { name, hits, score } ]
  relatedCompanies: [ { name, ticker, companyId, score,
                        positive, negative, neutral, hits } ]
  relatedDocuments: [ { name, date, company,
                        positive, negative, neutral, hits } ]
                      # name arrives as "[Document Title](url)" — pass verbatim
  relatedKeywords:  [ { name, hits, score, explanation } ]
  themes: [ { title, insight, marketImplications,
              evidence: [ { text, company } ] } ]
              # text already ends with "[Source](url)" — pass verbatim
narrative:
  executiveSummary: "<verbatim from themes broker>"
  conclusion:       "<verbatim from themes broker>"
```

**Naming rules the renderer enforces:**
- Section titled exactly "Hits Overtime" — the words "Mentions" and "Trends" never appear.
- Citation links are pre-embedded in data fields — renderer parses `[Label](url)` and renders as anchor tags.

For related-keywords rows missing an explanation, supply a 1-sentence explanation in the payload — the renderer does not invent one.

---

## Step 5: Optional XLSX Export

After the HTML renderer reports success, ask the user:

> "Your report is ready: `<filename>.html`. Want this also as an XLSX file? (yes/no)"

**Skip the prompt** if the user explicitly asked for XLSX up front (e.g. "give me the topic research as xlsx", "in spreadsheet form") — in that case generate both formats automatically.

If the user answers yes (or pre-asked), invoke `anthropic-skills:xlsx` **directly from this skill** (not via a sub-agent) using the same data you already built for the HTML renderer.

**Filename:** same as the HTML file but `.xlsx` extension.

**Sheets to create** (skip any whose source data is missing or empty):
1. **Summary** *(tab teal `#205262`, no autofilter)* — `meta` fields as Key / Value rows (topic, date range, companies covered), then `narrative.executiveSummary` and `narrative.conclusion` as wrapped text blocks
2. **Hits Overtime** — Quarter, Total Hits, Positive Hits, Negative Hits
3. **Related Sectors** — Sector Name, Hits, Score
4. **Related Companies** — Name, Ticker, Score, Positive, Negative, Neutral, Hits
5. **Related Documents** — Name (linked — `name` field arrives as `[Title](url)`), Date, Company, Positive, Negative, Neutral, Hits
6. **Related Keywords** — Keyword, Hits, Score, Explanation
7. **Themes** — Theme Title, Insight, Market Implications, Evidence Text (with embedded [Source](url) link), Company; evidence rows indented below each theme entry

**Styling** (every sheet):
- Row 1: fill `#205262`, white bold text, height 22pt, frozen so it stays visible when scrolling
- Autofilter on header row (all sheets except Summary)
- Positive numeric values → font `#6AA64A` (green) · Negative → `#ED4545` (red)
- Scores: `0.00` · Change/% columns: `0.0%` · Counts: whole numbers
- Hyperlinks: blue underlined, display text "Source"
- Wrap long text (quotes, narratives) — no column wider than ~50 chars
- No zebra striping · No cell borders

Report the saved filename to the user when complete.

If the user answers no, end the skill normally.

---

## Date Handling

```
Past 90 days (default):          dateRange: { gte: "now-90d/d", lte: "now" }
getTopicOvertime default:        dateRange: { gte: "now-15M/d", lte: "now" }
Past year:                       dateRange: { gte: "now-1y/d",  lte: "now" }
Past 6 months:                   dateRange: { gte: "now-6M/d",  lte: "now" }
YTD:                             dateRange: { gte: "<YYYY>-01-01", lte: "now" }
```

Always pass `dateRange` (both `gte` and `lte`) and `corpus: ["S&P Transcripts"]` on every tool request.

---

## Best Practices

1. Never fabricate — themes and evidence come solely from the broker's synthesis.
2. Use "Hits" everywhere — never "Mentions" or "Trends" in any manually authored text.
3. Do not mention tool names in responses — describe the action.
