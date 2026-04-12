# Topic Research Evaluation Criteria

## Pass / Fail Requirements
When testing `pronto-topic-research` using `skill-creator`, verify these conditions:

### 1. Data Collection Constraints
- `getTrendOvertime` must automatically offset the `sinceDay` 1 year backward.
- All parallel tools must pass `documentTypes: ["Earnings Calls"]` exactly.
- Tool names must precisely match the 5 listed natively. NO usage of `searchSectors`.

### 2. Charting and Visualization
- MUST inject pure Light Mode CSS.
- MUST explicitly build a Line Chart titled "Hits Overtime". Ensure tooltips show Positive & Negative breakdowns.
- Overtime chart MUST map the older year's dataset array natively as a `borderDash` overlapping line.

### 3. Agent Protocol
- When invoking `pronto-broker.md`, AI must send EXCLUSIVELY the structured keys without any conversational padding text at all.
