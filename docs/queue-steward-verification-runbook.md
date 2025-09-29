# Queue Steward Log Verification Runbook

## Task
Confirm queue logs emit service.name=queue-steward, log.source=win-filelog

## Success Criteria
- ClickHouse query shows `service_name = "queue-steward"` and `log_source = "win-filelog"`
- SigNoz UI filters show entries with all three attributes: `dataset = "agent_queue"` AND `log.source = "win-filelog"` AND `service.name = "queue-steward"`

## Prerequisites
- Configuration updated in `config.yaml` (lines 32-37, 66-70, 118-122)
- Elevated PowerShell access required for service restart

## Execution Steps

### 1. Restart Windows Collector Service

**Open PowerShell as Administrator** and run:

```powershell
# Stop the service forcefully
Stop-Service -Name otelcol-contrib -Force

# Wait for complete shutdown
Start-Sleep -Seconds 3

# Start the service with new config
Start-Service -Name otelcol-contrib

# Verify service is running
Get-Service otelcol-contrib
```

**Expected Output**:
```
Status   Name               DisplayName
------   ----               -----------
Running  otelcol-contrib    OpenTelemetry Collector
```

### 2. Emit Canary Test

```powershell
# Navigate to project directory
Set-Location 'C:/otel'

# Generate fresh log entry
canary
```

**Expected Output**:
```
OK delta observed. before=XXXX after=XXXX token=XXXXXXXXX via=http://127.0.0.1:8888/metrics
```

**Record Canary Token**: `[PASTE TOKEN HERE]`

### 3. Verify ClickHouse Results

```powershell
# Query ClickHouse for latest queue logs
docker exec signoz-clickhouse clickhouse-client --query "SELECT toDateTime(timestamp/1000000000) AS ts, resources_string['service.name'] AS service_name, attributes_string['log.source'] AS log_source FROM signoz_logs.logs_v2 WHERE attributes_string['dataset'] = 'agent_queue' ORDER BY timestamp DESC LIMIT 5"
```

**Expected Output** (after restart):
```
2025-09-29 21:XX:XX	queue-steward	win-filelog
2025-09-29 21:XX:XX	queue-steward	win-filelog
2025-09-29 21:XX:XX	queue-steward	win-filelog
```

**Record ClickHouse Output**: `[PASTE ACTUAL OUTPUT HERE]`

### 4. Verify SigNoz UI

1. **Navigate to SigNoz**: http://localhost:8080 → Logs
2. **Add Filters**:
   - `dataset = agent_queue`
   - `log.source = win-filelog`
   - `service.name = queue-steward`
3. **Set Time Range**: Last 1 hour
4. **Run Query**

**Expected Result**: Visible log entries with all three attributes

**Record SigNoz Results**: `[DESCRIBE SCREENSHOT/RESULTS HERE]`

## Troubleshooting

### If service_name still shows "windows-logs"
- Verify service restart completed successfully
- Check if config.yaml changes are saved
- Ensure no syntax errors in config.yaml
- Try restarting again with elevated privileges

### If no logs appear in SigNoz
- Check if canary was emitted successfully
- Verify SigNoz collector is running: `docker ps | findstr signoz`
- Check SigNoz collector logs: `docker logs signoz-otel-collector`

### If ClickHouse query fails
- Verify SigNoz containers are running
- Check ClickHouse connectivity: `docker exec signoz-clickhouse clickhouse-client --query "SELECT 1"`

## Success Confirmation

✅ **Service Restarted**: `Get-Service otelcol-contrib` shows `Status = Running`  
✅ **Canary Emitted**: Token generated successfully  
✅ **ClickHouse Verified**: Rows show `service_name = queue-steward`  
✅ **SigNoz Verified**: UI shows entries with all three filters applied  

## Next Steps

1. Complete the verification steps above
2. Populate the ECRR evidence template
3. Add evidence to `docs/ECRR_QUALITY_DASHBOARD.md`
4. Update any relevant documentation with the new attribute structure
