# Compare Companies — Tool & Metrics Reference

This file documents the exact metrics to extract from each `pronto-company-intelligence` invocation and how they map to the comparison report.

---

## Invocation Pattern

Fire one invocation per company, all in parallel:

```
Skill: pronto-company-intelligence
Args: "[Company] — comparison mode: return raw metrics only, no HTML report.
Needed: companyId, sector, sentiment scores per quarter (Q1–Q4), investment scores per quarter,
stock reactions per earnings call, YTD/6M/1Y stock % change, revenue/EPS/EBITDA/FCF forward estimates,
exec avg sentiment, analyst avg sentiment, CEO sentiment, CFO sentiment, exec-analyst gap,
top 3 trending topics, top 3 risk factors, most bullish analyst (name + score),
most bearish analyst (name + score)."
```

---

## Metrics Capture Sheet

For each company, record these fields immediately after its invocation completes:

### Identity
| Field | Source tool | Notes |
|-------|------------|-------|
| `companyId` | getCompanyDescription | Required for deduplication |
| `sector` | getCompanyDescription | Used to flag cross-sector comparisons |
| `subSector` | getCompanyDescription | |
| `ticker` | getCompanyDescription | Used in report title |

### Sentiment & Investment (per quarter)
| Field | Source tool | Notes |
|-------|------------|-------|
| `sentimentScore_Q1..Q4` | getAnalytics per quarter | Range: −1.0 to +1.0 |
| `sentimentDirection` | computed | RISING if Q4 > Q1, FALLING if Q4 < Q1 |
| `investmentScore_Q1..Q4` | getAnalytics per quarter | Range: 0–10 |
| `investmentDirection` | computed | RISING / FALLING |
| `stockReaction_Q1..Q4` | getStockPrices around call | % change 1 week after vs before |
| `positiveCallCount` | computed | Count of quarters where stockReaction > 0 |

### Stock Performance
| Field | Source tool | Notes |
|-------|------------|-------|
| `stockChangeYTD` | getStockChange | % |
| `stockChange6M` | getStockChange | % |
| `stockChange1Y` | getStockChange | % |

### Financial Estimates (forward consensus)
| Field | Source tool | Notes |
|-------|------------|-------|
| `revenueGrowthFwd` | getPredictions (revenue) | % YoY growth |
| `epsGaapFwd` | getPredictions (epsGaap) | Value |
| `ebitdaFwd` | getPredictions (ebitda) | Value |
| `fcfFwd` | getPredictions (freeCashFlow) | Value |

### Speaker Sentiment
| Field | Source tool | Notes |
|-------|------------|-------|
| `execAvgSentiment` | getSpeakers (Executives) | Average across all execs |
| `analystAvgSentiment` | getSpeakers (Analysts) | Average across all analysts |
| `execAnalystGap` | computed | execAvg − analystAvg |
| `ceoSentiment` | getSpeakers (Executives_CEO) | |
| `cfoSentiment` | getSpeakers (Executives_CFO) | |
| `mostBullishAnalyst` | getSpeakers (Analysts, desc) | Name + firm + score |
| `mostBearishAnalyst` | getSpeakers (Analysts, asc) | Name + firm + score |

### Topics & Risks
| Field | Source tool | Notes |
|-------|------------|-------|
| `topTopics` | getTrends | Top 3 by score |
| `topRisks` | getCompanyDescription + getAnalytics negative events | Top 3 |

---

## Scoring Matrix

Score each company per dimension. Winner = highest value unless noted.

| Dimension | Metric used | Winner rule |
|-----------|------------|-------------|
| Sentiment Trend | `sentimentScore_Q4` + direction | Highest score AND RISING direction |
| Investment Score | `investmentScore_Q4` | Highest |
| Stock Performance | `stockChangeYTD` | Highest % |
| Earnings Call Reaction | `positiveCallCount` / total | Most positive reactions |
| Analyst Consensus | `analystAvgSentiment` | Highest |
| Revenue Growth | `revenueGrowthFwd` | Highest % |
| EPS Outlook | `epsGaapFwd` | Highest |
| Exec Confidence | `execAvgSentiment` | Highest |
| Risk Profile | `topRisks` severity | Fewest / least severe |

Tally wins per company. Most wins = overall leader.

**Tie-breaker**: If two companies tie on win count, the one with the higher investment score is the leader.

---

## Cross-Company Topic Comparison

After all invocations complete, compare `topTopics` arrays:

```
Shared topics  = topics appearing in ALL companies' top-3 lists → macro theme
Unique topics  = topics appearing in only one company's list    → company-specific narrative
Risk overlap   = risk factors appearing in 2+ companies         → systemic sector risk
```

Always flag:
- If 2+ companies share a risk topic → "Systemic risk: [topic] affects all compared companies"
- If one company has a risk the others don't → "Idiosyncratic risk for [Company]: [topic]"

---

## Enum Reference (same as company-intelligence)

**Speaker Types**: `Analysts` | `Executives` | `Executives_CEO` | `Executives_CFO` | `Executives_COO` | `Executives_CTO` | `Executives_VP`

**Document Types**: `Earnings Calls` | `10-K` | `10-Q`

**Prediction Metrics**: `revenue` | `epsGaap` | `ebitda` | `netIncomeGaap` | `freeCashFlow` | `capitalExpenditure`

**Sentiment Score Range**: −1.0 (very negative) → +1.0 (very positive). Above +0.10 = notably positive. Below −0.10 = notably negative.

**Investment Score Range**: 0–10. Above 7.0 = strong buy signal. Below 4.0 = weak/bearish.
