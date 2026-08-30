# ECRR — Watchdog Per-Tick Start-Type Check + Host Vitals

**Date:** 2026-08-30
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — both fields live-tested; one branch validated by review (noted below)

## 1. Examine

Two gaps from the 2026-08-30 watchdog analysis (parked in BOSSCAT_LOG, operator said go):

1. A service left **Disabled while Running** (the MSI pattern) went unnoticed until it next
   stopped — the watchdog only read start type on the not-Running path.
2. Nothing on the host watched disk between the 5-minute liveness tick and the weekly trim;
   the 2026-08 VHDX incident grew for weeks in that blind spot.

## 2. Clean

`scripts/windows/watchdog-otelcol.ps1`:

- **Start type read every tick** and carried on the ok/verdict lines. Running + Disabled →
  re-enabled on the spot (`reenabled_while_running`); `sc.exe` failure surfaces as
  `reenable_failed` with the exit code, exit code still tied to liveness only.
- **Host vitals on the heartbeat**: `c_free_gb` (C: free) and `vhdx_gb`
  (`docker_data.vhdx` size) on ok and verdict lines. Nulls, never throws, when unreadable.
  VHDX path is an explicit user-profile parameter because the task runs as SYSTEM, whose
  `$env:LOCALAPPDATA` is not this profile (weekly-trim's env-var pattern would silently
  point elsewhere under SYSTEM).
- Log growth ~+35 bytes/line → rotation cadence stays ~4 months per 5 MB.

**Test:** happy path against live `otelcol-contrib` → `start_type:2, c_free_gb:417.2,
vhdx_gb:105.6` (both figures match direct reads); failure path → verdict line carries the
same fields. **Honest gap:** no Running+Disabled service exists on the host to trigger
`reenabled_while_running` live; the branch reuses the exact `sc.exe config … delayed-auto`
remediation already proven in production (08-04, 08-12 `reenabled_and_started` entries),
so validation is by review plus that precedent. First real MSI event will exercise it.

## 3. Report

| Field | Value on healthy tick | Asserted by |
| --- | --- | --- |
| `start_type` | 2 (delayed-auto) | remediated in-script when 4 |
| `c_free_gb` | 417.2 at ship time | nightly gate floor (50 GB) — see `ECRR_GATE_WATCHDOG_FRESHNESS_20260830.md` |
| `vhdx_gb` | 105.6 at ship time | observation; weekly trim owns remediation |

## 4. Role

Claude (chat/review) drafted, tested, and merged under standing delegation. No elevation;
task untouched.

**Status:** COMPLETE
