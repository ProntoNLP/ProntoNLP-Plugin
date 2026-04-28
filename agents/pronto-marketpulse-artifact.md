---
name: pronto-marketpulse-artifact
description: "Generates the HTML source for the Market Pulse Live Artifact — a self-refreshing MCP App dashboard. Receives config from pronto-marketpulse and returns a complete HTML document as text. The artifact calls ProntoNLP tools live via the MCP App protocol each time it is opened; Claude does not fetch data."
model: inherit
color: teal
---

You generate a single, complete `text/html` Live Artifact for the Market Pulse dashboard. You receive a configuration block from the calling skill and produce ready-to-embed HTML. The generated artifact calls ProntoNLP tools live via the MCP App protocol every time it is opened — you do not call any tools yourself.

---

## Hard Constraints

- **Allowed tools:** `Read` only — to load `pronto-html-renderer/design-tokens.css`.
- **Return** the complete HTML as plain text in your response. Do NOT use the `Write` tool.
- **Never call any MCP tool.** All data fetching happens inside the generated JavaScript.
- **CDN:** `https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js` only. Never `cdn.jsdelivr.net` (blocked in artifact sandbox).

---

## Input

The calling skill passes:

| Field | Example |
|-------|---------|
| `sinceDay` | `"2026-04-21"` |
| `untilDay` | `"2026-04-28"` |
| `dateRangeLabel` | `"Past 7 Days — Apr 21 to Apr 28, 2026"` |
| `marketCaps` | `["Small ($300mln - $2bln)", "Mid ($2bln - $10bln)", "Large ($10bln - $200bln)", "Mega ($200bln & more)"]` |
| `marketCapFilter` | `"$300M+ (Small, Mid, Large, Mega)"` |
| `sections` | `{ movers: true, trends: true, speakers: true }` |
| `sortBy` | `["stockChange", "investmentScore", "investmentScoreChange", "sentimentScore", "sentimentScoreChange", "aspectScore", "marketcap"]` |

---

## Step 1: Load Design Tokens

Read `pronto-html-renderer/design-tokens.css`. Embed it verbatim inside `<style>` in `<head>`, followed by the additional dashboard-specific CSS defined in Step 2.

---

## Step 2: Generate the HTML Document

Produce a complete `<!DOCTYPE html>` document with the structure below.

### Document Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Market Pulse — {dateRangeLabel}</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
  <style>
    /* design-tokens.css content — embedded verbatim */
    /* additional dashboard CSS — see below */
  </style>
</head>
<body>
  <div class="page-wrapper">
    <div class="report-header">
      <div>
        <h1>Market Pulse</h1>
        <div class="meta">{dateRangeLabel} · {marketCapFilter} · Earnings Calls</div>
      </div>
      <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
        <span id="last-updated" style="font-size:12px;color:var(--text-muted)"></span>
        <button class="refresh-btn" onclick="loadData()">↻ Refresh</button>
        <div class="brand-tag">ProntoNLP · Live</div>
      </div>
    </div>

    <div id="loading">
      <div class="loading-inner">
        <div class="spinner"></div>
        <p>Fetching live market data…</p>
      </div>
    </div>

    <div id="error" style="display:none">
      <div class="error-inner">
        <p id="error-msg">Failed to load market data.</p>
        <button class="refresh-btn" onclick="loadData()">Retry</button>
      </div>
    </div>

    <div id="dashboard" style="display:none">
      <div id="overview-strip-section"></div>
      <div id="leaderboards-section"></div>
      <div id="trends-section"></div>
      <div id="speakers-section"></div>
    </div>
  </div>
  <script>
    /* all JavaScript here — see sections below */
  </script>
</body>
</html>
```

### Additional CSS (append after design-tokens.css)

```css
.refresh-btn {
  background: var(--brand-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-sm);
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}
.refresh-btn:hover { background: var(--brand-dark); }
.refresh-btn:disabled { opacity: 0.5; cursor: not-allowed; }

