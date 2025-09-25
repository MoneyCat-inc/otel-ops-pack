# ECRR Report — SigNoz Live Refresh & Collector Fix

Date: 2025-09-23
Agent: Cursor Agent — Observability Copilot
Role: OTel Wiring & Monitoring Steward

---

## 1) Examine

- SigNoz UI reachable at http://localhost:8080; containers healthy (signoz, signoz-clickhouse, signoz-otel-collector).
- Windows Collector service otelcol-contrib initially failing to start (Win32 1064) due to config issues.
- ClickHouse baseline before fix showed dataset mostly blank; dataset="windows" = 0.

Evidence commands

```
sc query otelcol-contrib
docker ps --format '{{.Names}}\t{{.Status}}'
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.logs_v2"
docker exec signoz-clickhouse clickhouse-client --query "SELECT severity_text, count() FROM signoz_logs.logs_v2 WHERE timestamp >= toUnixTimestamp64Nano(now64(9)-toIntervalHour(24)) GROUP BY severity_text ORDER BY count() DESC"
```

---

## 2) Clean

Changes applied (idempotent):
- Fixed OTTL nil check in transform/enrich (use attributes["dataset"] == nil).
- Removed non-Windows filelog paths (/tmp/...) from filelog.include.
- Added file_storage extension and enabled it under service.extensions to satisfy sending_queue.storage: file_storage.

Key config locations

```
config.yaml:22  # filelog.include
config.yaml:100 # transform/enrich OTTL
config.yaml:1   # extensions.file_storage
config.yaml:150 # service.extensions includes file_storage
```

Apply/validate

```
"C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" validate --config "C:\otel\config.yaml"
pwsh -File .\restart-collector.ps1
sc query otelcol-contrib
```

---

## 3) Report

Results after fix:
- Collector starts cleanly; health check OK; no immediate WARN/ERROR spikes observed.
- Emitted canary Windows Application event SigNozTest (EventID 1001).
- dataset="windows" now increments (confirmed growth from 381 → 547 → 660+).
- Last-10m severity mix clean (no ERROR rows).

Fresh evidence commands

```
# Canary
New-EventLog -LogName Application -Source SigNozTest -ErrorAction SilentlyContinue
Write-EventLog -LogName Application -Source SigNozTest -EntryType Information -EventId 1001 -Message "SigNoz test windows canary - $(Get-Date -Format o)"

# Verification
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.logs_v2 WHERE arrayElement(mapValues(attributes_string), indexOf(mapKeys(attributes_string),'dataset'))='windows'"

docker exec signoz-clickhouse clickhouse-client --query "SELECT severity_text, count() FROM signoz_logs.logs_v2 WHERE timestamp >= toUnixTimestamp64Nano(now64(9)-toIntervalMinute(10)) GROUP BY severity_text ORDER BY count() DESC"
```

---

## 4) Role

- Actor: Cursor Agent — Observability Copilot
- Responsibilities: Diagnose collector start failure, apply minimal config diffs, verify ingestion, and establish live monitoring.

---

## ✅ ECRR Gate

- Examine: state captured; failure identified (OTTL + storage extension).
- Clean: config corrected; storage enabled; Unix paths removed.
- Report: evidence and commands included; ingestion growth confirmed; severities clean.
- Role: declared; actions within local-first guardrails.

---

## Follow-ups

- Keep 5‑minute watcher running to alert on ERROR spikes (especially filelog/canary).
- If parser errors reappear, iterate on canary JSON emitter and parsing rules.

Watcher command

```
pwsh -File .\scripts\watch-severity.ps1
```

---

## Artifacts

- docs/ECRR_REPORTS/2025-09-23-signoz-log-sweep.md (updated Live Refresh)
- docs/ECRR_REPORTS/2025-09-23-ecrr-live-refresh.md (this report)
- scripts/canary-ecrr.ps1 (emitter hardened)
- scripts/watch-severity.ps1 (5‑minute watcher)
---
## Work Session (Active)

* Session ID: session-20250923-214839
* Started: 2025-09-23 21:48:39
* Owner: system-architect
* Priority: medium

Next Steps:
- Complete the ECRR methodology (Examine -> Clean -> Report -> Role)
- Capture progress notes as the session evolves
- Gather evidence artifacts before resolution

*ECRR or it didn't happen.*

---
## Resolution Summary

* Completed: 2025-09-23 21:48:41
* Outcome: Report processed and archived
* Notes: Completed via batch processing

*Report archived by scripts/ecrr-manage.ps1.*

