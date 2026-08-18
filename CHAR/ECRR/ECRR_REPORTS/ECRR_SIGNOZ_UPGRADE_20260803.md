# ECRR — SigNoz Stack Upgrade (v0.96.1 → v0.135.1)

**Date:** 2026-08-03  
**Actor:** Cursor{Implementer} + machine operator `@fubumaki`  
**Verdict:** **GREEN** — verify-pipeline exit 0; pinpoint verification end-to-end (no ClickHouse fallback)

## 1. Examine

- SigNoz v0.96.1 `v5/query_range` traces path called `/api/v1/fields/keys?signal=traces` → 500 `failed to get traces keys`
- Root cause: server-side metadata bug in v0.96.1; ClickHouse data healthy (460 spans/hr, 139 keys via v3 autocomplete)
- `schema-migrator` (deprecated) was the migration path; v0.113+ replaces it with `telemetrystore-migrator` (otel-collector binary)
- ClickHouse 25.5.6 lacked shard/replica macros required by replication config in newer SigNoz collector
- Backup taken before upgrade: `artifacts/deployment-backups/signoz-upgrade-20260803-114335/`

## 2. Clean

**`docker-compose.yml`**
- `signoz`: `v0.96.1` → `v0.135.1`; added `SIGNOZ_TOKENIZER_JWT_SECRET` (v0.112+ preferred path; legacy `SIGNOZ_JWT_SECRET` retained for rollback compatibility)
- `signoz-otel-collector`: `v0.129.6` → `v0.144.6`; added `depends_on: signoz-telemetrystore-migrator`; entrypoint now runs `migrate sync check` before starting collector
- `signoz-schema-migrator-sync` + `signoz-schema-migrator-async` (deprecated): replaced by single `signoz-telemetrystore-migrator` service using otel-collector binary (`migrate bootstrap && sync up && async up`); memory limit raised to 512M
- `signoz-clickhouse`: `25.5.6` → `25.8`

**`clickhouse-cluster-config.xml`**
- Added `<macros><shard>01</shard><replica>01</replica></macros>` — required by replication DDL in v0.144.6 collector

**Migration**
- `signoz-telemetrystore-migrator` ran bootstrap + sync + async; exit 0
- Network recreate during `compose up` caused early disconnect on background job — migrator re-run completed successfully

## 3. Report

| Component | Before | After |
|-----------|--------|-------|
| signoz | v0.96.1 | v0.135.1 |
| signoz-otel-collector | v0.129.6 | v0.144.6 |
| Migrator | schema-migrator (deprecated) | telemetrystore-migrator |
| ClickHouse | 25.5.6 | 25.8 |
| ClickHouse macros | absent | shard=01, replica=01 |
| v5 pinpoint verification | 500 `failed to get traces keys` | `span_found`, `PINPOINT (traceID)` |
| ClickHouse fallback needed | yes | no |

Proof: `verify-pipeline` exit 0 — `api_mode: "PINPOINT (traceID)"`, `api_reason: "span_found"`, trace `747df37e…`  
Backup: `artifacts/deployment-backups/signoz-upgrade-20260803-114335/`

## 4. Role

Machine operator performed upgrade and migration; Cursor{Implementer} documented. `Get-HttpErrorBody` (added previous session) confirmed the root cause during diagnosis. No further action required — SigNoz upgrade closes the last open item from the 2026-08-02 recovery session.

**Status:** COMPLETE

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: artifacts/ecrr-compliance-metrics.json.
- Guardrail: Append-only; original report body unchanged.
