# SigNoz stack upgrade — runbook

**Scope:** the Docker side of the pack (`docker-compose.yml`: SigNoz, signoz-otel-collector,
telemetrystore migrator, ClickHouse). The Windows collector has its own runbook
(`windows-collector.md`) and its own pin (`scripts/windows/collector-version.txt`).

**Pin authority:** the SigNoz Helm chart `values.yaml` for the target release —
`https://raw.githubusercontent.com/SigNoz/charts/signoz-<ver>/charts/signoz/values.yaml`.
As of SigNoz v0.138.0 the bundled `deploy/` compose and `install.sh` are deprecated in favour of
Foundry; our compose is hand-maintained, so the chart is the only upstream pin source left.
Always move `signoz` and `signoz-otel-collector` together, to the exact pair the chart pins.

**Rule that applies to every step here:** the gate must be able to fail. "Containers are up" is not
GREEN; a canary span that arrives is.

---

## Step 2 (2026-08-23): SigNoz v0.135.1 → v0.138.0, collector v0.144.6 → v0.144.8 — PR #595

Chart `signoz-0.138.0` pins: `signoz/signoz:v0.138.0`, `signoz/signoz-otel-collector:v0.144.8`,
ClickHouse `25.12.5` (the ClickHouse move is step 3, separate gate — not required for this step).

What changes between 0.135.1 and 0.138.0 that matters here (verified from release notes):

