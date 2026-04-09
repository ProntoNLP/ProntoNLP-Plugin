# Topic Intelligence — Tool Cheatsheet

## Tools Used

This skill uses the following ProntoNLP tools for topic-based research:

---

## 1. getAnalytics — Topic Sentiment Analysis

**Purpose:** Overall sentiment and event data for a topic across all documents.

```json
{
  "topicSearchQuery": "<topic keyword>",
  "documentTypes": ["Earnings Calls"],
  "analyticsType": ["scores", "eventTypes", "aspects", "patternSentiment"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response fields:**
- `sentimentScore`: overall sentiment (0.0–1.0)
- `investmentScore`: investment relevance (0.0–1.0)
- `eventTypes[]`: dominant events (GrowthDriver, RiskFactor, etc.)
- `aspects[]`: specific sub-topics discussed

**Report usage:** Section 1 (Executive Summary), Section 9 (Top Aspects)

---

## 2. getTrends — Related Topic Trends

**Purpose:** What topics are trending alongside the main topic.

```json
{
  "topicSearchQuery": "<topic keyword>",
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD",
  "limit": 20,
  "sortBy": "score",
  "sortOrder": "desc"
}
```

**Response fields:**
- `topics[]`: related topic names
- `score`: topic relevance score
- `change`: % change in mentions

**Report usage:** Section 7 (Related Themes)

---

## 3. searchSectors — Topic Distribution by Sector

**Purpose:** Which sectors discuss the topic most frequently.

```json
{
  "searchQueries": ["<topic keyword>"],
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response fields:**
- `sectors[]`: ranked list of sectors
- `topicDistribution`: mentions per sector
- `sentimentPerSector`: sentiment score per sector

**Report usage:** Section 4 (Sector Distribution)

---

## 4. searchTopCompanies — Companies Discussing the Topic

**Purpose:** Which companies mention the topic most often.

```json
{
  "topicSearchQuery": "<topic keyword>",
  "documentTypes": ["Earnings Calls"],
  "limit": 30,
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response fields:**
- `topCompanies[]`: ranked companies
- `hitCount`: number of mentions
- `sentiment`: sentiment per company
- `companyName`, `ticker`, `country`, `sector`

**Report usage:** Section 5 (Top Companies)

---

## 5. getTopMovers — Sentiment/Investment Leaders on Topic

**Purpose:** Top companies by sentiment or investment score on this topic.

```json
{
  "topicSearchQuery": "<topic keyword>",
  "documentTypes": ["Earnings Calls"],
  "marketCaps": ["Small ($300mln - $2bln)", "Mid ($2bln - $10bln)", "Large ($10bln - $200bln)", "Mega ($200bln & more)"],
  "limit": 20,
  "sortBy": ["sentimentScore", "investmentScore", "sentimentScoreChange", "aspectScore"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Response fields:**
- `topMovers[]`: companies ranked by criterion
- `underperforming[]`: low score, high mentions
- `overperforming[]`: high score, high mentions

**Report usage:** Section 1, Section 5

---

## 6. getTermHeatmap — Keyword Heatmap Visualization

**Purpose:** Visual heatmap of topic distribution across sectors/companies.

```json
{
  "topicSearchQuery": "<topic keyword>",
  "documentTypes": ["Earnings Calls"],
  "sinceDay": "YYYY-MM-DD",
  "untilDay": "YYYY-MM-DD"
}
```

**Report usage:** Section 2 (Keyword Heatmap) — REQUIRED before rendering

---

## 7. pronto-search-summarizer — Quote Collection

**Purpose:** Attributed quotes about the topic from executives and analysts.

**subagent_type:** `prontonlp-plugin:pronto-search-summarizer`

Task format:
```
"Find quotes about <topic> across the market. Run these searches:
1. Most bullish/positive quotes about <topic> — sentiment: positive, size: 5
2. Most bearish/negative quotes about <topic> — sentiment: negative, size: 5
3. Notable analyst questions about <topic> — sections: EarningsCalls_Question, size: 5
4. Quotes from different sectors about <topic> — documentTypes: Earnings Calls, size: 5
Return all results with speaker name, role, company, and date."
```

→ Agent returns clean summary with quotes and source links.

**Report usage:** Section 8 (Key Quotes)

---

## ID Flow

```
topicSearchQuery → 
  ├── getAnalytics → sentiment, events, aspects
  ├── getTrends → related topics
  ├── searchSectors → sector distribution
  ├── searchTopCompanies → company rankings
  ├── getTopMovers → sentiment leaders
  └── getTermHeatmap → visualization
```

---

## Date Handling

| Scope | sinceDay | untilDay |
|-------|----------|----------|
| Default (past year) | 1 year ago | today |
| Past quarter | 90 days ago | today |
| Past 6 months | 6 months ago | today |
| YTD | Jan 1 current year | today |

---

## Quick Parameter Reference

**Document types**: `Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day`

**Market caps**: `Nano (under $50mln)` | `Micro ($50mln - $300mln)` | `Small ($300mln - $2bln)` | `Mid ($2bln - $10bln)` | `Large ($10bln - $200bln)` | `Mega ($200bln & more)`

**Sort options**: `sortBy: "score"` | `sortBy: "sentiment"` | `sortBy: "day"` | `sortBy: "count"`

**Event types**: `GrowthDriver` | `RiskFactor` | `CapexExpansion` | `Restructuring` | `RegulatoryChange` | `MergerAcquisition`
