# ECRR — Steady-State Log Audit + Watchdog Log Rotation

**Date:** 2026-08-30
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — all steady-state logs alive and honest; one unbounded writer fixed (rotation), two report-only findings

## 1. Examine

Audit of every recurring log the steady-state posture (`docs/PURPOSE.md`) produces, checked live:

- **`artifacts/watchdog/watchdog.log`** — alive. 7,650 lines, 2026-08-02 → 2026-08-30, 987 KB, ~32 KB/day, **no rotation (unbounded)**. 15 non-ok lines, all explained: two `reenabled_and_started` (08-04, 08-12 — the watchdog doing its job), a 25-minute `start_failed`/`not_found` flap on 08-13 13:10–13:35 during the collector 0.158.0 reinstall (recovered 14:15), one `started` on 08-14. Coverage gaps only on 08-25 (197/288) and 08-26 (234/288) — quarterly-upgrade reboots.
- **`docs/BossCat/BOSSCAT_LOG.md`** — current; last entry 2026-08-19 (runner PATH incident).
- **Evidence lane** — `otel-ops-evidence` run-archiver committing several times daily; latest 2026-08-30T01:31Z. Monthly rollup due ~09-01.
- **ClickHouse `system.*` logs** — TTL present on all `*_log` MergeTree tables except `crash_log` (5.21 KiB, deliberately unbounded per the 08-18 VHDX incident closeout) and **`background_schedule_pool_log` (1.04 MiB, unbounded — not covered by #565/#567**, likely new in CH 25.8). TTL enforcement is lazy-on-merge: `system.text_log` holds 1.14 M expired rows (~30% of 3.85 M; event_date < 08-23) awaiting merge; `system.trace_log` is clean at exactly 7 days. **No forced `OPTIMIZE`** — the 08-18 incident was a merge memory-limit death-loop; forcing a ~1 GiB part merge risks re-creating it. Normal merges + weekly trim will drain it.
- **`artifacts/otel-logs/`** — stale point-in-time output (.NET auto-instrumentation, Oct 2025), not a steady-state writer.

## 2. Clean

`scripts/windows/watchdog-otelcol.ps1`: size-based rotation before the service check.

- New params: `-MaxLogBytes` (default 5 MB ≈ 5 months at current rate), `-MaxArchives` (default 3). Bound: `(1 + MaxArchives) × MaxLogBytes` = 20 MB worst case.
- Chain `watchdog.log → .1 → .2 → .3`, oldest dropped. Fresh log opens with a `{"action":"rotated","rotated_bytes":N}` line; failure writes `{"action":"rotate_failed","err":...}` — rotation is observable in both directions and never blocks the service check (exit code stays tied to service health only).
- No task re-registration needed: `BossCat-OtelcolWatchdog` invokes the script from disk.

**Test:** scratchpad run, 1,500-byte threshold, 4 consecutive rotations — archive chain shifted correctly, oldest dropped, `rotated` marker present, exit 0 each run against the live (Running) service.

## 3. Report

| Log | Status | Action |
| --- | --- | --- |
| watchdog.log | alive, was unbounded | **fixed** — rotation at 5 MB, 3 archives |
| BOSSCAT_LOG.md | current | none |
| otel-ops-evidence lane | committing daily | none; rollup due ~09-01 |
| ClickHouse `system.*` TTLs | holding (lazily) | report-only: `background_schedule_pool_log` has no TTL — fold into next config touch |
| `system.text_log` expired backlog | 1.14 M rows awaiting merge | report-only: do **not** force OPTIMIZE; recheck after weekly trim |

## 4. Role

Claude (chat/review) audited, drafted, tested, and merged under the operator's standing delegation. No credentials, no elevation — the scheduled task itself was untouched.

**Status:** COMPLETE
