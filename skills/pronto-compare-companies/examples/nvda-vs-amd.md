# Example: NVDA vs AMD Comparison

**User prompt:** "Compare NVDA vs AMD"

---

## Step 1: Parse Companies

- Company A: **NVDA** (NVIDIA Corporation)
- Company B: **AMD** (Advanced Micro Devices)
- Mode: Full Comparison (default — no narrow scope signal)

---

## Step 2: Parallel Skill Invocations

Both fired simultaneously:

```
Skill: pronto-company-intelligence
Args: "NVDA — comparison mode: collect all data and metrics but do not render the HTML report yet.
Return raw findings: sentiment scores per quarter (Q1–Q4), investment scores per quarter,
stock performance (YTD/6M/1Y), analyst estimates (revenue, EPS, EBITDA, FCF forward),
exec avg sentiment, analyst avg sentiment, CEO sentiment, CFO sentiment,
exec-analyst gap, top 3 trending topics, top 3 risk factors,
most bullish analyst (name + firm + score), most bearish analyst (name + firm + score)."
```

```
Skill: pronto-company-intelligence
Args: "AMD — comparison mode: collect all data and metrics but do not render the HTML report yet.
Return raw findings: sentiment scores per quarter (Q1–Q4), investment scores per quarter,
stock performance (YTD/6M/1Y), analyst estimates (revenue, EPS, EBITDA, FCF forward),
exec avg sentiment, analyst avg sentiment, CEO sentiment, CFO sentiment,
exec-analyst gap, top 3 trending topics, top 3 risk factors,
most bullish analyst (name + firm + score), most bearish analyst (name + firm + score)."
```

---

## Step 3: Captured Metrics

### NVDA

| Field | Value |
|-------|-------|
| Sector | Information Technology — Semiconductors |
| Ticker | NVDA |
| Sentiment Q1 | 0.52 |
| Sentiment Q2 | 0.58 |
| Sentiment Q3 | 0.61 |
| Sentiment Q4 | 0.67 |
| Sentiment Direction | RISING |
| Investment Q1 | [raw] |
| Investment Q2 | [raw] |
| Investment Q3 | [raw] |
| Investment Q4 | [raw] |
| Investment Direction | RISING |
| Stock Reaction — Q1 | +4.2% |
| Stock Reaction — Q2 | +6.1% |
| Stock Reaction — Q3 | +8.3% |
| Stock Reaction — Q4 | +5.7% |
| Positive Call Count | 4 of 4 |
| Stock YTD | +38.4% |
| Stock 6M | +22.1% |
| Stock 1Y | +61.8% |
| Revenue Fwd ($B) | 48.2 |
| EPS GAAP Fwd | 2.94 |
| EBITDA Fwd ($B) | 29.7 |
| FCF Fwd ($B) | 26.1 |
| Exec Avg Sentiment | 0.61 |
| Analyst Avg Sentiment | 0.54 |
| Exec-Analyst Gap | +0.07 |
| CEO Sentiment | 0.68 |
| CFO Sentiment | 0.59 |
| Most Bullish Analyst | Sarah Chen, Goldman Sachs, 0.72 |
| Most Bearish Analyst | Mark Torres, Bernstein, 0.31 |
| Top Topics | AI Accelerators, Data Center, Sovereign AI |
| Top Risks | Export Controls, Supply Chain Concentration, Competition from AMD/custom silicon |

### AMD

