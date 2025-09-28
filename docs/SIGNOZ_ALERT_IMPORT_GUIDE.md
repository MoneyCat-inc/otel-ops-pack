# SigNoz Alert Import Guide

## Manual Import Method (Recommended for Local Development)

Since the API token authentication is not working for the local SigNoz instance, use the manual import method:

### Step 1: Access SigNoz UI
1. Open your browser and go to: http://localhost:8080
2. Log in to your SigNoz instance

### Step 2: Navigate to Alerts
1. Click on "Alerts" in the left sidebar
2. Click "Create Alert" or "New Alert"

### Step 3: Configure Main Alert
Use the following settings for the **Windows Canary Log Absence** alert:

**Basic Settings:**
- **Name**: `Windows Canary Log Absence`
- **Description**: `Alert when Windows canary logs stop appearing for more than 5 minutes`
- **Severity**: `Critical`

**Query Configuration:**
- **Query Type**: `Logs`
- **Query**: 
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats count() as log_count by bin(1m)
```
- **Group By**: `log.file.path`
- **Legend Format**: `{{log.file.path}}`

**Alert Conditions:**
- **Threshold**: `1`
- **Operator**: `Below`
- **Evaluation Window**: `5m`
- **Alert Frequency**: `1m`
- **Notification on Missing Data**: `Enabled`
- **Minimum Data Points**: `1`

**Labels:**
- `alert_type`: `canary`
- `service`: `windows-logs`
- `environment`: `local`

**Annotations:**
- **Summary**: `Windows canary logs have stopped appearing`
- **Description**: `No Windows canary logs detected for 5 minutes. This indicates potential issues with Windows log collection or processing.`

### Step 4: Configure Test Alert
Repeat the process for the **Windows Canary Test Alert**:

**Basic Settings:**
- **Name**: `Windows Canary Test Alert`
- **Description**: `Test alert for Windows canary log absence detection`
- **Severity**: `Warning`

**Query Configuration:**
- **Query Type**: `Logs`
- **Query**: 
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats count() as log_count by bin(1m)
```

**Alert Conditions:**
- **Threshold**: `1`
- **Operator**: `Below`
- **Evaluation Window**: `2m`
- **Alert Frequency**: `1m`

**Labels:**
- `alert_type`: `canary_test`
- `service`: `windows-logs`
- `environment`: `local-test`

### Step 5: Create Dashboard Panels

Navigate to **Dashboards** and create a new dashboard called "Windows Canary Log Health":

**Panel 1: Canary Log Count**
- **Title**: `Canary Log Count (Last Hour)`
- **Type**: `Stat`
- **Query**: 
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats count()
```
- **Thresholds**: Warning: 10, Critical: 5

**Panel 2: Canary Log Rate**
- **Title**: `Canary Log Rate (per minute)`
- **Type**: `Line`
- **Query**: 
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats count() by bin(1m)
```

**Panel 3: Last Timestamp**
- **Title**: `Last Canary Log Timestamp`
- **Type**: `Stat`
- **Query**: 
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats latest(@timestamp)
```

### Step 6: Verify Setup

1. **Check Log Ingestion**: Go to **Logs** → Apply filter: `log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'`
2. **Verify Alerts**: Go to **Alerts** → Check that both alerts are active
3. **Test Dashboard**: Go to **Dashboards** → Open "Windows Canary Log Health"

## Alternative: Session Cookie Method

If you prefer API automation, you can extract session cookies from your browser:

1. Open browser dev tools (F12)
2. Go to Application/Storage → Cookies → http://localhost:8080
3. Find the session cookie (usually named `session` or similar)
4. Use it in API calls instead of Bearer token

## Troubleshooting

- **No logs visible**: Ensure the OpenTelemetry collector is running and canary logs are being generated
- **Alerts not triggering**: Check that the query syntax is correct and logs are being ingested
- **Dashboard empty**: Verify the time range and query filters

## Next Steps

1. Set up notification channels (email, Slack, etc.)
2. Test alert triggering by stopping canary generation
3. Monitor alert status and fine-tune thresholds
4. Consider setting up alert rules for production use