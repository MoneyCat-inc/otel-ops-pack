# Windows Collector (otelcol-contrib) — Runbook

**Authority:** BossCat OEM  
**Gate:** #022 (BOSSCAT-022A)  
**Purpose:** Collect Windows host metrics and Event Logs for observability pipeline

---

## Overview

The Windows OpenTelemetry Collector (`otelcol-contrib`) runs as a Windows service to collect:
- **Host Metrics:** CPU, memory, disk, network, process stats (60s interval)
- **Event Logs:** Application and System logs (real-time)

All telemetry is exported to the OTLP aggregator (signoz-otel-collector) via gRPC on port 14317.

---

## Install / Repair

**Command:**
```powershell
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
```

**What it does:**
1. Creates config directory: `%ProgramData%\otelcol-contrib\`
2. Writes collector config with OTLP endpoint substitution
3. Configures service for **Delayed Auto-Start**
4. Sets **failure recovery:** Restart after 10s (3 attempts)
5. Starts/restarts the service

**Parameters:**
- `-ConfigSource` (default: `.\windows\otelcol\otelcol-contrib-config.yaml`)
- `-OtlpGrpcEndpoint` (default: `127.0.0.1:14317`)
- `-ServiceName` (default: `otelcol-contrib`)

**Example (custom endpoint):**
```powershell
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1 -OtlpGrpcEndpoint "192.168.1.100:14317"
```

---

## Verify

**Command:**
```powershell
pwsh -File .\scripts\windows\verify-otel-collector.ps1
```

**What it checks:**
1. Service status: RUNNING
2. OTLP aggregator reachability (ports 14317/14318)
3. Canary event written to Application log
4. Wait for collector processing (3s)

**Exit Codes:**
- `0` - All checks passed
- `1` - Verification failed (see error output)

---

## Service Management

**Check Status:**
```powershell
Get-Service otelcol-contrib
```

**Start Service:**
```powershell
Start-Service otelcol-contrib
```

**Stop Service:**
```powershell
Stop-Service otelcol-contrib
```

**Restart Service:**
```powershell
Restart-Service otelcol-contrib
```

**View Service Config:**
```powershell
sc.exe qc otelcol-contrib
```

---

## Configuration

**Config Location:** `%ProgramData%\otelcol-contrib\config.yaml`

**Key Settings:**
- **OTLP Endpoint:** Configured via `OTLP_GRPC_ENDPOINT` (default: `127.0.0.1:14317`)
- **Collection Interval:** 60 seconds for host metrics
- **Event Log Channels:** Application, System
- **Memory Limit:** 512 MiB (spike: 128 MiB)
- **Batch Timeout:** 10 seconds

**Editing Config:**
1. Edit source: `.\windows\otelcol\otelcol-contrib-config.yaml`
2. Re-run: `pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1`
3. Service will restart with new config

---

## Monitoring

### Internal Telemetry

The collector exposes its own metrics at:
```
http://localhost:8888/metrics
```

**Key Metrics:**
- `otelcol_receiver_accepted_metric_points` - Metrics received
- `otelcol_receiver_accepted_log_records` - Logs received
- `otelcol_exporter_sent_metric_points` - Metrics exported
- `otelcol_exporter_sent_log_records` - Logs exported
- `otelcol_processor_batch_batch_send_size` - Batch sizes

### Windows Event Viewer

**View Collector Events:**
1. Open Event Viewer (`eventvwr.msc`)
2. Navigate to: Windows Logs → Application
3. Filter by Source: `OpenTelemetry Collector` (or your service name)

### SigNoz UI

**Check Host Metrics:**
1. Navigate to: http://localhost:8080
2. Dashboards → Host Metrics
3. Filter by: `host.type = "windows"`

**Check Event Logs:**
1. Navigate to: http://localhost:8080 → Logs
2. Filter: `log.source = "windowseventlog"`
3. Look for canary events: `message contains "VizCanary"`

---

## Troubleshooting

### Service Won't Start

**Symptoms:** Service stops immediately after starting

**Diagnosis:**
```powershell
# Check Windows Event Log
Get-EventLog -LogName Application -Source "OpenTelemetry Collector" -Newest 10

# Validate config syntax
.\otelcol-contrib.exe validate --config "%ProgramData%\otelcol-contrib\config.yaml"
```

**Common Causes:**
- Invalid YAML syntax in config
- OTLP endpoint unreachable
- Permissions issue (service account)
- Missing dependencies

**Resolution:**
1. Fix config syntax errors
2. Verify Docker containers running: `docker ps`
3. Check firewall: `Test-NetConnection localhost -Port 14317`
4. Re-run install script: `pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1`

---

### No Data in SigNoz

**Symptoms:** Service running but no metrics/logs appear in SigNoz

**Diagnosis:**
```powershell
# Check collector internal metrics
Invoke-RestMethod http://localhost:8888/metrics | Select-String "exporter_sent"