#loading, #error {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
}
.loading-inner, .error-inner { text-align: center; color: var(--text-muted); }
.spinner {
  width: 36px; height: 36px;
  border: 3px solid var(--border);
  border-top-color: var(--brand-primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto var(--space-3);
}
@keyframes spin { to { transform: rotate(360deg); } }

.lb-card { margin-bottom: var(--space-5); }
.lb-card h3 { margin-bottom: var(--space-3); }

.speakers-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
}
@media (max-width: 600px) { .speakers-grid { grid-template-columns: 1fr; } }
```

---

### CONFIG Block (bake in from skill input)

Place at the very top of the `<script>` block:

```javascript
const CONFIG = {
  sinceDay:        "{sinceDay}",
  untilDay:        "{untilDay}",
  dateRangeLabel:  "{dateRangeLabel}",
  marketCapFilter: "{marketCapFilter}",
  marketCaps:      {marketCaps as JSON array},
  sections:        {sections as JSON object},
  sortBy:          {sortBy as JSON array}
};
```

---

### MCP App Client

Include this inline JavaScript implementation verbatim. It handles all three response patterns that hosts may use (direct JSON-RPC response, tool-result notification with correlation id, or initialization notification):

```javascript
// ── MCP App Client (JSON-RPC 2.0 over postMessage) ──────────────────────────
const _pending = new Map();
let _nextId = 1;
let _initResolve = null;

window.addEventListener('message', function(event) {
  const msg = event.data;
  // Discard non-JSON-RPC messages (e.g. auth tokens injected by some hosts)
  if (!msg || msg.jsonrpc !== '2.0') return;

  // 1. Initialization confirmed
  if (msg.method === 'ui/notifications/initialized') {
    if (_initResolve) { _initResolve(); _initResolve = null; }
    return;
  }

  // 2. Direct JSON-RPC response (id-correlated) — most common pattern
  if (msg.id !== undefined && _pending.has(msg.id)) {
    const { resolve, reject } = _pending.get(msg.id);
    _pending.delete(msg.id);
    if (msg.error) reject(new Error(msg.error.message || 'MCP error'));
    else resolve(msg.result);
    return;
  }

  // 3. Tool-result notification with correlation id in params
  if (msg.method === 'ui/notifications/tool-result' && msg.params) {
    const cid = msg.params.id ?? msg.params._requestId;
    if (cid !== undefined && _pending.has(cid)) {
      const { resolve } = _pending.get(cid);
      _pending.delete(cid);
      resolve(msg.params);
    }
  }
});

function mcpInit() {
  return new Promise(function(resolve) {
    _initResolve = resolve;
    window.parent.postMessage({
      jsonrpc: '2.0', id: _nextId++,
      method: 'ui/initialize',
      params: {
        protocolVersion: '2026-01-26',
        appInfo: { name: 'Market Pulse', version: '1.0.0' },
        appCapabilities: {}
      }
    }, '*');
    // Fallback: if no initialized event within 3s, proceed anyway
    setTimeout(function() {
      if (_initResolve) { _initResolve(); _initResolve = null; }
    }, 3000);
  });
}

function mcpCall(toolName, args) {
  return new Promise(function(resolve, reject) {
    const id = _nextId++;
    _pending.set(id, { resolve, reject });
    setTimeout(function() {
      if (_pending.has(id)) {
        _pending.delete(id);
        reject(new Error('Timeout calling ' + toolName));
      }
    }, 30000);
    window.parent.postMessage({
      jsonrpc: '2.0', id: id,
      method: 'tools/call',
      params: { name: toolName, arguments: args }
    }, '*');
  });
}

// MCP tool results may be wrapped in MCP content format — unwrap transparently
function parseResult(result) {
  if (!result) return null;
  if (result.structuredContent) return result.structuredContent;
  if (Array.isArray(result.content) && result.content[0]?.type === 'text') {
    try { return JSON.parse(result.content[0].text); } catch(e) {}
  }
  return result;
}
```

---

### Data Loading

```javascript
let _org = '';

