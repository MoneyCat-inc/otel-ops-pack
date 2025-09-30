# SigNoz Dashboard Troubleshooting Guide

## Data Type: LOGS (not metrics)
The panels should display **log data** from queue telemetry, specifically:
- **Source**: `C:/logs/queue/health.log` (JSON lines)
- **Content**: Agent queue metrics (queueLength=14, readyCount=14, killSwitch=false)
- **Format**: JSON logs with dataset="agent_queue"

## Troubleshooting Steps

### 1. Check Time Range
- **Current**: Dashboard shows "Last 30 minutes" 
- **Try**: Expand to "Last 7 days" or "Last 24 hours"
- **Reason**: Logs might be older than expected

### 2. Verify Log Ingestion
Go to **SigNoz → Logs → Explorer** and test these filters:

```sql
-- Test 1: Look for any queue logs
body contains "agent_queue"

-- Test 2: Look for specific file path
attributes_string['log.file.path'] contains "queue"

-- Test 3: Look for dataset field
body contains "dataset\":\"agent_queue\""
```

### 3. Check Data Availability
If no logs appear in Explorer:
- **Issue**: Logs not being ingested by SigNoz
- **Cause**: Collector not processing `C:/logs/queue/health.log`
- **Fix**: Verify collector configuration

### 4. Panel Query Issues
The dashboard queries use:
- **Table**: `signoz_logs.logs_v2`
- **Field**: `body` (contains JSON)
- **Filter**: `body LIKE '%"dataset":"agent_queue"%'`

### 5. Quick Test
Create a simple test panel manually:
1. **Add Panel** → **Logs**
2. **Query**: `body contains "agent_queue"`
3. **Time Range**: Last 24 hours
4. **Expected**: Should show queue telemetry entries

## Expected Results
If working correctly, you should see:
- **Queue Depth**: ~14
- **Ready Count**: 14
- **Pending Count**: 0
- **Kill Switch**: false
- **Agent Name**: cursor-agent-observability-copilot

## Next Steps
1. **Test Logs Explorer** first to confirm data ingestion
2. **Expand time range** to "Last 7 days"
3. **Create simple test panel** to verify basic functionality
4. **Check collector logs** if no data appears


