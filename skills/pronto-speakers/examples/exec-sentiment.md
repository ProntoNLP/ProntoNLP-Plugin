# Example: Executive Comparison — "CEO vs CFO sentiment for Microsoft"

Full Mode B workflow: getSpeakers (CEO, CFO, all Executives, Analysts) + getSpeakerCompanies in Batch 1, searchTopCompanies per top speaker in Batch 2, key quotes via search in Batch 3, then charts.

---

## Batch 1: All Speaker Views (5 parallel calls — no dependencies)

```
Tool: getSpeakers (CEO)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Executives_CEO"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 5,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ speakers:
    { speakerId: "EX_CEO_001", name: "Satya Nadella", role: "CEO", sentimentScore: 0.47, numOfSentences: 198 }

Tool: getSpeakers (CFO)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Executives_CFO"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 5,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ speakers:
    { speakerId: "EX_CFO_001", name: "Amy Hood", role: "CFO", sentimentScore: 0.31, numOfSentences: 154 }

Tool: getSpeakers (all Executives — ranked by activity)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Executives"],
  sortBy: "count",
  sortOrder: "desc",
  limit: 20,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ speakers:
    { speakerId: "EX_CEO_001", name: "Satya Nadella",  role: "CEO",      sentimentScore: 0.47, numOfSentences: 198 }
    { speakerId: "EX_CFO_001", name: "Amy Hood",       role: "CFO",      sentimentScore: 0.31, numOfSentences: 154 }
    { speakerId: "EX_IR_001",  name: "Brett Iversen",  role: "IR",       sentimentScore: 0.18, numOfSentences: 62 }
    { speakerId: "EX_CTO_001", name: "Kevin Scott",    role: "CTO",      sentimentScore: 0.39, numOfSentences: 44 }
    { speakerId: "EX_VP_001",  name: "Judson Althoff", role: "EVP",      sentimentScore: 0.35, numOfSentences: 38 }
    ... (15 more)
    → compute exec avg: (0.47 + 0.31 + 0.18 + 0.39 + 0.35 + ...) / N ≈ 0.36

Tool: getSpeakers (Analysts — most bullish first)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 20,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ speakers:
    { speakerId: "AN_001", name: "Keith Weiss",       company: "Morgan Stanley",  sentimentScore: 0.52, numOfSentences: 44 }
    { speakerId: "AN_002", name: "Karl Keirstead",    company: "UBS",             sentimentScore: 0.44, numOfSentences: 38 }
    { speakerId: "AN_003", name: "Mark Moerdler",     company: "Bernstein",       sentimentScore: 0.41, numOfSentences: 35 }
    { speakerId: "AN_004", name: "Brent Thill",       company: "Jefferies",       sentimentScore: 0.28, numOfSentences: 29 }
    { speakerId: "AN_005", name: "Brad Reback",       company: "Stifel",          sentimentScore: 0.22, numOfSentences: 27 }
    ...
    { speakerId: "AN_019", name: "Alex Zukin",        company: "Wolfe Research",  sentimentScore: -0.08, numOfSentences: 31 }
    { speakerId: "AN_020", name: "Phil Winslow",      company: "Wells Fargo",     sentimentScore: -0.14, numOfSentences: 25 }
    → compute analyst avg: ≈ 0.24

Tool: getSpeakerCompanies (firm-level)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Analysts"],
  sortBy: "sentiment",
  sortOrder: "desc",
  limit: 20,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ firms:
    { name: "Morgan Stanley",  sentimentScore: 0.50, numOfSentences: 88 }
    { name: "UBS",             sentimentScore: 0.44, numOfSentences: 71 }
    { name: "Bernstein",       sentimentScore: 0.40, numOfSentences: 65 }
    { name: "Jefferies",       sentimentScore: 0.27, numOfSentences: 54 }
    { name: "Stifel",          sentimentScore: 0.21, numOfSentences: 49 }
    { name: "Wolfe Research",  sentimentScore: -0.07, numOfSentences: 58 }
    { name: "Wells Fargo",     sentimentScore: -0.13, numOfSentences: 44 }
```

---

## Batch 2: Per-Speaker Company Coverage (4 parallel calls — one per speakerId)

```
Tool: searchTopCompanies (Satya Nadella)
Params: {
  speakerId: "EX_CEO_001",
  limit: 10,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ [
    { name: "Microsoft",  sentiment: 0.47 },
    { name: "OpenAI",     sentiment: 0.55 },
    { name: "LinkedIn",   sentiment: 0.38 }
  ]

Tool: searchTopCompanies (Amy Hood)
Params: {
  speakerId: "EX_CFO_001",
  limit: 10,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ [
    { name: "Microsoft",  sentiment: 0.31 },
    { name: "Nuance",     sentiment: 0.24 }
  ]

Tool: searchTopCompanies (Keith Weiss — most bullish analyst)
Params: {
  speakerId: "AN_001",
  limit: 10,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ [
    { name: "Microsoft",   sentiment: 0.52 },
    { name: "Salesforce",  sentiment: 0.45 },
    { name: "ServiceNow",  sentiment: 0.41 }
  ]

Tool: searchTopCompanies (Phil Winslow — most bearish analyst)
Params: {
  speakerId: "AN_020",
  limit: 10,
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ [
    { name: "Microsoft",   sentiment: -0.14 },
    { name: "Workday",     sentiment: -0.09 },
    { name: "Oracle",      sentiment: -0.05 }
  ]
```

