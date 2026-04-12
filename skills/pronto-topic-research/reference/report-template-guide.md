# Template Guidelines
This document specifies how `pronto-topic-research` should structure its HTML output.

## Essential CSS
The following CSS should be utilized globally, maintaining Light Mode compliance:
```css
body { font-family: -apple-system, sans-serif; background: #ffffff; color: #1e293b; padding: 20px; }
.title { color: #0f172a; border-bottom: 2px solid #1D9E75; padding-bottom: 8px; margin-bottom: 4px; }
.subtitle { color: #64748b; font-size: 14px; margin-top: 0; margin-bottom: 24px; }
table { width: 100%; border-collapse: separate; border-spacing: 0; background: #ffffff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
```

## Broker Delegation Template
Do strictly pass arguments to `pronto-broker.md` without additional instructional strings:
```yaml
org: orgName
topicSearchQuery: "Example Clause"
sinceDay: 2026-01-12
untilDay: 2026-04-12
documentTypes: ["Earnings Calls"]
```
