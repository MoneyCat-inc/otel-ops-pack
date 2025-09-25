# Windows Logs Canary Alert System

## Overview

The Windows Logs Canary Alert system provides automated monitoring for Windows Event Log ingestion into SigNoz. It creates canary entries in Windows Event Logs and monitors their successful ingestion to detect pipeline issues.

## Components

### 1. Alert Configuration
- **File**: `signoz-windows-logs-canary-alert.json`
- **Purpose**: SigNoz alert configuration for Windows logs canary monitoring
- **Duration**: 1 hour monitoring window
- **Threshold**: Alert if no canaries detected for 1 hour

### 2. Test Script
- **File**: `scripts/windows-logs-canary-test.ps1`
- **Purpose**: Generate Windows Event Log canary entries
- **Usage**: Creates test entries in Application log with specific canary IDs

### 3. Monitoring Script
- **File**: `scripts/monitor-windows-logs-canary.ps1`
- **Purpose**: CLI monitoring of canary ingestion via ClickHouse queries
- **Usage**: Check canary count in specified time window

### 4. Import Script
- **File**: `scripts/import-windows-logs-canary-alert.ps1`
- **Purpose**: Import alert configuration into SigNoz
- **Usage**: Provides manual import instructions and verification

## Quick Start

### 1. Generate Canary Entries
```powershell
# Create 5 test canary entries
.\scripts\windows-logs-canary-test.ps1 -Count 5

# Create entries in System log
.\scripts\windows-logs-canary-test.ps1 -Count 3 -LogName System
```

### 2. Monitor Canary Ingestion
```powershell
# Monitor last 10 minutes
.\scripts\monitor-windows-logs-canary.ps1 -TimeWindowMinutes 10

# Monitor last hour with custom threshold
.\scripts\monitor-windows-logs-canary.ps1 -TimeWindowMinutes 60 -AlertThreshold 2
```

### 3. Import Alert into SigNoz
```powershell
# Get import instructions
.\scripts\import-windows-logs-canary-alert.ps1
```

## SigNoz UI Verification

### Logs Query
Navigate to: **SigNoz UI → Logs**

**Filter Query:**
```
attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%'
```

**Expected Results:**
- Recent entries with canary IDs like `windows-logs-canary-20250924-012707-1`
- Entries should appear within 1-2 minutes of running the test script

### Alert Configuration
Navigate to: **SigNoz UI → Alerts → Create Alert**

**Configuration:**
- **Name**: Windows Logs Canary Missing (1 Hour)
- **Severity**: Warning
- **Query**: `SELECT count() as value FROM logs WHERE attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%' AND timestamp >= now() - INTERVAL 1 HOUR`
- **Condition**: Below 1 for 60 minutes
- **Labels**: `component=windows-logs`, `canary=true`, `alert_type=ingestion`

## Monitoring Features

### Real-time Detection
- Monitors Windows Event Log canary entries in SigNoz
- Detects ingestion pipeline failures within 1 hour
- Provides detailed diagnostic information

### Alert Thresholds
- **Default**: Alert if no canaries in 1 hour
- **Configurable**: Adjust time window and threshold
- **Severity**: Warning level alerts

### Diagnostic Queries
When canaries are missing, the system provides:
- Total log count in time window
- Windows Event Log entries count
- All canary entries count
- Windows canary entries count
- Time range of available logs

## File Structure

```
C:\otel\
├── signoz-windows-logs-canary-alert.json          # Alert configuration
├── scripts/
│   ├── windows-logs-canary-test.ps1               # Test script
│   ├── monitor-windows-logs-canary.ps1            # Monitoring script
│   └── import-windows-logs-canary-alert.ps1       # Import script
├── artifacts/
│   ├── windows-logs-canary-test-*.json            # Test reports
│   └── windows-logs-canary-monitor-*.json         # Monitoring reports
└── WINDOWS_LOGS_CANARY_ALERT_GUIDE.md            # This guide
```

## Troubleshooting

### No Canaries Detected
1. **Check Windows Event Log**:
   ```powershell
   Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object { $_.Message -like '*windows-logs-canary*' }
   ```

2. **Check Collector Service**:
   ```powershell
   Get-Service otelcol-contrib
   ```

3. **Check SigNoz Connectivity**:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 8080
   ```

### Permission Issues
- Ensure PowerShell is running as Administrator
- Windows Event Log writing requires elevated privileges

### Ingestion Delays
- Allow 1-2 minutes for log processing
- Check collector configuration for batch settings
- Verify OTLP endpoints (5317/5318) are accessible

## Integration with Existing Systems

### ECRR Framework
The Windows Logs Canary Alert system follows ECRR principles:
- **Examine**: Capture current ingestion state
- **Clean**: Remove drift and ensure pipeline health
- **Report**: Generate monitoring artifacts
- **Role**: Declare responsible actors

### Cat Nap Control Room
- Maintains calm, efficient monitoring aesthetic
- Color-coded status indicators
- Minimal noise, maximum signal

## Commands Summary

```powershell
# Generate canary entries
.\scripts\windows-logs-canary-test.ps1

# Monitor ingestion
.\scripts\monitor-windows-logs-canary.ps1

# Import alert
.\scripts\import-windows-logs-canary-alert.ps1

# Check recent canaries in SigNoz
# Use filter: attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%'
```

## Success Criteria

✅ **Canary Generation**: Test script creates Windows Event Log entries  
✅ **Ingestion Verification**: Entries appear in SigNoz within 2 minutes  
✅ **Monitoring Detection**: CLI monitor detects canary entries  
✅ **Alert Configuration**: SigNoz alert properly configured  
✅ **Pipeline Health**: No ingestion failures detected  

## Next Steps

1. Import alert configuration into SigNoz UI
2. Set up automated canary generation (Task Scheduler)
3. Configure notification channels for alerts
4. Integrate with existing monitoring dashboards
5. Set up alert escalation procedures
