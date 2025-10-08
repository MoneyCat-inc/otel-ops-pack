# 🎯 SigNoz SHOWTIME Views — Quick Reference
**Authority:** BossCat OEM  
**Mission:** Light up SigNoz with live, active data views

---

## 🎪 The 3 Showtime Views

These views are specifically designed to **show off real data** from the BossCat canary tests. Use them to demonstrate the pipeline is alive and ingesting telemetry.

### 1️⃣ IONA Canary Activity (Logs)

**What it shows:** Live log burst from `iona-canary.ps1`  
**Time range:** Last 15 minutes  
**Filters:**
- `message contains "canary test"`
- `service.name = "frontend"`
- `source = "Application"` (Windows Event Log)

**How to populate:**
```powershell
pwsh -File scripts\iona-canary.ps1 -DurationMinutes 5 -EventsPerMinute 120
```

**Where to view in SigNoz:**
1. Navigate to **Logs** → http://localhost:8080/logs
2. Apply filters:
   - Search: `canary test`
   - Service: `frontend`
   - Time: Last 15 minutes
3. You should see **~600 log events** from the burst

---

### 2️⃣ Frontend Canary Spans (Traces)

**What it shows:** Synthetic trace spans from `iona-trace-canary.ps1`  
**Time range:** Last 15 minutes  
**Filters:**
- `service.name = "frontend"`
- `name = "iona-canary-span"`
- Attributes:
  - `bosscat = "1"`
  - `canary = "1"`
  - `env = "dev"`

**How to populate:**
```powershell
pwsh -File scripts\iona-trace-canary.ps1 -Force
```

**Where to view in SigNoz:**
1. Navigate to **Traces** → http://localhost:8080/traces
2. Apply filters:
   - Service: `frontend`
   - Operation: `iona-canary-span`
   - Tags: `bosscat=1`, `canary=1`
   - Time: Last 15 minutes
3. You should see **1 trace span** with ~1200ms duration

---

### 3️⃣ Collector Ingest Pulse (Metrics)

**What it shows:** Real-time OTel Collector throughput  
**Time range:** Last 1 hour  
**Queries:**
```promql
# Logs received per second
rate(otelcol_receiver_accepted_log_records[5m])

# Spans received per second
rate(otelcol_receiver_accepted_spans[5m])

# Logs exported per second
rate(otelcol_exporter_sent_log_records[5m])

# Spans exported per second
rate(otelcol_exporter_sent_spans[5m])
```

**Where to view in SigNoz:**
1. Navigate to **Dashboards** → http://localhost:8080/dashboards
2. Open **BossCat Executive Dashboard** (or create a new panel)
3. Add the above queries as separate panels
4. You should see **spikes** corresponding to canary bursts

---

## 🚀 Quick Light-Up Sequence

Run this sequence to populate all three showtime views at once:

```powershell
# 1. Log burst (600 events over 5 min)
pwsh -File scripts\iona-canary.ps1 -DurationMinutes 5 -EventsPerMinute 120

# 2. Trace canary (1 span)
pwsh -File scripts\iona-trace-canary.ps1 -Force

# 3. Wait for ingestion (5-10 seconds)
Start-Sleep -Seconds 10

# 4. Verify in SigNoz UI
Write-Host "🎯 Check SigNoz → Logs, Traces, Metrics"
Write-Host "   Logs: filter 'canary test' + service=frontend"
Write-Host "   Traces: filter service=frontend + span=iona-canary-span"
Write-Host "   Metrics: query otelcol_receiver_* and otelcol_exporter_*"
```

---

## 🔍 Troubleshooting: "No Data" in Views

### Logs View Empty?
- ✅ Check Windows Event Log: `Get-EventLog -LogName Application -Source "IONA-Canary" -Newest 10`
- ✅ Check file log: `Get-Content C:\otel\artifacts\iona\iona-canary.log -Tail 20`
- ✅ Verify OTel Collector is running: `docker ps | Select-String signoz-otel-collector`
- ✅ Check collector config: `config/otel-collector.yaml` → ensure `windowseventlog/application` receiver is present

### Traces View Empty?
- ✅ Check collector ports are open:
  ```powershell
  Test-NetConnection -ComputerName localhost -Port 9411  # Zipkin
  Test-NetConnection -ComputerName localhost -Port 5318  # OTLP/HTTP
  ```
- ✅ Verify traces pipeline in collector config:
  ```yaml
  service:
    pipelines:
      traces:
        receivers: [otlp, zipkin]
        exporters: [clickhousetraces]  # or otlp if forwarding to SigNoz
  ```
- ✅ Check SigNoz trace ingestion health: http://localhost:8080/api/v1/traces

### Metrics View Empty?
- ✅ Verify OTel Collector is exposing metrics: `http://localhost:8888/metrics`
- ✅ Check if SigNoz is scraping collector metrics (this may require additional config)
- ✅ Alternative: Use SigNoz built-in collector metrics (if auto-instrumented)

---

## 📚 Related BossCat Scripts

- **`scripts/iona-canary.ps1`** → Log burst generator
- **`scripts/iona-trace-canary.ps1`** → Trace span generator
- **`scripts/bosscat-steps-7-8.ps1`** → Saved Views + Dashboard automation
- **`scripts/quick-monitor.ps1`** → Fast health check

---

## 🐾 BossCat Authority

**Issued by:** BossCat OEM (Executive Overseer Manager)  
**Style:** Cat Nap Control Room — Feline Silence Maintained  
**Compliance:** ECRR (Examine → Clean → Report → Role)

🐾 **End of Showtime Views Cheatsheet**

