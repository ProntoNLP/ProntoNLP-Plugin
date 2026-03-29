# Evaluations

Evaluation criteria for assessing the quality of responses generated using the pronto-persona skill.

## Evaluation Dimensions

### Tool Selection
- Was the most specific tool used for the question type?
- Was `search` only used as a genuine fallback (not when a dedicated tool exists)?
- Was `getAnalytics` used (not `search`) for sentiment scores, event types, and aspect data?
- Was `getTopMovers` used (not `search`) for investment opportunities / stock movers?
- Was `getTrends` used only when the word "trends" was explicitly in the question?
- Was `getTopicMentionsAndSentimentMap` used for topic mention volume across sectors/companies?

### Tool Sequencing & Parallelism
- Were independent tool calls batched in parallel within each step?
- Were IDs correctly extracted from one tool and passed to the next?
- Was `companyId` from `getCompanyDescription` passed to `getStockPrices`, `getStockChange`, `getPredictions`?
- Were competitor `companyIds` from `getCompanyCompetitors` passed to `getDeepResearchStockAverage`?
- Were `transcriptIds` from `getCompanyDocuments` passed to `getAnalytics` and `search`?
- Was `searchTopCompanies` called once per `speakerId` (never batched)?

### Search Tool Usage (when used)
- Was the search query the smallest, most accurate phrase (search-engine style)?
- Was `deepSearch: true` triggered when fewer than 30 relevant results were returned?
- Was `addContext` called on the most relevant result IDs?
- Was the date range kept within 1 year per call (split if longer)?

### Citations & Formatting
- Does every factual statement include a reference-style citation `[N][N]`?
- Do all citation URLs follow the format `https://dev.prontonlp.com/#/ref/<FULL_ID>`?
- Are numbers in `[N][N]` inline references sequential and matching the link definitions?
- Are full IDs preserved (including digits after the hyphen, e.g. `$SENTID123456-890`)?
- Are responses formatted in standard markdown?

### Response Quality
- Were at least 5 companies / events / aspects used as examples for sector or trend questions?
- Were supporting quotes or sentences included for each example?
- Were tool names omitted from the user-facing response?
- Were facts sourced only from 2022+ SEC filings and Earnings Calls?
- For `getTopMovers` results — were company IDs embedded as empty markdown links `Name [](id)`?
- Were banned words avoided (`hot`, `underperforming`, `overperforming`)?
- Were approved substitutes used (`worth monitoring`, `potential buying opportunities`, `potential sell signals`)?

### Data Integrity
- Were all facts sourced exclusively from tool outputs?
- Were missing or empty tool results acknowledged honestly (not fabricated)?
- Was "last quarter" / "last earnings call" filtered by last 90 days?
- Was today's date used as `untilDate` for "current / recent / latest" queries?

## Scoring

Each dimension is scored 1–5:
- 5: Exceptional — exceeds expectations
- 4: Good — meets all requirements
- 3: Adequate — minor gaps
- 2: Below expectations — significant gaps
- 1: Failing — major issues

Overall score = average of all dimensions.
