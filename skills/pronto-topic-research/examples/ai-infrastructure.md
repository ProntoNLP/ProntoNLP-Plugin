# Example: Full Report — "AI Infrastructure"

Complete workflow showing parallel data collection, search-summarizer delegation, themes broker synthesis, and renderer handoff.

---

## Step 0: Parse Topic

User input: "how is AI infrastructure discussed across earnings calls?"

```
topicSearchQuery: "AI infrastructure"
dateRangeLabel:  "Past 90 Days"
sinceDay:        2026-01-19   (90 days before today)
untilDay:        2026-04-19
sinceDay (overtime): 2025-01-19  (15 months back for getTrendOvertime)
```

---

## Step 1: Setup

```
getOrganization
→ org: "acme"    ← SAVED — used in every citation link and subagent call
```

---

## Step 2: Parallel Data Collection (all 6 fire simultaneously)

### Trend tools (all with topicSearchQuery: "AI infrastructure", documentTypes: ["Earnings Calls"], corpus: ["S&P Transcripts"])

```
getTrendOvertime
Params: {
  topicSearchQuery: "AI infrastructure",
  documentTypes: ["Earnings Calls"],
  dateRange: { gte: "2025-01-19", lte: "2026-04-19" },
  corpus: ["S&P Transcripts"],
  timeframeInterval: "quarter"
}
→ hitsOvertime:
    { quarter: "Q1 2025", totalHits: 312, positiveHits: 198, negativeHits: 41 }
    { quarter: "Q2 2025", totalHits: 487, positiveHits: 321, negativeHits: 58 }
    { quarter: "Q3 2025", totalHits: 623, positiveHits: 418, negativeHits: 72 }
    { quarter: "Q4 2025", totalHits: 891, positiveHits: 607, negativeHits: 89 }
    { quarter: "Q1 2026", totalHits: 1043, positiveHits: 714, negativeHits: 103 }
  → direction: RISING — hits more than tripled in 5 quarters

getTrendRelatedSectors
Params: { topicSearchQuery: "AI infrastructure", dateRange: { gte: "2026-01-19", lte: "2026-04-19" }, ... }
→ relatedSectors:
    { name: "Information Technology", hits: 4821, score: 0.94 }
    { name: "Communication Services", hits: 1203, score: 0.72 }
    { name: "Industrials", hits: 634, score: 0.51 }
    { name: "Financials", hits: 498, score: 0.44 }
    { name: "Energy", hits: 312, score: 0.38 }   ← power demand for data centers

getTrendWordsByCompany
Params: { topicSearchQuery: "AI infrastructure", dateRange: { gte: "2026-01-19", lte: "2026-04-19" }, ... }
→ relatedCompanies:
    { name: "NVIDIA",          ticker: "NVDA", companyId: "7892", score: 0.98, positive: 187, negative: 12, neutral: 43, hits: 242 }
    { name: "Microsoft",       ticker: "MSFT", companyId: "1234", score: 0.91, positive: 143, negative: 18, neutral: 51, hits: 212 }
    { name: "Amazon",          ticker: "AMZN", companyId: "2345", score: 0.88, positive: 134, negative: 21, neutral: 47, hits: 202 }
    { name: "Alphabet",        ticker: "GOOGL", companyId: "3456", score: 0.85, positive: 118, negative: 24, neutral: 39, hits: 181 }
    { name: "Meta Platforms",  ticker: "META", companyId: "4567", score: 0.82, positive: 102, negative: 19, neutral: 33, hits: 154 }
    { name: "Eaton",           ticker: "ETN",  companyId: "5678", score: 0.71, positive: 78,  negative: 8,  neutral: 22, hits: 108 }
    { name: "Vertiv",          ticker: "VRT",  companyId: "6789", score: 0.68, positive: 67,  negative: 11, neutral: 19, hits: 97  }

getTrendWordsByDocument
Params: { topicSearchQuery: "AI infrastructure", dateRange: { gte: "2026-01-19", lte: "2026-04-19" }, ... }
→ relatedDocuments:
    { name: "NVIDIA Q4 FY2026 Earnings", date: "2026-02-26", company: "NVIDIA",    refId: "ref_001", positive: 54, negative: 3,  neutral: 9,  hits: 66 }
    { name: "Microsoft Q2 FY2026 Earnings", date: "2026-01-29", company: "Microsoft", refId: "ref_002", positive: 41, negative: 6,  neutral: 14, hits: 61 }
    { name: "Amazon Q4 2025 Earnings",   date: "2026-02-06", company: "Amazon",    refId: "ref_003", positive: 38, negative: 7,  neutral: 11, hits: 56 }
    { name: "Meta Q4 2025 Earnings",     date: "2026-01-29", company: "Meta",      refId: "ref_004", positive: 29, negative: 5,  neutral: 8,  hits: 42 }
    { name: "Alphabet Q4 2025 Earnings", date: "2026-02-04", company: "Alphabet",  refId: "ref_005", positive: 31, negative: 9,  neutral: 12, hits: 52 }

getTrendNetwork
Params: { topicSearchQuery: "AI infrastructure", dateRange: { gte: "2026-01-19", lte: "2026-04-19" }, ... }
→ relatedKeywords:
    { name: "data center", hits: 2134, score: 0.96, explanation: "Physical facilities housing AI compute — the most co-mentioned term." }
    { name: "GPU",         hits: 1876, score: 0.93, explanation: "Graphics processing units used as primary AI training and inference hardware." }
    { name: "power consumption", hits: 987, score: 0.78, explanation: "Electricity demand from AI workloads — flagged as both a cost driver and supply risk." }
    { name: "capital expenditure", hits: 912, score: 0.76, explanation: "Infrastructure build-out spend; hyperscalers are committing multi-year capex cycles." }
    { name: "cooling",     hits: 743, score: 0.71, explanation: "Thermal management for high-density compute racks; liquid cooling gaining share." }
    { name: "inference",   hits: 698, score: 0.69, explanation: "Running trained models in production — distinct from training; growing faster in discussion." }
    { name: "sovereign AI", hits: 421, score: 0.58, explanation: "National governments building AI infrastructure domestically; new demand vector." }
```

