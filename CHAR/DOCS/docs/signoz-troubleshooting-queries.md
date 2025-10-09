# Test Query for SigNoz Logs

## Simple Test Query
Try this query in SigNoz Logs Explorer to see what fields are available:

```sql
SELECT * FROM signoz_logs.logs_v2 
WHERE attributes_string['log.file.path'] LIKE '%queue%' 
LIMIT 5
```

## Alternative Field Tests
If the above doesn't work, try these variations:

```sql
-- Test 1: Look for any queue-related logs
SELECT * FROM signoz_logs.logs_v2 
WHERE body LIKE '%agent_queue%' 
LIMIT 5

-- Test 2: Check all available fields
SELECT * FROM signoz_logs.logs_v2 
LIMIT 1

-- Test 3: Look for specific attributes
SELECT * FROM signoz_logs.logs_v2 
WHERE attributes_string['log.file.path'] LIKE '%health.log%' 
LIMIT 5
```

## Expected Results
If logs are being ingested, you should see:
- `body` field containing the JSON telemetry data
- `attributes_string['log.file.path']` containing `C:/logs/queue/health.log`
- `timestamp` field with recent timestamps

## Troubleshooting Steps
1. **Check Logs Explorer**: Go to SigNoz → Logs → Explorer
2. **Apply Filter**: Try `body contains "agent_queue"`
3. **Check Time Range**: Set to "Last 1 hour"
4. **Verify Data**: Look for entries with queueLength=14, readyCount=14

## If No Data Found
The issue might be:
- Collector not processing the queue logs
- Wrong field names in queries
- Time range mismatch
- Authentication issues with SigNoz API


