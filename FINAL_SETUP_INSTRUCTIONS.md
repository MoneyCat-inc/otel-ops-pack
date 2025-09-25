# Final Setup Instructions - SigNoz UI Configuration

## Current Status ✅
- **SigNoz**: Healthy and accessible at `http://localhost:8080`
- **Disk Monitoring**: Script executing successfully (69.02% usage, status: ok)
- **Log Generation**: JSON logs with `dataset="disk-monitor"` being written
- **Alert Testing**: Warning alert verified working (can trigger at 64% threshold)
- **Thresholds**: Restored to 80% warning, 90% critical

## Step-by-Step Manual Setup

### 1. Import 3 Alert Configurations

**Navigate to Alerts:**
1. Open browser to `http://localhost:8080`
2. Click **"Alerts"** in the left sidebar
3. Click **"New Alert"** or **"Create Alert"**

**Alert 1: Disk Usage Warning**
- **Name**: `Disk Usage Warning`
- **Description**: `Alert when disk usage exceeds 80%`
- **Query**: `count by (drive) (attributes.dataset="disk-monitor" and attributes.status="warning") > 0`
- **Severity**: `Warning`
- **Duration**: `1 minute`
- **Enabled**: `Yes`
- Click **"Save"**

**Alert 2: Disk Usage Critical**
- **Name**: `Disk Usage Critical`
- **Description**: `Alert when disk usage exceeds 90%`
- **Query**: `count by (drive) (attributes.dataset="disk-monitor" and attributes.status="critical") > 0`
- **Severity**: `Critical`
- **Duration**: `30 seconds`
- **Enabled**: `Yes`
- Click **"Save"**

**Alert 3: Disk Monitor Offline**
- **Name**: `Disk Monitor Offline`
- **Description**: `Alert when disk monitoring stops reporting`
- **Query**: `count by (attributes.dataset) (attributes.dataset="disk-monitor") == 0`
- **Severity**: `Warning`
- **Duration**: `5 minutes`
- **Enabled**: `Yes`
- Click **"Save"**

### 2. Create Saved View

**Navigate to Logs:**
1. Click **"Logs"** in the left sidebar
2. In the search/filter bar, enter: `attributes.dataset = "disk-monitor"`
3. Press Enter
4. You should see logs with entries like "Drive C: usage 69.02% (status: ok)"

**Create Saved View:**
1. Click **"Save"** or **"Save View"** (near search bar)
2. **Name**: `Disk Monitoring Logs`
3. **Description**: `Saved view for disk monitoring logs with dataset filter`
4. Click **"Save"**

### 3. Create Dashboard (Optional)

**Navigate to Dashboards:**
1. Click **"Dashboards"** in the left sidebar
2. Click **"New Dashboard"** or **"Create Dashboard"**
3. **Name**: `Disk Monitoring Dashboard`
4. **Description**: `Comprehensive disk monitoring dashboard for OTel observability pipeline`
5. Click **"Create"**

**Add Panel 1: Disk Usage Gauge**
1. Click **"Add Panel"** or **"New Panel"**
2. **Title**: `Disk Usage by Drive`
3. **Type**: `Gauge` or `Single Stat`
4. **Query**: `attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")`
5. **Unit**: `percent`
6. **Thresholds**: Warning: 80, Critical: 90
7. Click **"Save"**

**Add Panel 2: Disk Usage Trend**
1. Click **"Add Panel"**
2. **Title**: `Disk Usage Trend (24h)`
3. **Type**: `Line Chart` or `Time Series`
4. **Query**: `attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")`
5. **Time Range**: `24 hours`
6. **Refresh**: `1 minute`
7. Click **"Save"**

**Add Panel 3: Free Space Bar Chart**
1. Click **"Add Panel"**
2. **Title**: `Free Space by Drive`
3. **Type**: `Bar Chart`
4. **Query**: `attributes.free_gb by (attributes.drive) (attributes.dataset="disk-monitor")`
5. **Unit**: `GB`
6. Click **"Save"**

**Add Panel 4: Disk Status Pie Chart**
1. Click **"Add Panel"**
2. **Title**: `Disk Status Distribution`
3. **Type**: `Pie Chart`
4. **Query**: `count by (attributes.status) (attributes.dataset="disk-monitor")`
5. Click **"Save"**