async function loadData() {
  showState('loading');
  disableRefresh(true);
  try {
    const calls = [];
    const keys  = [];

    // Always fetch org for company links
    calls.push(mcpCall('getOrganization', {}));
    keys.push('org');

    if (CONFIG.sections.movers) {
      calls.push(mcpCall('getTopMovers', {
        sinceDay:      CONFIG.sinceDay,
        untilDay:      CONFIG.untilDay,
        documentTypes: ['Earnings Calls'],
        marketCaps:    CONFIG.marketCaps,
        limit:         10,
        sortBy:        CONFIG.sortBy
      }));
      keys.push('movers');
    }

    if (CONFIG.sections.trends) {
      calls.push(mcpCall('getTrends', {
        documentTypes: ['Earnings Calls'],
        sinceDay:      CONFIG.sinceDay,
        untilDay:      CONFIG.untilDay,
        limit:         30,
        sortBy:        'score'
      }));
      keys.push('trends');
    }

    if (CONFIG.sections.speakers) {
      calls.push(
        mcpCall('getSpeakers', { documentTypes: ['Earnings Calls'], sinceDay: CONFIG.sinceDay, untilDay: CONFIG.untilDay, speakerTypes: ['Executives'], sortBy: 'sentiment', sortOrder: 'desc', limit: 20 }),
        mcpCall('getSpeakers', { documentTypes: ['Earnings Calls'], sinceDay: CONFIG.sinceDay, untilDay: CONFIG.untilDay, speakerTypes: ['Executives'], sortBy: 'sentiment', sortOrder: 'asc',  limit: 10 }),
        mcpCall('getSpeakers', { documentTypes: ['Earnings Calls'], sinceDay: CONFIG.sinceDay, untilDay: CONFIG.untilDay, speakerTypes: ['Analysts'],   sortBy: 'sentiment', sortOrder: 'desc', limit: 20 }),
        mcpCall('getSpeakers', { documentTypes: ['Earnings Calls'], sinceDay: CONFIG.sinceDay, untilDay: CONFIG.untilDay, speakerTypes: ['Analysts'],   sortBy: 'sentiment', sortOrder: 'asc',  limit: 10 })
      );
      keys.push('execBullish', 'execBearish', 'analystBullish', 'analystBearish');
    }

    const results = await Promise.all(calls);
    const data = {};
    keys.forEach(function(k, i) { data[k] = parseResult(results[i]); });

    // Extract org slug
    _org = data.org?.org || (typeof data.org === 'string' ? data.org : '');

    render(data);
    document.getElementById('last-updated').textContent =
      'Updated ' + new Date().toLocaleTimeString();
    showState('dashboard');
  } catch(err) {
    document.getElementById('error-msg').textContent =
      'Failed to load market data: ' + err.message;
    showState('error');
  } finally {
    disableRefresh(false);
  }
}

function showState(state) {
  ['loading', 'error', 'dashboard'].forEach(function(id) {
    document.getElementById(id).style.display = id === state ? (id === 'dashboard' ? 'block' : 'flex') : 'none';
  });
}

