# SigNoz Disk Alerts Setup Guide

## Overview
This guide provides step-by-step instructions for importing disk monitoring alerts and creating a saved view in SigNoz for the OTel observability pipeline.

## Prerequisites
- SigNoz running at `http://localhost:8080`
- Disk monitoring script generating logs with `dataset="disk-monitor"`
- SigNoz version 0.95.0+ (verified compatible)

## Step 1: Import Disk Alerts

### Option A: Using the Import Script
```powershell
# Dry run to preview what will be imported
pwsh -File scripts/import-disk-alerts.ps1 -DryRun

# Import alerts and create saved view
pwsh -File scripts/import-disk-alerts.ps1 -CreateSavedView
```

### Option B: Manual Import via SigNoz UI

1. **Open SigNoz UI**: Navigate to `http://localhost:8080`
2. **Go to Alerts**: Click on "Alerts" in the left sidebar
3. **Create New Alert**: Click "New Alert" or "Create Alert"

#### Alert 1: Disk Usage Warning
- **Name**: `Disk Usage Warning`
- **Description**: `Alert when disk usage exceeds 80%`
- **Query**: 
  ```
  count by (drive) (attributes.dataset="disk-monitor" and attributes.status="warning") > 0
  ```
- **Severity**: `Warning`
- **Duration**: `1 minute`

#### Alert 2: Disk Usage Critical
- **Name**: `Disk Usage Critical`
- **Description**: `Alert when disk usage exceeds 90%`
- **Query**: 
  ```
  count by (drive) (attributes.dataset="disk-monitor" and attributes.status="critical") > 0
  ```
- **Severity**: `Critical`
- **Duration**: `30 seconds`

#### Alert 3: Disk Monitor Offline
- **Name**: `Disk Monitor Offline`
- **Description**: `Alert when disk monitoring stops reporting`
- **Query**: 
  ```
  count by (attributes.dataset) (attributes.dataset="disk-monitor") == 0
  ```
- **Severity**: `Warning`
- **Duration**: `5 minutes`

## Step 2: Create Saved View for Disk Monitoring

### Via SigNoz UI
1. **Navigate to Logs**: Click "Logs" in the left sidebar
2. **Apply Filter**: In the search bar, enter:
   ```
   attributes.dataset = "disk-monitor"
   ```
3. **Create Saved View**: 
   - Click the "Save" button (usually near the search bar)
   - Name: `Disk Monitoring Logs`
   - Description: `Saved view for disk monitoring logs with dataset filter`
4. **Set Time Range**: Choose appropriate time range (e.g., Last 1 hour)

### Via API (Alternative)
```powershell
# Create saved view configuration
$savedViewConfig = @{
    name = "Disk Monitoring Logs"
    description = "Saved view for disk monitoring logs"
    query = 'attributes.dataset = "disk-monitor"'
    timeRange = @{
        start = "1h"
        end = "now"
    }
}

$json = $savedViewConfig | ConvertTo-Json -Depth 10
Write-Host "Saved view config: $json"
```

## Step 3: Verify Setup

### Test Disk Monitoring
```powershell
# Generate test disk monitoring data
pwsh -File scripts/monitor-disk-usage.ps1

# Check logs are being ingested
Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1
```

### Verify in SigNoz
1. **Check Logs**: Go to Logs → Filter by `attributes.dataset = "disk-monitor"`
2. **Verify Latest Entry**: Should show `Drive C: usage 69.02% (status: ok)`
3. **Check Alerts**: Go to Alerts → Verify all three alerts are created and enabled
4. **Test Saved View**: Use the saved view to quickly access disk monitoring logs

## Step 4: Dashboard Configuration (Optional)

### Create Disk Monitoring Dashboard
1. **Navigate to Dashboards**: Click "Dashboards" in SigNoz
2. **Create New Dashboard**: Click "New Dashboard"
3. **Add Panels**:

#### Panel 1: Disk Usage by Drive (Gauge)
- **Title**: `Disk Usage by Drive`
- **Query**: `attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")`
- **Type**: `Gauge`

#### Panel 2: Disk Usage Trend (Line Chart)
- **Title**: `Disk Usage Trend (24h)`
- **Query**: `attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")`
- **Type**: `Line Chart`

#### Panel 3: Free Space by Drive (Bar Chart)
- **Title**: `Free Space by Drive`
- **Query**: `attributes.free_gb by (attributes.drive) (attributes.dataset="disk-monitor")`
- **Type**: `Bar Chart`

#### Panel 4: Disk Status Count (Pie Chart)
- **Title**: `Disk Status Count`
- **Query**: `count by (attributes.status) (attributes.dataset="disk-monitor")`
- **Type**: `Pie Chart`

#### Panel 5: Recent Disk Alerts (Table)
- **Title**: `Recent Disk Alerts`
- **Query**: `attributes.message by (attributes.drive, attributes.status) (attributes.dataset="disk-monitor" and attributes.status!="ok")`
- **Type**: `Table`

## Verification Commands

```powershell
# Check SigNoz health
curl -s "http://localhost:8080/api/v1/health"

# Run disk monitoring
pwsh -File scripts/monitor-disk-usage.ps1

# Verify log ingestion
Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 3

# Check scheduled task status
Get-ScheduledTaskInfo -TaskName 'DiskUsageMonitor'
```

## Troubleshooting

### Common Issues

1. **Alerts Not Triggering**
   - Verify query syntax in SigNoz UI
   - Check that logs are being ingested with correct attributes
   - Ensure alert duration is appropriate

2. **Saved View Not Working**
   - Verify filter syntax: `attributes.dataset = "disk-monitor"`
   - Check time range settings
   - Ensure logs are being generated

3. **Logs Not Appearing in SigNoz**
   - Verify filelog receiver configuration in `config.yaml`
   - Check OTel collector logs for parsing errors
   - Ensure log file permissions are correct

### Debug Commands
```powershell
# Check OTel collector status
sc query otelcol-contrib

# Verify log file structure
Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1 | ConvertFrom-Json

# Test SigNoz connectivity
curl -s "http://localhost:8080/api/v1/version"
```

## Next Steps

1. **Monitor Alert Performance**: Watch for false positives/negatives
2. **Tune Thresholds**: Adjust warning (80%) and critical (90%) thresholds as needed
3. **Add More Drives**: Extend monitoring to additional drives if required
4. **Integration**: Connect alerts to notification channels (email, Slack, etc.)

## References

- [SigNoz Alerts Documentation](https://signoz.io/docs/userguide/alerts/)
- [SigNoz Logs Documentation](https://signoz.io/docs/userguide/logs/)
- [OTel Filelog Receiver](https://opentelemetry.io/docs/collector/configuration/processors/filelog/)
