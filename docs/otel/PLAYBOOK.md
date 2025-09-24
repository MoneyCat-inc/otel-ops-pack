# Windows → SigNoz Break-Glass Playbook

**Purpose:** One-screen checklist to restore log/trace/metric ingest from Windows hosts into SigNoz. Pair with the full `ON_CALL_RUNBOOK.md` for deep dives.

---

## 1. Snapshot (≤2 minutes)

1. **Collector health**
   ```powershell
   Invoke-WebRequest -Uri http://127.0.0.1:13134/healthz -TimeoutSec 5 | ConvertFrom-Json
   ```
2. **SigNoz stack**
   ```powershell
   docker compose ps
   docker exec signoz-clickhouse clickhouse-client -q "SELECT now(), count() FROM signoz_logs.logs_v2 LIMIT 1"
   ```
3. **Smoke harness** (runs synthetic log/trace/metric round-trip)
   ```powershell
   pwsh -File scripts/otel/smoke.ps1
   ```

If any command fails, capture output and proceed to triage.

---

## 2. Fast Triage

| Symptom | Checks | Immediate Actions |
| --- | --- | --- |
| `otelcol-contrib` service stopped | `Get-Service otelcol-contrib`<br/>`Get-EventLog -LogName Application -Source "OpenTelemetry Collector" -Newest 5` | `Restart-Service otelcol-contrib`<br/>Re-run smoke. |
| SigNoz collector unhealthy | `Invoke-WebRequest http://localhost:13133/healthz`<br/>`docker logs signoz-otel-collector --tail 200` | `docker compose restart signoz-otel-collector`<br/>Confirm ClickHouse up first. |
| Smoke fails with batch/processor error | `Get-Content C:\otel\config.yaml`<br/>`& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config C:\otel\config.yaml --dry-run` | Restore known-good config: `Copy-Item C:\otel\config-hardened-plus.yaml C:\otel\config.yaml -Force`. |
| Drops/backpressure | `docker exec signoz-otel-collector curl -s http://localhost:8888/metrics | Select-String otelcol_exporter_queue_size` | Temporarily reduce ingest (disable noisy receivers) and size queue once config patches merge. |

---

## 3. Stabilize & Document

1. **Lock in config**
   ```powershell
   Copy-Item C:\otel\config.yaml C:\otel\config.yaml.$(Get-Date -Format 'yyyyMMddHHmmss').bak
   ```
2. **Capture evidence**
   ```powershell
   pwsh -File scripts/otel/smoke.ps1 -SkipStackCheck > artifacts/smoke-$(Get-Date -Format 'yyyyMMddHHmmss').log
   ```
3. **Escalate if unresolved in 15 minutes** — send snapshot + smoke logs to the on-call channel.

---

## 4. Aftercare

* File findings against `docs/otel/FINDINGS.json` IDs when applicable.
* Schedule config hardening (memory limiter, queues) before re-enabling noisy sources.
* Update dashboards to include collector health endpoints and queue depth once queues exist.
