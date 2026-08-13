<!-- markdownlint-disable MD013 MD031 MD034 -->
# CLEAN-HOST E2E — Run card (0.158.0 VALIDATION)

**Run ID:** `clean-host-e2e-20260813`
**Prepared:** 2026-08-13 by Claude (chat/review seat) — executed by machine operator `@fubumaki`
**Prior run:** `clean-host-e2e-20260726` — GREEN, clone → first span **7.47 min**
**Briefing:** `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`
**Status:** SCHEDULED — gate clock not started
**Closes:** Phase 1, Roadmap 2026 H2

## Why this run differs from 20260726

Three things in the previous card are now wrong. Each would cost a run if followed as written.

| Prior card said | Now |
|---|---|
| Clone `docs/clean-host-e2e-scheduled` @ `e7e9ba420` | **Clone `main`.** F1–F2 landed via #391; the branch still exists on origin but is orphaned and behind. |
| "Phase 0 is **not** repeated (tools + MSI already proven)" | **Phase 0 must be repeated.** The `phase0-ready-20260726` checkpoint has **0.104.0** installed. Running from it would validate the version we just replaced. |
| MSI install treated as proven | **Not proven.** The 2026-08-13 host upgrade failed **1603** (Error 1920) *and removed the working install*. See the runbook warning added in #454. |

## Second purpose: close the MSI gap

PR #452 pinned the MSI to `0.158.0` with checksum verification and fixed a URL that had been
returning 404. That path is **reproducible for a clean host but unproven as an upgrade**, because the only
attempt so far was an upgrade over an existing 0.104.0 install.

This run is the natural place to settle it: a genuinely clean guest is the case the pinned MSI is
supposed to serve. **Phase 0 below deliberately uses the pinned MSI path**, so the run either
confirms it or produces the evidence to change it.

If Phase 0 MSI install fails on a clean guest too, fall back to the manual tarball sequence in the
runbook, record it, and treat "the repo has no working automated collector install" as a finding for
Phase 2 rather than a blocker for this gate.

## Phase 0 — prepare guest (EXCLUDED from gate clock)

Start from a guest with no collector installed at all — not the 20260726 checkpoint.

```powershell
# On the Hyper-V host
Restore-VMSnapshot -VMName clean-host-e2e -Name <pre-collector-snapshot> -Confirm:$false
Start-VM clean-host-e2e
```

In the guest:

```powershell
# Install collector 0.158.0 via the pinned path (this is the thing under test)
pwsh -File .\startup-observability.ps1   # $CollectorVersion = 0.158.0, verifies SHA256
sc.exe qc otelcol-contrib                # confirm it registered
Stop-Service otelcol-contrib; Set-Service otelcol-contrib -StartupType Disabled
```

Then snapshot as `phase0-ready-20260813` so the gate can be re-run without repeating Phase 0.

**Expected guest state at checkpoint:** `C:\otel` absent; no SigNoz containers; `otelcol-contrib`
**Stopped + Disabled** at **0.158.0**; Docker engine healthy; ports 4317/4318 free.

## Gate clock (Phases 1–4 only)

**Start:** first `git clone` byte
**Stop:** first canary/synthetic span visible — `verify-pipeline` exit 0 with span evidence
**Target:** ≤ 30 min (prior run 7.47)

```powershell
# GATE CLOCK START
git clone --single-branch https://github.com/MoneyCat-inc/otel-ops-pack.git C:\otel
cd C:\otel
git rev-parse --short HEAD                # record for the ECRR
pwsh -File .\start-signoz.ps1              # migrator service name fixed in #450
pwsh -File .\scripts\preflight-health-check.ps1
# writes %ProgramData%\otelcol-contrib\config.yaml from .\config.yaml (default since #429)
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
pwsh -File .\scripts\windows\health-check-collector-config.ps1   # expect GREEN exit 0 (fixed #438)
pwsh -File .\scripts\quick-monitor.ps1
pwsh -File .\canary-test.ps1
pwsh -File .\BRAV\SCPT\verify-pipeline.ps1
# GATE CLOCK STOP
```

## What to assert beyond the clock

- **F3 retired:** config validate exits 0 on `0.158.0` — already true on the daily host, confirm on clean
- **Drift guard passes:** `health-check-collector-config.ps1` exits **0**, not 21. It asserted a path
  the service never uses until #438; a RED here now means real drift
- **Event Log receivers live:** `otelcol_receiver_accepted_log_records` shows
  `windowseventlog/application` and `windowseventlog/system`. This is the telemetry class that
  justified keeping the collector in Phase 1 — if it does not appear on a clean host, the Phase 1
  decision needs revisiting
- **No host metrics expected:** the canonical config has no `hostmetrics` receiver. Absence of
  `otelcol_receiver_accepted_metric_points` is correct, not a failure (see #454)

## Restore checkpoint (if a dry-run contaminates)

```powershell
Restore-VMSnapshot -VMName clean-host-e2e -Name phase0-ready-20260813 -Confirm:$false
Start-VM clean-host-e2e
```

## Artifacts to produce

- `artifacts/clean-host-e2e-20260813.json`
- `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260813.md` — must state the MSI-on-clean-host verdict
- BOSSCAT_LOG `[CLEAN-HOST E2E]` one-liner, GREEN/AMBER/RED

— prepared by Claude (chat/review); the gate clock is the operator's
