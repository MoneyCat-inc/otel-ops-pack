# Windows Collector Recovery & Alert Test Runbook

## Overview
This runbook documents the successful recovery of the Windows OpenTelemetry Collector and the implementation of automated health checks with alerting.

## System Status (Last Updated: 2025-10-02 05:10:00)

### ✅ Current Status
- **Collector**: Active and listening on ports 5317 (gRPC) / 5318 (HTTP)
- **Canary Generation**: Automated every 5 minutes via scheduled task
- **Latest Session**: WINDOWS-CANARY-20251002-050728
- **SigNoz Health**: `{"status": "ok"}`
- **Alert Status**: Should auto-resolve as new entries settle

### 🔧 Configuration Files
- **Collector Config**: `C:\otel\config.yaml`
- **Alert Config**: `signoz-windows-logs-canary-alert.json`
- **Canary Script**: `scripts\generate-windows-canary.ps1`
- **Log Path**: `C:\logs\windows-canary-test.log`

### 📋 Scheduled Task
- **Name**: Windows Canary Health Check
- **Frequency**: Every 5 minutes
- **Command**: `powershell.exe -File 'C:\otel\scripts\generate-windows-canary.ps1' -DurationMinutes 1`
- **Account**: SYSTEM
- **Status**: Ready (Next run: 05:14:00)

## Verification Steps

### 1. Alert Status Check
1. Navigate to: http://localhost:8080 → Alerts → All Alerts
2. Look for: "Windows Logs Canary Absence"
3. Expected: RESOLVED (green status)

### 2. Logs Verification
1. Navigate to: SigNoz → Logs → Explorer
2. Set Time Range: Last 15 minutes
3. Apply Filter:
   ```
   (log.source = 'windows_event_log' AND body contains 'windows-canary') OR
   (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')
   ```
4. Expected: Recent entries with session WINDOWS-CANARY-20251002-050728

### 3. System Health Commands
```powershell
# Check latest canary logs
Get-Content 'C:\logs\windows-canary-test.log' | Select-Object -Last 3

# Check scheduled task status
schtasks /query /tn 'Windows Canary Health Check' /fo list

# Verify SigNoz health
Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health'

# Check collector ports
Get-NetTCPConnection -LocalPort 5317,5318 -State Listen
```

## Alert Configuration

### Windows Logs Canary Absence Alert
- **Trigger**: No canary logs for 10+ minutes
- **Query**: 
  ```
  (log.source = 'windows_event_log' AND body contains 'windows-canary') OR
  (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')
  ```
- **Threshold**: < 1 log entry
- **Evaluation Window**: 10 minutes
- **Severity**: Critical

## Troubleshooting

### If Alert Fires
1. Check collector status: `Get-Service otelcol-contrib`
2. Verify ports: `Get-NetTCPConnection -LocalPort 5317,5318`
3. Check scheduled task: `schtasks /query /tn 'Windows Canary Health Check'`
4. Run canary manually: `scripts\generate-windows-canary.ps1 -DurationMinutes 1`

### If Collector Stops
1. Restart service: `Restart-Service otelcol-contrib`
2. Or restart manually: `& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml"`

## Maintenance

### Periodic Checks (Recommended: Weekly)
1. Review alert status in SigNoz
2. Verify scheduled task is running
3. Check log file growth and rotation
4. Monitor SigNoz UI for any issues

### Monthly Tasks
1. Review and update alert thresholds if needed
2. Check collector configuration for drift
3. Verify SigNoz health and performance
4. Update documentation if changes are made

## Success Metrics
- ✅ Canary logs generated every 5 minutes
- ✅ Alert resolves within 1-2 minutes of log generation
- ✅ No false positives in alert firing
- ✅ SigNoz consistently shows `{"status": "ok"}`
- ✅ Collector ports 5317/5318 remain active

---
**Document Version**: 1.0  
**Last Updated**: 2025-10-02 05:10:00  
**Status**: Production Ready ✅
