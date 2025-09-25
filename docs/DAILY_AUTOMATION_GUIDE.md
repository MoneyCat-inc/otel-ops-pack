# Daily Automation Guide for OTel Latency Management

## Overview

This guide covers the complete daily automation setup for OpenTelemetry latency baseline management and SigNoz dashboard updates. The automation system provides:

- **Daily baseline updates** from latest experiment data
- **Automated dashboard configuration export** with current metrics
- **SigNoz dashboard import instructions** for manual application
- **Comprehensive monitoring** with alerts and saved searches

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Scheduled     │    │   Baseline       │    │   SigNoz        │
│   Task          │───▶│   Management     │───▶│   Dashboard     │
│   (Daily 2AM)   │    │   Script         │    │   Import        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Dashboard      │
                       │   Export         │
                       │   (JSON Config)  │
                       └──────────────────┘
```

## Quick Start

### 1. Setup Daily Automation

```powershell
# Run as Administrator
pwsh -File scripts/setup-daily-automation.ps1

# Or with custom schedule time
pwsh -File scripts/setup-daily-automation.ps1 -ScheduleTime "03:30"

# Preview without making changes
pwsh -File scripts/setup-daily-automation.ps1 -DryRun
```

### 2. Verify Setup

```powershell
# Check automation status
pwsh -File scripts/verify-daily-automation.ps1

# View scheduled task
Get-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily"
```

### 3. Test Automation

```powershell
# Run automation manually
pwsh -File scripts/manage-latency-baselines.ps1 -Action apply

# Or trigger scheduled task
Start-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily"
```

## Detailed Configuration

### Scheduled Task Configuration

The automation creates a Windows scheduled task with these settings:

- **Task Name**: `OTel-Latency-Baseline-Daily`
- **Schedule**: Daily at 2:00 AM (configurable)
- **Action**: `pwsh -File scripts/manage-latency-baselines.ps1 -Action apply`
- **Principal**: SYSTEM account with highest privileges
- **Settings**: Allow start on batteries, don't stop on batteries, start when available

### Baseline Management

The `apply` action performs these steps:

1. **Find Latest Experiment**: Locates the most recent experiment in `artifacts/doe/`
2. **Extract Control Run**: Identifies the control run from the experiment
3. **Update Baseline**: Updates the baseline with latest latency measurements
4. **Export Dashboard**: Generates SigNoz dashboard configuration
5. **Import Instructions**: Provides manual import steps for SigNoz

### Dashboard Configuration

The exported dashboard includes:

#### Panels
- **Latency P95 (24h)**: Primary latency metric with baseline thresholds
- **Latency P50 (24h)**: Median latency with baseline comparison
- **Baseline Comparison**: Current vs baseline P95 latency
- **Regression Alert**: Percentage regression from baseline
- **Request Volume (24h)**: Traffic volume over time
- **Error Rate (24h)**: Error percentage with thresholds
- **Pipeline Health**: Canary test status

#### Alerts
- **OTel Latency Regression**: P95 exceeds baseline threshold
- **OTel High Error Rate**: Error rate > 5%
- **OTel Pipeline Stalled**: No canary events detected
- **OTel Data Flow Interrupted**: No events for extended period

#### Saved Searches
- **OTel Latency Events**: All latency measurements
- **OTel Error Events**: Error events in pipeline
- **OTel Canary Tests**: Canary test executions
- **OTel Baseline Updates**: Baseline update events
- **OTel High Latency**: Events with latency > 1s

## Manual Operations

### Create Schedule Only

```powershell
# Create scheduled task without full setup
pwsh -File scripts/manage-latency-baselines.ps1 -Action create-schedule -ScheduleTime "02:00"
```

### Export Dashboard Only

```powershell
# Export dashboard configuration
pwsh -File scripts/export-dashboard-config.ps1 -BaselineFile "artifacts/doe/baselines/latency.json"
```

### Import Dashboard to SigNoz

```powershell
# Get import instructions
pwsh -File scripts/import-dashboard.ps1 -DashboardFile "artifacts/signoz-dashboard-config.json" -ApplyMode
```

### Manual Baseline Operations

```powershell
# List available baselines
pwsh -File scripts/manage-latency-baselines.ps1 -Action list

# Create baseline from specific run
pwsh -File scripts/manage-latency-baselines.ps1 -Action create -SourceRunId "control-r1-20250921-190945"

# Update baseline
pwsh -File scripts/manage-latency-baselines.ps1 -Action update -SourceRunId "control-r2-20250922-080000"

# Compare run against baseline
pwsh -File scripts/manage-latency-baselines.ps1 -Action compare -SourceRunId "test-run-001"
```

## SigNoz Integration

### Dashboard Import Process

Since SigNoz doesn't support automated dashboard import via API, the automation provides detailed manual instructions:

1. **Open SigNoz UI**: Navigate to `http://localhost:8080`
2. **Import Dashboard**: Go to Dashboards → Import
3. **Upload Configuration**: Upload `artifacts/signoz-dashboard-config.json`
4. **Configure Data Sources**: Set up data source connections if needed
5. **Save Dashboard**: Save the imported dashboard

### Alert Configuration

Configure alerts manually in SigNoz:

1. **Navigate to Alerts**: Go to Alerts → New Alert
2. **Use Provided Queries**: Copy queries from the exported configuration
3. **Set Evaluation Windows**: Use the recommended evaluation periods
4. **Configure Severity**: Set appropriate severity levels

