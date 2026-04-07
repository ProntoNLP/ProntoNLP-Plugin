# ProntoNLP ID Flow Reference

The MCP already provides full tool definitions and parameters. This file only documents the **ID flow** — how to pass IDs between tools — since that's not in the MCP definitions.

---

## ID Flow Diagram

```
getCompanyDescription({ companyNameOrTicker: "AAPL" })
  └→ companyId (e.g. "4567")
       ├→ getStockPrices({ companyId: "4567", ... })
       ├→ getStockChange({ companyId: "4567", ... })
       └→ getPredictions({ companyId: "4567", ... })

getCompanyCompetitors({ companyNameOrTicker: "AAPL" })
  └→ competitor companyIds (e.g. ["8901", "1234", "5678"])
       └→ getStockChange({ companyId: "8901", ... })  // per competitor

getCompanyDocuments({ companyName: "Apple" })
  └→ transcriptIds (e.g. ["doc_q1", "doc_q2", "doc_q3", "doc_q4"])
       ├→ getAnalytics({ documentIDs: ["doc_q1"], ... })  // per quarter
       └→ pronto-search-summarizer (pass transcriptIds in prompt)  // Batch 4
```

## Which tools accept companyId vs companyName

| Accepts `companyId` | Accepts `companyName` only |
|---------------------|---------------------------|
| getStockPrices | getAnalytics |
| getStockChange | getTrends |
| getPredictions | getSpeakers |
| | getSpeakerCompanies |
| | search (also accepts `companyIDs` array) |
| | getCompanyDocuments |

**Rule**: When a tool accepts both, prefer `companyId` for precision.

## Enum References

These values are used across multiple tools. Keeping them here avoids looking them up each time.

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP` | `Executives_Director` | `Executives_President` | `Executives_IR` | `Executives_Board`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day` | `Special Calls` | `Shareholder/Analyst Calls` | `ESG Report` | `Guidance/Update Calls`

**Earnings Call Sections**: `EarningsCalls_PresenterSpeech` | `EarningsCalls_Answer` | `EarningsCalls_Question` | `EarningsCalls_PresentationOprMsg` | `EarningsCalls_QAOprMsg`
