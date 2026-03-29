# Sector & Topic Tools — Cheatsheet

Quick reference for parameters, enums, and ID flow for sector/topic analysis tools.

---

## Tool Flow

```
getAnalytics({ searchQueries: ["tariff"], sectors: ["Financials"], ... })
  └→ eventTypes[].id  (e.g. "FinancialPerformance", "Operations", "Forecast")
       └→ searchTopCompanies({ eventTypes: ["FinancialPerformance"], ... })  // one call per event type
       └→ search({ eventTypes: ["FinancialPerformance"], companyIDs: [...], ... })

searchSectors({ searchQueries: ["AI"], ... })
  └→ sector rankings (name, sentimentScore, mentionCount)
       └→ searchTopCompanies({ sectors: ["Information Technology"], ... })

searchTopCompanies({ ... })
  └→ companyId per result
       └→ search({ companyIDs: [...], ... })  // for supporting quotes
```

---

## Enum References

### Sectors
`Information Technology` | `Financials` | `Health Care` | `Consumer Discretionary` | `Consumer Staples` | `Industrials` | `Communication Services` | `Energy` | `Materials` | `Real Estate` | `Utilities`

### Document Types
`Earnings Calls` | `10-K` | `10-Q` | `Company Conference Presentations` | `Analyst/Investor Day` | `Special Calls` | `Shareholder/Analyst Calls` | `ESG Report` | `Guidance/Update Calls`

### Analytics Types
`scores` | `eventTypes` | `aspects` | `patternSentiment` | `importance` | `llmTags`

### Sentiment Values
`positive` | `negative` | `neutral`

### Sort Orders
`asc` | `desc`

---

## Key Parameter Rules

1. **Always use `eventTypes` from `getAnalytics` output** — never guess event type names; call `getAnalytics` first to discover them
2. **One `searchTopCompanies` per event type** — call in parallel, never merge multiple event types into one call
3. **Date range limit** — `getAnalytics` max 1 year per call; split longer ranges into yearly chunks
4. **Prefer structured params** — use `eventTypes`/`aspects`/`sectors` instead of `searchQueries` when they apply

---

## Date Helpers

```
Past 2 weeks:   sinceDay = 14 days ago,   untilDay = today
Past 90 days:   sinceDay = 90 days ago,   untilDay = today
Past 6 months:  sinceDay = 6 months ago,  untilDay = today
Past year:      sinceDay = 1 year ago,    untilDay = today
```

---

## Citation URL

```
https://dev.prontonlp.com/#/ref/<FULL_ID>
```

ID formats:
- Sentence IDs: `$SENTID123456-890` — always keep digits after the hyphen
- Trend IDs: `$TREND123456`
