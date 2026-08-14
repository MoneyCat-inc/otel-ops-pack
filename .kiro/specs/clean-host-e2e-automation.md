# Spec: Scheduled Clean-Host E2E Automation Wrapper

> **projection — not canonical**
>
> Source:
> - `docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md`
> - `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`
> - `docs/BossCat/CLEAN_HOST_E2E_RUN_CARD_20260813.md`
>
> Actor: Kiro{Implementer} (provisional — pilot-scoped)
> Date: 2026-08-14

---

## Goal

Deliver a PowerShell automation wrapper that orchestrates clean-host E2E gate
runs on a prepared Hyper-V guest. The wrapper:

1. Validates Phase-0 contamination state (fail closed if contaminated)
2. Runs Phases 1–4 gate clock with a 30-minute hard cap
3. Produces structured artifacts: timing JSON, ECRR report stub, BOSSCAT_LOG entry
4. Exits non-zero on any failure (contamination, clock >30 min, verify ≠ 0)

---

## Requirements

### R1 — Phase-0 Contamination Checkpoint

The wrapper SHALL check the guest state before starting the gate clock:

| Check | Pass | Fail (abort) |
|-------|------|--------------|
| `C:\otel` absent | `Test-Path C:\otel` → false | Directory exists |
| No SigNoz containers | `docker ps -a --filter name=signoz` → empty | Any signoz container present |
| Collector service state | Stopped OR not installed | RUNNING (contaminated) |
| Docker engine responsive | `docker info` exit 0 | Docker not running |
| Ports free: 4317, 4318, 5320, 5321, 8080 | No listener on any | Port bound |

If any check fails, the wrapper SHALL:
- Write a contamination report to stderr
- Exit with code **10** (distinct from gate failures)
- NOT start the gate clock

### R2 — Gate Clock (Phases 1–4)

The wrapper SHALL execute the gate clock sequence:

1. `git clone --single-branch <repo> C:\otel`
2. `start-signoz.ps1` + `preflight-health-check.ps1`
3. Enable collector service + `install-or-repair-otel-collector.ps1`
4. `health-check-collector-config.ps1` + `quick-monitor.ps1`
5. `canary-test.ps1` + `BRAV/SCPT/verify-pipeline.ps1`

Timing: record start/stop per step; total from first clone byte to verify exit.

### R3 — 30-Minute Hard Cap

If the gate clock exceeds 30 minutes wall-clock time:
- Terminate remaining steps
- Set status to **RED** (clock exceeded)
- Record the actual elapsed minutes in the timing JSON
- Exit with code **2**

### R4 — Fail-Closed Semantics

| Condition | Exit code | Status |
|-----------|-----------|--------|
| Contamination detected (R1) | 10 | CONTAMINATED |
| Gate clock > 30 min | 2 | RED (clock) |
| verify-pipeline exit ≠ 0 | 1 | RED (verify) |
| Any critical step exit ≠ 0 | 1 | RED |
| All pass, clock ≤ 30 min | 0 | GREEN |

### R5 — Timing JSON Output

Path: `artifacts/clean-host-e2e-<YYYYMMDD>.json`

Schema (matches existing pattern from `clean-host-e2e-20260813.json`):

```json
{
  "run_id": "clean-host-e2e-<YYYYMMDD>",
  "status": "GREEN|RED|CONTAMINATED",
  "gate_clock_minutes": 6.86,
  "gate_clock_start_utc": "ISO8601",
  "gate_clock_stop_utc": "ISO8601",
  "verify_exit": 0,
  "target_minutes": 30,
  "head_sha": "abc1234",
  "steps": [
    { "name": "git-clone", "minutes": 0.45, "exit_code": 0, "ended_utc": "ISO8601" }
  ],
  "phase0_checkpoint": {
    "contamination_checks_passed": true,
    "docker_ok": true,
    "collector_state": "Stopped",
    "ports_free": true
  },
  "actor": "Kiro{Implementer}",
  "recorded_utc": "ISO8601"
}
```

### R6 — ECRR Report Stub

Path: `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_<YYYYMMDD>.md`

The wrapper SHALL generate a template with:
- Frontmatter (markdownlint-disable)
- Title, date, actor, verdict placeholder
- Examine section (populated from contamination checkpoint data)
- Clean section (populated from step results)
- Report section (gate clock time, verify exit, assertions)
- Role section (actor trailer)

### R7 — BOSSCAT_LOG Entry

Append one-liner to `docs/BossCat/BOSSCAT_LOG.md` matching established format:

```
- <ISO8601> — **[CLEAN-HOST E2E <STATUS>]** Run `clean-host-e2e-<YYYYMMDD>`: clone→first span **X.XX min** (target ≤30), verify exit N. <details>. ECRR: `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_<YYYYMMDD>.md`; artifact `artifacts/clean-host-e2e-<YYYYMMDD>.json`. — **Kiro{Implementer}**
```

---

## Operator-Only Boundaries

The following actions are NOT automated by this wrapper. If the wrapper
reaches a point where one is required, it SHALL stop, report why, and
instruct the operator:

1. **Hyper-V snapshot restore** — contamination recovery
2. **Elevated MSI install / service repair** — Phase 0 setup
3. **Gate clock physical execution** — the wrapper orchestrates but
   the operator must launch it elevated on the guest

The wrapper is designed to be invoked BY the operator (or a scheduled task
running as SYSTEM on the guest) after Phase 0 is already complete and the
checkpoint is at the expected state.

---

## File Layout

```
scripts/windows/invoke-clean-host-e2e.ps1   ← main automation wrapper
```

Single script. No new dependencies beyond PowerShell 7+ and git (both
already required by the project).

---

## Out of Scope

- AWS merge gates or CI workflows
- Hyper-V automation (snapshot management)
- Replacing or modifying existing `run-gate-clock.ps1`
- SigNoz API key provisioning
- Concurrent Kiro + Cursor edits

---

## Acceptance Criteria

1. `pwsh -c "& { . scripts/windows/invoke-clean-host-e2e.ps1 }"` parses without error
2. On a contaminated host (C:\otel exists), exits 10 immediately
3. On a clean host, runs Phases 1–4 and produces all three artifacts
4. Clock > 30 min triggers abort with RED status
5. verify-pipeline exit ≠ 0 produces RED verdict
6. Timing JSON matches schema above
7. ECRR stub is valid markdown with four ECRR sections
8. BOSSCAT_LOG entry matches established one-liner format
