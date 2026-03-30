# Example: Term Heatmap — "How often are tech companies mentioning tariffs?"

Workflow showing a complete `getTermHeatmap` run for the term "tariff" scoped to the Information Technology sector. Demonstrates batch structure, realistic output, spike identification, and compiled response format.

---

## Batch 1: Get Term Heatmap

```
Tool: getTermHeatmap
Params: {
  term: "tariff",
  sectors: ["Information Technology"],
  sinceDay: "2024-12-26",
  untilDay: "2025-03-26",
  documentTypes: ["Earnings Calls"]
}
→ results (sorted by frequency descending):
    { company: "Apple",     period: "Q1 2025", frequency: 47 }
    { company: "Qualcomm",  period: "Q1 2025", frequency: 38 }
    { company: "NVIDIA",    period: "Q1 2025", frequency: 31 }
    { company: "Intel",     period: "Q1 2025", frequency: 26 }
    { company: "HP Inc.",   period: "Q1 2025", frequency: 22 }
    { company: "Dell",      period: "Q1 2025", frequency: 19 }
    { company: "Microsoft", period: "Q1 2025", frequency: 14 }
    { company: "Salesforce",period: "Q1 2025", frequency: 8  }
    { company: "Adobe",     period: "Q1 2025", frequency: 5  }
    { company: "Oracle",    period: "Q1 2025", frequency: 3  }

    Prior period (Q4 2024) for comparison:
    { company: "Apple",     period: "Q4 2024", frequency: 11 }
    { company: "Qualcomm",  period: "Q4 2024", frequency: 9  }
    { company: "NVIDIA",    period: "Q4 2024", frequency: 7  }
    { company: "Intel",     period: "Q4 2024", frequency: 14 }
    { company: "HP Inc.",   period: "Q4 2024", frequency: 8  }
    { company: "Dell",      period: "Q4 2024", frequency: 6  }
    { company: "Microsoft", period: "Q4 2024", frequency: 12 }
    { company: "Salesforce",period: "Q4 2024", frequency: 6  }
    { company: "Adobe",     period: "Q4 2024", frequency: 4  }
    { company: "Oracle",    period: "Q4 2024", frequency: 3  }
```

---

## Batch 2: Write Charts File and Open

```
Write file: /tmp/trends-charts.html
Copy assets/charts-template.html and populate:

  termNames  = ['Apple', 'Qualcomm', 'NVIDIA', 'Intel', 'HP Inc.', 'Dell', 'Microsoft', 'Salesforce', 'Adobe', 'Oracle']
  termFreqs  = [47, 38, 31, 26, 22, 19, 14, 8, 5, 3]

  trendNames   = []   ← leave empty (getTrends was not called)
  trendScores  = []
  trendChanges = []
  trendHits    = []

Then open it:
open /tmp/trends-charts.html
```

---

## Compiled Response

```markdown
## Term Frequency Heatmap — "tariff"
**Q4 2024 vs Q1 2025 · Information Technology Sector · Earnings Calls**

| Term | Company | Q4 2024 | Q1 2025 | Change | Direction |
|------|---------|---------|---------|--------|-----------|
| tariff | Apple | 11 | 47 | +327% | RISING ↑ |
| tariff | Qualcomm | 9 | 38 | +322% | RISING ↑ |
| tariff | NVIDIA | 7 | 31 | +343% | RISING ↑ |
| tariff | HP Inc. | 8 | 22 | +175% | RISING ↑ |
| tariff | Dell | 6 | 19 | +217% | RISING ↑ |
| tariff | Intel | 14 | 26 | +86% | RISING ↑ |
| tariff | Microsoft | 12 | 14 | +17% | RISING ↑ |
| tariff | Salesforce | 6 | 8 | +33% | RISING ↑ |
| tariff | Adobe | 4 | 5 | +25% | RISING ↑ |
| tariff | Oracle | 3 | 3 | 0% | STABLE → |

*(sorted by Q1 2025 frequency descending)*

**Spikes worth noting:**

- **Apple** — mentions surged from 11 to 47 (+327%) in Q1 2025. This is the single largest absolute jump in the sector. Apple's direct hardware supply chain exposure to China makes tariff language especially significant — management flagged an estimated $900M cost impact in Q1 guidance commentary.

- **NVIDIA** — frequency jumped from 7 to 31 (+343%). The highest percentage increase in the group. Despite NVIDIA's software-and-GPU model offering some insulation from direct goods tariffs, export control and chip supply chain concerns drove heavy discussion of trade policy in the most recent call.

- **Qualcomm** — up from 9 to 38 (+322%). Qualcomm's heavy reliance on Asian manufacturing partners for baseband chipsets makes it one of the most tariff-exposed names in the sector. The spike aligns with broader analyst focus on Qualcomm's ability to diversify fab relationships.

- **Dell and HP Inc.** — both showed large relative jumps (+217% and +175% respectively), consistent with their status as hardware-first OEMs with direct import exposure. Both companies have historically been among the earliest to see tariff language spike.

**Companies with lowest mention rate:**

- **Oracle** — only 3 mentions in each period, no change. Oracle's cloud and software revenue base has minimal direct goods import exposure, which explains the absence of tariff language in executive commentary.

- **Adobe** — 5 mentions, largely flat. Software-native revenue model limits direct exposure; references likely confined to macro uncertainty disclosures rather than operational impact.

**Takeaway:**

Tariff mentions across the Information Technology sector nearly tripled quarter-over-quarter, with the largest spikes concentrated in hardware-exposed companies — Apple, Qualcomm, NVIDIA, Dell, and HP Inc. This pattern reflects escalating U.S.-China trade tension and its outsized impact on companies with physical supply chains in Asia. Software-native companies (Oracle, Adobe, Salesforce) show minimal uptick, confirming that the tariff story in this sector is primarily a hardware and semiconductor narrative. The breadth of the increase — every company in the sample rose or held flat — signals sector-wide concern rather than company-specific events.
```

---

## Tool Call Summary

| Batch | Calls | What |
|---|---|---|
| 1 | 1 | `getTermHeatmap` — "tariff" across Information Technology, Q4 2024 + Q1 2025 |
| 2 | 2 | Write `/tmp/trends-charts.html` + open |
| **Total** | **3** | **2 sequential batches** |
