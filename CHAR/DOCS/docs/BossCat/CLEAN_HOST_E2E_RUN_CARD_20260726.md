<!-- markdownlint-disable MD013 MD031 MD034 -->
# CLEAN-HOST E2E ΓÇö Run card (SCHEDULED RE-RUN)

**Run ID:** `clean-host-e2e-20260726`  
**Scheduled:** 2026-07-25T22:45:00Z  
**Prior run:** `clean-host-e2e-20260725` ΓÇö RED on clock (68 min), GREEN on pipeline; ECRR `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260725.md`  
**Briefing:** `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`  
**Status:** **COMPLETE ΓÇö GREEN.** Clone ΓåÆ first span **7.47 min** (target Γëñ30; prior run 68.1). See `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260726.md` and `artifacts/clean-host-e2e-20260726.json`.

## What this re-run measures

**Clone ΓåÆ first span** with F1ΓÇôF3 fixes applied. Phase 0 is **not** repeated (tools + MSI already proven).

| Checkpoint | Value |
|---|---|
| Hyper-V snapshot | `phase0-ready-20260726` on VM `clean-host-e2e` |
| Guest state | `C:\otel` absent; no SigNoz containers; `otelcol-contrib` **Stopped + Disabled**; Docker engine healthy; ports 4317/4318 free |
| Phase 0 | Excluded from gate clock |

## Precondition before gate clock

F1ΓÇôF2 are now on `main` as `312aff7db` (via #391). At gate time they were only on `origin/docs/clean-host-e2e-scheduled` @ `e7e9ba420` (since orphaned by the split); `main` still had scrapers list syntax then.  
F3 (Phase 0 stop+disable) is already baked into checkpoint `phase0-ready-20260726`.

**Clone must target the scheduled branch** ΓÇö plain `git clone` would pull `main` and regress F1ΓÇôF2.

## Gate clock (Phases 1ΓÇô4 only)

**Start:** first `git clone` byte  
**Stop:** first canary/synthetic span visible / verify-pipeline exit 0 with span evidence  
**Target:** Γëñ 30 minutes  
**Branch:** `docs/clean-host-e2e-scheduled` @ `e7e9ba420` (code == `main` `312aff7db` post-#391)

```powershell
# GATE CLOCK START
git clone --branch docs/clean-host-e2e-scheduled --single-branch https://github.com/MoneyCat-inc/otel-ops-pack.git C:\otel
cd C:\otel
git rev-parse --short HEAD   # expect e7e9ba420 (fix now on main as 312aff7db via #391)
pwsh -File .\start-signoz.ps1
pwsh -File .\scripts\preflight-health-check.ps1
# repair writes %ProgramData%\otelcol-contrib\config.yaml + HKLM ImagePath
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
# verify ImagePath contains ProgramData\otelcol-contrib\config.yaml
pwsh -File .\scripts\quick-monitor.ps1
pwsh -File .\canary-test.ps1
pwsh -File .\BRAV\SCPT\verify-pipeline.ps1
# GATE CLOCK STOP
```

## Restore checkpoint (if a dry-run contaminates)

```powershell
# On Hyper-V host
Restore-VMSnapshot -VMName clean-host-e2e -Name phase0-ready-20260726 -Confirm:$false
Start-VM clean-host-e2e   # if needed
```

## Artifacts to produce

- `artifacts/clean-host-e2e-20260726.json`  
- `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260726.md`  
- BOSSCAT_LOG `[CLEAN-HOST E2E]` GREEN/AMBER/RED  

ΓÇö Cursor{Implementer}
