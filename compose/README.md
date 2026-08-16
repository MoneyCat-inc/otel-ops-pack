# Compose variants

Canonical SigNoz stack for this repo is the root **`docker-compose.yml`**
(promoted from `docker-compose-optimized.yml` in Pack 2 Task 7B). Prefer:

```bash
docker compose up -d
```

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
