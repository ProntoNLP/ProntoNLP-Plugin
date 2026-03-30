# ProntoNLP Tool Cheatsheet

Quick reference for parameters, ID flow, and enum values across all tools.

---

## ID Flow Diagram

```
getCompanyDescription({ companyNameOrTicker: "AAPL" })
  └→ companyId (e.g. "4567")
       ├→ getStockPrices({ companyId: "4567", ... })
       ├→ getStockChange({ companyId: "4567", ... })
       └→ getPredictions({ companyId: "4567", metric: "revenue", ... })

getCompanyCompetitors({ companyNameOrTicker: "AAPL" })
  └→ competitor companyIds (e.g. ["8901", "1234", "5678"])
       ├→ getDeepResearchStockAverage({ companyIds: ["8901", "1234", "5678"], includeSp500: true, ... })
       └→ getStockChange({ companyId: "8901", ... })  // per competitor

getCompanyDocuments({ companyName: "Apple", documentTypes: ["Earnings Calls"] })
  └→ transcriptIds (e.g. ["doc_q1", "doc_q2", "doc_q3", "doc_q4"])
       ├→ getAnalytics({ documentIDs: ["doc_q1"], ... })  // per quarter
       └→ search({ documentIDs: ["doc_q1"], ... })        // per quarter

getAnalytics({ ... })
  └→ eventTypes[].id (e.g. "FinancialPerformance", "Forecast", "Operations")
       └→ searchTopCompanies({ eventTypes: ["FinancialPerformance"], ... })
       └→ search({ eventTypes: ["FinancialPerformance"], ... })

getSpeakers({ companyName: "Apple", speakerTypes: ["Analysts"], ... })
  └→ speakerId per speaker (e.g. "SP_001", "SP_002")
       └→ searchTopCompanies({ speakerId: "SP_001" })  // one call per ID — never batch
       └→ searchTopCompanies({ speakerId: "SP_002" })
```

---

## Which Tools Accept companyId vs companyName

| Accepts `companyId` | Accepts `companyName` (or ticker) |
|---------------------|-----------------------------------|
| getStockPrices | getAnalytics |
| getStockChange | getTrends |
| getPredictions | getSpeakers |
| getDeepResearchStockAverage (`companyIds` array) | getSpeakerCompanies |
| | search (also accepts `companyIDs` array) |
| | getCompanyDocuments |
| | getCompanyDescription (`companyNameOrTicker`) |
| | getCompanyCompetitors (`companyNameOrTicker`) |

**Rule**: When a tool accepts both, prefer `companyId` for precision.

---

## Enum References

### Speaker Types
`Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP` | `Executives_Director` | `Executives_President` | `Executives_IR` | `Executives_Board`

### Document Types
`Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day` | `Special Calls` | `Shareholder/Analyst Calls` | `ESG Report` | `Guidance/Update Calls`

### Earnings Call Sections
`EarningsCalls_PresenterSpeech` | `EarningsCalls_Answer` | `EarningsCalls_Question` | `EarningsCalls_PresentationOprMsg` | `EarningsCalls_QAOprMsg`

### Analytics Types
`scores` | `eventTypes` | `aspects` | `patternSentiment` | `importance` | `llmTags`

### Prediction Metrics
`revenue` | `netIncomeGaap` | `epsGaap` | `ebitda` | `capitalExpenditure` | `freeCashFlow`

### getTopMovers — sortBy values (pass as array, supports multi-sort)
| Value | Meaning |
|-------|---------|
| `investmentScore` | Normalized investment score |
| `investmentScoreChange` | Change in investment score vs prior period |
| `sentimentScore` | Raw sentiment score |
| `sentimentScoreChange` | Change in sentiment vs prior period |
| `stockChange` | Stock price % change |
| `aspectScore` | Raw aspect score |
| `marketcap` | Market capitalization (default) |

Pass multiple values to get **independent ranked lists per criterion** in one call:
- `["investmentScoreChange"]` → one ranked list
- `["investmentScoreChange", "sentimentScoreChange"]` → two separate ranked lists

Response structure: `{ "investmentScoreChange": { topMovers, underperforming, overperforming }, "sentimentScoreChange": { ... } }`

### Sort Orders
`asc` | `desc`

---

## Date Helpers

```
Past 90 days (last quarter):  sinceDay = 90 days ago,  untilDay = today
Past 6 months:                sinceDay = 6 months ago, untilDay = today
YTD:                          sinceDay = Jan 1,        untilDay = today
Past year:                    sinceDay = 1 year ago,   untilDay = today
```

**getAnalytics limit**: max 1 year per call. Split longer ranges into yearly chunks.

---

## Citation URL

```
https://dev.prontonlp.com/#/ref/<FULL_ID>
```

ID formats:
- Sentence IDs: `$SENTID123456-890` — always keep the digits after the hyphen
- Trend IDs: `$TREND123456`
- If a tool returns a range of IDs, pick one representative
