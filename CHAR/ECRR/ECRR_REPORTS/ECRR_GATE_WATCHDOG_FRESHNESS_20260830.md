# ECRR — Nightly Gate: Watchdog Freshness + Disk Floor

**Date:** 2026-08-30
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — all four failure/pass directions proven locally; dispatch proof recorded below

## 1. Examine

Item 3 of the approved plan: nothing watched the watchman. The watchdog log ran unbounded
for a month before the 2026-08-30 audit looked; a dead watchdog task would be invisible
indefinitely. Separately, the new per-tick vitals (`c_free_gb`) are inert data unless
something asserts on them — and a check must be able to both pass and fail.

## 2. Clean

- New `scripts/windows/check-watchdog-freshness.ps1`: exits 1 when the newest
  `watchdog.log` line is missing, unparseable, older than 15 minutes (3 missed ticks —
  tolerant of burst runs and reboot catch-up), or reports `c_free_gb` under 50 GB
  (the 2026-08 VHDX incident bottomed out at 3 GB; 50 gives weeks of warning at that
  growth rate). The floor check skips lines without the field (burst/rotated lines,
  pre-vitals history) rather than false-failing.
- `gate-nightly.yml`: one step after stack reachability, gated on
  `stack_available == 'true'` so GitHub-hosted runners keep their SKIP path. A trip fails
  the workflow — honest red, same class as the 08-19 runner-PATH red. Strengthens the
  standing gate; no new lane or workflow.

**Test matrix (local):** pass on live log (exit 0); `-MaxAgeMinutes 0` → stale trip
(exit 1); `-MinCFreeGb 999` against a vitals-bearing log → floor trip (exit 1); missing
path → trip (exit 1); floor correctly skipped on a pre-vitals newest line (null guard).

## 3. Report

| Assertion | Trips when | Proven |
| --- | --- | --- |
| freshness ≤ 15 min | watchdog task dead/stale | locally (threshold 0) |
| newest line parses | log corrupt | locally (missing-path variant) |
| C: free ≥ 50 GB | VHDX-class disk creep | locally (floor 999) |

Post-merge `workflow_dispatch` of gate-nightly verifies the step green on the self-hosted
runner — run link in BOSSCAT_LOG.

## 4. Role

Claude (chat/review) drafted, tested, merged, and dispatched under standing delegation.
Thresholds (15 min / 50 GB) were named in the plan the operator approved.

**Status:** COMPLETE
