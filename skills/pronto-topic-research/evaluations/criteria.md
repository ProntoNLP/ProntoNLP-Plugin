# Topic Research Evaluation Criteria

## Pass / Fail Requirements
When testing `pronto-topic-research` using `skill-creator`, verify these conditions:

### 1. Data Collection Constraints
- Every trend tool request must pass `sinceDay` and `untilDay` explicitly (no omitted date params).
- `getTrendOvertime` must default to `sinceDay` = 15 months ago when the user does not provide a timeframe.
- `getTrendOvertime` must always pass `interval: "quarter"`.
- All other trend tools must default to `sinceDay` = 90 days ago when the user does not provide a timeframe.
- All parallel tools must pass `documentTypes: ["Earnings Calls"]` exactly.
- All parallel tools must pass `corpus: ["S&P Transcripts"]` exactly.
- Tool names must precisely match the 5 listed native trend tools plus the `pronto-search-summarizer` subagent. NO usage of `searchSectors`.

### 2. Charting and Visualization
- MUST inject pure Light Mode CSS.
- MUST use a clean section-first HTML structure (title, executive summary, charts, tables, themes, conclusion).
- MUST explicitly build a Line Chart titled "Hits Overtime". Ensure tooltips show Positive & Negative breakdowns.
- Overtime chart MUST map the older year's dataset array natively as a `borderDash` overlapping line.

### 3. Agent Protocol
- Step 2 must run `prontonlp-plugin:pronto-search-summarizer` in parallel with the 5 trend tools.
- Step 2 search-agent prompt must request best verbatim sentences only (no raw JSON/metadata blob) and maximize relevant/high-quality coverage while excluding weak/off-topic results.
- Step 2 search-agent output format must be plain text with one sentence per line, no bullets/numbering/headers, and one citation link per line.
- Step 2 search-agent output must be persisted to `[topic]-search-results.txt`.
- Step 3 `pronto-themes-broker` call must include `searchResults` from Step 2 and must not pass `topicSearchQuery`.
- `pronto-themes-broker` is synthesis-only and must not spawn subagents, invoke skills, or recurse into `prontonlp-plugin:pronto-topic-research`.
