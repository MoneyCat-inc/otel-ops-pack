# SigNoz Disk Monitoring Setup Guide

## Prerequisites

Ensure SigNoz is running and accessible:
```powershell
# Check if SigNoz is running
docker ps --filter "name=signoz"

# Check if accessible
Invoke-WebRequest -Uri "http://localhost:8080" -Method GET -TimeoutSec 5
```

If SigNoz is not running, start it with:
```powershell
# Start SigNoz stack
docker-compose -f docker-compose.yml up -d

# Wait for services to be ready
Start-Sleep -Seconds 30
```

## Step 1: Import Disk Monitoring Alerts

### 1.1 Generate Alert Pack
```powershell
# Ensure alert pack is generated
pwsh -File scripts/setup-disk-alerts.ps1
```

### 1.2 Import into SigNoz UI

1. **Open SigNoz UI**: Navigate to http://localhost:8080
2. **Go to Alerts**: Click on "Alerts" in the left sidebar
3. **Import Alerts**: Click "Import" or "Import JSON"
4. **Upload File**: Select `artifacts/signoz-disk-alerts.json`
5. **Review Configuration**: Verify the two alerts are imported:
   - **Disk Usage Warning** (>=80% usage)
   - **Disk Usage Critical** (>=90% usage)
6. **Save**: Click "Save" or "Import" to complete

### 1.3 Verify Alert Import
- Check that both alerts appear in the Alerts list
- Verify query filters are set correctly:
  - Warning: `attributes.dataset = "disk-monitor" AND attributes.status = "warning"`
  - Critical: `attributes.dataset = "disk-monitor" AND attributes.status = "critical"`

## Step 2: Create Disk Monitoring Dashboard

### 2.1 Create New Dashboard
1. **Go to Dashboards**: Click "Dashboards" in left sidebar
2. **Create Dashboard**: Click "New Dashboard"
3. **Name**: "Disk Usage Monitoring"
4. **Save**: Click "Save"

### 2.2 Add Dashboard Panels

#### Panel 1: Current Disk Usage Overview
1. **Add Panel**: Click "Add Panel"
2. **Panel Type**: Single Stat
3. **Title**: "Current Disk Usage"
4. **Query**:
   ```
   attributes.percent_used WHERE attributes.dataset = "disk-monitor"
   ```
5. **Time Range**: Last 5 minutes
6. **Thresholds**:
   - Green: < 80
   - Yellow: 80-90
   - Red: > 90
7. **Save Panel**: Click "Save"

#### Panel 2: Disk Usage Trend
1. **Add Panel**: Click "Add Panel"
2. **Panel Type**: Time Series
3. **Title**: "Disk Usage Trend (24h)"
4. **Query**:
   ```
   attributes.percent_used WHERE attributes.dataset = "disk-monitor"
   ```
5. **Time Range**: Last 24 hours
6. **Group By**: `attributes.drive`
7. **Interval**: 1 hour
8. **Save Panel**: Click "Save"

#### Panel 3: Free Space Alert
1. **Add Panel**: Click "Add Panel"
2. **Panel Type**: Table
3. **Title**: "Free Space by Drive"
4. **Query**:
   ```
   attributes.free_gb, attributes.drive, attributes.percent_used WHERE attributes.dataset = "disk-monitor"
   ```
5. **Time Range**: Last 5 minutes
6. **Sort**: `attributes.free_gb` ascending
7. **Save Panel**: Click "Save"

#### Panel 4: Drive Status Summary
1. **Add Panel**: Click "Add Panel"
2. **Panel Type**: Table
3. **Title**: "Drive Status Summary"
4. **Query**:
   ```
   attributes.drive, attributes.status, attributes.percent_used, attributes.free_gb WHERE attributes.dataset = "disk-monitor"
   ```
5. **Time Range**: Last 5 minutes
6. **Group By**: `attributes.drive`
7. **Save Panel**: Click "Save"

### 2.3 Arrange Dashboard Layout
- Drag panels to arrange in a logical layout
- Resize panels as needed
- Save dashboard when complete

## Step 3: Configure Notification Channels

