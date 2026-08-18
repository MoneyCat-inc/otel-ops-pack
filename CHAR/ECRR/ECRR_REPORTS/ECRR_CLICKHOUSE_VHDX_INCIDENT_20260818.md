# ECRR — ClickHouse system-log / Docker VHDX disk-full incident

**Date:** 2026-08-18  
**Actor:** Cursor{Implementer} + chat/review + machine operator `@fubumaki`  
**Verdict:** **GREEN — CLOSED**  
**PRs:** #565 (TTL + weekly trim), #567 (`remove=` no-op fix), #566 (runbook)

## 1. Examine

- C: **3 GB** free (99.7%). `docker_data.vhdx` **516 GB**, last write 06:39. Engine HTTP 500 / ping timeout. WSL including Ubuntu frozen (`HCS_E_CONNECTION_TIMEOUT`).
- Windows collector healthy; export queue **full**; this boot was **not** filling ClickHouse.
- Hourly monitor dormant since 2025-10-02. Canaries tiny.
- Guest used ~69 GB. ClickHouse volume dominated by `system.*`: `text_log` 20.4 GiB, `trace_log` 17.6 GiB, total ~50 GiB since 2025-10-05. SigNoz telemetry ~350 MiB.
- Background merges failed `MEMORY_LIMIT_EXCEEDED` at 1.80 GiB (~98k/day). No TTL. Data disk mounted without `discard`. Sparse WSL flag does not cover `docker_data.vhdx`.
- `<tag remove="remove"/>` on ClickHouse 25.x does not disable compiled-in system logs (#565 gap, fixed in #567).

## 2. Clean

- Truncated ClickHouse `system.*` diagnostic tables (not telemetry) → `system` DB ~1.6 MiB.
- Quit Docker Desktop, then `wsl --shutdown`, then `Optimize-VHD -Mode Full` (309s): VHDX **516.47 → 102.38 GB**, C: free **~425 GB**.
- Recreated `signoz-clickhouse` with `clickhouse-system-logs-config.xml` (`text_log` warning + 7-day TTL; sampler off).
- Merged #567; dropped 13 leftover `system.*_N` tables; `ALTER TABLE` TTL on `query_metric_log` and `latency_log` (config present, tables not renamed).
- Registered `OTel-Docker-Weekly-Trim` (Mondays 09:00). Moved corrupted sockets aside (`*.stale-20260818`).

## 3. Report

| Check | Before | After |
| --- | --- | --- |
| `docker_data.vhdx` | 516 GB | 102 GB |
| C: free | 3 GB | ~425 GB |
| ClickHouse `system` | 50 GiB unbounded | ~1.6 MiB, 7-day TTL |
| `text_log` | ~15M Debug/Trace rows/day | warning-only |
| Failed merges | ~98k/day | none |
| Guard | none | weekly prune+fstrim, warn @ 200 GB |

Runbook: `docs/DOCKER_VHDX_MAINTENANCE.md`.

**Deferred (accepted):** `crash_log` no TTL (~5 KiB, crash-only). Stale socket dirs deletable elevated, zero urgency. Optional Docker Desktop `DiskSizeMiB` cap (~150 GB) still a one-time UI setting.

## 4. Role

Chat/review diagnosed merge-loop vs collector firehose. Cursor{Implementer} truncated, compacted, merged #567, dropped leftovers, ALTERed remaining TTLs. Machine operator handled elevated WSL/Docker stop order and PR authorship for #565/#566/#567.

**Status:** COMPLETE

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: ECRR processor run 2026-08-18, 389/389 gated (PR #571).
- Guardrail: Append-only; original report body unchanged.