### Search-summarizer (same parallel batch)

```
pronto-search-summarizer (subagent_type: prontonlp-plugin:pronto-search-summarizer)

org: "acme"
topicSearchQuery: "AI infrastructure"
sinceDay: 2026-01-19
untilDay: 2026-04-19
documentTypes: ["Earnings Calls"]
instruction: Return ONLY the best verbatim sentences — no JSON, no metadata.
             Prioritize the most important and interesting; exclude weak/off-topic.
             Plain text, one sentence per line, no bullets or headers.
             Each line ends with: [Link: https://acme.prontonlp.com/#/ref/<FULL_ID>]

→ searchResults (saved to ai-infrastructure-search-results.txt):

"We are on track to spend over $60 billion in capital expenditure this year, with the majority going toward AI infrastructure including data centers, networking, and custom silicon." [Link: https://acme.prontonlp.com/#/ref/MSFT_Q2_2026_001]
"Demand for our H100 and B200 GPUs continues to exceed our ability to supply — we are working with partners to expand manufacturing capacity as fast as physically possible." [Link: https://acme.prontonlp.com/#/ref/NVDA_Q4_2026_044]
"We see AI infrastructure as a multi-decade build-out, not a cyclical spend — the transition from CPU-centric to accelerated computing is just beginning." [Link: https://acme.prontonlp.com/#/ref/NVDA_Q4_2026_051]
"Power availability is now the primary constraint on data center expansion in the United States — we are actively working with utilities and exploring nuclear options." [Link: https://acme.prontonlp.com/#/ref/AMZN_Q4_2025_088]
"Every Fortune 500 company is asking us the same question: how do we build the AI infrastructure to remain competitive over the next ten years?" [Link: https://acme.prontonlp.com/#/ref/MSFT_Q2_2026_019]
"We are seeing sovereign AI demand accelerating — governments in Europe, the Middle East, and Southeast Asia are commissioning national AI infrastructure projects." [Link: https://acme.prontonlp.com/#/ref/NVDA_Q4_2026_067]
"Our capital allocation has permanently shifted — AI infrastructure now competes for budget alongside core business investment, and in most planning scenarios it wins." [Link: https://acme.prontonlp.com/#/ref/META_Q4_2025_033]
"We're worried about concentration risk — if three hyperscalers control the majority of AI compute, smaller companies may find it economically impossible to compete." [Link: https://acme.prontonlp.com/#/ref/GOOGL_Q4_2025_112]
```

