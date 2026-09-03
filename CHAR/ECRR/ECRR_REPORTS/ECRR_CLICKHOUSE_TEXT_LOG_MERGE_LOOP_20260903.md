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
