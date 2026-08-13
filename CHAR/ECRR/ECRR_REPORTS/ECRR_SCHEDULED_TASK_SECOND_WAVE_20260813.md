# ECRR — Scheduled-Task Second Wave: elevated inventory and disposition

**Date:** 2026-08-13
**Actor:** Claude (chat/review seat); elevated enumeration by machine operator `@fubumaki`
**Verdict:** **GREEN** — every project-owned task classified against a reproduced root cause; no task
changed by this report, disposition proposed for operator execution

## 1. Examine

Elevated enumeration returned **334 tasks**, against 228 from the non-elevated pass corrected in
`ECRR_PHASE0_SCHEDULER_INVENTORY_20260803.md`. Raw record archived to `otel-ops-evidence`
@ `63c3f02`, `CHAR/EVID/artifacts/scheduled-tasks/task-inventory-elevated-20260813.json`.

**Result codes, decoded.** Two carried working interpretations that were wrong:

| Code | Hex | n | Meaning |
|---|---|---|---|
| 0 | `0x00000000` | 143 | success |
| 267011 | `0x00041303` | 117 | `SCHED_S_TASK_HAS_NOT_RUN` — genuinely never run |
| 64 | `0x00000040` | 30 | **pwsh 7 `-File <missing>`** |
| 4294770688 | `0xFFFD0000` | 11 | **Windows PowerShell 5.1 `-File <missing>`** |
| 2147943467 | `0x8007042B` | 7 | `ERROR_PROCESS_ABORTED` |
| 2147943515 | `0x8007045B` | 6 | `ERROR_SHUTDOWN_IN_PROGRESS` |
| 2 | `0x00000002` | 3 | script-level exit (Resonai social) |

Corrections worth recording. `4294770688` was read as "task has not yet run"; it is not — that is
`267011`, a different value, and the affected tasks *had* run with zero missed runs. The reported
hex `0xFFFEFEF0` was also wrong; the value is `0xFFFD0000`. Both were reproduced directly:

```text
powershell.exe -File <missing>  ->  -196608  ->  unsigned 4294770688
pwsh.exe       -File <missing>  ->  64
```

**Exit 64 and exit 0xFFFD0000 are the same fault reported by two different hosts.** The split is
perfect: 30/30 exit-64 tasks invoke pwsh 7, 11/11 exit-0xFFFD0000 tasks invoke powershell 5.1.

**Every one of those 41 tasks points at a script that does not exist — 41 of 41, no exceptions.**

**Root cause.** 19 of the 41 name a path under `scripts/` while the script itself lives in
`BRAV/SCPT/`. That is the tetragram reorganisation: files moved, registered tasks did not. It is the
same path-drift class already found in the ECRR script cluster
(`ECRR_COMPLIANCE_ENGINE_RETIREMENT_20260803.md`), now confirmed to extend to the scheduler.

## 2. Clean

No task was created, modified, or unregistered by this report. Analysis only; disposition below is a
proposal for the operator, who alone can execute it.

## 3. Report

Of 334 tasks, **54 are project-owned** (two further name matches — `SpaceAgentTask`, `Firefox
Default Browser Agent` — are vendor tasks caught by the filter and excluded).

| Class | n | Evidence | Proposed disposition |
|---|---|---|---|
| Healthy | 9 | exit 0 | keep |
| Broken, script genuinely gone | 22 | target absent everywhere | **unregister** |
| Broken, script relocated to `BRAV/SCPT/` | 19 | target absent at named path, present elsewhere | **decide per task — see below** |
| Script present, real failure | 3 | Resonai social, exit 2 | Phase 2 SOCM scope |
| Script present, real failure | 1 | `IONABossCatBootHealth`, exit 1 | diagnose |

**Repairable does not mean repair.** The 19 relocated tasks are the subtle group. Repointing them
would silently resurrect machinery this project has just deliberately removed — `ECRR-Compliance-Monitor`,
`ECRR Compliance Monitoring`, `ECRR Archive Management`, `ECRR CI Integration`,
`ECRR-Orchestrator-Daily`, `OTel-Canary-Test` and `OTel-ECRR-Canary` all belong to the compliance
engine retired in #433. Repairing them would undo Phase 0 by hand.

Of the 19, the ones plausibly worth repointing rather than retiring are `OTel-Artifacts-Cleanup`
(prunes `artifacts/` beyond 30 days — directly serves the Phase 0 exit criterion) and
`BossCat-Nightly-Orchestration` (already an intentional survivor). The rest should be judged against
the standing rule: no recurring writer without an owner, a review date, and a kill switch.

**These 41 have been failing silently since the reorganisation.** Nothing surfaced it, because a
failing scheduled task on a workstation is invisible unless someone looks. That is the same class of
defect as the compliance gate that could never fail (#433) and the drift guard that could never pass
(#438) — machinery that reports nothing and is therefore trusted by default.

## 4. Role

Chat/review seat enumerated, decoded, reproduced, and classified. Machine operator executes.

**Proposed operator action, elevated** — unregister the 22 with no surviving script, then decide the
19 case by case. Suggested first cut, safe because the target does not exist in any location:

```powershell
$gone = @(
  'AgentQueueTelemetry','DiskUsageMonitor','ECRR Compliance Monitor','ECRR-AutoBot',
  'IONA-SigNoz-Daily-Verification','MemoryAlertMonitor','MemX Hardware Audit',
  'OTel GPU Smoke Nightly','OTel-Parser-Error-Monitor','OTel-Parser-Monitoring',
  'otel_config_backup_daily','otel_drift_guard_15m','otel_queue_watch_5m',
  'QueueSteward-NightlyDiagnostics','Resonai-Agent-Watchdog','SigNoz-Adaptive-Monitor',
  'SigNoz-Canary-Monitor','SigNozCanaryMonthlyDrill','BossCatAgentWatchdog',
  'EventLogCanaryApplication','EventLogCanarySystem','QueueHealthCanary'
)
foreach ($t in $gone) { Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction Continue }
```

Note `Resonai-Agent-Watchdog` additionally carries a doubled path segment
(`...\scripts\scripts\agent\svc\...`), so it would have failed even had the script survived.

Deferred, not in scope here: the three `Resonai-*` social maintenance tasks belong to the SOCM split
and should be resolved in Phase 2 alongside the AGENTS.md remnants; `IONABossCatBootHealth` runs a
script that exists and fails for its own reasons, needing diagnosis rather than disposition.

**Status:** COMPLETE
