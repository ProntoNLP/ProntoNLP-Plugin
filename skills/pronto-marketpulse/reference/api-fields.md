# ProntoNLP API Field Reference — Market Pulse

Reference tables for fields returned by the ProntoNLP tools used in this skill.

---

## getTopMovers

Pass `sortBy` as an array of sort criteria. The response is an object keyed by criterion — each key contains its own independent `topMovers`, `underperforming`, and `overperforming` arrays.

```
response = {
  "stockChange": { topMovers: [...], underperforming: [...], overperforming: [...] },
  "investmentScore": { ... },
  ...
}
```

**Available `sortBy` values:**

| Value | Meaning |
|-------|---------|
| `"stockChange"` | % change in stock price over the period |
| `"investmentScore"` | Current investment attractiveness score (0–10) |
| `"investmentScoreChange"` | Change in investment score vs the prior period |
| `"sentimentScore"` | Current sentiment score (−1 to +1) |
| `"sentimentScoreChange"` | Change in sentiment score vs the prior period |
| `"aspectScore"` | Aspect-level performance score |
| `"marketcap"` | Market capitalization in USD |

**Company object fields:**

| Field | Meaning |
|-------|---------|
| `id` | Numeric Pronto company ID — use in links |
| `ticker` | Stock ticker symbol |
| `displayName` | `"Company Name (TICKER)"` combined string |
| `name` | Company name only |
| `sector` | Top-level industry sector |
| `subSector` | More specific industry classification |
| `stockChange` | % change in stock price |
| `investmentScore` | Current investment score |
| `investmentScoreChange` | Change in investment score vs prior period |
| `sentimentScore` | Current sentiment score (−1 to +1) |
| `sentimentScoreChange` | Change in sentiment score vs prior period |
| `aspectScore` | Aspect-level score |
| `marketCap` | Market cap in USD |
| `category` | Source array: `"underperforming"`, `"overperforming"`, or `"topMover"` |

**Source category tracking**: record `category` for signal badges — `"underperforming"` means stock is down but fundamentals are strong (`Potential Buy` signal).

**Response arrays:**
- `topMovers` — companies with the most significant movement on the sort criterion
- `underperforming` — falling stock price but high investment score (potential buying opportunities)
- `overperforming` — rising stock price but low investment score (potential sell signals)

---

## getTrends

| Field | Meaning |
|-------|---------|
| `name` | Trend topic (e.g., "tariffs", "AI investment", "margin pressure") |
| `explanation` | 1–2 sentence description of why it's trending |
| `score` | Significance score, 0–1 (higher = more notable) |
| `hits` | Raw mention count across all documents in the period |
| `change` | % change in mention frequency vs the prior period (positive = rising, negative = fading) |

---

## getSpeakers

| Field | Meaning |
|-------|---------|
| `name` | Speaker's full name |
| `company` | Company name |
| `companyId` | Numeric company ID — use in ProntoNLP links |
| `sentimentScore` | −1.0 (very bearish) to +1.0 (very bullish) |
| `numOfSentences` | Sentence count for this speaker in the period |

**Speaker type values for `speakerTypes`:**
`"Executives"` | `"Analysts"` | `"Executives_CEO"` | `"Executives_CFO"` | `"Executives_COO"` | `"Executives_VP"` | `"Executives_IR"`

---

## Market Cap Filter Reference

The `marketCaps` parameter for `getTopMovers` accepts an **array of key strings**. `getTrends` and `getSpeakers` do not accept `marketCaps`.

Available keys:

| Key | Range |
|-----|-------|
| `"Nano (under $50mln)"` | < $50M |
| `"Micro ($50mln - $300mln)"` | $50M – $300M |
| `"Small ($300mln - $2bln)"` | $300M – $2B |
| `"Mid ($2bln - $10bln)"` | $2B – $10B |
| `"Large ($10bln - $200bln)"` | $10B – $200B |
| `"Mega ($200bln & more)"` | > $200B |

Default filter ($300M+):
```json
["Small ($300mln - $2bln)", "Mid ($2bln - $10bln)", "Large ($10bln - $200bln)", "Mega ($200bln & more)"]
```

To include everything (no cap filter), omit the `marketCaps` parameter entirely.
