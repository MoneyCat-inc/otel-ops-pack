# SigNoz UI Map (Local Build v0.95.0)

Purpose
- Quick reference to common routes, page anatomy, and local API behavior.

> See also: Cross-project summary — [ECRR Project Report](../ECRR_PROJECT_REPORT.md)

Top-level routes
- Dashboards: `/dashboard` (list), `/dashboard/:id` (view/edit)
- Traces: `/traces` (search), `/traces/:traceId` (timeline)
- Logs: `/logs` (query builder, saved views)
- Metrics: `/metrics` (explorer)
- Alerts: `/alerts` (list), `/alerts/new` (builder), `/alerts/:id` (detail)
- Applications/Service Map: `/applications` or `/service-map` (build-dependent)
- Settings/Admin: `/settings`, `/settings/datasources` (if present)

Logs page anatomy
- Time range: top-right (common presets: 15m, 1h, 24h)
- Search bar: free-text + field filters (e.g., `severity_text in ["ERROR","WARN"]`)
- Filters panel: key/op/value items with AND/OR
- Group by: multi-select (e.g., `service.name`, `severity_text`)
- Results: expandable rows; Attributes tab shows `service.name`, `host.name`, `log.file.path`, `exception.*`, `http.*`
- Trace pivot: "View related trace" when `traceId` present (opens `/traces/:traceId`)
- Saved views: save/import/export current layout

Alerts builder (logs-based)
- Data source: logs
- Filters: e.g., `service.name = otelcol-contrib`, `severity_text = ERROR`
- Aggregation: count/sum/avg
- Window: 5m/10m
- Condition: `> N`, `< N`, ratios
- Frequency: 1m/5m
- Notifications: channels if configured
- JSON import/edit: build-dependent

Traces
- Search: filter by service, duration, status
- Detail: span timeline, attributes, logs correlation via `traceId`/`spanId`

Dashboards
- Panels: time series, stat, table
- Queries: builder or raw
- Variables: environment/service (if configured)

Local API behavior (per docs)
- Health/Version (no auth):
  - `GET /api/v1/health` → `{ "status": "ok" }`
  - `GET /api/v1/version` → `{ "version": "v0.95.0", ... }`
- Queries (auth required):
  - `POST /api/v5/query_range`, `/api/v5/query` → 401 without token
- Management (views/alerts):
  - May be `/api/views`, `/api/alerts` with auth; use UI import when unavailable

Ready-to-import assets (in this repo)
- Saved view (ERROR/WARN, 15m, grouped): `artifacts/signoz-saved-view-high-severity.json`
- Alert (ERROR > 5 in 5m for `otelcol-contrib`): `artifacts/signoz-alert-high-severity-service.json`
- Quick link: `artifacts/signoz-logs-deeplink.txt`

Comfort Cat helpers
- Handoff walkthrough: `docs/comfort-cat/HANDOFF_ECRR01_AND_LOGS.md`
- Drilldown recipe: `docs/comfort-cat/DRILLDOWN_RECIPES.md`
- Query cookbook: `docs/QUERY_RECIPES.md`

Known gotchas
- Auth: `/api/v5/*` requires a token; unauthenticated calls return 401
- Management APIs: not always exposed locally; prefer UI import
- Time zones: UI shows local time; APIs use epoch ms
- Trace correlation: requires logs to carry `traceId`/`spanId`

## WER crash summaries
- Source: `C:\otel\scripts\capture-wer-phoneexperience.ps1` (writes to `C:\logs\wer-phoneexperience.log`)
- SigNoz Logs filter: `dataset = "windows-wer" AND faulting_application = "PhoneExperienceHost.exe"`
- Suggested view: Group by `exception_code`, `faulting_module`; display `process_id`, `thread_id`
- Schedule helper: run `pwsh -File C:\otel\scripts\schedule-wer-phoneexperience.ps1 -IntervalMinutes 15`
- Smoke test: `pwsh -File C:\otel\scripts\capture-wer-phoneexperience.ps1 -EmitTestRecord` (writes synthetic log line)
- Verification: `dataset = "windows-wer" AND synthetic = "true"` within last 24h
- Task management: `Get-ScheduledTask -TaskName SigNoz-WER-PhoneExperience` to check status

## Firmware & DMA follow-up
- Current BIOS: `American Megatrends Inc. 5602 (13.1.25)` (from SysInfo report)
- Kernel DMA protection: Off (common on B450); enable in BIOS if newer firmware supports it
- Action: check ASUS support for newer BIOS enabling DMA guard; document changes in `artifacts/monolith-D-summary.json`
- Health check: when BIOS updated, flip collector health script to treat DMA guard regressions as failures

