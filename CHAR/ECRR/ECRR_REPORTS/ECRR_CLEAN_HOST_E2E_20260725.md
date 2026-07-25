# ECRR — Clean-Host E2E Gate Run (`clean-host-e2e-20260725`)

**Date:** 2026-07-25
**Actor:** Cursor{Implementer} (gate driver via PowerShell Direct) + machine operator `@fubumaki` (OOBE, UAC, Docker Desktop session)
**Verdict:** **RED on gate clock (68 min > 30 min target) — GREEN on pipeline (verify-pipeline exit 0, canary trace confirmed in ClickHouse)**
**Artifacts:** `artifacts/clean-host-e2e-20260725.json` · Run card: `docs/BossCat/CLEAN_HOST_E2E_RUN_CARD_20260725.md`

---

## Examine

- **Host:** daily workstation `D-MONOLITH` confirmed contaminated (C:\otel present, otelcol RUNNING, SigNoz containers) — fail-closed, gate not run there.
- **Clean guest:** Hyper-V Gen2 VM `clean-host-e2e` (Win11 Pro 26200, 4 vCPU, static 8 GB, nested virt, TPM). Windows applied to VHDX via DISM after DVD-boot miss; BitLocker/Device Encryption blocked offline injects (worked around via Copy-VMFile + PowerShell Direct).
- **Clean precondition verified inside guest before clone:** `Test-Path C:\otel` false; zero SigNoz containers; ClickHouse row counts 0.
- **Phase 0 (excluded from clock):** 7.4 min initial + remediation. Pinned MSI otelcol-contrib **0.104.0** installed; Git 2.55.0, pwsh 7.6.4, Python 3.12.10, Docker 29.6.2, OTel pip packages verified in-guest.

## Clean

Fixes applied **inside the guest** to reach first span (each is a repo defect a stranger would hit):

1. Stopped Windows collector to free 4317/4318; started `signoz-otel-collector` container.
2. Service ImagePath set via registry to `--config C:\otel\config.yaml` (`sc.exe config` quoting failed silently).
3. Patched `C:\otel\config.yaml` hostmetrics `scrapers` from list to map syntax; `otelcol validate` exit 0; service Running on 5320/5321/8888.

## Report

### Gate clock (Phases 1–4)

| Milestone | UTC | Elapsed |
|---|---|---|
| Clone start (clock start) | 21:12:47 | 0 |
| SigNoz healthy (after Docker outage) | ~21:44 | ~31 min |
| First span + canary log in ClickHouse | 22:20:53 | **68.1 min** |
| Full pipeline, verify-pipeline exit 0 | 22:28:49 | 76.0 min |

Phase splits: P1 clone 0.3 min · P2 SigNoz 6.9 min (+ ~19 min Docker engine outage) · P3 collector 35.5 min (~34 min = StopPending hang) · P4 verify 2.0 min (WARN) · fix-forward 12 min.

### Final evidence

- `verify-pipeline.ps1` **exit 0 / outcome OK**; canary trace `8e647f93aa5e1482c85122dcd9b1dfce` API-confirmed (CLICKHOUSE mode), ingest latency ≈ 0 ms (≤5 s target met).
- ClickHouse: 7 logs (2 canary), 2 spans, 6,388 metric samples in trailing 5 min (hostmetrics flowing).
- All gate checks true: collector running, OTLP reachable, span rate nonzero, export drops zero, error ratio <5%.

### Findings (the gate's real product)

| # | Severity | Finding |
|---|---|---|
| F1 | CRITICAL | MSI collector auto-starts with default config binding 0.0.0.0:4317/4318 → `signoz-otel-collector` container loses port race and never starts. Run-card order (MSI Phase 0 → SigNoz Phase 2) guarantees this for every stranger. |
| F2 | CRITICAL | `install-or-repair-otel-collector.ps1` writes ProgramData config but never updates service ImagePath — service silently keeps MSI default config. The run card's manual warning is real and unautomated. |
| F3 | CRITICAL | Canonical `windows/otelcol/otelcol-contrib-config.yaml` uses scrapers **list** syntax, incompatible with pinned **0.104.0** (needs map). Pinned MSI + canonical config = crash-loop. |
| F4 | HIGH | Collector under default config doesn't stop cleanly; `Restart-Service` hung ~34 min in StopPending; needed `taskkill`. |
| F5 | MEDIUM | Docker Desktop engine died mid-run under nested Hyper-V; recoverable only from interactive session (~19 min cost). |
| F6 | MEDIUM | Phase 0: winget defaults to per-user installs (pwsh/Python invisible to other admin sessions). |
| F7 | LOW | Docker Desktop reports "Virtualization support not detected" when guest has dynamic memory enabled; static RAM required. |

### Repo follow-ups (proposed)

1. Fix scrapers syntax in canonical config for 0.104.0, or bump the pin and re-verify (F3).
2. install-or-repair: set service ImagePath explicitly + stop-timeout with taskkill fallback (F2, F4).
3. Run card/runbook: stop or reconfigure the Windows collector **before** `docker compose up`, or move MSI install after SigNoz start (F1).

## Role

- **Cursor{Implementer}:** VM provisioning, Phase 0 verification/remediation, gate drive, fix-forward, evidence, this report.
- **Machine operator (@fubumaki):** OOBE, UAC approvals, Docker Desktop interactive session, throwaway `GuestAI` credential (transited chat → burned with VM).
- **Cred note:** guest credential is discarded with the VM per post-FG-r2 rotation rule; never reused outside `clean-host-e2e`.

— Cursor{Implementer}
