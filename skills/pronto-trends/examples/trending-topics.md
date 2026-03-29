# Example: Trending Topics — "What themes are rising in the tech sector right now?"

Workflow showing getTrends output interpretation and response format.

---

## Batch 1: Get Trends

```
Tool: getTrends
Params: {
  sectors: ["Information Technology"],
  sinceDay: "2025-12-26",
  untilDay: "2026-03-26",
  sortBy: "score",
  sortOrder: "desc",
  limit: 20
}
→ trends:
    { name: "AI Agents",            score: 95, hits: 412, change: +72% }
    { name: "Apple Intelligence",   score: 92, hits: 312, change: +45% }
    { name: "Data Center Capacity", score: 88, hits: 298, change: +38% }
    { name: "Inference Workloads",  score: 84, hits: 267, change: +55% }
    { name: "Cloud Cost Savings",   score: 79, hits: 243, change: +22% }
    { name: "Cybersecurity Spend",  score: 74, hits: 198, change: +18% }
    { name: "Vision Pro",           score: 68, hits: 187, change: -12% }
    { name: "Chip Shortage",        score: 61, hits: 143, change: -8%  }
    { name: "China Revenue",        score: 57, hits: 131, change: -15% }
    { name: "PC Recovery",          score: 52, hits: 112, change: +5%  }
```

---

## Compile: Response

```markdown
## Trending Topics — Information Technology Sector

**Top 10 themes over the past 90 days:**

| Topic | Score | Hits | % Change | Direction |
|-------|-------|------|----------|-----------|
| AI Agents | 95 | 412 | +72% | RISING ↑ |
| Apple Intelligence | 92 | 312 | +45% | RISING ↑ |
| Inference Workloads | 84 | 267 | +55% | RISING ↑ |
| Data Center Capacity | 88 | 298 | +38% | RISING ↑ |
| Cloud Cost Savings | 79 | 243 | +22% | RISING ↑ |
| Cybersecurity Spend | 74 | 198 | +18% | RISING ↑ |
| PC Recovery | 52 | 112 | +5% | RISING ↑ |
| Chip Shortage | 61 | 143 | -8% | DECLINING ↓ |
| Vision Pro | 68 | 187 | -12% | DECLINING ↓ |
| China Revenue | 57 | 131 | -15% | DECLINING ↓ |

**Fastest-rising themes:**
- **AI Agents** (+72%) — Dominating executive commentary; management teams are actively discussing autonomous agent deployment timelines
- **Inference Workloads** (+55%) — Shift from training to inference is a key inflection point driving GPU and data center demand
- **Apple Intelligence** (+45%) — On-device AI feature discussions accelerating ahead of new hardware cycles

**Declining themes worth watching:**
- **China Revenue** (−15%) — Fading from discussion may reflect reduced guidance commentary, not necessarily lower exposure
- **Vision Pro** (−12%) — Post-launch hype cooling; management reducing emphasis after initial cycle
```

---

## Tool Call Summary

| Batch | Calls | What |
|-------|-------|------|
| 1 | 1 | getTrends |
| **Total** | **1** | **Single call** |
