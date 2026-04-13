# Template Guidelines
This document specifies how `pronto-topic-research` should run and structure its HTML output.

## Execution Flow (Current)
1. Step 1: `getOrganization`
2. Step 2 (parallel batch):
   - `getTrendOvertime`
   - `getTrendRelatedSectors`
   - `getTrendWordsByCompany`
   - `getTrendWordsByDocument`
   - `getTrendNetwork`
   - `pronto-search-summarizer` (returns best verbatim sentences as `searchResults`)
3. Persist search output text to `[topic]-search-results.txt`
4. Step 3: call `pronto-themes-broker` with `searchResults`
5. Step 4: compile final HTML

## Themes Broker Delegation Template
Pass results-first input to `pronto-themes-broker`:
```yaml
org: orgName
sinceDay: 2026-01-12
untilDay: 2026-04-12
documentTypes: ["Earnings Calls"]
corpus: ["S&P Transcripts"]
searchResults:
  [paste full search agent sentence output here]
```

## HTML Structure
Use a section-first layout:
```html
<header>
  <h1 class="title">Topic Research: ...</h1>
  <p class="subtitle">Generated: ...</p>
</header>
<section class="executive-summary">...</section>
<section class="charts">...</section>
<section class="tables">...</section>
<section class="themes">...</section>
<section class="conclusion">...</section>
```

## Essential CSS (Light Mode)
```css
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f8fafc; color: #0f172a; padding: 24px; max-width: 1240px; margin: 0 auto; }
header, section { background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px 18px; margin-bottom: 14px; }
.title { margin: 0; }
.subtitle { color: #64748b; margin-top: 6px; }
table { width: 100%; border-collapse: separate; border-spacing: 0; }
```
