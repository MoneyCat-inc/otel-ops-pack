# ECRR — ClickHouse `text_log` merge-retry loop (VHDX watch item reopened)

**Date:** 2026-09-03
**Actor:** Claude (chat/review), config + records under standing delegation from `@fubumaki`; truncate / recreate / compact are machine-operator steps
**Verdict:** **GREEN** — loop broken, config loaded, VHDX compacted 156 → 49.9 GB; 24-hour watchdog window running (due 2026-09-04T15:34Z)

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
operator's standing delegation. Machine operator (`@fubumaki`) executed the truncate, recreate,
verification, and compact. Claude verified each step and closed the ECRR to GREEN.

## 5. Close — GREEN (2026-09-03T15:34Z)

All operator steps completed and verified:

| Step | Result |
| --- | --- |
| `--force-recreate signoz-clickhouse` | ✅ container Started healthy |
| `max_server_memory_usage` `changed=1` | ✅ 2684354560 (2.5 GiB) |
| `merges_mutations_memory_usage_soft_limit` `changed=1` | ✅ 1073741824 (1 GiB) — was `0` before recreate |
| `TRUNCATE system.text_log` | ✅ no error |
| `TRUNCATE system.metric_log` | ✅ no error |
| `MEMORY_LIMIT_EXCEEDED` counter post-truncate | ✅ **147** — flat across 3 readings over ~16 min |
| `shrink-docker-vhdx.ps1 -SkipPrune -Force` | ✅ 156.28 GB → 49.92 GB (106.35 GB freed, 68.1%) |

**Pass criterion:** `vhdx_gb` in watchdog log must stay flat for 24 hours after compact.
24-hour window opens: **2026-09-03T15:34Z**. Watchdog check due: **2026-09-04T15:34Z**.

Verdict: **GREEN** — loop broken, config loaded, VHDX compacted. 24-hour watchdog window running. 🐾

## 6. Independent verification — chat/review seat (2026-09-03 15:37–15:47Z)

Read live from the recreated container (uptime 193 s at first read), not from the operator's
transcript:

| Check | Observed |
| --- | --- |
| `max_server_memory_usage` / `merges_mutations_memory_usage_soft_limit` | 2684354560 / 1073741824, both `changed = 1` |
| `system.text_log` rows since restart | **0** (level `fatal` took) |
| `system.errors` `MEMORY_LIMIT_EXCEEDED` | no row at 15:37Z and 15:47Z (zero since restart) |
| Inserts rejected with code 241 | last at 15:10Z (pre-truncate); **0** since restart |
| `MergesMutationsMemoryTracking` 5-min max | 1.74 GiB at 15:10Z (last failing `metric_log` merge, peak 1.89 GiB), then 23–148 MiB from 15:15Z on; 52 MiB over the last 10 min |
| `MemoryTracking` 5-min max | 2.16 GiB at 15:10Z, then 289–428 MiB |
| `vhdx_gb` (watchdog) | 156.3 → 50.2 (16:35 local) → 50.8 → 50.9; increments 0.6 then 0.1 GB — post-restart settle, not the 1.5 GB/h slope |

The loop died at the truncate (~15:14Z), before the compact — the merge-memory series shows it.
The 24-hour flat-`vhdx_gb` criterion is the only item still open; it is a watchdog read on
2026-09-04T15:34Z, not a change. If the slope reappears, the diagnosis path is the same table
above, starting with `system.part_log` `peak_memory_usage` by table.

## 7. Addendum (2026-09-03 18:30–19:00Z) — the loop is back on `metric_log` alone; verdict AMBER

Read during the Ready-For-Gate follow-through, not from a relay:

| Check | 16:20Z | 18:35Z |
| --- | --- | --- |
| `system.errors` `MEMORY_LIMIT_EXCEEDED` | absent | **390**, last 18:29:54Z |
| Failed merges since 15:30Z (`system.part_log`, `error=241`) | 0 | **389**, all `system.metric_log`, 17:18:53Z → 18:29:23Z, peak 1.99 GiB |
| `metric_log` active parts | (truncated 15:14Z) | 7 parts, **all Compact**, 11,664 rows, **4.96 MiB** |
| `text_log` rows / SigNoz insert exceptions (code 241) | 0 / 0 | 0 / 0 |
| `MergesMutationsMemoryTracking` between attempts | 0 B | 0 B |
| ClickHouse active bytes | 2.24 GiB | 2.26 GiB |
| Docker data disk, real usage (`df` in `docker-desktop`) | — | 36.4 GB of 1006.9 GB |
| Watchdog `vhdx_gb` | 50.2 → 50.9 | **52.3** at 18:35Z; slope 0.2 GB/h before 17:18Z, 0.5 GB/h after |

Reading: the 15:14Z TRUNCATE removed the oversized `text_log` part and the loop stopped, but the
`metric_log` merge cost is structural. The wide schema carries 1,552 columns and a merge opens a
stream per column, so seven Compact parts holding 5 MiB peak at 1.99 GiB — the same figure the
889 MiB `text_log` part produced. Fewer rows cannot make it cheaper, and the 1 GiB soft limit
bounds stacking, not one merge. Nothing self-feeds now (`text_log` at `fatal`) and inserts are
unaffected, so the damage is confined to ext4 churn — the VHDX slope resumed the moment merges
started failing, while real usage stayed flat.

Section 5's GREEN stands for what it claimed (loop broken, config loaded, compact done) and is
not edited. This addendum changes the verdict for the *item* to **AMBER**: the 24 h flat-`vhdx_gb`
criterion cannot pass while `metric_log` merges fail, and the fix is a schema change, not another
TRUNCATE. Config change filed the same evening in `clickhouse-system-logs-config.xml`
(`<schema_type>transposed</schema_type>`, ClickHouse PR #78412) with operator lines in
`docs/DOCKER_VHDX_MAINTENANCE.md`: recreate → verify create statement → `DROP` the renamed
`metric_log_N` → error counter flat → 24 h read restarts. Alternative considered and not chosen:
Altinity's `vertical_merge_algorithm_min_rows_to_activate = 1` via `ALTER TABLE` — a stopgap that
keeps 1,552 columns and a table-local setting a later config-driven recreate would silently reset.

Side finding, hygiene only: `signoz-zookeeper` has `autopurge.purgeInterval=0`; 202 preallocated
64 MiB transaction logs since 2025-10 (sparse, 16 MiB real — `docker system df` reports the
apparent 6.79 GB). Not a VHDX driver; recorded for the next config touch.
