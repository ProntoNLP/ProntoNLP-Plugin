# ProntoNLP Rendering Conventions

Reference documentation for the shared rendering contract. The `pronto-html-renderer` agent is the single implementation of all rules below. Skills **must not** reimplement any of these — they only pass structured data and call the renderer.

---

## Citation & Company Links

| Kind | Format |
|------|--------|
| Evidence / quote citation | `https://{org}.prontonlp.com/#/ref/<FULL_ID>` |
| Company name link | `https://{org}.prontonlp.com/#/ref/$COMPANY<numericId>` |

- `{org}` is always resolved by the calling skill via `getOrganization`. Never hardcode.
- Every quote rendered must have a `[source]` citation link unless the quote explicitly carries no `refId`.
- Never emit a bare ID or an unsubstituted `{org}` token into the final HTML.

---

## Numeric Display

| Field type | Rule |
|------------|------|
| `investmentScore`, `sentimentScore` | Raw 0.0–1.0 — show `0.71`, never `7.1` or `7.1/10` |
| `*ScoreChange` | With sign and `%` — `+4.2%`, `-1.8%` |
| Stock `%Change` | With sign and `%` |
| Market cap | `$1.2T` / `$45.3B` / `$3.1B` / `$850M` |
| Counts | Integer, no decimals |

---

## Color Rule (platform palette)

| Condition | Color | Platform source |
|-----------|-------|-----------------|
| value > 0 | `#6AA64A` — green | `$color-secondary-400` |
| value < 0 | `#ED4545` — red | `$color-red-400` |
| value = 0 | `#7B96A3` — muted | `$color-neutral-400` |

Applies to all signed numbers: stock changes, score deltas, event counts.

---

## Sentiment Labels (no emojis)

| Score | Label |
|-------|-------|
| ≥ 0.6 | `BULLISH` |
| 0.2 – 0.59 | `Positive` |
| −0.19 – 0.19 | `Neutral` |
| −0.59 – −0.2 | `Negative` |
| ≤ −0.6 | `BEARISH` |

---

## Direction Labels

- Quarter-over-quarter change: `▲ RISING` (green) / `▼ FALLING` (red)
- Forecast tone: `IMPROVING` / `DETERIORATING`
- Determined by comparing the earliest vs. latest available value.

---

## Topic-Report Word Rules

- Section titled exactly **"Hits Overtime"**.
- The words **"Mentions"** and **"Trends"** must never appear in any section heading, chart title, or column label in the topic report.

---

## Section Resilience

Every section must survive its siblings being absent. If a `data` key is absent or an empty array, emit nothing for that section — no heading, no placeholder. Sections must not reference each other's DOM elements.

---

## Output Format

- Standalone HTML file: full `<!DOCTYPE html>` document.
- Chart.js loaded from `https://cdn.jsdelivr.net/npm/chart.js`.
- CSS from `design-tokens.css` embedded inline in `<head>`.
- All chart JS in a single `<script>` block at end of `<body>`.
- Written to the current working directory.

---

## Renderer Tool Restriction

The `pronto-html-renderer` agent is allowed **only**:
- `Read` — to load `pronto-html-renderer/design-tokens.css`
- `Write` — to save the final HTML file

Forbidden: every MCP tool, every other agent, `Bash`, `Edit`, `Glob`, `Grep`, `WebFetch`.

---

## Forbidden Across All Skills

Never call these from inside any skill — they are user-triggered visualizations only:
- `getMindMap`
- `getTermHeatmap`
- `deep-research`
