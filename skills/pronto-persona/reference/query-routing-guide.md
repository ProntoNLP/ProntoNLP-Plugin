# Query Routing Guide

How to pick the right tool for any question type. Use this as the decision tree before making any tool calls.

---

## Decision Tree

```
Does the question mention a specific company or ticker?
├── YES → getCompanyDescription first to get companyId
│   ├── Asks about stock price / price change → getStockPrices or getStockChange
│   ├── Asks about earnings / sentiment → getCompanyDocuments → getAnalytics
│   ├── Asks about analyst estimates → getPredictions
│   ├── Asks about competitors → getCompanyCompetitors
│   ├── Asks about speakers / executives → getSpeakers / getSpeakerCompanies
│   └── General quotes / evidence → search (fallback)
│
└── NO → Broad market / sector question
    ├── Asks about "trends" (word explicitly present) → getTrends
    ├── Asks about top movers / investment opportunities / stocks worth watching → getTopMovers
    ├── Asks about topic sentiment across sectors → searchSectors
    ├── Asks about top companies for a topic → searchTopCompanies
    ├── Asks about topic mention volume or sentiment distribution across companies → searchTopCompanies (with searchQuery)
    ├── Asks about analytics / event types for a sector → getAnalytics (with sectors filter)
    └── General topic search → search (fallback)
```

---

## Common Mistakes to Avoid

### Using `search` when a dedicated tool exists
| Wrong | Right |
|-------|-------|
| `search` for stock price | `getStockPrices` or `getStockChange` |
| `search` for analyst estimates | `getPredictions` |
| `search` for sentiment scores | `getAnalytics` |
| `search` for investment movers | `getTopMovers` |
| `search` to find event types | `getAnalytics` first, then `search` with those event types |

### Calling `getTrends` for any market question
`getTrends` is **only for when the word "trends" is explicitly in the question**. Do not use it for general market analysis, topic sentiment, or company-level questions.

### Batching `searchTopCompanies` for multiple speakerIds
Always call `searchTopCompanies` once per `speakerId` — never pass multiple speaker IDs in one call.

### Using `searchQuery` synonyms instead of `eventTypes`/`aspects`
If the user asks about a specific event type or aspect, use `getAnalytics` to find the correct `eventTypes` or `aspect` values first. Do not substitute synonyms or free-text searches — it produces inaccurate results.

---

## Query Type → Tool Mapping

| Query pattern | Primary tool | Follow-up |
|---------------|-------------|-----------|
| "How is [company] doing?" | `getCompanyDescription` | `getStockChange`, `getPredictions` |
| "What's the stock price of X?" | `getStockPrices` | — |
| "Revenue/EPS forecast for X?" | `getPredictions` | — |
| "X's last earnings call themes" | `getCompanyDocuments` → `getAnalytics` | `search` (quotes) |
| "Who spoke most positively at X's call?" | `getSpeakers` | `searchTopCompanies` (per speakerId) |
| "What firms are most bullish on X?" | `getSpeakerCompanies` | — |
| "How does X compare to competitors?" | `getCompanyCompetitors` → `getDeepResearchStockAverage` | `getStockChange` per competitor |
| "Top negative events in [sector] this week" | `getAnalytics` (sectors filter) | `searchTopCompanies` per event |
| "Which companies discussed [topic] most positively?" | `searchTopCompanies` | `search` (quotes) |
| "Sentiment for [topic] across sectors" | `searchSectors` | — |
| "Which companies mention [topic] most?" | `searchTopCompanies` (with searchQuery) | `search` (quotes) |
| "What are the market trends?" | `getTrends` (only if "trends" is in the query) | — |
| "Top stocks / movers / worth watching" | `getTopMovers` | `getCompanyDescription` (top 10-15) |
| "How did basket of stocks perform?" | `getDeepResearchStockAverage` | — |
| "What did X say about [topic]?" | `search` (fallback) | `addContext` on relevant IDs |

---

## `search` Tool — When and How

Use `search` only when no other tool can answer the question. When you do:

1. Get `companyId` / `transcriptId` from upstream tools if needed
2. Use the smallest, most accurate query string (not a sentence — a keyword or short phrase)
3. If fewer than 30 relevant results → re-run with `deepSearch: true`
4. Call `addContext` on the most relevant result IDs for deeper content
5. Max date range: **1 year per call** — split longer ranges

**Do not use `search` for:**
- Calculating sentiment scores → use `getAnalytics`
- Finding investment movers → use `getTopMovers`
- Getting stock prices → use `getStockPrices` / `getStockChange`
- Retrieving analyst estimates → use `getPredictions`
- Finding event types → use `getAnalytics` first to identify them
