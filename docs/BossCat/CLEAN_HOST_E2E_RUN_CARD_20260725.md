# CLEAN-HOST E2E — Run card (SCHEDULED)

**Run ID:** `clean-host-e2e-20260725`  
**Scheduled:** 2026-07-25T16:20:00Z  
**Briefing:** `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`  
**Status:** **AWAITING FRESH VM** — daily workstation is contaminated (fail-closed)

## Contamination proof (do not run gate clock here)

| Check | This workstation |
|-------|------------------|
| `C:\otel` | Present |
| `otelcol-contrib` | RUNNING |
| SigNoz containers | Present (`signoz`, `signoz-clickhouse`, …) |

## Gate clock (Phases 1–4 only)

**Start:** first `git clone` byte  
**Stop:** first canary/synthetic span visible in SigNoz UI (or verify-pipeline exit 0 with span evidence)  
**Target:** ≤ 30 minutes  
**Phase 0:** recorded separately — excluded from gate clock

## Pinned MSI (Phase 0 — no tribal hunt)

- **Version:** `otelcol-contrib` **0.104.0** (Gate #022 / runbook-proven; not “latest”)
- **Asset:** `otelcol-contrib_0.104.0_windows_x64.msi`
- **URL:** https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.104.0/otelcol-contrib_0.104.0_windows_x64.msi
- **Release page:** https://github.com/open-telemetry/opentelemetry-collector-releases/releases/tag/v0.104.0

## Machine operator — Phase 0 checklist (before pinging Cursor)

Provision a **fresh** Windows 10/11 VM (Hyper-V / VMware / cloud). Then install:

1. [ ] PowerShell 7+  
2. [ ] Git  
3. [ ] Docker Desktop (engine running; WSL2 if required)  
4. [ ] Python 3.11+ on PATH  
5. [ ] `pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http`  
6. [ ] Download + install pinned MSI above (elevated)  
7. [ ] Confirm **before clone:** `Test-Path C:\otel` → false; `sc query otelcol-contrib` → not found OR freshly installed unused; no SigNoz containers (`docker ps` empty of signoz*)  
8. [ ] Record Phase 0 wall-clock minutes (optional but preferred)

**When Phase 0 is done:** reply in chat with VM ready + Phase 0 minutes. Cursor starts gate clock at clone.

## Cursor — Phases 1–4 (after ping)

```powershell
# GATE CLOCK START
git clone https://github.com/MoneyCat-inc/otel-ops-pack.git C:\otel
cd C:\otel
pwsh -File .\start-signoz.ps1
pwsh -File .\scripts\preflight-health-check.ps1
Copy-Item -Force .\windows\otelcol\otelcol-contrib-config.yaml C:\otel\config.yaml
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
# ensure sc qc shows --config C:\otel\config.yaml (repair if ProgramData-only)
pwsh -File .\scripts\quick-monitor.ps1
pwsh -File .\canary-test.ps1
pwsh -File .\BRAV\SCPT\verify-pipeline.ps1
# GATE CLOCK STOP — first span visible / verify exit 0
```

## Artifacts to produce

- `artifacts/clean-host-e2e-20260725.json` (timing + exits)  
- `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260725.md`  
- BOSSCAT_LOG `[CLEAN-HOST E2E]` GREEN/AMBER/RED  

— Cursor{Implementer}
