# Speaker & Analyst Tools — Cheatsheet

Quick reference for parameters, enums, and ID flow for speaker/analyst tools.

---

## Tool Flow

```
getSpeakers({ companyName: "Apple", speakerTypes: ["Analysts"], sortBy: "sentiment", sortOrder: "desc" })
  └→ speakerId per speaker (e.g. "SP_001", "SP_002")
       └→ searchTopCompanies({ speakerId: "SP_001" })  // one call per ID — never batch
       └→ searchTopCompanies({ speakerId: "SP_002" })

getSpeakerCompanies({ companyName: "Apple", speakerTypes: ["Analysts"], ... })
  └→ firm-level sentiment rankings (name, sentimentScore, numOfSentences)
```

**Critical:** `searchTopCompanies` with a `speakerId` must be called once per speaker. Never pass multiple IDs in one call.

---

## Speaker Type Enums

### All Speaker Types
`Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP` | `Executives_Director` | `Executives_President` | `Executives_IR` | `Executives_Board`

### Common Combinations
| Goal | speakerTypes value |
|------|--------------------|
| All executives | `["Executives"]` |
| CEO only | `["Executives_CEO"]` |
| CFO only | `["Executives_CFO"]` |
| All buy-side analysts | `["Analysts"]` |

---

## Sort Parameters

| Goal | sortBy | sortOrder |
|------|--------|-----------|
| Most positive first | `sentiment` | `desc` |
| Most negative first | `sentiment` | `asc` |
| Most active (volume) | `count` | `desc` |

---

## Reading Sentiment Scores

- Range: **-1.0 (very negative) to +1.0 (very positive)**
- > +0.10 = notably positive
- < -0.10 = notably negative
- "Count" (numOfSentences) = proxy for how vocal/active the speaker is

---

## Comparison Statements to Always Include

When comparing executives and analysts:
- "Executives are MORE POSITIVE/MORE NEGATIVE than analysts by X.XX"
- "CEO is MORE BULLISH/MORE CAUTIOUS than CFO"

When identifying extremes:
- "Most bullish analyst: [Name] from [Firm] (X.XX)"
- "Most bearish analyst: [Name] from [Firm] (X.XX)"

---

## Date Helpers

```
Past 90 days (last quarter):  sinceDay = 90 days ago,  untilDay = today
Past 6 months:                sinceDay = 6 months ago, untilDay = today
Past year:                    sinceDay = 1 year ago,   untilDay = today
```

---

## Citation URL

```
https://dev.prontonlp.com/#/ref/<FULL_ID>
```

ID formats:
- Sentence IDs: `$SENTID123456-890` — always keep digits after the hyphen
