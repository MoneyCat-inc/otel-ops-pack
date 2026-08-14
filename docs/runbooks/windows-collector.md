<!-- markdownlint-disable MD013 MD022 MD032 MD034 -->
# Windows Collector (otelcol-contrib) — Runbook

<!-- markdownlint-disable -->

**Authority:** BossCat OEM  
**Gate:** #022 (BOSSCAT-022A - Deployed & Hardened)  
**Purpose:** Collect Windows host metrics and Event Logs for observability pipeline  
**Version:** 1.1.0 (Post-Op Hardened)

---

## Status: FIRST-CLASS (Phase 1 decision, 2026-08-03)

**Correcting the record.** Gate #026A was read as declaring this collector intentionally bypassed
on the grounds that Docker collectors carry telemetry. **That reading is wrong and should not be
used to justify deprioritising this component.**

Measured 2026-08-03: the service exports **472 log records to SigNoz with zero send failures**,
sourced from `windowseventlog/application` (268), `windowseventlog/system` (39), `filelog/canary`
(125) and `otlp` HTTP (62). **A collector running inside a Docker container cannot read the Windows
Event Log** — it is a host-OS facility with no container-visible equivalent. This service is the
sole carrier of that telemetry class.

What Gate #026A actually established is narrower: for **.NET trace export**, the direct-to-SigNoz
path is preferred over routing through this collector. That is a routing preference for one signal
type, not a verdict on the component.

Operator decision (Phase 1, Roadmap 2026 H2): **keep as first-class and upgrade.** See
`docs/BossCat/MEMO_WINDOWS_COLLECTOR_20260803.md`.

**Upgraded to `v0.158.0` on 2026-08-13** (Phase 1 execution). Running / Automatic, exporting with
zero send failures. The clean-host E2E finding **F3** (scraper list-syntax crash-loop on `0.104.0`)
is **retired** — config validate exits 0 on `0.158.0`.

The version is now pinned in one place, `startup-observability.ps1` (`$CollectorVersion`). Before
#452 nothing in the repo decided the version at all; `0.104.0` was simply what had been installed by
hand in Oct 2025.

---

## 🚨 Canonical Configuration Path (CRITICAL)

> **⚠️ This section contradicted the Configuration section below, and the live service. Corrected
> 2026-08-03.** The claims below asserted `C:\otel\config.yaml` is the service's config path and
> that any other path is a RED condition. The running service reads
> `C:\ProgramData\otelcol-contrib\config.yaml` and is healthy (472 log records exported, zero send
> failures), so the old text would have flagged the correct, working state as RED.
>
> **The two paths are different roles, not rivals:**
>
> - `C:\otel\config.yaml` — the **source of record**, edited in the repo and reviewed via PR. This
>   is what "authoritative" was reaching for.
> - `C:\ProgramData\otelcol-contrib\config.yaml` — the **deployed copy** the service actually
>   reads. Written by `install-or-repair-otel-collector.ps1`; never hand-edit it.
>
> Editing the repo file does **not** change collector behaviour until install-or-repair runs. That
> is the intended flow, and it means a git branch switch cannot mutate live config.

**Source of record (edit here):** `C:\otel\config.yaml`

**Deployed config (service reads this, do not hand-edit):** `C:\ProgramData\otelcol-contrib\config.yaml`

**⚠️ RED Condition:** the service pointing at a config path that no deploy step writes — e.g. a
stale per-user path, or a `windows/otelcol/` source file passed directly. A service on the
ProgramData path is **correct**.

**Verification Command:**
```powershell
sc qc otelcol-contrib | findstr /i "BINARY_PATH_NAME"
```

**Expected Output:**
```
BINARY_PATH_NAME   : "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\ProgramData\otelcol-contrib\config.yaml"
```

**Applying a config change:**
```powershell
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
```

**Critical Requirements:**
- ✅ Endpoint MUST be: `127.0.0.1:14317` (gRPC to localhost aggregator)
- ❌ OLD/WRONG: `host.docker.internal:4318` (causes connection refused errors)
- ✅ Collector Version: `v0.158.0` (upgraded and verified 2026-08-13; pinned in `startup-observability.ps1`)
- ✅ Config Syntax: Standard receivers format (see compatibility notes below)

**Drift Guard Health Check:**
```powershell
pwsh -File .\scripts\windows\health-check-collector-config.ps1
```
Run every 15 minutes via Task Scheduler. Exit code 20/21 = RED condition.

> **⚠️ This guard inherited the same wrong assumption and could never pass.** Its Check 3 asserted
> the service runs `--config "C:\otel\config.yaml"` — the source path, which the service never
> uses — so on 2026-08-03 it returned **exit 21 (RED)** against a collector exporting 472 records
> with zero failures. A gate that cannot pass is as useless as one that cannot fail; treat any
> historical RED from this script before its fix as unproven. Corrected separately in the code
> lane.

---

## 📡 Trace Paths — Canonical Endpoints (Gate #027)