- v0.136: v1 alert-history endpoints deprecated (no callers in this repo).
- v0.137: saved views move to `/api/v2/saved_views`; v1 `/api/v1/explorer/views` deprecated but
  still served. **Saved-view migration runs automatically on first start and now validates
  queries.** Our two enterprise-views scripts try v2 first (#595); their v1 POST bodies are not yet
  migrated and are annotated in-line.
- No required upgrade stops on this path; no ClickHouse schema break. Migrator and collector ship
  in the same image and must stay on the same tag.

### Apply (operator, elevated not required)

```powershell
# 0. Preconditions: stack healthy, C: has headroom, no gate run in progress
docker compose ps
Get-PSDrive C | Select-Object @{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}

# 1. Back up the SQLite metastore BEFORE the new image starts (migration is one-way)
New-Item -ItemType Directory -Force backups | Out-Null
docker cp signoz:/var/lib/signoz/signoz.db ("backups/signoz.db.pre-0.138.0-" + (Get-Date -Format yyyyMMdd-HHmm))

# 2. Pull the pinned images (tags already in docker-compose.yml after #595)
docker compose pull signoz signoz-otel-collector signoz-telemetrystore-migrator

# 3. Apply. The migrator must exit 0 before the collector starts (service_completed_successfully).
docker compose up -d
docker compose logs signoz-telemetrystore-migrator --tail 50   # expect "migrations completed" / exit 0
docker compose ps                                              # signoz + collector healthy

# 4. Gate — the same check gate-nightly runs, against the live stack
pwsh -File BRAV/SCPT/verify-pipeline.ps1 -CanaryScriptPath synthetic/send_synthetic_otel_simple.py
# GREEN = exit 0 and the canary span is queryable. Then confirm the UI loads and an existing
# dashboard + one saved view still render (the saved-view migration is the only data-shape change).
```

### Rollback

```powershell
docker compose down signoz signoz-otel-collector signoz-telemetrystore-migrator
git checkout main -- docker-compose.yml          # or revert #595
docker cp backups/signoz.db.pre-0.138.0-<stamp> signoz:/var/lib/signoz/signoz.db   # after recreate, before start
docker compose up -d
pwsh -File BRAV/SCPT/verify-pipeline.ps1 -CanaryScriptPath synthetic/send_synthetic_otel_simple.py
```

Restoring the metastore is what makes rollback real; the image tags alone do not undo the
saved-view migration.

### Result

**2026-08-23 — step 2 PROVEN on D-MONOLITH (daily host).** Metastore backup:
`backups/signoz.db.pre-0.138.0-20260823-1614` (684 KB). `docker compose pull` +
`up -d`: migrator **exit 0** (schema migrations finished, container Exited as expected);
`signoz` **v0.138.0 healthy**; `signoz-otel-collector` **v0.144.8 healthy**; ClickHouse
unchanged at **25.8** (step 3). Gate: `verify-pipeline.ps1` **exit 0** — SigNoz API
health `ok`, version **v0.138.0**, canary trace **PINPOINT** confirmed
(`fc81dc50a43d358ce8e1331eb5b49d5d`). Collector log scrape inconclusive (same as prior
runs). UI/dashboard spot-check: operator to confirm saved view renders. Evidence:
`out/evidence-20260823-151711Z.zip`.

---

## Step 3: ClickHouse 25.8 → 25.12.5 — PR #598

Not a prerequisite for step 2 — the chart pin is pre-emptive (a future collector will require
≥ 25.12.5 for trace attributes as JSON). ClickHouse upgrades its on-disk format in place and does
not guarantee downgrade; from 25.10 the default `String` serialization makes newly written parts
unreadable by older versions. **The volume snapshot is the only rollback.**

What #598 changes besides the tag, and why:

- **`clickhouse-mergetree-compat-config.xml` — `escape_variant_subcolumn_filenames=0`.**
  ClickHouse 25.11 (#87300) renamed Variant subcolumn stream files inside Wide parts; it is a
  listed backward-incompatible change for tables with Variant/Dynamic/JSON columns, and the
  filename is derived from the table's current settings at read time rather than stored per part.
  This stack has JSON columns on `signoz_logs.logs_v2` and `signoz_traces.signoz_index_v3`, with
  Wide parts written on 25.8. Keeping the old naming is the changelog's prescribed remedy; the
  SigNoz chart sets nothing for it. Only revisit on a fresh volume.
- **`clickhouse-system-logs-config.xml` — `total_memory_profiler_step=0`.** The 2026-08-18 fix
  zeroed `total_memory_tracker_sample_probability` (random allocation sampler). The
  Memory/MemoryPeak rows that refilled `system.trace_log` to 5.88 GiB by 2026-08-23 (~2 GiB/day)
  come from the *step* profiler. Both are now zero.

Both files were preflighted on a throwaway 25.12.5 container: server starts, both settings read
back as 0.

### Apply (operator)

```powershell
# 0. Preconditions: stack healthy, step 2 PROVEN, C: headroom >= 3x clickhouse_data size
docker compose ps
docker system df -v | Select-String clickhouse_data

# 1. Snapshot the ClickHouse volume - THIS IS THE ROLLBACK. Stop writers first so the snapshot
#    is consistent; the collector's on-disk queue buffers telemetry while it is down.
docker compose stop signoz-otel-collector signoz signoz-clickhouse
New-Item -ItemType Directory -Force backups | Out-Null
docker run --rm -v otel_clickhouse_data:/from -v "${PWD}/backups:/to" alpine `
  tar czf ("/to/clickhouse_data.pre-25.12.5-" + (Get-Date -Format yyyyMMdd-HHmm) + ".tgz") -C /from .

# 2. Pull and start. ClickHouse converts the on-disk format on first start; watch the log.
docker compose pull signoz-clickhouse
docker compose up -d
docker compose logs signoz-clickhouse --tail 100     # no "Exception" / "CANNOT" lines; healthy
docker compose ps

# 3. Prove the settings landed on the real server, not just the preflight
docker exec signoz-clickhouse clickhouse-client -q "SELECT version()"
docker exec signoz-clickhouse clickhouse-client -q "SELECT name, value FROM system.server_settings WHERE name='total_memory_profiler_step'"          # 0
docker exec signoz-clickhouse clickhouse-client -q "SELECT name, value FROM system.merge_tree_settings WHERE name='escape_variant_subcolumn_filenames'"  # 0

# 4. Prove old data still reads - the compat pin exists for exactly this
docker exec signoz-clickhouse clickhouse-client -q "SELECT count() FROM signoz_traces.signoz_index_v3 WHERE resource.\`service.name\` IS NOT NULL"   # baseline 2026-08-23: 74661
docker exec signoz-clickhouse clickhouse-client -q "SELECT count() FROM signoz_logs.logs_v2 WHERE body_v2.message IS NOT NULL"   # baseline 2026-08-23: 34125

# 5. Gate
pwsh -File BRAV/SCPT/verify-pipeline.ps1 -CanaryScriptPath synthetic/send_synthetic_otel_simple.py

# 6. 24 h later: trace_log must have stopped growing (was 5.88 GiB on 2026-08-23)
docker exec signoz-clickhouse clickhouse-client -q "SELECT table, formatReadableSize(sum(bytes_on_disk)) FROM system.parts WHERE database='system' AND active GROUP BY table ORDER BY sum(bytes_on_disk) DESC LIMIT 5"
```

### Rollback

```powershell
docker compose stop signoz-otel-collector signoz signoz-clickhouse
git checkout main -- docker-compose.yml clickhouse-system-logs-config.xml   # or revert #598
docker run --rm -v otel_clickhouse_data:/to -v "${PWD}/backups:/from" alpine `
  sh -c "rm -rf /to/* && tar xzf /from/clickhouse_data.pre-25.12.5-<stamp>.tgz -C /to"
docker compose up -d
```

### Result

**2026-08-23 — step 3 APPLIED on D-MONOLITH, gate GREEN.** Driven from the
chat seat under explicit operator go. Snapshot `backups/clickhouse_data.pre-25.12.5-20260823-1710.tgz`
(4.45 GB, tar exit 0, 57,953 entries, all 12 `signoz_*` metadata files) — first two attempts were
discarded (a `timeout` killed one at 15 min; Git Bash path-mangled the other into a 20-byte file;
`MSYS_NO_PATHCONV=1` fixed it). `version()` = **25.12.5.44**; `total_memory_profiler_step` = 0;
`escape_variant_subcolumn_filenames` = 0. Old-data reads: traces **74,661** (= baseline), logs
34,136 (baseline 34,125 + collector queue drain), forced scan of the five 25.8-era Wide parts
74,557 rows. `verify-pipeline.ps1` **exit 0** (quick_monitor pass, canary_send pass, trace
`460eb88354241052b85a86c465f0e30f`). The system-log truncation before snapshot was skipped
(blocked from the chat seat), so the snapshot carries the 6.9 GiB of diagnostic tables.

**2026-08-24 follow-up (chat seat, operator sequence):**

1. Dropped renamed leftovers: `system.trace_log_0` (5.90 GiB), `metric_log_0`, `query_log_0`,
   `part_log_0`, `error_log_0`. Confirming `SELECT` returns no `*_log_0` tables.
2. Merged **PR #600**; `docker compose up -d signoz-clickhouse` recreated the container.
   `memory_profiler_step` (profile) = 0; `otel-profile.xml` mounted under `users.d`.
   Fresh `trace_log` still held ~57.5M Memory + 57.5M MemoryPeak rows (~2.40 GiB) written
   *before* the profile pin. Post-recreate 25 s delta on those types: **0** new rows.

**Still open:** 24 h `trace_log` size check — should be flat (no Memory growth) after this pin.

---

**ClickHouse 26.x: deferred** until the SigNoz chart pins it. 26.1 removed codecs and the Lazy
engine and changed `system.metric_log` modes; none of that is tested under SigNoz.