### 3.1 Set Up Email Notifications
1. **Go to Settings**: Click "Settings" in left sidebar
2. **Notification Channels**: Click "Notification Channels"
3. **Add Channel**: Click "Add Channel"
4. **Channel Type**: Email
5. **Configuration**:
   - Name: "Disk Monitoring Email"
   - SMTP Host: Your SMTP server
   - SMTP Port: 587 (or 25)
   - Username: Your email
   - Password: Your email password
   - From Address: Your email
   - To Addresses: Admin emails (comma-separated)
6. **Test**: Click "Test" to verify
7. **Save**: Click "Save"

### 3.2 Set Up Slack Notifications (Optional)
1. **Add Channel**: Click "Add Channel"
2. **Channel Type**: Slack
3. **Configuration**:
   - Name: "Disk Monitoring Slack"
   - Webhook URL: Your Slack webhook URL
   - Channel: #alerts (or your preferred channel)
4. **Test**: Click "Test" to verify
5. **Save**: Click "Save"

### 3.3 Configure Alert Notifications
1. **Go to Alerts**: Return to Alerts page
2. **Edit Warning Alert**: Click edit on "Disk Usage Warning"
3. **Notification Channels**: Select "Disk Monitoring Email"
4. **Save**: Click "Save"
5. **Edit Critical Alert**: Click edit on "Disk Usage Critical"
6. **Notification Channels**: Select both email and Slack channels
7. **Save**: Click "Save"

## Step 4: Verify Monitoring

### 4.1 Check Log Ingestion
1. **Go to Logs**: Click "Logs" in left sidebar
2. **Apply Filter**: Enter `attributes.dataset = "disk-monitor"`
3. **Verify Data**: Should see recent disk usage entries
4. **Check Fields**: Verify these fields are present:
   - `attributes.drive`
   - `attributes.percent_used`
   - `attributes.status`
   - `attributes.free_gb`

### 4.2 Test Alert Conditions
```powershell
# Generate a test warning condition (if disk is below 80%)
pwsh -File scripts/monitor-disk-usage.ps1 -WarningPercent 60 -CriticalPercent 70

# Check if warning appears in SigNoz logs
# Filter: attributes.dataset = "disk-monitor" AND attributes.status = "warning"
```

### 4.3 Verify Dashboard Data
1. **Open Dashboard**: Go to your "Disk Usage Monitoring" dashboard
2. **Check Panels**: Verify all panels show current data
3. **Refresh**: Click refresh to ensure real-time updates
4. **Time Range**: Adjust time ranges to see historical data

## Troubleshooting

### No Logs Appearing in SigNoz
1. **Check OTel Collector**: Verify collector is running and configured
2. **Check File Paths**: Ensure `C:/logs/disk-monitor/` is being monitored
3. **Check Collector Config**: Verify filelog receiver includes disk-monitor path

### Alerts Not Triggering
1. **Check Query Syntax**: Verify alert queries match log format
2. **Check Time Ranges**: Ensure evaluation windows are appropriate
3. **Check Thresholds**: Verify threshold values are correct

### Dashboard Panels Empty
1. **Check Time Range**: Ensure panels have appropriate time ranges
2. **Check Query Syntax**: Verify panel queries are correct
3. **Check Data Availability**: Ensure logs are being ingested

## Quick Verification Commands

```powershell
# Check if monitoring is running
Get-ScheduledTask -TaskName 'DiskUsageMonitor'

# Run manual check
pwsh -File scripts/monitor-disk-usage.ps1

# Check recent logs
Get-Content C:/logs/disk-monitor/disk-usage.log -Tail 5

# Check event logs
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'DiskUsageMonitor' } -MaxEvents 3
```

## Next Steps

1. **Monitor Dashboard**: Check dashboard regularly for disk usage trends
2. **Tune Thresholds**: Adjust warning/critical thresholds based on your needs
3. **Add More Drives**: Extend monitoring to additional drives if needed
4. **Set Up Cleanup**: Enable auto-cleanup for critical thresholds if desired

## Support

For issues with this setup:
1. Check the main [DISK_MONITORING_GUIDE.md](DISK_MONITORING_GUIDE.md)
2. Review [QUERY_RECIPES.md](QUERY_RECIPES.md) for additional queries
3. Check SigNoz documentation for UI-specific issues