**For .NET Auto-Instrumentation (OTLP Exporters):**

### PRIMARY PATH (Recommended) — Direct to SigNoz ✅
**Endpoint:** `http://127.0.0.1:14317` (OTLP gRPC)  
**Status:** ✅ **PROVEN WORKING** (Gate #026A verified)  
**Use Case:** .NET services, direct telemetry export  
**Advantages:**
- Minimal hops (app → SigNoz)
- Verified with opentelemetry-dotnet-instrumentation v1.12.0
- Traces, metrics, and logs confirmed working
- 2.63% overhead measured

**Configuration:**
```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:14317"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
```

### SECONDARY PATH (for .NET traces) — Via Windows Collector ✅

> **"Secondary" applies to .NET trace routing only.** For Windows Event Log and host file logs this
> collector is the *only* path — see the FIRST-CLASS status note at the top of this runbook.

**Endpoint:** `http://127.0.0.1:5320` (Windows Collector OTLP gRPC) / `http://127.0.0.1:5321` (HTTP)  
**Status:** ✅ **CANONICAL** (`config.yaml` receivers; ports moved off 5317/5318 to avoid PlariumPlay 5300–5319)  
**Use Case:** Centralized collection, preprocessing, multi-export  
**Config:** Receiver on 5320/5321 → Processors → Export to SigNoz `localhost:4317`

**Configuration:**
```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:5320"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
```

**Health Probe:**
```powershell
pwsh -File .\scripts\windows\verify-collector-traces.ps1
# Verifies: receiver.accepted_spans ≈ exporter.sent_spans (±1%)
```

**Note:** As of Gate #027, collector path configured but has received 0 traces (never tested with live app). Direct path (14317) is production baseline.

---

## Overview

The Windows OpenTelemetry Collector (`otelcol-contrib`) runs as a Windows service and carries
**logs only**:
- **Windows Event Logs:** Application and System channels (real-time) — the reason this collector is
  first-class; a container cannot read these
- **File logs:** `filelog/canary` over `C:/logs/**/*.log`
- **OTLP ingest:** local apps on `127.0.0.1:5320` (gRPC) / `5321` (HTTP)

All telemetry is exported to the OTLP aggregator (signoz-otel-collector) via gRPC on port 14317.

> **⚠️ This section previously claimed host metrics — CPU, memory, disk, network, process stats at
> 60s. That was wrong.** The canonical config has **no `hostmetrics` receiver**, and the live
> collector reports no `otelcol_receiver_accepted_metric_points` series at all. If host metrics are
> wanted, that is a change to make deliberately, not an assumption to inherit.

**Version Compatibility Notes (v0.158.0):**
- **Windows Event Log Receiver:** `windowseventlog` receiver name, unchanged from `0.104.0`
- **Config validate:** exits 0 on `0.158.0` with the canonical config
- **Retired with the upgrade:** the `0.104.0` hostmetrics scraper list-vs-map syntax caveat that
  used to live here. It described a receiver this config does not use, and the version it applied to
  is gone. Reinstate a version note here only when a real incompatibility is observed.

---

## Install / Repair

> ### ⚠️ Read before upgrading: the MSI path fails on this host
>
> Observed during the 2026-08-13 upgrade to `0.158.0`. A quiet MSI install fails with **1603**,
> caused by **Error 1920 — the service could not start during install**, because the MSI's default
> config is written and started before a valid canonical config is in place.
>
> **The first attempt also removed the working `0.104.0` install**, so a failed MSI upgrade leaves
> the host with *no* collector, not the previous one. Budget for that.
>
> **Reliable path used instead:**
> 1. Download the tarball for the target version (not the MSI)
> 2. Extract to `C:\Program Files\OpenTelemetry Collector\`
> 3. `sc create` the service
> 4. `pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1` to write the deployed
>    config and set startup/recovery
>
> `startup-observability.ps1` (`$CollectorVersion`, #452) still uses the MSI with checksum
> verification. It is correct and reproducible for a *clean* host; it is not yet proven as an
> *upgrade* path. Until that gap is closed, treat upgrades as the manual sequence above.

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
- `-ConfigSource` (default: `.\config.yaml` — the source of record; changed in #429, this runbook
  previously named the older `.\windows\otelcol\otelcol-contrib-config.yaml`)
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
1. Edit source: `.\config.yaml` (the repo source of record — **not** the ProgramData copy)
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
- **Collector Config (source of record):** `config.yaml` at the repo root
- **Collector Config (deployed, service reads):** `C:\ProgramData\otelcol-contrib\config.yaml`
- **Install Script:** `scripts/windows/install-or-repair-otel-collector.ps1`
- **Verify Script:** `scripts/windows/verify-otel-collector.ps1`
- **Gate Integration:** `BRAV/SCPT/verify-windows-collector.ps1`

---

**Last Updated:** 2025-10-26 (Gate #022)  
**Authority:** BossCat OEM  
**Status:** Production-ready

🐾

