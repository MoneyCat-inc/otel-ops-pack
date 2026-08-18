# Docker VHDX Maintenance

Why `docker_data.vhdx` bloats on this host, and the controls that keep it bounded.
Written after the 2026-08-18 incident (VHDX at 516 GB, C: at 3 GB free, WSL VM
wedged, Docker engine returning 500s).

## Root cause (incident 2026-08-18)

Live Docker data was ~69 GB; the VHDX file was 516 GB. The gap was dead ext4
blocks the VHDX never returns to Windows:

1. ClickHouse's internal `system.*` log tables had **no TTL** and grew to
   **50 GiB** since 2025-10-05 (`text_log` 20.4 GiB at Debug/Trace level,
   `trace_log` 17.6 GiB from the query profiler). Actual SigNoz telemetry:
   under 400 MiB.
2. Merges of those bloated tables exceeded the container's 2 GiB memory limit
   (`MEMORY_LIMIT_EXCEEDED`) and were retried ~98k times/day. Each failed
   attempt wrote and discarded partial parts — allocating fresh ext4 blocks —
   and logged more rows into `text_log`, feeding the loop.
3. A WSL2 VHDX only ever grows (no `discard` on the data mount, sparse mode
   off, never compacted), so the churn ratcheted the host file up until C:
   filled and the VM froze.

Secondary damage: the hard freeze corrupted unix-socket files under
`%LOCALAPPDATA%\Docker\run\` and `%LOCALAPPDATA%\docker-secrets-engine\`,
crash-looping Docker Desktop on restart (see Recovery below).

## Prevention (what this repo now carries)

| Control | Where | Notes |
|---|---|---|
| ClickHouse system-log TTLs, `text_log` at warning, profiler logs disabled | `clickhouse-system-logs-config.xml`, mounted via `docker-compose.yml` | Takes effect on container recreate: `docker compose -p otel up -d signoz-clickhouse` |
| Weekly prune + fstrim | `scripts/windows/docker-weekly-trim.ps1` | Register once: `pwsh -File scripts/windows/docker-weekly-trim.ps1 -Register`. Logs to `artifacts/docker-trim-log.txt` |
| Offline compact (elevated) | `scripts/shrink-docker-vhdx.ps1` | Run when the weekly log warns (VHDX > 200 GB) |

Manual settings worth applying once (not repo-controllable):

- **Cap the VM disk**: Docker Desktop → Settings → Resources → *Virtual disk
  limit* (`DiskSizeMiB` in `settings-store.json`), e.g. 150 GB. Bloat then
  fails inside Docker instead of silently eating C:.
- **Sparse VHDX** (elevated, while WSL is down):
  `wsl --manage docker-desktop --set-sparse true`. With sparse on, the weekly
  fstrim shrinks the host file directly and offline compacts become rare.

## One-time cleanup after the config lands

When `clickhouse-system-logs-config.xml` first applies, ClickHouse renames any
existing table whose settings changed with a `_N` suffix and creates a fresh
one. The renamed tables (and the pre-incident leftovers `query_log_0`,
`trace_log_0`, `metric_log_0`) keep their disk until dropped:

```sql
SELECT table FROM system.tables WHERE database = 'system' AND table LIKE '%_log_%';
-- then for each:
DROP TABLE system.<name>;
```

`trace_log` itself also stops being written but is not auto-dropped; drop it too.

## Recovery runbook (engine down / disk full)

1. `wsl --shutdown`; stop Docker Desktop processes (`com.docker.service` needs
   an elevated seat).
2. If Docker Desktop crash-loops with `remove <path>: The file cannot be
   accessed by the system` on a socket path: the socket file is corrupt and
   undeletable. Rename its parent directory aside (e.g. `Docker\run` →
   `Docker\run.stale-<date>`); Docker recreates it on startup. Known locations:
   `%LOCALAPPDATA%\Docker\run\`, `%LOCALAPPDATA%\docker-secrets-engine\`.
3. Reclaim space: fstrim via the distro (containers cannot run it):
   `wsl -d docker-desktop fstrim -v /mnt/docker-desktop-disk`, then compact
   offline with `scripts/shrink-docker-vhdx.ps1` (elevated).
4. If ClickHouse is merge-looping (`MEMORY_LIMIT_EXCEEDED` from
   `MergeTreeBackgroundExecutor`), truncate the offending `system.*` log
   tables — they are diagnostics, not telemetry.
