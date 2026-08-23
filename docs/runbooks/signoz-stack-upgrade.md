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

## Step 3 (next, separate gate): ClickHouse 25.8 → 25.12.5

Not a prerequisite for step 2 — the chart pin is pre-emptive (a future collector will require
≥ 25.12.5 for trace attributes as JSON). ClickHouse upgrades its on-disk format in place and does
not guarantee downgrade, so the gate is:

1. Snapshot the `clickhouse_data` volume (`docker run --rm -v otel_clickhouse_data:/from -v
   ${PWD}/backups:/to alpine tar czf /to/clickhouse_data.tgz -C /from .`) — this is the rollback.
2. Bump `clickhouse/clickhouse-server:25.8` → `25.12.5` in compose.
3. Same restart carries the system-log profiler fix: add
   `<total_memory_profiler_step>0</total_memory_profiler_step>` to
   `clickhouse-system-logs-config.xml` (the 2026-08-18 fix zeroed
   `total_memory_tracker_sample_probability`, which is the *random* sampler; the Memory/MemoryPeak
   rows filling `system.trace_log` at ~2 GiB/day come from the *step* profiler).
4. Gate as above, plus `SELECT table, formatReadableSize(sum(bytes_on_disk)) FROM system.parts
   WHERE database='system' AND active GROUP BY table` 24 h later — trace_log must stop growing.

**ClickHouse 26.x: deferred** until the SigNoz chart pins it. 26.1 removed codecs and the Lazy
engine and changed `system.metric_log` modes; none of that is tested under SigNoz.
