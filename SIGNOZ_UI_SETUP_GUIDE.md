# SigNoz UI Setup Guide - Disk Monitoring

## Overview
Complete step-by-step guide for setting up disk monitoring alerts, saved view, and dashboard in SigNoz UI.

## Prerequisites
- SigNoz running at `http://localhost:8080`
- Disk monitoring script generating logs with `dataset="disk-monitor"`
- Current disk usage: 69.02% (status: ok)

---

## Step 1: Import 3 Alert Configurations

### Navigate to Alerts
1. Open browser to `http://localhost:8080`
2. Click **"Alerts"** in the left sidebar
3. Click **"New Alert"** or **"Create Alert"** button

### Alert 1: Disk Usage Warning

**Configuration:**
- **Name**: `Disk Usage Warning`
- **Description**: `Alert when disk usage exceeds 80%`
- **Query**: 
  ```
  count by (drive) (attributes.dataset="disk-monitor" and attributes.status="warning") > 0
  ```
- **Severity**: `Warning`
- **Duration**: `1 minute`
- **Enabled**: `Yes`

**Steps:**
1. Fill in the name and description
2. In the query field, paste the query above
3. Set severity to "Warning"
4. Set duration to "1 minute"
5. Enable the alert
6. Click **"Save"** or **"Create"**

### Alert 2: Disk Usage Critical

**Configuration:**
- **Name**: `Disk Usage Critical`
- **Description**: `Alert when disk usage exceeds 90%`
- **Query**: 
  ```
  count by (drive) (attributes.dataset="disk-monitor" and attributes.status="critical") > 0
  ```
- **Severity**: `Critical`
- **Duration**: `30 seconds`
- **Enabled**: `Yes`

**Steps:**
1. Click **"New Alert"** again
2. Fill in the name and description
3. Paste the query above
4. Set severity to "Critical"
5. Set duration to "30 seconds"
6. Enable the alert
7. Click **"Save"**

### Alert 3: Disk Monitor Offline

**Configuration:**
- **Name**: `Disk Monitor Offline`
- **Description**: `Alert when disk monitoring stops reporting`
- **Query**: 
  ```
  count by (attributes.dataset) (attributes.dataset="disk-monitor") == 0
  ```
- **Severity**: `Warning`
- **Duration**: `5 minutes`
- **Enabled**: `Yes`

**Steps:**
1. Click **"New Alert"** again
2. Fill in the name and description
3. Paste the query above
4. Set severity to "Warning"
5. Set duration to "5 minutes"
6. Enable the alert
7. Click **"Save"**

### Verification
- You should now see 3 alerts in the Alerts list
- All alerts should show as "Enabled"
- Check that the queries are correctly formatted

---

## Step 2: Create Saved View

### Navigate to Logs
1. Click **"Logs"** in the left sidebar
2. Wait for logs to load

### Apply Filter
1. In the search/filter bar at the top, enter:
   ```
   attributes.dataset = "disk-monitor"
   ```
2. Press Enter or click the search button
3. You should see disk monitoring logs with entries like "Drive C: usage 69.02% (status: ok)"

### Create Saved View
1. Look for a **"Save"** button or **"Save View"** option (usually near the search bar)
2. Click **"Save"** or **"Save View"**
3. Fill in the details:
   - **Name**: `Disk Monitoring Logs`
   - **Description**: `Saved view for disk monitoring logs with dataset filter`
4. Click **"Save"**

### Verification
- The saved view should appear in your saved views list
- You can access it quickly for future log reviews
- The filter should be pre-applied when you open the saved view

---

## Step 3: Create Dashboard (Optional)

### Navigate to Dashboards
1. Click **"Dashboards"** in the left sidebar
2. Click **"New Dashboard"** or **"Create Dashboard"**

### Dashboard Settings
1. **Name**: `Disk Monitoring Dashboard`
2. **Description**: `Comprehensive disk monitoring dashboard for OTel observability pipeline`
3. Click **"Create"** or **"Save"**

### Add Panel 1: Disk Usage Gauge
1. Click **"Add Panel"** or **"New Panel"**
2. **Title**: `Disk Usage by Drive`
3. **Type**: Select **"Gauge"** or **"Single Stat"**
4. **Query**: 
   ```
   attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")
   ```
5. **Unit**: `percent`
6. **Thresholds**: 
   - Warning: 80
   - Critical: 90
7. Click **"Save"** or **"Apply"**

### Add Panel 2: Disk Usage Trend
1. Click **"Add Panel"** again
2. **Title**: `Disk Usage Trend (24h)`
3. **Type**: Select **"Line Chart"** or **"Time Series"**
4. **Query**: 
   ```
   attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")
   ```
