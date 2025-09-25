# SigNoz Alert Import Instructions - Windows Logs Canary

## Manual Import Steps

### Step 1: Access SigNoz UI
1. Open browser and navigate to: **http://localhost:8080**
2. Ensure you're logged in (if authentication is enabled)

### Step 2: Create New Alert
1. Click on **"Alerts"** in the left sidebar
2. Click **"Create Alert"** button
3. Select **"Logs"** as the alert type

### Step 3: Configure Alert Details

#### Basic Information
- **Alert Name**: `Windows Logs Canary Missing (1 Hour)`
- **Description**: `Alert when Windows Event Log canaries are missing for more than 1 hour, indicating potential ingestion pipeline issues`
- **Severity**: `Warning`
- **Labels**:
  - `component: windows-logs`
  - `canary: true`
  - `alert_type: ingestion`
  - `duration: 1h`

#### Query Configuration
**Query Type**: Logs Query

**Query**:
```sql
SELECT count() as value 
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 1 HOUR
```

#### Condition Settings
- **Condition**: `Below`
- **Threshold**: `1`
- **Duration**: `60m` (60 minutes)
- **Evaluation Interval**: `5m` (5 minutes)

#### Runbook (Optional)
- **Description**: `Windows logs canary missing for 1 hour - check ingestion pipeline`
- **URL**: `http://localhost:8080/logs?query=attributes_string['dataset']%20%3D%20'windows'%20AND%20body%20LIKE%20'%25windows-logs-canary%25'`

### Step 4: Test the Alert
1. Click **"Test Alert"** to verify the query works
2. Ensure the query returns a count value
3. If test fails, verify SigNoz has Windows logs data

### Step 5: Save Alert
1. Click **"Save Alert"**
2. Verify the alert appears in the alerts list
3. Check that the alert is in "Active" status

## Verification Steps

### 1. Check Alert Status
- Navigate to **Alerts** → **Alert Rules**
- Find "Windows Logs Canary Missing (1 Hour)"
- Verify status is "Active"

### 2. Test Canary Generation
```powershell
# Generate test canaries
.\scripts\windows-logs-canary-test.ps1 -Count 3

# Wait 1-2 minutes, then check SigNoz logs
# Filter: attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%'
```

### 3. Verify Alert Behavior
- Generate canaries → Alert should NOT trigger
- Wait 1+ hours without canaries → Alert should trigger
- Check alert history for any false positives

## Troubleshooting

### Query Issues
If the query fails:
1. Check SigNoz logs for syntax errors
2. Verify attribute names match ClickHouse schema
3. Test with simpler query first:
   ```sql
   SELECT count() FROM logs WHERE body LIKE '%windows-logs-canary%'
   ```

### No Data Found
If no Windows logs are found:
1. Check if Windows Event Logs are being ingested
2. Verify collector configuration
3. Run canary test script to generate sample data

### Alert Not Triggering
1. Check alert evaluation interval (should be 5m or less)
2. Verify threshold and duration settings
3. Check alert notification channels are configured

## Expected Behavior

### Normal Operation
- Alert status: "Active"
- No alerts triggered when canaries are present
- Query returns count > 0 when canaries exist

### Alert Triggered
- Alert fires after 60 minutes of no canaries
- Notification sent to configured channels
- Alert appears in alert history

## Next Steps After Import
1. Configure notification channels (email, Slack, etc.)
2. Set up automated canary generation
3. Add canary status to monitoring dashboards
4. Test alert escalation procedures
