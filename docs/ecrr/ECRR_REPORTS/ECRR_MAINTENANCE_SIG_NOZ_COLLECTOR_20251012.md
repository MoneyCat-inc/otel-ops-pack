# ECRR Maintenance — OTel Collector Hostname/Auth Fix

Timestamp: 2025-10-12
Actor: BossCat OEM
Scope: OTel collector → ClickHouse connectivity

## Examine
- Collector restarts due to ClickHouse resolution/auth failures.
- Exporter DSNs pointed to `signoz-clickhouse` without credentials.

## Clean
- Updated hostnames to `signoz-clickhouse-simple` in `signoz-collector-config.yaml`.
- Added ClickHouse credentials to DSNs: `username=default&password=signoz`.
- Verified container transitions to `healthy`.

## Report
- SigNoz UI: 200 OK at `/api/v1/health`.
- Collector: Healthy; restart loop resolved.
- Ingestion path ready for canary.

## Role
- Investigator: Identified hostname/auth mismatch.
- Gap-Closer: Patched config and restarted service.
- QA Scribe: Logged maintenance report here.
