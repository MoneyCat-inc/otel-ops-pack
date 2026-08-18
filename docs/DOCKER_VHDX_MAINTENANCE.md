# Docker VHDX Maintenance

Why `docker_data.vhdx` bloats on this host, and the controls that keep it bounded.

**Incident 2026-08-18 — CLOSED** (VHDX 516 GB, C: at 3 GB free, WSL wedged, Docker engine 500s). Closeout: `CHAR/ECRR/ECRR_REPORTS/ECRR_CLICKHOUSE_VHDX_INCIDENT_20260818.md`. PRs #565 / #567 (source) and #566 (this runbook).

## Closed state (2026-08-18 13:40 BST)

| | Before | After |
|---|---|---|
| `docker_data.vhdx` | 516 GB | 102 GB |
| C: free | 3 GB | ~425 GB |
| ClickHouse `system` DB | 50 GiB, unbounded, merge death-loop | ~1.6 MiB, live tables 7-day TTL |
| `text_log` writes | ~15M Debug/Trace rows/day | warning-only |
| Failed merges | ~98k/day | none |
| Regrowth guard | nothing | weekly prune+fstrim task, warns at 200 GB |

It was not the Windows collector, canaries, or SigNoz telemetry (~350 MiB). ClickHouse's own unbounded `system.*` diagnostics fed a merge-retry loop that allocated fresh ext4 blocks into a VHDX that only grows.

`crash_log` is left without TTL on purpose: it only receives rows when the server crashes (~5 KiB). Self-limiting; not worth a config cycle.

## Root cause

Live Docker data was ~69 GB; the VHDX file was 516 GB. The gap was dead ext4 blocks the VHDX never returns to Windows:

1. ClickHouse internal `system.*` log tables had **no TTL** and grew to **50 GiB** since 2025-10-05 (`text_log` 20.4 GiB at Debug/Trace, `trace_log` 17.6 GiB from the memory sampler). Actual SigNoz telemetry: under 400 MiB.
2. Merges of those tables exceeded the container's **2 GiB** memory limit (`MEMORY_LIMIT_EXCEEDED`) and were retried ~98k times/day. Each failed attempt wrote and discarded partial parts — allocating fresh ext4 blocks — and logged more rows into `text_log`.
3. A WSL2 **data** VHDX (`docker_data.vhdx`) only ever grows: no `discard` on the data mount, sparse mode does **not** cover this file (`wsl --manage --set-sparse` only affects the distro's small `ext4.vhdx`), never compacted — so the churn ratcheted the host file until C: filled and the VM froze.

Secondary damage: the freeze corrupted unix-socket reparse points under `%LOCALAPPDATA%\Docker\run\` and `%LOCALAPPDATA%\docker-secrets-engine\`, crash-looping Docker Desktop on restart.

### Gotchas (verified live)

- **`<tag remove="remove"/>` is a no-op on ClickHouse 25.x.** Compiled-in defaults re-enable `trace_log`, `asynchronous_metric_log`, etc. even when the element is absent from the preprocessed config. Bound them with an explicit 7-day TTL (the mechanism that actually applies). #565 tried `remove`; #567 replaced it.
- **Changing TTL/settings renames the old table to `system.<name>_N`.** Those leftovers keep their disk until `DROP TABLE`. Swept 2026-08-18 after #567 recreate; none remain.
- **`query_metric_log` / `latency_log`** were in `config.d` but existing tables did not rename; they needed `ALTER TABLE … MODIFY TTL` once. Done.
- **Quit Docker Desktop before `wsl --shutdown`.** If Desktop is still running it auto-restarts WSL (breaks Ubuntu integration and re-locks the VHDX). Then: `wsl --shutdown`; `Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx" -Mode Full`.
- **`fstrim` does not shrink the host file** unless the data disk is sparse (it is not). Trim is still required *before* compact so unused ext4 blocks are punch-holed for Optimize-VHD.

## Prevention (what this repo now carries)

| Control | Where | Notes |
|---|---|---|
| ClickHouse system-log TTLs, `text_log` at warning, memory sampler off | `clickhouse-system-logs-config.xml`, mounted via `docker-compose.yml` | Apply: `docker compose -p otel up -d --force-recreate signoz-clickhouse` |
| Weekly prune + fstrim, warn at 200 GB | `scripts/windows/docker-weekly-trim.ps1` | Registered: `OTel-Docker-Weekly-Trim` Mondays 09:00. Re-register: `pwsh -File scripts/windows/docker-weekly-trim.ps1 -Register`. Logs to `artifacts/docker-trim-log.txt` |
| Offline compact (elevated) | `scripts/shrink-docker-vhdx.ps1` | Run when the weekly log warns (VHDX > 200 GB). `-SkipPrune -Force` if guest data is already small. |

Manual settings worth applying once (not repo-controllable):

- **Cap the VM disk**: Docker Desktop → Settings → Resources → *Virtual disk limit* (`DiskSizeMiB` in `settings-store.json`), e.g. 150 GB. Bloat then fails inside Docker instead of silently eating C:.
- **Do not rely on sparse** for `docker_data.vhdx`. It is a separately attached disk; `wsl --manage docker-desktop --set-sparse true` only covers the distro `ext4.vhdx`.

## Recovery runbook (engine down / disk full)

1. Quit Docker Desktop from the systray (or `docker desktop stop`). Then `wsl --shutdown`. `com.docker.service` needs an elevated seat if it will not die.
2. If Docker Desktop crash-loops with `remove <path>: The file cannot be accessed by the system` on a socket path: the socket is corrupt and undeletable. Rename its parent aside (e.g. `Docker\run` → `Docker\run.stale-<date>`); Docker recreates it on startup. Known locations: `%LOCALAPPDATA%\Docker\run\`, `%LOCALAPPDATA%\docker-secrets-engine\`. Leftovers from 2026-08-18 (`*.stale-20260818`) are inert; delete from an elevated shell whenever.
3. If ClickHouse is merge-looping (`MEMORY_LIMIT_EXCEEDED` from `MergeTreeBackgroundExecutor`), truncate the offending `system.*` log tables — they are diagnostics, not telemetry.
4. Reclaim space: fstrim via the distro (containers cannot): `wsl -d docker-desktop fstrim -v /mnt/docker-desktop-disk`, then compact offline with `scripts/shrink-docker-vhdx.ps1` (elevated). Expect the host file to fall toward live guest used + images (this incident: 516 GB → 102 GB, ~17 GB live ClickHouse/guest after truncate).