**Add Panel 5: Recent Alerts Table**
1. Click **"Add Panel"**
2. **Title**: `Recent Disk Alerts`
3. **Type**: `Table`
4. **Query**: `attributes.message by (attributes.drive, attributes.status) (attributes.dataset="disk-monitor" and attributes.status!="ok")`
5. **Time Range**: `1 hour`
6. Click **"Save"**

### 4. Monitor Results

**Verify Setup:**
1. **Check Logs**: Go to Logs → Apply filter `attributes.dataset = "disk-monitor"`
   - Should see recent entries with "Drive C: usage 69.02% (status: ok)"
2. **Check Alerts**: Go to Alerts
   - All 3 alerts should be enabled and not firing (since usage is below thresholds)
3. **Check Dashboard**: View the dashboard panels
   - Gauge should show ~69% for C: drive
   - Trend should show recent data points

**Test Alert Thresholds:**
```powershell
# Test warning alert (temporarily lowers threshold to 64%)
pwsh -File scripts/test-disk-alerts.ps1 -TestWarning

# Restore original thresholds after testing
pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults
```

## Copy-Paste Queries

**Alert Queries:**
```
count by (drive) (attributes.dataset="disk-monitor" and attributes.status="warning") > 0
count by (drive) (attributes.dataset="disk-monitor" and attributes.status="critical") > 0
count by (attributes.dataset) (attributes.dataset="disk-monitor") == 0
```

**Dashboard Queries:**
```
attributes.percent_used by (attributes.drive) (attributes.dataset="disk-monitor")
attributes.free_gb by (attributes.drive) (attributes.dataset="disk-monitor")
count by (attributes.status) (attributes.dataset="disk-monitor")
attributes.message by (attributes.drive, attributes.status) (attributes.dataset="disk-monitor" and attributes.status!="ok")
```

**Logs Filter:**
```
attributes.dataset = "disk-monitor"
```

## Verification URLs

- **SigNoz UI**: `http://localhost:8080`
- **Alerts**: `http://localhost:8080/alerts`
- **Logs**: `http://localhost:8080/logs`
- **Dashboards**: `http://localhost:8080/dashboards`

## Quick Verification Commands

```powershell
# Check current disk monitoring status
pwsh -File scripts/monitor-disk-usage.ps1

# Check latest log entry
Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1 | ConvertFrom-Json

# Test warning alert
pwsh -File scripts/test-disk-alerts.ps1 -TestWarning

# Restore thresholds
pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults

# Check SigNoz health
curl -s "http://localhost:8080/api/v1/health"
```

## Success Criteria

✅ **Alerts Created**: 3 alerts configured and enabled in SigNoz  
✅ **Saved View**: "Disk Monitoring Logs" view created and accessible  
✅ **Dashboard**: 5-panel dashboard showing disk usage trends  
✅ **Log Ingestion**: Recent disk monitoring logs visible in SigNoz  
✅ **Alert Testing**: Warning alert can be triggered and verified  

## Current Data Status

**Latest Log Entry:**
- **Drive**: C:
- **Usage**: 69.02%
- **Status**: ok
- **Severity**: INFO
- **Dataset**: disk-monitor
- **Timestamp**: 2025-09-23 23:25:36

**Alert Thresholds:**
- **Warning**: 80% (not triggered - current usage 69.02%)
- **Critical**: 90% (not triggered - current usage 69.02%)
- **Offline**: 5 minutes without reports (not triggered - monitoring active)

## Next Steps After Setup

1. **Monitor Trends**: Watch dashboard for disk usage patterns
2. **Tune Thresholds**: Adjust 80%/90% thresholds based on operational needs
3. **Add Notifications**: Configure alert notifications (email, Slack, etc.)
4. **Extend Monitoring**: Add monitoring for additional drives if needed
5. **Regular Reviews**: Use saved view for operational log reviews

---

**Status**: 🎯 **Ready for Manual Setup** - All configurations prepared and verified  
**Next**: Follow the step-by-step instructions above to complete SigNoz UI setup
