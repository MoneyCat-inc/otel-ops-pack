# ECRR — ClickHouse `text_log` merge-retry loop (VHDX watch item reopened)

**Date:** 2026-09-03
**Actor:** Claude (chat/review), config + records under standing delegation from `@fubumaki`; truncate / recreate / compact are machine-operator steps
**Verdict:** **AMBER** — config landed; the loop stays live until the operator truncate + recreate; closes GREEN on 24 h of flat `vhdx_gb` after the next compact

## 1. Examine

The 2026-09-01 VHDX closure (`BOSSCAT_LOG` 2026-09-01T10:30Z, compact 126.3 → 101.8 GB) did not
hold. Watchdog vitals (`artifacts/watchdog/watchdog.log`, `vhdx_gb`):

| Tick | `docker_data.vhdx` |
| --- | --- |
| 2026-09-01 11:25 (first post-compact) | 101.9 GB |
| 2026-09-02 22:05 (plateau) | 156.3 GB |
| Live Docker data (`docker system df`) | ~37 GB |
| Weekly-trim warning threshold | 200 GB |

Growth was ~1.5 GB/hour for 35 hours, then flat. Live evidence from the container:

- `system.errors`: `MEMORY_LIMIT_EXCEEDED` 147,710 since the 2026-09-02 23:07Z recreate.
- `system.text_log` Error rows/day: 708k (08-31), 1.62M (09-01), 1.05M (09-02), 287k by 14:00 (09-03)
  — the loop predates #741; the cap raise did not touch it.
- Top Error loggers last hour: `MergePlainMergeTreeTask::executeStep` (11.5k) and
  `MergeTreeBackgroundExecutor` (10.4k), all `Code: 241 … would use 2.50 GiB`. Failing tables by
  UUID: `system.metric_log` and `system.text_log`.
- `system.part_log` merge writes: 30–40 GiB/day (39.7 GiB on 09-01), dominated by `system.*`.
- `system.metric_log` hourly max `MergesMutationsMemoryTracking`: 1.90–1.97 GiB every hour today
  against a 2.5 GiB server cap; `MemoryTracking` peaks 2.33–2.34 GiB.
- `system.text_log`: 26 parts, largest 889 MiB, 2.68 GiB total — the merge that cannot fit.
- Collateral: SigNoz inserts rejected with code 241 — 38 / 56 / 39 / 78 / 265 / 85 / 20 per day
  (08-28 → 09-03); the collector logs "Exporting failed. Will retry" (11 in 6 h), so delayed,
  not proven lost.

Mechanism: each failed merge of `text_log` is logged at Error level *into* `text_log`. The table
that cannot merge grows from its own failure reports; each retry re-allocates ~1.9 GiB; TTL DELETE
needs the same merges, so it cannot drain either. The 2026-08-18 fix set `text_log` to warning —
enough to stop the Debug/Trace flood, not enough to stop a loop whose payload is Error level.

## 2. Clean

- `clickhouse-system-logs-config.xml`: `text_log` level `warning` → `fatal`, comment records why.
  Server errors remain in `docker logs signoz-clickhouse`; nothing in this stack reads
  `system.text_log`. A level change does not rename the table (no `_N` leftover).
- `clickhouse-memory-config.xml`: `merges_mutations_memory_usage_soft_limit` = 1 GiB (present in
  25.12.5 `system.server_settings`, default 0). Stops new merges being scheduled while merges already
  hold 1 GiB — bounds stacking, does not shrink one oversized merge; that part is removed by the
  operator TRUNCATE. Comment adds the "confirm `changed=1`" rule from #742.
- `docs/DOCKER_VHDX_MAINTENANCE.md`: recurrence section with the ordered operator lines
  (force-recreate → verify settings → TRUNCATE `text_log` + `metric_log` → confirm error counter
  flat and merge memory under 1 GiB → trim + compact) and the pass criterion (flat `vhdx_gb` for
  24 h, not the compact itself).
- `docs/BossCat/BOSSCAT_LOG.md`: one-liner.

Not done from this seat, by rule: TRUNCATE (destructive statement), container recreate on the
host, elevated compact.

## 3. Report

| Item | State |
| --- | --- |
| `text_log` level | fatal (config), applies on recreate |
| Merges soft limit | 1 GiB (config), applies on recreate — verify `changed=1` |
| Existing `text_log` / `metric_log` parts | **operator TRUNCATE pending** |
| VHDX | 156.3 GB, flat since 09-02 22:05; compact only after the loop is confirmed dead |
| Close criterion | `MEMORY_LIMIT_EXCEEDED` counter flat + `vhdx_gb` flat 24 h post-compact |

Standing rule reaffirmed: a compact is not a fix. The 09-01 closure recorded the compact as the
closure; the watchdog vitals were the check that could fail, and did.

## 4. Role

Claude (chat/review) traced the regrowth from watchdog vitals to the failing merges and the
self-feeding log, drafted config and records, opened and squash-merged the PR on green under the
operator's standing delegation. Machine operator (`@fubumaki`) executes the truncate, recreate,
verification, and compact; Claude verifies and closes the ECRR to GREEN afterwards. — 🐾
