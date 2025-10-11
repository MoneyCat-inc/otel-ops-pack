# BossCat Operations Guide

![Gate Status](https://img.shields.io/badge/Gate-READY-green?style=flat-square&logo=checkmarx)
![Guardrails](https://img.shields.io/badge/Guardrails-LOCKED-blue?style=flat-square&logo=shield)
![Collector](https://img.shields.io/badge/Collector-RUNNING-green?style=flat-square&logo=opentelemetry)

[![BossCat Gate Verification](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml/badge.svg)](../../actions/workflows/bosscat-gate-verify.yml)
[![BossCat Regression Matrix](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-regression-matrix.yml/badge.svg)](../../actions/workflows/bosscat-regression-matrix.yml)
[![Weekly Re-Cert](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails-recert.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails-recert.yml)
[![Monthly Rollup](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml)

• Governance: [Run Branch Protection Setup](../../actions/workflows/bosscat-branch-protection.yml)

Purpose: Governance and local-first operations for Resonai [OTel].

Key Artifacts:
- docs/ecrr/ECRR_REPORTS/ — ECRR audit trails
- docs/observability/snapshots/ — Dashboard exports
- docs/status/ — Status and test summaries
- docs/IONA_ERRORS.md — Error ledger

Runbooks:
- Gate verify: pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict
- ECRR benchmark: pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1
- Watchdog control: pwsh -File BRAV/SCPT/watchdog-control.ps1 [start|stop|status|logs|evidence] [gate|site|both]

## ECRR Benchmark Trend

- Latest summary JSON: `DELT/ARTF/ecrr-benchmark.json`
- Rolling CSV: `DELT/ARTF/ecrr-benchmark-trend.csv`
- Mirror CSV (for IDE/artifacts): `artifacts/ecrr-benchmark-trend.csv`
- Generate locally:
  - `pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1`
  - `pwsh -NoProfile -File scripts/append-ecrr-benchmark-trend.ps1 -Dedup`
- CI/Nightly maintenance:
  - `.github/workflows/bosscat-gate-verify.yml`
  - `.github/workflows/nightly-dashboard-export.yml`

## Evidence Links

- Queue Steward Evidence: [artifacts/queue-steward-verification.txt](../../artifacts/queue-steward-verification.txt)
- ECRR Trend (CSV): [DELT/ARTF/ecrr-benchmark-trend.csv](../../DELT/ARTF/ecrr-benchmark-trend.csv)
- ECRR Benchmark (JSON): [DELT/ARTF/ecrr-benchmark.json](../../DELT/ARTF/ecrr-benchmark.json)
- Latest ECRR Gate Run: [docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md](../ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md)

### Retention & Sampling Policy

- Sampling sources: on every gate verification (PR/CI) and nightly dashboard export.
- De-duplication key: `timestamp + commit + branch + latest_name` (keeps first occurrence).
- Retention window: last 365 days and at most 2000 rows (newest kept).
- Artifact retention in CI:
  - Gate verify artifacts: 30 days
  - Nightly artifacts: 90 days
- Tunables (optional):
  - `scripts/append-ecrr-benchmark-trend.ps1 -MaxDays <int> -MaxRows <int>`
  - Set `-MirrorCsv` to control the mirror path for IDEs.

## Automated Operations

**Daily:** GATE + SITE watchdogs keep collector running  
**Weekly:** Guardrails re-certification (Monday 03:00 UTC)  
**Monthly:** Evidence rollup and archival (1st day, 02:00 UTC)

## Collector Recovery

**If collector fails repeatedly despite GATE bot:**

1. Check GATE bot logs:
   ```powershell
   Get-Content DELT/ARTF/watchdog-gate.log -Tail 50
   ```

2. Check Windows Event Log:
   ```powershell
   Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 10
   ```

3. Verify config is valid:
   ```powershell
   & "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" validate --config C:\otel\config.yaml
   ```

4. Check for port conflicts:
   ```powershell
   Get-NetTCPConnection -LocalPort 13134,5317,5318,8888,55679 -State Listen
   ```

5. Manual restart as admin:
   ```powershell
   sc stop otelcol-contrib
   Start-Sleep -Seconds 5
   sc start otelcol-contrib
   ```

6. If persistent, check GATE bot evidence:
   ```powershell
   Get-Content DELT/ARTF/watchdog-gate-evidence.json | ConvertFrom-Json
   ```
