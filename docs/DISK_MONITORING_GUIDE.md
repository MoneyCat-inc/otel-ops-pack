# Disk Usage Monitoring Guide

## Overview

This guide covers automated disk usage monitoring for Windows hosts with SigNoz integration. The monitoring system tracks disk usage thresholds, logs to structured JSON files, writes Windows Event Log entries, and provides SigNoz alerting capabilities.

## Quick Start

### 1. Setup Monitoring (One-time)

```powershell
# Create scheduled task to run every 15 minutes
pwsh -File scripts/setup-disk-monitoring.ps1 -RunNow

# Generate SigNoz alert pack
pwsh -File scripts/setup-disk-alerts.ps1
```

### 2. Verify Monitoring

```powershell
# Run manual check
pwsh -File scripts/monitor-disk-usage.ps1

# Check logs
Get-Content C:/logs/disk-monitor/disk-usage.log -Tail 5

# Check scheduled task
Get-ScheduledTask -TaskName 'DiskUsageMonitor'
```

### 3. View in SigNoz

1. Open http://localhost:8080
2. Navigate to **Logs** → **Query Builder**
3. Filter: `attributes.dataset = "disk-monitor"`
4. Add status filter: `attributes.status = "critical"` or `"warning"`

## Components

### Core Scripts

- **`monitor-disk-usage.ps1`** - Main monitoring script
- **`setup-disk-monitoring.ps1`** - Scheduled task management
- **`setup-disk-alerts.ps1`** - SigNoz alert pack generator

### Output Files

- **`C:/logs/disk-monitor/disk-usage.log`** - JSON log entries
- **Windows Event Log** - Application log entries (EventID 8001)
- **`artifacts/signoz-disk-alerts.json`** - Alert configuration

## Configuration

### Default Thresholds

- **Warning**: 80% disk usage
- **Critical**: 90% disk usage
- **Check Interval**: 15 minutes

### Customization

```powershell
# Custom thresholds and drive
pwsh -File scripts/monitor-disk-usage.ps1 -Drive "D:" -WarningPercent 75 -CriticalPercent 85

# Different check interval
pwsh -File scripts/setup-disk-monitoring.ps1 -IntervalMinutes 30

# Enable auto-cleanup on critical
pwsh -File scripts/setup-disk-monitoring.ps1 -EnableCleanupOnCritical
```

## Log Format

Each log entry contains:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "message": "Drive C: usage 69.02% (status: ok)",
  "drive": "C:",
  "total_gb": 465.76,
  "used_gb": 321.45,
  "free_gb": 144.31,
  "percent_used": 69.02,
  "percent_free": 30.98,
  "warning_threshold": 80,
  "critical_threshold": 90,
  "status": "ok",
  "severity": "INFO",
  "dataset": "disk-monitor",
  "cleanup_triggered": false
}
```

## SigNoz Integration

### Log Filters

**All disk monitoring logs:**
```
attributes.dataset = "disk-monitor"
```

**Warning events only:**
```
attributes.dataset = "disk-monitor" AND attributes.status = "warning"
```

**Critical events only:**
```
attributes.dataset = "disk-monitor" AND attributes.status = "critical"
```

**Specific drive:**
```
attributes.dataset = "disk-monitor" AND attributes.drive = "C:"
```

### Dashboard Panels

1. **Current Disk Usage**
   - Type: Single Stat
   - Query: `attributes.percent_used` WHERE `attributes.dataset = "disk-monitor"`
   - Time Range: Last 5 minutes
   - Thresholds: Green <80%, Yellow 80-90%, Red >90%

2. **Disk Usage Trend**
   - Type: Time Series
   - Query: `attributes.percent_used` WHERE `attributes.dataset = "disk-monitor"`
   - Time Range: 24 hours
   - Group By: `attributes.drive`

3. **Free Space by Drive**
   - Type: Table
   - Query: `attributes.free_gb` WHERE `attributes.dataset = "disk-monitor"`
   - Time Range: Last 5 minutes
   - Sort by: `attributes.free_gb` ascending

## Alerting

### Import Alerts

1. Run `pwsh -File scripts/setup-disk-alerts.ps1`
2. Open SigNoz → **Alerts** → **Import JSON**
3. Upload `artifacts/signoz-disk-alerts.json`

### Alert Types

1. **Disk Usage Warning** (>=80%)
   - Severity: Warning
   - Evaluation: 5 minutes
   - Notification: Email

2. **Disk Usage Critical** (>=90%)
   - Severity: Critical
   - Evaluation: 1 minute
   - Notification: Email + Slack

## Troubleshooting

### Common Issues

**Script not running:**
```powershell
# Check task status
Get-ScheduledTask -TaskName 'DiskUsageMonitor'

