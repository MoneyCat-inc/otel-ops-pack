# ✅ IONA → SigNoz Post-Rollout QA & Hardening Pack

> **Audience:** Windows ops engineers maintaining the IONA pipelines after the SigNoz cutover
>
> **Goal:** Run a 5-minute trust-but-verify check, keep production dashboards/alerts aligned, and harden the collector for steady-state operations.

---

## 🔎 5-Minute Trust-but-Verify Runbook

### 1. Collector service & config sanity (Windows)

```powershell
# Identify the collector service (adjust the match if you use a custom name)
Get-Service | Where-Object { $_.Name -match 'otel|OpenTelemetry|collector' } | Format-Table Name, Status

# Tail the most recent collector log (update the path if logs land elsewhere)
Get-ChildItem 'C:\ProgramData\otelcol' -Filter *.log -Recurse |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 |
  ForEach-Object { Get-Content $_.FullName -Tail 200 }

# Confirm OTLP ports are reachable from the Windows host
Test-NetConnection -ComputerName localhost -Port 4317
Test-NetConnection -ComputerName localhost -Port 4318
```

### 2. SigNoz metrics confirm the pipeline

SigNoz UI → **Metrics** → **Explorer** → run the following PromQL queries:

| Intent | Query |
| --- | --- |
| Throughput by mode | `sum by (mode) (rate(iona_jobs_completed_total[5m]))` |
| Failure fingerprint | `sum by (error_type) (rate(iona_jobs_failed_total[5m]))` |
| P95 job duration (requires histogram) | `histogram_quantile(0.95, sum by (le) (rate(iona_job_duration_ms_bucket[5m])))` |

*Expected Result:* charts show recent activity (>0) with the expected `mode`/`error_type` labels.

### 3. No-data guard for the last 30 minutes

```promql
increase(iona_jobs_completed_total[30m]) > 0
```

If the result is `0`, confirm the demo generator or production workload has sent data within the last 30 minutes.

---

## 📊 Production Dashboard Starters

Add these panels to the SigNoz dashboard JSON you already prepared:

1. **Throughput by mode**
   ```promql
   sum by (mode) (rate(iona_jobs_completed_total[5m]))
   ```
2. **Error rate (%)**
   ```promql
   100 * sum(rate(iona_jobs_failed_total[5m])) /
     clamp_min(sum(rate(iona_jobs_completed_total[5m])) + sum(rate(iona_jobs_failed_total[5m])), 1)
   ```
3. **P95 job duration (ms)**
   ```promql
   histogram_quantile(0.95, sum by (le) (rate(iona_job_duration_ms_bucket[5m])))
   ```
4. **Concurrency & queue depth**
   ```promql
   avg(iona_jobs_running) by (mode)
   avg(iona_jobs_queued) by (mode)
   ```
5. **Top error types (last 15 minutes)**
   ```promql
   topk(5, sum(rate(iona_jobs_failed_total[15m])) by (error_type))
   ```
6. **No-data SLI (single-value)**
   ```promql
   increase(iona_jobs_completed_total[30m])
   ```

---

## 🚨 Baseline Alert Policy

| Alert | Severity | Expr | For | Notes |
| --- | --- | --- | --- | --- |
| No ingestion | Critical | `increase(iona_jobs_completed_total[30m]) == 0` | 5m | Routes to on-call; catches pipeline stalls. |
| Error ratio high | Warning | Error % (query above) > 2% | 10m | Promote to critical when >5% for 5m. |
| Error ratio very high | Critical | Error % (query above) > 5% | 5m | Use the same query as the warning threshold. |
| P95 latency breach | Critical | `histogram_quantile(0.95, sum by (le) (rate(iona_job_duration_ms_bucket[5m]))) > <p95_ms_target>` | 10m | Fill in `<p95_ms_target>` with the agreed SLO (e.g., 1500ms). |
| Queue backlog | Warning | `avg(iona_jobs_queued[10m]) > <threshold>` | 10m | Set `<threshold>` to your acceptable queue depth. |

> Export the rules via the SigNoz Alerts UI or `signozctl alert export` for version control.

---

## 🛡️ Collector Hardening Snippet (drop-in)

Apply this structure to the Windows collector config (replace the exporter endpoint if SigNoz lives elsewhere):

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  memory_limiter:
    check_interval: 5s
    limit_mib: 512
    spike_limit_mib: 128
  batch: {}

exporters:
  otlphttp/signoz:
    endpoint: http://localhost:4318
    tls:
      insecure: true

service:
  telemetry:
    metrics:
      address: 0.0.0.0:8888
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/signoz]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/signoz]
```

*Tip:* scrape `http://<collector-host>:8888/metrics` with SigNoz or Prometheus to watch `otelcol_` self-metrics.

---

## 🔁 Canary & Demo Scripts

Use the existing automation for quick confidence boosts:

```powershell
# 1. Trust-but-verify orchestration
pwsh -File verify-iona-signoz-integration.ps1

# 2. Emit a counter sample
pwsh -Command ". .\scripts\metrics.ps1; Send-IonaMetric -Name 'iona_jobs_completed_total' -Type 'counter' -Value 1 -Attributes @{ mode = 'Companion' }"

# 3. Exercise the supervisor demo
pwsh -File scripts\iona-supervisor-runner.ps1 -JobCount 3
```

Optional background canary:

```powershell
while ($true) {
  . .\scripts\metrics.ps1
  Send-IonaMetric -Name 'iona_jobs_completed_total' -Type 'counter' -Value 1 -Attributes @{ mode='canary' }
  Start-Sleep -Seconds 60
}
```

---

## 📦 Handoff Bundle Checklist

Include these artifacts in the final ticket or repository drop:

- ✅ Final collector config (with the hardening processors + telemetry block).
- ✅ SigNoz dashboard JSON (with the panel queries above).
- ✅ Alert rules export (JSON or YAML from SigNoz).
- ✅ Verification scripts (trust-but-verify & canary emitters) plus the ECRR expectation sheet.
- ✅ Rollback snippet for the collector config (e.g., copy the backup file and restart the service).

**Rollback example:**

```powershell
Copy-Item C:\otel\collector.previous.yaml C:\otel\collector.yaml -Force
$svc = (Get-Service | Where-Object { $_.Name -match 'otel|OpenTelemetry' }).Name
Restart-Service -Name $svc -Force
```

---

## 🧭 Alignment with ECRR + Cat Nap

- **Examine:** The trust-but-verify runbook captures real-time service state and SigNoz evidence.
- **Clean:** Hardening processors prevent runaway memory and enforce batching.
- **Report:** Dashboard + alerts + handoff bundle encode the operational contract.
- **Role:** Engineers can re-run the scripts without side effects, keeping telemetry calm (Cat Nap) while honoring ECRR.
