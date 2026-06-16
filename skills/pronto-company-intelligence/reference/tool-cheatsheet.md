# ProntoNLP ID Flow Reference

The MCP already provides full tool definitions and parameters. This file only documents the **ID flow** — how to pass IDs between tools — since that's not in the MCP definitions.

---

## ID Flow Diagram

```
getCompanies({ companyNameOrTicker: "Apple" })
  └→ companyId (e.g. "4567")
       ├→ getStockPrices({ companiesIds: ["4567"], ... })
       ├→ getStockChange({ companiesIds: ["4567"], ... })
       ├→ getCompanyConsensus({ companiesIds: ["4567"], metrics: [...], ... })
       └→ getCompanyPeers({ companiesIds: ["4567"] })
            └→ peer companyIds[] → getStockChange({ companiesIds: [peer1, peer2, peer3, ...], ... })  // 1 call, all peers

getDocuments({ companiesIds: ["4567"], documentTypes: ["Earnings Calls"], excludeFutureDocuments: true })
  └→ transcriptId per doc, e.g. ["doc_q1", "doc_q2", "doc_q3", "doc_q4"]
       ├→ getAnalytics({ transcriptsIds: ["doc_q1"], companiesIds: ["4567"], ... })  // per quarter — separate calls
       ├→ getDocumentSummary({ focus: "key risks and risk factors mentioned by management", transcriptsIds: ["doc_q1","doc_q2","doc_q3","doc_q4"], corpus: ["S&P Transcripts"] })  // ALL quarters in 1 call (max 5)
       └→ pronto-search-summarizer (pass transcriptsIds: [doc_q1,doc_q2,doc_q3,doc_q4] in prompt)  // 1 call all quarters
```

## Which tools accept companiesIds vs companyNameOrTicker

| Accepts `companiesIds` (array) | Accepts `companyNameOrTicker` only |
|--------------------------------|------------------------------------|
| getStockPrices | getCompanies (for resolution) |
| getStockChange | |
| getCompanyConsensus | |
| getCompanyPeers | |
| getTopMovers | |
| getAnalytics | |
| getTrends | |
| getSpeakers | |
| searchSentences | |
| getDocuments | |
| getDocumentSummary | |

**Rule**: Always resolve company name/ticker via `getCompanies` first, then pass `companiesIds` arrays to all other tools.

## Date Format

All tools use `dateRange: { gte, lte }` — never `sinceDay`/`untilDay`.

Elasticsearch relative syntax is accepted:
- `"now-1y/d"` = 1 year ago (rounded to day)
- `"now-90d/d"` = 90 days ago
- `"now-6M/d"` = 6 months ago (capital M = months)
- `"now"` = current moment
- `"2025-01-01"` = absolute date

## Enum References

These values are used across multiple tools.

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP` | `Executives_Director` | `Executives_President` | `Executives_IR` | `Executives_Board`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day` | `Special Calls` | `Shareholder/Analyst Calls` | `ESG Report` | `Guidance/Update Calls`

**Earnings Call Sections**: `EarningsCalls_PresenterSpeech` | `EarningsCalls_Answer` | `EarningsCalls_Question` | `EarningsCalls_PresentationOprMsg` | `EarningsCalls_QAOprMsg`

**getCompanyConsensus Metrics**: `revenue` | `netIncomeGaap` | `epsGaap` | `ebitda` | `capitalExpenditure` | `freeCashFlow`

**getStockPrices Intervals**: `minute` | `hour` | `day` | `week` | `month` | `quarter` | `year`

**getStockChange Sort**: `most_increased` | `most_decreased` | `most_moved`

**getDocumentSummary `focus`**: free-form string describing what to summarize. Examples: `"key risks and risk factors"` · `"forward guidance and predictions"` · `"analyst questions and management responses"` · `"revenue growth commentary"`

## Multi-ID Batching Rules

Most tools accept arrays for both `companiesIds` and `transcriptsIds`. Key rules:

| Tool | Batching behavior |
|------|------------------|
| `getDocuments` | Pass all company IDs in ONE call |
| `getStockChange` | Pass all company IDs in ONE call per period |
| `getCompanyConsensus` | Pass all company IDs in ONE call |
| `getDocumentSummary` | Pass all transcript IDs in ONE call — **max 5 transcripts** |
| `searchSentences` | Pass all `transcriptsIds` in ONE call instead of per-quarter |
| `getStockPrices` (earnings reaction) | **Keep separate** — each call needs a different date window |
| `getAnalytics` (per quarter) | **Keep separate** — needs per-quarter attribution |
| `getTrends` (per company) | **Keep separate** — needs per-company topic breakdown |
| `getSpeakers` (per company) | **Keep separate** — needs per-company attribution |
| `showDocumentMindMap` | ⚠️ Takes a **single string** `transcriptId`, NOT an array — always one call per transcript |

---

## Key Parameter Rules

| Wrong | Correct |
|-------|---------|
| `companyId` (scalar) | `companiesIds` (array) |
| `documentID` / `documentIDs` | `transcriptsIds` (array) |
| `sentiment: 'positive'` | `DLSentiment: ['positive']` |
| `sinceDay` / `untilDay` as tool input | `dateRange: { gte, lte }` |
