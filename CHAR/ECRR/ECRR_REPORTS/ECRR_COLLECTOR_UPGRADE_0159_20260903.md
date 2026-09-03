# ECRR — Daily host collector 0.158.0 → 0.159.0 (audit P1-1)

**Date:** 2026-09-03
**Actor:** Machine operator `@fubumaki` (elevated PowerShell, executed the upgrade); Claude
(chat/review) verified live and wrote this record.
**Trigger:** `ECRR_READY_FOR_GATE_AUDIT_20260903.md` P1-1 — the single pin
(`scripts/windows/collector-version.txt`) had said 0.159.0 since 2026-08-23 (#591) while the daily
host binary reported 0.158.0. The commit-time drift guard compares the two pin files to each other
and never to the installed binary; the pre-commit hook printed "collector pin 0.159.0 consistent"
on the 0.158.0 host while the audit itself was being committed.
**Verdict:** **GREEN** — host on 0.159.0, service Running / Automatic, receivers listening, records
exported within minutes; the host-vs-pin gap is recorded as an open guard gap, not closed.

## 1. Examine

| Check (before) | Value |
| --- | --- |
| `otelcol-contrib.exe --version` | 0.158.0 |
| `collector-version.txt` / `phase0-setup.ps1` fallback | 0.159.0 / 0.159.0 |
| Runbook | "Pin moved to v0.159.0 on 2026-08-23"; no line saying the daily host had moved |
| Guard coverage | file-to-file only |

Path: the runbook's tarball sequence, not the MSI. The MSI is documented as failing on this host
with 1603 (Error 1920, service start during install) and as removing the working install first.

## 2. Clean

Operator, elevated, from `C:\otel`:

1. Download `otelcol-contrib_0.159.0_windows_amd64.tar.gz` from the upstream release.
2. `Stop-Service otelcol-contrib`; extract `otelcol-contrib.exe` over
   `C:\Program Files\OpenTelemetry Collector\`; `Start-Service otelcol-contrib`.
3. `pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1` — rewrote the deployed
   config, confirmed ImagePath, Automatic (Delayed Start), failure recovery 10 s × 3, service RUNNING.

Docs (docs lane, same day): CHARTER stack-facts line to v0.159.0 (verified 2026-09-03); runbook
gains a dated "daily host upgraded" paragraph stating the path used and the guard gap.

## 3. Report

| Check (after, chat/review seat, 18:3xZ) | Value |
| --- | --- |
| `otelcol-contrib.exe --version` | **0.159.0** |
| Service | Running / Automatic |
| 5320 (gRPC) / 5321 (HTTP) / 8888 (metrics) | listening / listening / listening |
| `otelcol_exporter_sent_log_records{otlp,4317}` | 22 within minutes of restart |
| `otelcol_exporter_queue_size` logs/metrics/traces | 0 / 0 / 0 |
| Watchdog tick after restart | `ok`, `start_type` 2, no incident bundle |

**Open gap:** nothing compares the installed binary to the pin. A one-line check in the watchdog
tick or in `hygiene_fast` (`--version` vs `collector-version.txt`) would make "pin moved" unable
to pass while the host lags. Proposed, not built: it is a new check and needs an owner decision.

## 4. Role

Operator executed every elevated step. Chat/review seat supplied the command sequence from the
runbook, verified the result from the metrics endpoint and the service, and files this record.
