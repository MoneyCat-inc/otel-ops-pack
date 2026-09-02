# Current Architecture — Windows Collector → SigNoz

**Status**: ✅ **ACTIVE** (rewritten 2026-09-01 from the canonical config files, not from memory)
**Authority**: BossCat OEM · decision record: `docs/BossCat/MEMO_WINDOWS_COLLECTOR_20260803.md`,
Roadmap 2026 H2 Phase 1 (closed 2026-08-13: **keep as first-class, upgraded**)

> **Correction (2026-09-01).** The previous version of this document (2025-11-02) described a
> "direct-to-SigNoz" architecture with the Windows collector **deprecated**. That was reversed by
> the Phase 1 decision: the Windows collector is the **sole carrier of Windows Event Log
> telemetry** — a Docker container cannot read the Event Log — and it was upgraded, not retired.
> The companion deprecation notice carries a RESCINDED banner. Everything below is read from
> `config.yaml`, `docker-compose.yml` and `DELT/CONF/otel-ports.json` as of 2026-09-01.

---

## Topology

```text
Windows host                                         Docker (root docker-compose.yml)
─────────────────────────────────────────            ───────────────────────────────────────
Windows Event Log (Application, System) ─┐
C:/logs/**/*.log (filelog/canary) ───────┤           signoz-otel-collector  v0.144.8
local OTLP 127.0.0.1:5320 gRPC / 5321 ───┤──► otlp ─► 4317 gRPC / 4318 HTTP
                                         │           │
  otelcol-contrib service (v0.159.0 pin) ┘           ▼
  canonical config: config.yaml                      clickhouse-server 25.12.5 (+ zookeeper 3.9.3)
                                                     │
.NET apps: OTLP traces direct ──────────────────────►│  (Gate #026A routing preference for traces)
                                                     ▼
                                                     SigNoz UI  http://localhost:8080  (v0.138.0)
```

Two tiers, one hop between them. The host tier collects what only the host can see; the Docker
tier stores and serves it.

---

## Tier 1 — Windows collector (`otelcol-contrib` service)

| Item | Value (canonical) |
| --- | --- |
| Config the service loads | `config.yaml` (repo root). `windows/otelcol/otelcol-contrib-config.yaml` is the reference template |
| Version pin | **0.159.0** (moved 2026-08-23, PR #591; upgraded 0.104.0 → 0.158.0 on 2026-08-13). Pinned in one place — see the runbook |
| Receivers | `windowseventlog/application`, `windowseventlog/system`, `filelog/canary` (`C:/logs/**/*.log`), `otlp` on **127.0.0.1:5320** (gRPC) / **5321** (HTTP) |
| Processors | `memory_limiter`, `filter/drop_noise` (drops event IDs 6005/6006/7036 and Windows-Update / SCM chatter), `attributes/redact_sensitive`, `resource/*`, per-signal `batch/*` (logs: 200 ms, 1024/2048) |
| Exporter | `otlp` → **localhost:4317** (the Docker SigNoz collector) |
| Extensions | `health_check` on `127.0.0.1:13134/healthz`, `file_storage` (`C:\ProgramData\Otelcol\FileStorage`) |
| Pipelines | **logs**: all four receivers · **traces**: `otlp` · **metrics**: `otlp` only — **there is no `hostmetrics` receiver** |
| Supervision | `watchdog-otelcol.ps1` scheduled task: heartbeat, start-type repair, host vitals, incident bundles — `docs/cheatsheets/WATCHDOG_CHEATSHEET.md` |

Port authority is `DELT/CONF/otel-ports.json`, drift-checked by `BRAV/SCPT/check-otel-ports-drift.ps1`.
Ingest deliberately avoids the PlariumPlay 5300–5319 bind range.

## Tier 2 — SigNoz stack (`docker-compose.yml`)

| Service | Image | Ports |
| --- | --- | --- |
| `signoz` | `signoz/signoz:v0.138.0` | 8080 (UI) |
| `signoz-otel-collector` | `signoz/signoz-otel-collector:v0.144.8` | 4317 gRPC, 4318 HTTP, 18888/18889 internal metrics |
| `signoz-clickhouse` | `clickhouse/clickhouse-server:25.12.5` | internal |
| `signoz-zookeeper` | `signoz/zookeeper:3.9.3` | internal |
| `signoz-telemetrystore-migrator` | `signoz/signoz-otel-collector:v0.144.8` | one-shot |
| `demo-app` | `otel-otel-demo-app` (local build) | 3001 |

Mounted configs live under `DELT/CONF/configs/`. Parked compose variants under `compose/` require
`--project-directory ..` (see `compose/README.md`); the root file is the canonical stack.

---

## What Gate #026A actually established

Gate #026A (Oct 2025) is the source of the old "bypassed" reading. What it established is narrower:
for **.NET trace export**, sending OTLP straight to the Docker collector (4318) is preferred over
routing through the Windows collector. That is a routing preference for one signal type. It was
never a verdict on the component — the record was corrected in #436 (Phase 2).

---

## Health, validation, proof

```powershell
pwsh -File scripts\quick-monitor.ps1                       # fast health check
pwsh -File scripts\preflight-health-check.ps1              # readiness
pwsh -File BRAV\SCPT\verify-pipeline.ps1                   # end-to-end gate validation (exit 0/1/2)
pwsh -File scripts\windows\test-otlp-e2e.ps1               # OTLP canary through the Windows collector
```

The standing proof that the whole thing installs from nothing is the **clean-host E2E gate**
(`docs/runbooks/clean-host-e2e.md`): 6.86 min clone-to-first-span on a clean Windows host
(2026-08-13). It is the one gate `docs/PURPOSE.md` commits to keeping green.

---

## Related documentation

- **Runbook**: `docs/runbooks/windows-collector.md` (status, version notes, repair surface)
- **Decision record**: `docs/BossCat/MEMO_WINDOWS_COLLECTOR_20260803.md`; roadmap Phase 1 in `docs/BossCat/ROADMAP_2026H2.md`
- **Rescinded notice**: [WINDOWS_COLLECTOR_DEPRECATION.md](WINDOWS_COLLECTOR_DEPRECATION.md) (kept as record)
- **Repository layout**: [REPOSITORY_STRUCTURE.md](../REPOSITORY_STRUCTURE.md)
- **Stack upgrade runbook**: `docs/runbooks/signoz-stack-upgrade.md`

---

**Version**: 2.0 · **Last verified against config**: 2026-09-01 · **Maintained by**: MoneyCat-inc