### Saved Searches

Create saved searches for quick access:

1. **Go to Logs**: Navigate to Logs → Saved Searches → New
2. **Use Provided Queries**: Copy queries from the exported configuration
3. **Save Searches**: Save for future use

## Monitoring and Troubleshooting

### Verification Commands

```powershell
# Check automation status
pwsh -File scripts/verify-daily-automation.ps1

# View scheduled task details
Get-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily" | Format-List

# Check task execution history
Get-ScheduledTaskInfo -TaskName "OTel-Latency-Baseline-Daily"
```

### Common Issues

#### Scheduled Task Not Running

```powershell
# Check task state
Get-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily"

# Enable task if disabled
Enable-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily"

# Run task manually
Start-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily"
```

#### No Baseline Data

```powershell
# Check for experiment data
Get-ChildItem -Path "artifacts/doe" -Directory | Sort-Object LastWriteTime -Descending

# Create initial baseline
pwsh -File scripts/manage-latency-baselines.ps1 -Action create -SourceRunId "your-run-id"
```

#### SigNoz Not Accessible

```powershell
# Test SigNoz connectivity
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get

# Check Docker services
docker ps | findstr signoz
```

### Log Files

The automation creates several log files:

- **Scheduled Task Logs**: Windows Event Viewer → Task Scheduler
- **PowerShell Logs**: Check `$env:TEMP` for PowerShell execution logs
- **Baseline Files**: `artifacts/doe/baselines/latency.json`
- **Dashboard Config**: `artifacts/signoz-dashboard-config.json`

## Advanced Configuration

### Custom Schedule Times

```powershell
# Different schedule times
pwsh -File scripts/setup-daily-automation.ps1 -ScheduleTime "01:00"  # 1 AM
pwsh -File scripts/setup-daily-automation.ps1 -ScheduleTime "06:30"  # 6:30 AM
pwsh -File scripts/setup-daily-automation.ps1 -ScheduleTime "23:45"  # 11:45 PM
```

### Multiple Baselines

```powershell
# Create different baseline types
pwsh -File scripts/manage-latency-baselines.ps1 -Action create -BaselineName "production" -SourceRunId "prod-run-001"
pwsh -File scripts/manage-latency-baselines.ps1 -Action create -BaselineName "staging" -SourceRunId "staging-run-001"

# Schedule automation for specific baseline
pwsh -File scripts/manage-latency-baselines.ps1 -Action create-schedule -BaselineName "production"
```

### Custom Thresholds

```powershell
# Use custom regression threshold
pwsh -File scripts/manage-latency-baselines.ps1 -Action apply -Threshold 15  # 15% threshold
```

## Security Considerations

### Service Account Permissions

The scheduled task runs under the SYSTEM account with highest privileges:

- **File System Access**: Full access to `C:\otel` directory
- **PowerShell Execution**: Can run PowerShell scripts
- **Network Access**: Can connect to SigNoz API
- **Registry Access**: Can read Windows configuration

### Data Privacy

- **Local Processing**: All data processing happens locally
- **No External Calls**: No data sent to external services
- **Baseline Storage**: Baselines stored in local JSON files
- **Dashboard Export**: Configuration exported locally only

## Maintenance

### Regular Tasks

1. **Monitor Task Execution**: Check scheduled task runs daily
2. **Review Baseline Updates**: Verify baseline data quality
3. **Update Dashboard**: Ensure SigNoz dashboard reflects current metrics
4. **Check Alerts**: Verify alert configurations are working

### Backup and Recovery

```powershell
# Backup baseline data
Copy-Item "artifacts/doe/baselines/latency.json" "backups/baseline-$(Get-Date -Format 'yyyyMMdd').json"

# Backup dashboard configuration
Copy-Item "artifacts/signoz-dashboard-config.json" "backups/dashboard-$(Get-Date -Format 'yyyyMMdd').json"

# Restore from backup
Copy-Item "backups/baseline-20250921.json" "artifacts/doe/baselines/latency.json"
```

### Updates and Upgrades

When updating the automation system:

1. **Stop Scheduled Task**: Disable the task before updates
2. **Backup Configuration**: Save current baseline and dashboard configs
3. **Update Scripts**: Deploy new script versions
4. **Test Automation**: Run verification and test apply action
5. **Re-enable Task**: Enable scheduled task after verification

## Support and Troubleshooting

### Getting Help

1. **Check Verification**: Run `scripts/verify-daily-automation.ps1`
2. **Review Logs**: Check Windows Event Viewer and PowerShell logs
3. **Test Components**: Test individual components manually
4. **Check Dependencies**: Verify SigNoz and experiment data availability

### Contact Information

For issues with the automation system:

- **Documentation**: Check this guide and inline script help
- **Logs**: Review automation execution logs
- **Verification**: Use the verification script for diagnostics

---

## Summary

The daily automation system provides comprehensive, hands-off management of OTel latency baselines and SigNoz dashboard updates. The system is designed to be:

- **Reliable**: Runs daily without manual intervention
- **Flexible**: Configurable schedule times and thresholds
- **Transparent**: Clear logging and verification capabilities
- **Maintainable**: Easy to update and troubleshoot

The automation ensures that latency monitoring remains current and accurate while minimizing operational overhead.