# Check last run result
Get-ScheduledTask -TaskName 'DiskUsageMonitor' | Get-ScheduledTaskInfo
```

**No logs appearing:**
```powershell
# Check log directory
Test-Path C:/logs/disk-monitor

# Check file permissions
Get-Acl C:/logs/disk-monitor
```

**Event log errors:**
```powershell
# Check for EventID 8001
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ID = 8001 } -MaxEvents 10
```

### Manual Testing

```powershell
# Test with verbose output
pwsh -File scripts/monitor-disk-usage.ps1 -Verbose

# Test different thresholds
pwsh -File scripts/monitor-disk-usage.ps1 -WarningPercent 50 -CriticalPercent 60

# Test without event log
pwsh -File scripts/monitor-disk-usage.ps1 -DisableEventLog
```

## Maintenance

### Log Rotation

The system creates new log entries without rotation. For long-term deployments:

```powershell
# Manual log cleanup (keep last 1000 lines)
$logFile = "C:/logs/disk-monitor/disk-usage.log"
if (Test-Path $logFile) {
    $lines = Get-Content $logFile
    if ($lines.Count -gt 1000) {
        $lines[-1000..-1] | Set-Content $logFile -Encoding UTF8
    }
}
```

### Task Management

```powershell
# Remove monitoring
pwsh -File scripts/setup-disk-monitoring.ps1 -Remove

# Update interval
pwsh -File scripts/setup-disk-monitoring.ps1 -IntervalMinutes 10 -Remove
pwsh -File scripts/setup-disk-monitoring.ps1 -IntervalMinutes 10
```

### Cleanup Automation

The system supports optional auto-cleanup when critical thresholds are reached:

```powershell
# Enable auto-cleanup (requires cleanup script)
pwsh -File scripts/setup-disk-monitoring.ps1 -EnableCleanupOnCritical

# Manual cleanup test
pwsh -File scripts/disk-cleanup-audit.ps1 -AnalyzeOnly
```

## Security Considerations

- Scripts run with SYSTEM privileges via scheduled task
- Log files are readable by administrators
- Event log entries are visible in Windows Event Viewer
- No sensitive data is logged (only disk usage metrics)

## Integration with OTel Pipeline

The disk monitoring integrates with the existing OpenTelemetry pipeline:

1. **File Logs** → OTel File Log Receiver → SigNoz
2. **Event Logs** → OTel Windows Event Log Receiver → SigNoz
3. **Direct OTLP** → Optional HTTP endpoint forwarding

### OTel Configuration

Ensure your `config.yaml` includes:

```yaml
receivers:
  filelog:
    include: [ "C:/logs/disk-monitor/*.log" ]
    operators:
      - type: json_parser
        parse_from: body
        parse_to: attributes
  
  windowseventlog:
    channels:
      - Application
    filters:
      - source: DiskUsageMonitor
```

## Verification Checklist

- [ ] Scheduled task created and running
- [ ] Log files generated in `C:/logs/disk-monitor/`
- [ ] Event log entries visible (EventID 8001)
- [ ] SigNoz logs show `dataset="disk-monitor"`
- [ ] Alert pack generated in `artifacts/`
- [ ] Alerts imported in SigNoz (optional)
- [ ] Dashboard panels created (optional)

## Next Steps

1. **Import alerts** from `artifacts/signoz-disk-alerts.json`
2. **Create dashboard** with disk usage panels
3. **Set up notifications** (email/Slack channels)
4. **Configure cleanup automation** (optional)
5. **Monitor multiple drives** by running setup for each drive

For additional queries and dashboard templates, see [QUERY_RECIPES.md](QUERY_RECIPES.md#infrastructure-monitoring-local-host).