---

## Batch 3: Key Quotes (3 parallel calls)

```
Tool: search (CEO positive quotes)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Executives_CEO"],
  sentiment: "positive",
  size: 3,
  sortBy: "sentiment",
  sortOrder: "desc",
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ results:
    { text: "We are seeing the most significant wave of compute infrastructure demand we have ever experienced.", speaker: "Satya Nadella", date: "2025-10-30" }
    { text: "Azure growth accelerated again this quarter, and our AI business is tracking to an annualized revenue run rate of $13 billion.", speaker: "Satya Nadella", date: "2026-01-29" }

Tool: search (CFO positive quotes)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Executives_CFO"],
  sentiment: "positive",
  size: 3,
  sortBy: "sentiment",
  sortOrder: "desc",
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ results:
    { text: "Gross margin dollars grew 13% year over year, driven by the shift in mix toward higher-margin cloud services.", speaker: "Amy Hood", date: "2026-01-29" }
    { text: "We expect commercial bookings growth to remain strong given healthy renewal cycles across enterprise agreements.", speaker: "Amy Hood", date: "2025-10-30" }

Tool: search (analyst skeptical questions)
Params: {
  companyName: "Microsoft",
  speakerTypes: ["Analysts"],
  sentiment: "negative",
  size: 3,
  sections: ["EarningsCalls_Question"],
  sortBy: "sentiment",
  sortOrder: "asc",
  sinceDay: "2025-03-30",
  untilDay: "2026-03-30"
}
→ results:
    { text: "Given the elevated capex commitments, can you help us understand when you expect returns to normalize and margins to recover?", speaker: "Phil Winslow", date: "2026-01-29" }
    { text: "The Copilot seat additions look softer than the Street expected — is enterprise adoption genuinely accelerating or is uptake more uneven?", speaker: "Alex Zukin", date: "2025-10-30" }
```

---

## Batch 4: Write Charts File

```
Write file: /tmp/speakers-charts.html
Copy assets/charts-template.html and populate data arrays:

  analystNames       = ['Keith Weiss', 'Karl Keirstead', 'Mark Moerdler', 'Brent Thill', 'Brad Reback', ..., 'Alex Zukin', 'Phil Winslow']
  analystSentiments  = [0.52, 0.44, 0.41, 0.28, 0.22, ..., -0.08, -0.14]

  speakerLabels      = ['CEO', 'CFO', 'Exec Avg', 'Analyst Avg']
  speakerSentiments  = [0.47, 0.31, 0.36, 0.24]

  firmNames          = ['Morgan Stanley', 'UBS', 'Bernstein', 'Jefferies', 'Stifel', 'Wolfe Research', 'Wells Fargo']
  firmSentiments     = [0.50, 0.44, 0.40, 0.27, 0.21, -0.07, -0.13]

  execNames          = ['Satya Nadella', 'Amy Hood', 'Kevin Scott', 'Judson Althoff', 'Brett Iversen']
  execSentiments     = [0.47, 0.31, 0.39, 0.35, 0.18]
  execSentenceCounts = [198, 154, 44, 38, 62]

Then open it:
  open /tmp/speakers-charts.html
```

---

## Compiled Response

