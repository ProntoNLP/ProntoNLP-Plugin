# Example: Speaker Analysis — "Who were the most positive analysts covering Apple? Which companies did they focus on?"

Full workflow showing getSpeakers → getSpeakerCompanies → searchTopCompanies per speakerId.

---

## Batch 1: Get Speakers + Firms (parallel)

```
Tool: getSpeakers (all analysts — most bullish first)
Params: {
  companyName: "Apple",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 20,
  sinceDay: "2025-03-26",
  untilDay: "2026-03-26"
}
→ speakers:
    { speakerId: "SP_001", name: "Erik Woodring",     company: "Morgan Stanley", sentimentScore: 0.58, numOfSentences: 32 }
    { speakerId: "SP_002", name: "Samik Chatterjee",  company: "JPMorgan",       sentimentScore: 0.51, numOfSentences: 28 }
    { speakerId: "SP_003", name: "Wamsi Mohan",       company: "Bank of America", sentimentScore: 0.45, numOfSentences: 25 }
    ... (17 more)
    { speakerId: "SP_019", name: "Toni Sacconaghi",   company: "Bernstein",      sentimentScore: -0.12, numOfSentences: 35 }
    { speakerId: "SP_020", name: "Rod Hall",          company: "Goldman Sachs",  sentimentScore: -0.18, numOfSentences: 22 }

Tool: getSpeakerCompanies (firm-level)
Params: {
  companyName: "Apple",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 20,
  sinceDay: "2025-03-26",
  untilDay: "2026-03-26"
}
→ firms:
    { name: "Morgan Stanley", sentimentScore: 0.55, numOfSentences: 64 }
    { name: "JPMorgan",       sentimentScore: 0.48, numOfSentences: 52 }
    ...
    { name: "Goldman Sachs",  sentimentScore: -0.15, numOfSentences: 41 }
    { name: "Bernstein",      sentimentScore: -0.22, numOfSentences: 38 }
```

---

## Batch 2: Per-Speaker Company Coverage (one call per speakerId — never batch)

```
Tool: searchTopCompanies (SP_001 — Erik Woodring)
Params: { speakerId: "SP_001", limit: 10 }
→ [
    { name: "Apple",   sentiment: 0.58 },
    { name: "Samsung", sentiment: 0.42 },
    { name: "Qualcomm", sentiment: 0.38 }
  ]

Tool: searchTopCompanies (SP_002 — Samik Chatterjee)
Params: { speakerId: "SP_002", limit: 10 }
→ [
    { name: "Apple",   sentiment: 0.51 },
    { name: "Alphabet", sentiment: 0.44 },
    { name: "Meta",    sentiment: 0.40 }
  ]

Tool: searchTopCompanies (SP_003 — Wamsi Mohan)
Params: { speakerId: "SP_003", limit: 10 }
→ [
    { name: "Apple",   sentiment: 0.45 },
    { name: "Dell",    sentiment: 0.39 }
  ]
```

---

## Compile: Response

```markdown
## Analyst Sentiment — Apple Coverage

**Most Bullish Analysts**

| Analyst | Firm | Sentiment | Sentences |
|---------|------|-----------|-----------|
| Erik Woodring | Morgan Stanley | 0.58 | 32 |
| Samik Chatterjee | JPMorgan | 0.51 | 28 |
| Wamsi Mohan | Bank of America | 0.45 | 25 |

**Most Bearish Analysts**

| Analyst | Firm | Sentiment | Sentences |
|---------|------|-----------|-----------|
| Rod Hall | Goldman Sachs | -0.18 | 22 |
| Toni Sacconaghi | Bernstein | -0.12 | 35 |

**Most Bullish Firms**

| Firm | Sentiment |
|------|-----------|
| Morgan Stanley | 0.55 |
| JPMorgan | 0.48 |

**Most Bearish Firms**

| Firm | Sentiment |
|------|-----------|
| Bernstein | -0.22 |
| Goldman Sachs | -0.15 |

---

**Erik Woodring (Morgan Stanley — 0.58)** primarily covers Apple, Samsung, and Qualcomm.
His positive tone on Apple is consistent with his broader semiconductor supply chain bullishness.

**Samik Chatterjee (JPMorgan — 0.51)** covers Apple alongside Alphabet and Meta —
a broad mega-cap tech focus with uniformly positive sentiment.

**Wamsi Mohan (Bank of America — 0.45)** concentrates on Apple and Dell,
suggesting a hardware/devices-first perspective.
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 2 | getSpeakers + getSpeakerCompanies (parallel) |
| 2 | 3 | searchTopCompanies × 3 (one per speakerId — sequential within batch but individually fast) |
| **Total** | **5** | **2 sequential batches** |
