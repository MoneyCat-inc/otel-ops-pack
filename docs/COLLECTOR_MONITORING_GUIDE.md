# Windows OTel Collector Monitoring Guide

This guide covers the monitoring and alerting setup for the Windows OpenTelemetry Collector to ensure stability and quick issue resolution.

## Overview

The Windows OTel Collector monitoring system consists of:
- **Health Monitoring**: Continuous monitoring of service status, ports, and health endpoints
- **Alerting**: Automated alerts for service interruptions and performance issues
- **Restart Procedures**: Automated and manual restart capabilities
- **Documentation**: Comprehensive procedures for troubleshooting

## Health Monitoring

### Scripts Available

#### 1. `scripts/collector-health-monitor.ps1`
Continuous health monitoring with configurable intervals and duration.

**Usage:**
```powershell
# Basic monitoring (30-second intervals, unlimited duration)
pwsh -File scripts/collector-health-monitor.ps1

# Custom interval and duration
pwsh -File scripts/collector-health-monitor.ps1 -IntervalSeconds 60 -MaxDurationMinutes 30

# Quiet mode with data export
pwsh -File scripts/collector-health-monitor.ps1 -Quiet -Export
```

**Parameters:**
- `-IntervalSeconds`: Check interval in seconds (default: 30)
- `-MaxDurationMinutes`: Maximum run duration in minutes (default: 0 = unlimited)
- `-Quiet`: Suppress status output
- `-Export`: Export health data to JSON files

**Health Checks:**
- Service running status
- Port listening status (5317 gRPC, 5318 HTTP)
- Health endpoint response (http://localhost:13134/healthz)
- Process activity
- Configuration file validity

#### 2. `scripts/test-collector-status.ps1`
Quick status check for immediate troubleshooting.

**Usage:**
```powershell
pwsh -File scripts/test-collector-status.ps1
```

**Output:**
- Service status (Running/Stopped)
- Port availability (5317/5318)
- Clear success/failure indicators

### Health Metrics

The monitoring system tracks:
- **Uptime**: Service running percentage
- **Port Health**: OTLP endpoint availability
- **Health Endpoint**: Internal health check response
- **Configuration**: Config file validity
- **Process Activity**: Background process status

## Alerting Configuration

### Alert Setup

#### 1. `scripts/setup-collector-alerts.ps1`
Configures SigNoz alerts for collector monitoring.

**Usage:**
```powershell
# Generate alert configuration (dry run)
pwsh -File scripts/setup-collector-alerts.ps1 -DryRun

# Import alerts to SigNoz
pwsh -File scripts/setup-collector-alerts.ps1 -Import
```

**Alert Types:**
1. **Collector Service Down** (Critical)
   - Triggers when service is not running for 1 minute
   - Query: `up{job='otelcol-contrib'} == 0`

2. **Collector High Error Rate** (Warning)
   - Triggers when error rate > 0.1 failures/second for 2 minutes
   - Query: `rate(otelcol_exporter_send_failed_total[5m]) > 0.1`

3. **Collector Memory Usage High** (Warning)
   - Triggers when memory usage > 1GB for 5 minutes
   - Query: `process_resident_memory_bytes{job='otelcol-contrib'} > 1073741824`

4. **Collector Port Not Listening** (Critical)
   - Triggers when OTLP ports are not responding for 1 minute
   - Query: `up{job='otelcol-otlp-ports'} == 0`

### Alert Configuration File

Alerts are exported to: `artifacts/signoz-collector-alerts.json`

This file contains the complete alert rule configuration for SigNoz.

## Restart Procedures

### Automated Restart

#### 1. `restart-collector.ps1`
Administrator-level service restart script.

**Usage (requires Administrator privileges):**
```powershell
# Run as Administrator
pwsh -File restart-collector.ps1
```

**Process:**
1. Stops the otelcol-contrib service
2. Waits 3 seconds for graceful shutdown
3. Starts the service
4. Waits 5 seconds for startup
5. Verifies service status
6. Tests port availability (5317/5318)

### Manual Restart

**Using Services Management:**
1. Open Services (`services.msc`)
2. Find "otelcol-contrib" service
3. Right-click → Restart

**Using Command Line:**
```powershell
# Stop service
Stop-Service -Name "otelcol-contrib"

# Start service
Start-Service -Name "otelcol-contrib"

# Check status
Get-Service -Name "otelcol-contrib"
```

## Troubleshooting Procedures

### Service Not Running

1. **Check service status:**
   ```powershell
   Get-Service -Name "otelcol-contrib"
   ```

2. **Check Windows Event Logs:**
   ```powershell
   Get-WinEvent -LogName Application -FilterHashtable @{ID=1000; ProviderName="otelcol-contrib"} -MaxEvents 10
   ```

3. **Check configuration file:**
   ```powershell
   Test-Path "C:\otel\config.yaml"
   Get-Content "C:\otel\config.yaml" | Select-Object -First 10
   ```

4. **Restart service:**
   ```powershell
   pwsh -File restart-collector.ps1
   ```

### Ports Not Listening

1. **Check port status:**
   ```powershell
   netstat -an | findstr ":531"
   ```

2. **Test connectivity:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 5317
   Test-NetConnection -ComputerName localhost -Port 5318
   ```

3. **Check for port conflicts:**
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -like "*otel*"}
   ```

### Health Endpoint Not Responding

1. **Test health endpoint:**
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:13134/healthz" -TimeoutSec 5
   ```

2. **Check if health extension is enabled in config:**
   - Verify `health_check` extension is configured
   - Check endpoint is set to `0.0.0.0:13134`

### High Memory Usage

1. **Check memory usage:**
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -like "*otel*"} | Select-Object ProcessName, WorkingSet, PagedMemorySize
   ```

2. **Review configuration for memory-intensive components:**
   - Check batch sizes in exporters
   - Review queue sizes
   - Verify memory limits

## Monitoring Artifacts

### Health Data Export

Health monitoring data is exported to `artifacts/` directory:
- Format: JSON
- Naming: `collector-health-YYYYMMDD-HHMMSS.json`
- Contains: Service status, port health, timestamps, errors

### Alert Configuration

Alert rules are exported to:
- `artifacts/signoz-collector-alerts.json`
- Contains: Complete SigNoz alert rule configuration
- Import-ready for SigNoz setup

## Integration with ECRR

This monitoring system supports the ECRR (Examine → Clean → Report → Role) methodology:

### Examine
- Health monitoring captures current state
- Status checks provide baseline measurements
- Error logs document issues

### Clean
- Automated restart procedures resolve service issues
- Port conflict detection prevents configuration problems
- Configuration validation ensures proper setup

### Report
- Health data export provides audit trail
- Alert notifications document incidents
- Status summaries track system health

### Role
- Clear ownership of monitoring responsibilities
- Defined escalation procedures
- Documented troubleshooting steps

## Best Practices

1. **Regular Health Checks**: Run health monitoring continuously
2. **Alert Response**: Respond to alerts within defined SLAs
3. **Documentation**: Update procedures based on incidents
4. **Testing**: Regularly test restart procedures
5. **Review**: Monthly review of alert effectiveness

## Related Documentation

- [ECRR Project Report](docs/ECRR_PROJECT_REPORT.md)
- [SigNoz Monitoring Setup](MONITORING_SETUP_GUIDE.md)
- [Windows Collector Configuration](config.yaml)
- [Task Management System](jobs/README.md)

---

**Last Updated**: 2025-09-23  
**Version**: 1.0  
**Maintained by**: Observability Copilot