```markdown
# Microsoft — Executive & Analyst Sentiment Analysis
Period: March 2025 – March 2026

---

## Executive Summary

CEO Satya Nadella carries the most positive tone of any Microsoft speaker, with a sentiment
score of +0.47 — substantially more bullish than CFO Amy Hood at +0.31. That 0.16-point gap
is notable: it suggests the CEO is leaning into the AI growth narrative more aggressively than
the CFO, whose commentary centers on margin discipline and capex returns. Across all executives,
the average sentiment is +0.36, which is MORE POSITIVE than the analyst average of +0.24 by
0.12 points. At this level of divergence, management tone should be weighed against the street's
more measured skepticism on near-term AI monetization.

---

## Role-by-Role Breakdown

| Group | Avg Sentiment | Sentences | Note |
|-------|---------------|-----------|------|
| CEO (Satya Nadella) | +0.47 | 198 | Most vocal executive |
| CFO (Amy Hood) | +0.31 | 154 | More cautious than CEO by 0.16 |
| All Executives (avg) | +0.36 | 496 | — |
| All Analysts (avg) | +0.24 | 610 | Executives MORE POSITIVE by 0.12 |

**CEO is MORE BULLISH than CFO by 0.16 points.**
**Executives are MORE POSITIVE than analysts by 0.12 points.**
**Exec-analyst gap: +0.12 — management may be moderately over-optimistic relative to sell-side consensus.**

---

## Top Executives by Activity

| Name | Role | Sentiment | Sentences | Coverage Focus |
|------|------|-----------|-----------|----------------|
| Satya Nadella | CEO | +0.47 | 198 | Microsoft, OpenAI, LinkedIn |
| Amy Hood | CFO | +0.31 | 154 | Microsoft, Nuance |
| Kevin Scott | CTO | +0.39 | 44 | Microsoft |
| Judson Althoff | EVP | +0.35 | 38 | Microsoft |
| Brett Iversen | IR | +0.18 | 62 | Microsoft |

---

## Analyst Rankings

**Most Bullish Analysts**

| Analyst | Firm | Sentiment | Sentences | Stance |
|---------|------|-----------|-----------|--------|
| Keith Weiss | Morgan Stanley | +0.52 | 44 | BULLISH |
| Karl Keirstead | UBS | +0.44 | 38 | Positive |
| Mark Moerdler | Bernstein | +0.41 | 35 | Positive |
| Brent Thill | Jefferies | +0.28 | 29 | Positive |
| Brad Reback | Stifel | +0.22 | 27 | Positive |

**Most Bearish Analysts**

| Analyst | Firm | Sentiment | Sentences | Stance |
|---------|------|-----------|-----------|--------|
| Phil Winslow | Wells Fargo | −0.14 | 25 | Negative |
| Alex Zukin | Wolfe Research | −0.08 | 31 | Neutral/Negative |

**Most bullish analyst: Keith Weiss (Morgan Stanley, +0.52)** — concentrated on Microsoft, Salesforce, and ServiceNow with uniformly positive sentiment across enterprise software.

**Most bearish analyst: Phil Winslow (Wells Fargo, −0.14)** — skeptical on Microsoft, Workday, and Oracle; questions center on capex payback timelines and Copilot adoption pace.

---

## Analyst Firm Rankings

| Firm | Sentiment | Sentences | Stance |
|------|-----------|-----------|--------|
| Morgan Stanley | +0.50 | 88 | BULLISH |
| UBS | +0.44 | 71 | Positive |
| Bernstein | +0.40 | 65 | Positive |
| Jefferies | +0.27 | 54 | Positive |
| Stifel | +0.21 | 49 | Positive |
| Wolfe Research | −0.07 | 58 | Neutral |
| Wells Fargo | −0.13 | 44 | Negative |

**Most bullish firm: Morgan Stanley (+0.50).**
**Most bearish firm: Wells Fargo (−0.13).**
**Spread between most bullish and most bearish: 0.63 points — a wide dispersion reflecting genuine disagreement about AI monetization timing.**

---

## Key Quotes

**CEO — Satya Nadella on AI momentum:**
"We are seeing the most significant wave of compute infrastructure demand we have ever experienced."
— Satya Nadella, CEO, Microsoft (October 30, 2025)

**CEO — Azure acceleration:**
"Azure growth accelerated again this quarter, and our AI business is tracking to an annualized revenue run rate of $13 billion."
— Satya Nadella, CEO, Microsoft (January 29, 2026)

**CFO — Margin improvement:**
"Gross margin dollars grew 13% year over year, driven by the shift in mix toward higher-margin cloud services."
— Amy Hood, CFO, Microsoft (January 29, 2026)

**CFO — Forward bookings:**
"We expect commercial bookings growth to remain strong given healthy renewal cycles across enterprise agreements."
— Amy Hood, CFO, Microsoft (October 30, 2025)

**Analyst skepticism — capex returns:**
"Given the elevated capex commitments, can you help us understand when you expect returns to normalize and margins to recover?"
— Phil Winslow, Wells Fargo (January 29, 2026)

**Analyst skepticism — Copilot adoption:**
"The Copilot seat additions look softer than the Street expected — is enterprise adoption genuinely accelerating or is uptake more uneven?"
— Alex Zukin, Wolfe Research (October 30, 2025)

---

## Gap Analysis

The +0.12 exec-analyst gap puts Microsoft in the "moderately over-optimistic" range. The CEO's
enthusiasm for AI infrastructure demand (+0.47) is the primary driver of the gap — it exceeds
the CFO's more measured tone (+0.31) by 0.16 points, and both exceed the analyst average (+0.24)
by material margins. The most bearish analysts are not broadly negative; they are specifically
concerned about near-term capex payback and Copilot seat growth. The divergence between the
CEO's long-term AI narrative and analysts' near-term ROI focus is the defining tension in
Microsoft's current investor story.
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 5 | getSpeakers (CEO) + getSpeakers (CFO) + getSpeakers (Executives) + getSpeakers (Analysts) + getSpeakerCompanies — all parallel |
| 2 | 4 | searchTopCompanies × 4 (CEO, CFO, top analyst, most bearish analyst) — all parallel |
| 3 | 3 | search × 3 (CEO quotes, CFO quotes, analyst skeptical questions) — all parallel |
| 4 | 1 | Write /tmp/speakers-charts.html and open |
| **Total** | **13** | **4 sequential batches** |
