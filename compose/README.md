# Compose variants

Canonical SigNoz stack for this repo is the root **`docker-compose.yml`**
(promoted from `docker-compose-optimized.yml` in Pack 2 Task 7B). Prefer:

```bash
docker compose up -d
```

> **Path caveat (audit P1-4, 2026-08-29):** every file in this directory references
> repo-root configs (`clickhouse-*.xml`, `signoz-collector-config.yaml`, Dockerfiles)
> with `./` paths that resolve against `compose/`, so they only work when invoked as
> `docker compose --project-directory .. -f compose/<file>.yml up`. The `legacy.yml`
> and `docker-compose.unified.yml` sidecar/triton mounts additionally point at
> pre-reorg roots (`./sidecars/`, `./triton-models/`) that moved to
> `ALFA/APPS/sidecars/` and `DELT/CONF/triton-models/` — fix before resurrecting.

| File | Purpose | Status |
|------|---------|--------|
| `../docker-compose.yml` | Canonical SigNoz + OTel collector stack | **active** |
| `legacy.yml` | Pre-promotion default compose (superseded) | deprecated |
| `docker-compose.unified.yml` | Unified experiment | experimental |
| `docker-compose-signoz.yml` | SigNoz-only variant | **parked** — lacks ClickHouse cluster XML / `--dev` migrator flags; migrator fails (`cluster 'cluster' not found`). Not CI-tested. Do not resurrect for gates. |
| `docker-compose-signoz-simple.yml` | Minimal SigNoz | deprecated |

`BRAV/INFR/deployment-pipeline/docker-compose.yml` is pipeline-local and unchanged.

`docker-compose.viz.yml` and `docker-compose.gpu.yml` left with the Pack 3B split —
they live in [MoneyCat-inc/viz-engine](https://github.com/MoneyCat-inc/viz-engine) under `compose/`.
