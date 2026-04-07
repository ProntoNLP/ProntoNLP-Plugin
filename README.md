# ProntoNLP Plugin

Tools and skills to perform advanced financial analysis, including sentiment analysis, company and sector intelligence, market pulse reporting, and comparative analysis — powered by ProntoNLP data.

## Prerequisites

The plugin and skills require access to [Pronto NLP](https://prontonlp.ai/) (now part of S&P Global) data subscription to work with.

## Installation

The plugin can be installed in any compatible AI client. The example below uses Claude Code.

Open Claude Code in your terminal:

```
claude
```

### Step 1 — Add from marketplace

Add the ProntoNLP marketplace to your client.

```
/plugin marketplace add ProntoNLP/ProntoNLP-Plugin
```

### Step 2 — Install the plugin

Install the ProntoNLP plugin from the marketplace.

```
/plugin install prontonlp-plugin
```

### Step 3 — Pick a scope

Choose how to install the plugin:

- **Install for you (user scope)** — installs across all your projects (recommended)
- **Install for all collaborators on this repository (project scope)** — shared via the repo
- **Install for you, in this repo only (local scope)** — only you, only this project

## Skills

### `pronto-company-intelligence`

Generates a full intelligence report for a single named company or ticker — covering earnings sentiment, investment score, stock performance, analyst and executive sentiment, trending topics, risk factors, and financial forecasts. The centerpiece is a quarter-over-quarter comparison of every earnings call in the past year, explicitly showing whether sentiment, investment scores, and stock price reaction are rising or falling.

Use for phrases like: *"analyze NVDA"*, *"Apple earnings"*, *"should I buy Tesla"*, *"what do analysts say about Microsoft"*, *"deep dive on AMD"*.

---

### `pronto-sector-intelligence`

Generates a sector-level intelligence report analyzing all companies within an industry — ranking them by investment score and sentiment, identifying dominant events and themes, surfacing bullish and bearish signals, and tracking trending topics across the sector.

Use for phrases like: *"analyze the tech sector"*, *"healthcare industry report"*, *"what is happening in financials"*, *"which companies in energy are leading"*, *"sentiment in real estate"*.

---

### `pronto-compare`

Generates a unified side-by-side comparison report for two or more named companies, tickers, market sectors, or any mix of companies and sectors — scoring each across sentiment, investment score, stock performance, trending topics, and risk factors to determine an overall leader. Supports 2 to 5 entities.

Use for phrases like: *"NVDA vs AMD"*, *"tech vs healthcare"*, *"NVDA vs the tech sector"*, *"compare Apple and Microsoft"*, *"which sector leads — IT or financials"*.

---

### `pronto-marketpulse`

Generates a broad market intelligence dashboard ranking companies across the entire market by investment score, sentiment shifts, and stock performance — based on recent earnings calls. Defaults to the past 7 days when no time frame is specified.

Use for phrases like: *"what's moving in the market"*, *"top movers"*, *"market recap"*, *"most bullish companies"*, *"biggest sentiment shifts"*, *"earnings season highlights"*.