| Field | Value |
|-------|-------|
| Sector | Information Technology — Semiconductors |
| Ticker | AMD |
| Sentiment Q1 | 0.41 |
| Sentiment Q2 | 0.38 |
| Sentiment Q3 | 0.43 |
| Sentiment Q4 | 0.39 |
| Sentiment Direction | FALLING |
| Investment Q1 | [raw] |
| Investment Q2 | [raw] |
| Investment Q3 | [raw] |
| Investment Q4 | [raw] |
| Investment Direction | FALLING |
| Stock Reaction — Q1 | +1.8% |
| Stock Reaction — Q2 | −2.3% |
| Stock Reaction — Q3 | +0.9% |
| Stock Reaction — Q4 | −1.4% |
| Positive Call Count | 2 of 4 |
| Stock YTD | −12.3% |
| Stock 6M | −8.7% |
| Stock 1Y | −4.1% |
| Revenue Fwd ($B) | 8.9 |
| EPS GAAP Fwd | 1.12 |
| EBITDA Fwd ($B) | 3.2 |
| FCF Fwd ($B) | 2.8 |
| Exec Avg Sentiment | 0.44 |
| Analyst Avg Sentiment | 0.38 |
| Exec-Analyst Gap | +0.06 |
| CEO Sentiment | 0.48 |
| CFO Sentiment | 0.41 |
| Most Bullish Analyst | Priya Kapoor, Morgan Stanley, 0.61 |
| Most Bearish Analyst | David Lee, UBS, 0.18 |
| Top Topics | AI Accelerators, PC Recovery, MI300 Ramp |
| Top Risks | Competition from NVDA, Data Center ramp pace, PC market softness |

---

## Step 3: Scoring Matrix

| Dimension | NVDA | AMD | Winner |
|-----------|------|-----|--------|
| Sentiment Trend | 0.67 ↑ RISING | 0.39 ↓ FALLING | 🏆 NVDA |
| Investment Score | [raw] | [raw] | 🏆 NVDA |
| Stock Performance (YTD) | +38.4% | −12.3% | 🏆 NVDA |
| Earnings Call Reaction | 4 of 4 | 2 of 4 | 🏆 NVDA |
| Analyst Consensus | 0.54 | 0.38 | 🏆 NVDA |
| Revenue Growth (fwd) | $48.2B | $8.9B | 🏆 NVDA |
| EPS Outlook | $2.94 | $1.12 | 🏆 NVDA |
| Exec Confidence | 0.61 | 0.44 | 🏆 NVDA |
| Risk Profile | 3 risks (systemic) | 3 risks (1 NVDA-specific) | 🏆 NVDA |
| **Overall Wins** | **9 / 9** | **0 / 9** | **🏆 NVDA** |

**Divergence signal:** AMD has a relatively high investment score despite its stock decline (−12.3% YTD) — the gap between fundamental signals and price performance suggests potential upside if the MI300 data center ramp materializes.

---

## Step 4: Shared Topics & Risks

**Shared topics:** AI Accelerators (both top-3 → macro theme for the semiconductor sector)

**Unique to NVDA:** Sovereign AI, Data Center (dominant position)

**Unique to AMD:** PC Recovery, MI300 Ramp (company-specific execution story)

**Systemic risks:** Competition in AI accelerators (affects both)

**Idiosyncratic risk for AMD:** PC market softness — NVDA is not exposed to this

---

## Step 4: Report Output (structure summary)

The report renders as inline HTML with:

- **Header:** NVDA vs AMD — Comparison Report | Generated: [date] | 2 Companies | Past Year
- **Section 1:** Scorecard — NVDA wins 9/9 rows, highlighted green; AMD cells highlighted red
- **Section 2:** Quarter cards — NVDA (blue top border, leader class), AMD (purple top border)
  - Callout: "📊 NVDA sentiment RISING (0.52 → 0.67) while AMD is FALLING (0.41 → 0.39) — diverging trajectories"
- **Section 3:** Grouped bar chart — NVDA dominates all three periods (YTD, 6M, 1Y)
- **Section 4:** Financial table — NVDA leads all four rows; revenue gap is 5.4×
- **Section 5:** Speaker chart + table — NVDA exec avg 0.61 vs AMD 0.44; both show positive exec-analyst gap
- **Section 6:** Topics — AI Accelerators shared; PC Recovery is AMD-specific narrative
- **Section 7:** Risk table — PC market softness marked ✅ for AMD, — for NVDA (idiosyncratic)
- **Section 8:** Verdict
  - Leader: NVDA — wins all 9 dimensions
  - Undervalued signal: AMD — high investment score relative to stock down 12.3%; MI300 ramp is the catalyst to watch
  - Highest risk: AMD — PC exposure is idiosyncratic vs NVDA
  - Bottom line: NVDA, because sentiment, investment score, and stock all align with an accelerating data center build-out that AMD is still trying to break into