# Check OTLP endpoint connectivity
Test-NetConnection localhost -Port 14317
Test-NetConnection localhost -Port 14318
```

**Common Causes:**
- OTLP aggregator not running
- Incorrect endpoint configuration
- Network connectivity issue
- Collector dropping data due to memory limit

**Resolution:**
1. Verify Docker services: `docker ps | grep signoz-otel-collector`
2. Check collector config: `%ProgramData%\otelcol-contrib\config.yaml`
3. Increase memory limit if needed (edit config, restart service)
4. Check collector logs in Event Viewer

---

### High Memory Usage

**Symptoms:** Collector process consuming excessive memory

**Diagnosis:**
```powershell
Get-Process | Where-Object {$_.Name -like "*otelcol*"} | Select-Object Name, WS, PM
```

**Resolution:**
1. Adjust memory_limiter in config:
   ```yaml
   processors:
     memory_limiter:
       limit_mib: 256  # Reduce from 512
       spike_limit_mib: 64  # Reduce from 128
   ```
2. Increase batch timeout to reduce processing frequency
3. Reduce collection interval for hostmetrics
4. Re-run install script to apply changes

---

### Canary Events Not Appearing

**Symptoms:** Verification script succeeds but events not in SigNoz

**Diagnosis:**
```powershell
# Check if event was written to Windows Event Log
Get-EventLog -LogName Application -Source "VizCanary" -Newest 5

# Check collector is reading Application log
Invoke-RestMethod http://localhost:8888/metrics | Select-String "receiver.*windowseventlog"
```

**Resolution:**
1. Verify event source exists: `[System.Diagnostics.EventLog]::SourceExists("VizCanary")`
2. Check collector config includes Application channel
3. Wait 60-120 seconds for batch processing
4. Check SigNoz with broader filter: `log.source = "windowseventlog"`

---

## Uninstall

**Manual Removal:**

1. **Stop and delete service:**
   ```powershell
   Stop-Service otelcol-contrib
   sc.exe delete otelcol-contrib
   ```

2. **Remove configuration:**
   ```powershell
   Remove-Item -Path "$env:ProgramData\otelcol-contrib" -Recurse -Force
   ```

3. **Remove binary (if installed manually):**
   ```powershell
   Remove-Item -Path "C:\Program Files\otelcol-contrib" -Recurse -Force
   ```

4. **Remove event source (optional):**
   ```powershell
   Remove-EventLog -Source "VizCanary"
   ```

---

## Firewall Rules

If collector cannot reach aggregator, add firewall rules:

```powershell
# Allow outbound to OTLP gRPC
New-NetFirewallRule -DisplayName "OTel Collector - OTLP gRPC" -Direction Outbound -LocalPort Any -RemotePort 14317 -Protocol TCP -Action Allow

# Allow outbound to OTLP HTTP
New-NetFirewallRule -DisplayName "OTel Collector - OTLP HTTP" -Direction Outbound -LocalPort Any -RemotePort 14318 -Protocol TCP -Action Allow
```

---

## Security Considerations

**Service Account:**
- Default: LocalSystem (full privileges)
- Recommended: Create dedicated service account with minimal privileges
- Required permissions: Read Event Logs, Network access, Performance counters

**Config File Permissions:**
- Default: Full control for Administrators
- Recommended: Read-only for service account, Full control for Administrators

**Network:**
- Collector only needs outbound access to OTLP aggregator
- Internal telemetry (8888) only exposed on localhost by default
- No inbound connections required

---

## Performance Tuning

**High-Frequency Environments:**

```yaml
receivers:
  hostmetrics:
    collection_interval: 300s  # Reduce from 60s to 5 minutes

processors:
  batch:
    timeout: 30s  # Increase from 10s
    send_batch_size: 2048  # Increase from 1024
```

**Low-Memory Environments:**

```yaml
processors:
  memory_limiter:
    limit_mib: 128  # Reduce from 512
    spike_limit_mib: 32  # Reduce from 128

  batch:
    send_batch_size: 512  # Reduce from 1024
```

---

## Related Documentation

- **Gate #022 Spec:** BOSSCAT-022A implementation details
- **Collector Config:** `windows/otelcol/otelcol-contrib-config.yaml`
- **Install Script:** `scripts/windows/install-or-repair-otel-collector.ps1`
- **Verify Script:** `scripts/windows/verify-otel-collector.ps1`
- **Gate Integration:** `BRAV/SCPT/verify-windows-collector.ps1`

---

**Last Updated:** 2025-10-26 (Gate #022)  
**Authority:** BossCat OEM  
**Status:** Production-ready

🐾

