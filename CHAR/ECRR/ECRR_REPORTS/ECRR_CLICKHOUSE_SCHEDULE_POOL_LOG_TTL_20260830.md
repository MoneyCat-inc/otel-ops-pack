# ECRR — TTL for `system.background_schedule_pool_log`

**Date:** 2026-08-30
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — TTL applied and verified live; operator follow-up (leftover `_0` drop) closed 2026-08-30

## 1. Examine

Follow-up from the steady-state log audit (`ECRR_STEADY_STATE_LOG_AUDIT_20260830.md`):
`system.background_schedule_pool_log` had no TTL — the only unbounded `system.*` MergeTree
log besides the deliberately-unbounded `crash_log`. Cause: the table did not exist when
#565/#567 bounded the system logs on CH 25.8; it appeared with the 25.12 upgrade (verified:
server 25.12.5.44, table's first row 2026-08-23 16:15, the upgrade window). Size at audit:
1.04 MiB — small, but the 2026-08-18 VHDX incident is exactly the failure mode of leaving
`system.*` writers unbounded.

## 2. Clean

- `clickhouse-system-logs-config.xml`: added `background_schedule_pool_log` with the standard
  `event_date + INTERVAL 7 DAY DELETE` TTL, with a comment recording why it was missed and
  that `crash_log` stays unbounded on purpose.
- Applied via `docker restart signoz-clickhouse` (config is a read-only mount into
  `config.d/`); ClickHouse healthy again in under a minute, all four SigNoz containers healthy.
- **Verified live:** fresh `background_schedule_pool_log` has the TTL (`has_ttl = 1`);
  per the documented rename behavior the old table was moved aside as
  `background_schedule_pool_log_0` (`has_ttl = 0`, ~1 MiB).

## 3. Report

| Item | State |
| --- | --- |
| `background_schedule_pool_log` TTL | 7-day DELETE, active |
| `crash_log` | unbounded by design (black box, ~KiB) |
| Leftover `background_schedule_pool_log_0` | **dropped by machine operator, 2026-08-30** (~1.04 MiB reclaimed); post-drop verified: `_0` gone, TTL table present and active, all four SigNoz containers healthy |

The drop was executed by the operator (`docker exec signoz-clickhouse clickhouse-client -q "DROP TABLE system.background_schedule_pool_log_0"`) after automation was correctly denied the destructive statement.

## 4. Role

Claude (chat/review) edited config, restarted the container, and verified under standing
delegation. The destructive `DROP TABLE` of the renamed leftover was blocked by the
permission layer and is left to the machine operator.

**Status:** COMPLETE