5. **Time Range**: `24 hours`
6. **Refresh**: `1 minute`
7. Click **"Save"**

### Add Panel 3: Free Space Bar Chart
1. Click **"Add Panel"** again
2. **Title**: `Free Space by Drive`
3. **Type**: Select **"Bar Chart"**
4. **Query**: 
   ```
   attributes.free_gb by (attributes.drive) (attributes.dataset="disk-monitor")
   ```
5. **Unit**: `GB`
6. Click **"Save"**

### Add Panel 4: Disk Status Pie Chart
1. Click **"Add Panel"** again
2. **Title**: `Disk Status Distribution`
3. **Type**: Select **"Pie Chart"**
4. **Query**: 
   ```
   count by (attributes.status) (attributes.dataset="disk-monitor")
   ```
5. Click **"Save"**

### Add Panel 5: Recent Alerts Table
1. Click **"Add Panel"** again
2. **Title**: `Recent Disk Alerts`
3. **Type**: Select **"Table"**
4. **Query**: 
   ```
   attributes.message by (attributes.drive, attributes.status, attributes.timestamp) (attributes.dataset="disk-monitor" and attributes.status!="ok")
   ```
5. **Time Range**: `1 hour`
6. Click **"Save"**

### Dashboard Layout
- Arrange panels as desired by dragging and resizing
- Set dashboard refresh interval to `30 seconds`
- Save the dashboard when complete

---

## Step 4: Monitor Results

### Verify Current Status
1. **Check Logs**: Go to Logs → Apply filter `attributes.dataset = "disk-monitor"`
   - Should see recent entries with "Drive C: usage 69.02% (status: ok)"
2. **Check Alerts**: Go to Alerts
   - All 3 alerts should be enabled and not firing (since usage is below thresholds)
3. **Check Dashboard**: View the dashboard panels
   - Gauge should show ~69% for C: drive
   - Trend should show recent data points

### Test Alert Thresholds
You can test the alerts using the provided PowerShell script:

```powershell
# Test warning alert (temporarily lowers threshold)
pwsh -File scripts/test-disk-alerts.ps1 -TestWarning

# Restore original thresholds after testing
pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults
```

### Monitor for Real Alerts
- **Warning Alert**: Will trigger when disk usage reaches 80%
- **Critical Alert**: Will trigger when disk usage reaches 90%
- **Offline Alert**: Will trigger if disk monitoring stops for 5 minutes

### Dashboard Monitoring
- **Gauge Panel**: Shows current usage with color coding (green < 80%, yellow 80-90%, red > 90%)
- **Trend Panel**: Shows usage patterns over time
- **Status Panel**: Shows distribution of ok/warning/critical statuses
- **Alerts Panel**: Shows recent alerts and warnings

---

## Troubleshooting

### Common Issues

**1. No logs visible in SigNoz**
- Verify OTel collector is running: `sc query otelcol-contrib`
- Check log file exists: `Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1`
- Verify filelog receiver in `config.yaml` includes `C:/logs/**/*.log`

**2. Alerts not triggering**
- Check query syntax in SigNoz UI
- Verify alerts are enabled
- Test with temporary threshold modification

**3. Dashboard panels not showing data**
- Verify queries are correctly formatted
- Check time range settings
- Ensure logs are being generated

### Verification Commands
```powershell
# Check disk monitoring status
pwsh -File scripts/monitor-disk-usage.ps1

# Verify setup
pwsh -File scripts/verify-disk-alerts-setup.ps1

# Test alerts
pwsh -File scripts/test-disk-alerts.ps1 -TestWarning

# Check latest log entry
Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1 | ConvertFrom-Json
```

---

## Success Criteria

✅ **Alerts Created**: 3 alerts configured and enabled in SigNoz  
✅ **Saved View**: "Disk Monitoring Logs" view created and accessible  
✅ **Dashboard**: 5-panel dashboard showing disk usage trends  
✅ **Log Ingestion**: Recent disk monitoring logs visible in SigNoz  
✅ **Alert Testing**: Warning alert can be triggered and verified  

## Next Steps

1. **Monitor Trends**: Watch dashboard for disk usage patterns
2. **Tune Thresholds**: Adjust 80%/90% thresholds based on operational needs
3. **Add Notifications**: Configure alert notifications (email, Slack, etc.)
4. **Extend Monitoring**: Add monitoring for additional drives if needed
5. **Regular Reviews**: Use saved view for operational log reviews