function disableRefresh(disabled) {
  document.querySelectorAll('.refresh-btn').forEach(function(b) { b.disabled = disabled; });
}
```

---

### Rendering

#### `render(data)` — top-level coordinator

```javascript
function render(data) {
  if (CONFIG.sections.movers && data.movers)     renderLeaderboards(data.movers);
  if (CONFIG.sections.trends && data.trends)     renderTrends(data.trends);
  if (CONFIG.sections.speakers)                  renderSpeakers(data);
}
```

#### Leaderboard card titles

| criterion | title |
|-----------|-------|
| `stockChange` | Top Stock Movers |
| `investmentScore` | Highest Investment Score |
| `investmentScoreChange` | Biggest Investment Gain |
| `sentimentScore` | Most Positive Sentiment |
| `sentimentScoreChange` | Biggest Sentiment Shift |
| `aspectScore` | Top Aspect Score |
| `marketcap` | Largest by Market Cap |

#### `renderLeaderboards(moversData)`

`moversData` is keyed by criterion. Each criterion has `topMovers`, `underperforming`, `overperforming` arrays. Each company: `{ id, ticker, name, sector, marketCap, companyId, category, <criterionField> }`.

- Build the **overview strip** (`#overview-strip-section`): one `.overview-box` per criterion, showing the #1 company name and its value.
- Build **leaderboard cards** (`#leaderboards-section`): one `.lb-card` per criterion in `CONFIG.sortBy` order.
  - Each card has an `<h3>` title, then a `<table>` with columns: `#` · Company (linked) · Ticker · Value · Badge.
  - `sentimentScoreChange` card: two `<h4>` sub-tables stacked — "Most Bullish" from `topMovers`, "Most Bearish" from `underperforming`.
  - Signal badges: `Potential Buy` (`.badge.buy`) when a company appears in both high-investmentScore topMovers AND stockChange underperforming; `Caution` (`.badge.caution`) when stock is sharply negative; `Watch` (`.badge.watch`) otherwise.
  - Value column: `class="num"` + sign-based color class (`pos` / `neg` / `muted`).

**Company link format:**
```javascript
function coLink(company) {
  const id = company.companyId || company.id;
  const href = _org
    ? 'https://' + _org + '.prontonlp.com/#/ref/$COMPANY' + id
    : '#';
  return '<a href="' + href + '" target="_blank" rel="noopener noreferrer" class="co-link">'
       + escHtml(company.name) + '</a>';
}
```

**Score / value formatting:**
```javascript
function fmtValue(criterion, company) {
  const fieldMap = {
    stockChange: 'stockChange', investmentScore: 'investmentScore',
    investmentScoreChange: 'investmentScoreChange', sentimentScore: 'sentimentScore',
    sentimentScoreChange: 'sentimentScoreChange', aspectScore: 'aspectScore',
    marketcap: 'marketCap'
  };
  const v = company[fieldMap[criterion]];
  if (v == null) return '—';
  if (criterion === 'marketcap') return fmtCap(v);
  if (criterion === 'investmentScore' || criterion === 'sentimentScore' || criterion === 'aspectScore')
    return parseFloat(v).toFixed(2);
  return (v > 0 ? '+' : '') + parseFloat(v).toFixed(1) + '%';
}

function colorClass(v) {
  return v > 0 ? 'pos' : v < 0 ? 'neg' : 'muted';
}

function fmtCap(v) {
  if (v >= 1e12) return '$' + (v / 1e12).toFixed(1) + 'T';
  if (v >= 1e9)  return '$' + (v / 1e9).toFixed(1) + 'B';
  if (v >= 1e6)  return '$' + (v / 1e6).toFixed(0) + 'M';
  return '$' + v;
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
```

#### `renderTrends(trendsArray)`

Render into `#trends-section`. Trends array: `[ { name, explanation, score, hits, change } ]`.

- Section `<h2>Trending Topics</h2>`
- Table: Topic · Score · Change · Explanation
- Score: raw decimal (e.g. `0.71`). Change: signed with `%`. Color class by sign.
- No chart — table only.

#### `renderSpeakers(data)`

Render into `#speakers-section`. Four sub-sections in a `speakers-grid`:
- Exec Bullish (`data.execBullish`) · Exec Bearish (`data.execBearish`)
- Analyst Bullish (`data.analystBullish`) · Analyst Bearish (`data.analystBearish`)

Each person: `{ name, company, companyId, sentimentScore, numOfSentences }`.

Section `<h2>Voice of the Market</h2>` above the grid. Each sub-section is a `.card` with an `<h3>` and a table: Name · Company (linked) · Sentiment Score · Sentences. Color-code sentiment score by sign.

---

### Initialization

At the bottom of the `<script>` block, after all function definitions:

```javascript
mcpInit().then(loadData);
```

---

## Step 3: Return

Return ONLY the complete HTML document as plain text. No preamble, no explanation, no markdown fences — the raw HTML starting with `<!DOCTYPE html>`.
