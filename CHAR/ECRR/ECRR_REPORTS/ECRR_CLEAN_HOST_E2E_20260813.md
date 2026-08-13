<!-- markdownlint-disable MD013 MD031 MD034 -->
# ECRR — Clean-Host E2E (`clean-host-e2e-20260813`)

**Date:** 2026-08-13  
**Actor:** Cursor{Implementer} + machine operator `@fubumaki`  
**Verdict:** **GREEN** — clone → first span **6.86 min** (target ≤30; prior 7.47)  
**Artifacts:** `artifacts/clean-host-e2e-20260813.json` · Run card: `docs/BossCat/CLEAN_HOST_E2E_RUN_CARD_20260813.md`  
**Guest artifact:** `C:\Phase0\gate-clock-20260813.json` (screenshot-confirmed; host pull pending)

---

## Examine

- Fresh Gen2 Hyper-V guest `clean-host-e2e` after host Insider fix (26300.9032; prior firmware `Invalid Signature`).
- **Phase 0 (excluded from clock):** pinned MSI **0.158.0** via startup path — **Method=`msi`**, ~**11.72 min**, service left **Stopped+Disabled**. Checkpoint `phase0-ready-20260813`.
- Nested virt cold-boot required for Docker; WSL installed in guest. Later checkpoint `docker-ready-20260813` (Docker healthy, no SigNoz images).
- Gate clock cloned **`main`** (not the orphaned July branch). Tip at successful run included **#460** + **#461**.

### Contaminating dry-runs (clock integrity)

| Attempt | Result | Cause | Restore |
|---|---|---|---|
| 1 | RED ~7.24 min | `install-or-repair` unelevated → exit 1; drift guard **exit 21** (correct) | `phase0-ready-20260813` |
| 2 | RED 6.87 min | Elevated; `Start-Service` ~16s fail — missing `C:\ProgramData\Otelcol\FileStorage` | `docker-ready-20260813` |
| 3 | **GREEN 6.86 min** | After #461 | — |

Failed attempts pulled SigNoz images; restores preserved a comparable cold cache for the measured run.

## Clean

| Fix | PR | Evidence this run |
|---|---|---|
| Refuse unelevated install-or-repair (exit **5**) | #460 | Attempt 2 reached real Start-Service (~0.27 min), not opaque ~2s access deny |
| Create `file_storage` dirs from config before start | #461 | Attempt 3: install-or-repair **exit 0**; health-check **exit 0** (was 21) |
| Drift guard asserts ProgramData config | #438 | Exit 21 on unrepaired attempts = true drift |
| MSI pin 0.158.0 + SHA | #452 | Phase 0 Method=`msi` on clean guest |

Daily-host `FileStorage` dir CreationTime **2025-09-17** — inherited, never provisioned by install-or-repair until #461.

## Report

### MSI-on-clean-host verdict (open question this card was designed to settle)

**PROVEN.** Phase 0 on a genuinely clean guest installed **0.158.0 via the pinned MSI path** (`Method=msi`). This closes the #454 gap: MSI 1603/Error 1920 was an **upgrade-over-existing** failure mode on the daily host, not a clean-install failure. Tarball/`sc create` remains a recovery path for upgrades, not the default clean-host path.

### Gate clock

| Milestone | Result |
|---|---|
| Clone → verify-pipeline exit 0 | **6.86 min** |
| Target | ≤30 min |
| Prior GREEN (20260726) | 7.47 min |
| Status | **GREEN** |

All timed steps exit 0: preflight, enable-collector-service, install-or-repair-collector, health-check-collector-config, quick-monitor, canary-test, verify-pipeline.

### Assertions beyond the clock

| Assert | Result |
|---|---|
| F3 retired (0.158.0 starts on canonical config) | **PASS** |
| Drift guard exit 0 | **PASS** |
| Event Log `windowseventlog/application` | **PASS** (load-bearing: canary writes Application/SigNoz-Canary EventId 1001) |
| Event Log `windowseventlog/system` | **informational only** — both receivers use `start_at: end`; a quiet guest may legitimately show zero System events inside a ~7 min window. Do not treat absence as Phase 1 failure. |
| No hostmetrics expected | **EXPECTED** (canonical config has none) |

### Comparison

| Run | Clone → first span | Collector | Verdict |
|---|---|---|---|
| 20260725 | 68.1 min | 0.104.0 path lies | RED on clock |
| 20260726 | 7.47 min | F1–F3 | GREEN |
| 20260813 | **6.86 min** | **0.158.0 MSI clean** | **GREEN** |

### Follow-ups

1. Commit gate runners (`RUN-GATE-CLOCK.cmd`, `run-gate-clock.ps1`, Phase 0 scripts) — were host-only until Desktop copy; not on `main` at run start.
2. Optionally archive guest `C:\Phase0\gate-clock-20260813.json` onto the host artifact for SHA/timestamps.
3. Document nested-virt cold-boot after snapshot restore in the run card (recurring F7).

## Role

- **Machine operator `@fubumaki`:** Phase 0, Docker/WSL, snapshot restores, elevated gate runs.  
- **Cursor{Implementer}:** Hyper-V restore/cold-boot, PR merge (#460/#461), evidence + this ECRR.  
- **Claude (chat/review):** run card, exit-1 timing analysis → #461 root cause; Event Log assert correction (#463).

— Cursor{Implementer}
