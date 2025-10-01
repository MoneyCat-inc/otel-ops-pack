# SigNoz "No Data" Troubleshooting Guide

**Issue**: Query syntax is correct but returning "no data" in SigNoz

## 🔍 **Step-by-Step Troubleshooting**

### Step 1: Verify Log Files Exist ✅
```powershell
# Check if canary logs exist
Get-ChildItem C:\logs\ | Where-Object { $_.Name -like "*canary*" }

# View recent canary log content
Get-Content C:\logs\windows-canary-test.log -TotalCount 3
```

**Status**: ✅ Log files exist and contain data

### Step 2: Check Log Content Format
The logs are in JSON format:
```json
{"message":"windows-canary test log entry 0","test_id":"canary-alert-test","timestamp":"2025-09-27T06:31:39.542Z","canary":"true","level":"INFO","service":"canary-test"}
```

### Step 3: Test Different Query Variations

Try these queries in SigNoz UI (Logs → Explore) one by one:

#### Query 1: Simple Message Search
```
body contains "windows-canary"
```

#### Query 2: File Path Search
```
log.file.path contains "windows-canary-test.log"
```

#### Query 3: Combined Search
```
body contains "windows-canary" AND log.file.path contains "windows-canary-test.log"
```

#### Query 4: Service Field Search
```
service = "canary-test"
```

#### Query 5: Test ID Search
```
test_id = "canary-alert-test"
```

#### Query 6: Level Search
```
level = "INFO"
```

### Step 4: Check Time Range
1. In SigNoz UI, set time range to **"Last 24 hours"**
2. Or set custom range to include the log generation time (22:33 today)

### Step 5: Check Field Names
1. Go to **Logs → Explore**
2. Click on any log entry
3. Expand the fields to see the exact field names
4. Use the exact field names in your query

### Step 6: Verify Log Ingestion
The issue might be that logs aren't being ingested into SigNoz. Check:

#### OTel Collector Status
```powershell
# Check if OTel collector service is running
sc query otelcol-contrib
```

#### SigNoz Health
```powershell
# Check SigNoz health
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
```

## 🚨 **Common Causes of "No Data"**

### 1. Log Ingestion Issue
- **Cause**: OTel collector not running or not configured to read `C:\logs`
- **Solution**: Start OTel collector service or check configuration

### 2. Wrong Field Names
- **Cause**: Using incorrect field names in query
- **Solution**: Use SigNoz field explorer to find correct field names

### 3. Time Range Issue
- **Cause**: Querying outside the time range when logs exist
- **Solution**: Expand time range to "Last 24 hours" or more

### 4. File Path Mismatch
- **Cause**: Actual file path in logs doesn't match query
- **Solution**: Check actual file path in log entries

### 5. Log Format Issue
- **Cause**: Logs not in expected format for SigNoz
- **Solution**: Check log format and adjust query accordingly

## 🔧 **Quick Fixes to Try**

### Fix 1: Generate Fresh Logs and Test
```powershell
# Generate fresh canary logs
pwsh -File scripts/generate-windows-canary.ps1 -DurationMinutes 1 -IntervalSeconds 15

# Wait 2-3 minutes for ingestion
Start-Sleep -Seconds 180

# Test query in SigNoz UI
```

### Fix 2: Use Broader Query
```
body contains "canary"
```

### Fix 3: Check All Logs
```
service exists
```

### Fix 4: Test with Timestamp
```
timestamp >= "2025-10-01T22:30:00Z"
```

## 📊 **Expected Field Structure**

Based on the log format, these fields should be available:
- `body` - Contains the full log message
- `message` - The log message content
- `timestamp` - Log timestamp
- `level` - Log level (INFO)
- `service` - Service name (canary-test)
- `test_id` - Test identifier
- `canary` - Canary flag (true)
- `log.file.path` - File path (if configured)

## 🎯 **Recommended Query for Alert**

Based on the log structure, use this query:

```
service = "canary-test" AND body contains "windows-canary"
```

Or this more specific one:
```
test_id = "canary-alert-test" AND level = "INFO"
```

## 📋 **Testing Checklist**

- [ ] Log files exist in `C:\logs\`
- [ ] Log content is in JSON format
- [ ] Time range includes log generation time
- [ ] OTel collector is running
- [ ] SigNoz is healthy and accessible
- [ ] Query uses correct field names
- [ ] Query syntax is valid (no single quotes, no SQL aggregations)

## 🚀 **Next Steps**

1. **Test each query variation** above in SigNoz UI
2. **Check time range** - use "Last 24 hours"
3. **Use field explorer** to find exact field names
4. **Verify log ingestion** by checking OTel collector status
5. **Generate fresh logs** if needed and wait for ingestion

## 📞 **If Still No Data**

Run this diagnostic script:
```powershell
pwsh -File scripts/diagnose-signoz-ingestion.ps1
```

This will check:
- Log file existence and content
- OTel collector status
- SigNoz health
- Sample queries with different field names

---
*Generated to troubleshoot SigNoz "no data" issues*