---

## Step 3: Themes Broker Synthesis

```
pronto-themes-broker (subagent_type: prontonlp-plugin:pronto-themes-broker)

org: "acme"
sinceDay: 2026-01-19
untilDay: 2026-04-19
documentTypes: ["Earnings Calls"]
corpus: ["S&P Transcripts"]
searchResults:
<full content of searchResults from Step 2>

→ Broker returns:

Executive Summary:
  "AI infrastructure spending has entered a structural acceleration phase, with hyperscalers
   committing to multi-year, multi-hundred-billion-dollar capital programs. The conversation
   has evolved from 'whether to invest' to 'how fast can we build.' Power availability and
   GPU supply are the two binding constraints cited most frequently. Sovereign AI demand has
   emerged as a new, underappreciated growth vector..."

Themes:
  1. "Capex acceleration is unprecedented" — evidence from MSFT ($60B+), META, AMZN
  2. "Power and supply constraints are the ceiling" — evidence from AMZN power quote, NVDA supply quote
  3. "Sovereign AI: governments enter the build-out" — evidence from NVDA sovereign AI quote
  4. "Concentration risk concerns are rising" — evidence from GOOGL analyst question

Conclusion:
  "The weight of evidence points to AI infrastructure as a durable multi-year investment
   theme — not a cycle. The limiting factors (power, silicon supply, skilled labor) are
   likely to be resolved over 2–4 years, not quarters..."
```

---

## Step 4: Render

```
report_type: topic
org: acme
filename: ai-infrastructure-research-20260419.html
title: "Topic Research: AI Infrastructure"
subtitle: "Past 90 Days (Jan 19 – Apr 19, 2026) · Earnings Calls"
data:
  meta: { topic: "AI infrastructure", dateRangeLabel: "Past 90 Days",
          sinceDay: "2026-01-19", untilDay: "2026-04-19", companiesCovered: 7 }
  hitsOvertime:
    dates:        ["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025", "Q1 2026"]
    totalHits:    [312, 487, 623, 891, 1043]
    positiveHits: [198, 321, 418, 607, 714]
    negativeHits: [41,  58,  72,  89,  103]
  relatedSectors: [
    { name: "Information Technology", hits: 4821, score: 0.94 },
    { name: "Communication Services", hits: 1203, score: 0.72 },
    ...
  ]
  relatedCompanies: [ { name: "NVIDIA", ticker: "NVDA", companyId: "7892", score: 0.98, positive: 187, negative: 12, neutral: 43, hits: 242 }, ... ]
  relatedDocuments: [ { name: "NVIDIA Q4 FY2026 Earnings", date: "2026-02-26", company: "NVIDIA", refId: "ref_001", positive: 54, negative: 3, neutral: 9, hits: 66 }, ... ]
  relatedKeywords:  [ { name: "data center", hits: 2134, score: 0.96, explanation: "Physical facilities housing AI compute..." }, ... ]
  themes: [
    { title: "Capex acceleration is unprecedented",
      insight: "Hyperscalers are committing multi-year capital programs...",
      marketImplications: "Equipment, power, and cooling suppliers are structural beneficiaries.",
      evidence: [ { text: "We are on track to spend over $60 billion...", company: "Microsoft", refId: "MSFT_Q2_2026_001" } ] },
    ...
  ]
narrative:
  executiveSummary: "AI infrastructure spending has entered a structural acceleration phase..."
  conclusion: "The weight of evidence points to AI infrastructure as a durable multi-year theme..."
```

---

## Key Patterns to Note

- **`getTrendOvertime` uses 15-month window** — all other tools use 90-day default. Never mix up.
- **`corpus: ["S&P Transcripts"]` is required** on every tool call — omitting it returns no results.
- **`timeframeInterval: "quarter"`** is required for `getTrendOvertime` — without it the time series is unusable.
- **All 6 Step 2 calls fire simultaneously** — never wait for one before starting another.
- **Search results written to `.txt`** alongside the HTML so raw evidence is reviewable.
- **Renderer enforces "Hits Overtime"** as the exact chart title — never "Mentions" or "Trends".
