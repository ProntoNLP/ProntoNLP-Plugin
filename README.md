# ProntoNLP Plugin

Tools and skills to perform advanced financial analysis, including sentiment analysis, company and sector intelligence, market pulse reporting, topic research, and comparative analysis — powered by ProntoNLP data.

## Prerequisites

The plugin and skills require access to [ProntoNLP](https://prontonlp.ai/) (now part of S&P Global) data subscription to work with.

## Installation

### In Claude Cowork/Code For Personal Users

1. Go to the **Cowork** tab
2. Click on **Customize**
3. Click on the **+** button in **Personal Plugins**
4. Click on **Create Plugin**
5. Click on **Add Marketplace**
6. Paste the [ProntoNLP Plugin](https://github.com/ProntoNLP/ProntoNLP-Plugin) repository URL

### In Claude Cowork/Code For Organizations Plan

1. Go to the [ProntoNLP Plugin repository](https://github.com/ProntoNLP/ProntoNLP-Plugin)
2. Click the green **\<\> Code** button
3. Click **Download ZIP**
4. Open **Claude Desktop**
5. Click on your profile image or name
6. Click on **Organization Settings**
7. Click on **Plugins**
8. Click on **Add Plugin**
9. Upload the ZIP file you downloaded

### In Claude Code

Open Claude Code in your terminal:

```
claude
```

**Step 1 — Add from marketplace**

Add the ProntoNLP marketplace to your client.

```
/plugin marketplace add ProntoNLP/ProntoNLP-Plugin
```

**Step 2 — Install the plugin**

Install the ProntoNLP plugin from the marketplace.

```
/plugin install prontonlp-plugin
```

**Step 3 — Pick a scope**

Choose how to install the plugin:

- **Install for you (user scope)** — installs across all your projects (recommended)
- **Install for all collaborators on this repository (project scope)** — shared via the repo
- **Install for you, in this repo only (local scope)** — only you, only this project

---

## Skills

### `pronto-company-intelligence`

Generates a full intelligence report for a single named company or ticker — covering earnings sentiment, investment score, stock performance, analyst and executive sentiment, trending topics, risk factors, and financial forecasts.

The centerpiece is a **quarter-over-quarter comparison** of every earnings call in the past year, explicitly showing whether sentiment, investment scores, and stock price reaction are RISING or FALLING. Layered on top: analyst forecasts, competitive benchmarks, trending topics, management quotes, and risk factors.

**Report modes:** Full Report (default), Quick Report, Sentiment Report, Competitive Report, Risk Assessment.

**Trigger phrases:** *"analyze NVDA"*, *"Apple earnings"*, *"should I buy Tesla"*, *"what do analysts say about Microsoft"*, *"deep dive on AMD"*, *"TSLA outlook"*, *"give me a report on Google"*.

> Do not use when comparing two or more companies — use `pronto-compare` instead.

---

### `pronto-sector-intelligence`

Generates a sector-level intelligence report analyzing all companies within an industry — ranking them by investment score and sentiment, identifying dominant events and themes, surfacing bullish and bearish signals, and tracking trending topics across the sector.

The report focuses on **patterns across many companies simultaneously**: sentiment direction, investment score leaders, divergence signals (high score + weak stock = potential buy signal), dominant positive/negative events, and fastest-rising themes.

**Report modes:** Full Report (default), Movers Report, Theme Analysis, Sentiment Report.

**Trigger phrases:** *"analyze the tech sector"*, *"healthcare industry report"*, *"what is happening in financials"*, *"which companies in energy are leading"*, *"sentiment in real estate"*, *"top movers in semiconductors"*.

> Do not use for a single named company — use `pronto-company-intelligence` instead.
> Do not use when comparing specific companies side by side — use `pronto-compare` instead.

---

### `pronto-compare`

Generates a unified side-by-side comparison report for two or more named companies, tickers, market sectors, or any mix of companies and sectors — scoring each across sentiment, investment score, stock performance, trending topics, and risk factors to determine an overall leader. Supports **2 to 5 entities**.

Handles all comparison modes: company vs company, sector vs sector, and mixed company vs sector — with adaptive scoring dimensions and a clear verdict section.

**Trigger phrases:** *"NVDA vs AMD"*, *"tech vs healthcare"*, *"NVDA vs the tech sector"*, *"compare Apple and Microsoft"*, *"which sector leads — IT or financials"*, *"semiconductors vs software"*.

> Do not use for a single named company — use `pronto-company-intelligence` instead.
> Do not use for a single sector — use `pronto-sector-intelligence` instead.
> Do not use for broad market overviews — use `pronto-marketpulse` instead.

---

### `pronto-marketpulse`

Generates a broad market intelligence dashboard ranking companies across the entire market by investment score, sentiment shifts, and stock performance — based on recent earnings calls. Gives a fundamentals-driven view of market activity rather than just price noise.

Defaults to the **past 7 days** when no time frame is specified. Supports filtering by market cap, sector, and time window.

This is the **only** ProntoNLP skill that should end as a **Claude live artifact**. It should refresh with current data when reopened in Claude Cowork/Desktop.

**Trigger phrases:** *"what's moving in the market"*, *"top movers"*, *"market recap"*, *"most bullish companies"*, *"biggest sentiment shifts"*, *"earnings season highlights"*, *"which large caps are outperforming"*.

> Do not use for a single named company — use `pronto-company-intelligence` instead.
> Do not use for a specific sector — use `pronto-sector-intelligence` instead.

All other report skills in this plugin stay **regular standalone HTML reports**. They are **not** live artifacts.

---

### `pronto-topic-research`

Performs qualitative topic-based research across the market — analyzing how a keyword or theme appears across earnings calls and financial documents. Produces an HTML report with an **Executive Summary, Themes with verbatim quotes as evidence, and a Conclusion**.

Uses a parallel data collection pipeline: trend volume over time, related sectors, top companies discussing the topic, related documents, related keywords, and verbatim evidence — all synthesized into a structured narrative by a dedicated themes broker.

**Report output includes:**
- Hits Overtime chart (quarterly trend line — total, positive, negative)
- Related Sectors bar chart
- Related Companies, Related Documents, and Related Keywords tables
- Themed narrative with cited verbatim evidence

**Trigger phrases:** *"how is AI regulation discussed"*, *"top themes around supply chain"*, *"executive summary on inflation"*, *"what are companies saying about tariffs"*, *"research the war with Iran theme"*.

> Do not use for a single named company — use `pronto-company-intelligence` instead.

---

## Internal Agents

The following agents are used internally by the skills above and are not intended to be invoked directly by users.

### `pronto-search-summarizer`

An elite search specialist that executes sophisticated multi-layer search strategies against ProntoNLP financial documents. Used by `pronto-topic-research`, `pronto-company-intelligence`, `pronto-sector-intelligence`, and `pronto-compare` to retrieve high-signal verbatim evidence. Supports four search strategies — Direct Strike, Contrastive/Parallel, Broad-to-Narrow Iteration, and Exhaustive Sweep — with section targeting, speaker-gap analysis, pagination, dual time-window, and post-search curation.

### `pronto-themes-broker`

A synthesis analyst (powered by Claude Haiku) that receives raw search results and produces a structured broker summary: Executive Summary, Key Themes with verbatim evidence, and a Conclusion with near/medium/long-term market implications and portfolio positioning. Operates strictly on provided data — calls no tools.

### `pronto-html-renderer`

The shared rendering engine for the regular ProntoNLP HTML reports. Receives a structured data payload and a `report_type` (`company`, `sector`, `compare`, or `topic`) and writes a fully styled standalone HTML file to disk. Owns all visual design decisions — platform color tokens, chart specifications, component layouts, and citation link formatting. Skills prepare and synthesize data; this agent produces the final output. Uses only `Read` and `Write` tools — no MCP calls.

### `pronto-marketpulse-live-artifact`

The dedicated live artifact builder for `pronto-marketpulse`. It creates or updates a Claude live artifact for Market Pulse instead of writing a standalone HTML file. This path is exclusive to Market Pulse; it is responsible for the live, refresh-on-open behavior.

---

## License

Licensed under the Apache 2.0 License. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Copyright 2026-present ProntoNLP. The present date is determined by the timestamp of the most recent commit in the repository.
