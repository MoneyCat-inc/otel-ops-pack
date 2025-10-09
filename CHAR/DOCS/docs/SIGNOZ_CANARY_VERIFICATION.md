# SigNoz Canary Verification Guide

## Quick Verification Steps

### 1. Open SigNoz UI
- Navigate to: `http://localhost:8080`
- Login if required (default: admin@signoz.io / admin)

### 2. Access Logs Explorer
- Click **"Logs"** in the left sidebar
- Select **"Logs Explorer"** tab

### 3. Apply Filters to Find Canary Record

#### Primary Filter (Recommended):
```
service.name = "windows-host"
```

#### Secondary Filter (More Specific):
```
message contains "SigNoz test from hardened collector"
```

#### Alternative Filter (File Path):
```
log.file.path contains "C:/logs/test.log"
```

### 4. Expected Results
You should see log entries with:
- **Timestamp**: Recent (within last few minutes)
- **Level**: INFO
- **Message**: "SigNoz test from hardened collector"
- **Service**: windows-host
- **File Path**: C:/logs/test.log

## Monitoring Setup

### Create Saved Query
1. In Logs Explorer, apply your desired filter
2. Click **"Save Query"** button
3. Name it: `Windows Collector Canary Test`
4. Description: `Monitor Windows collector log ingestion health`

### Set Up Alert (Optional)
1. Go to **"Alerts"** section
2. Click **"New Alert"**
3. Configure:
   - **Name**: `Windows Collector Ingestion Down`
   - **Query**: `service.name = "windows-host"`
   - **Condition**: `No logs received in last 5 minutes`
   - **Severity**: Warning
   - **Notification**: Email/Slack (configure as needed)

### Dashboard Panel
1. Go to **"Dashboards"**
2. Create new panel or add to existing dashboard
3. **Query**: `service.name = "windows-host"`
4. **Visualization**: Logs table or count over time
5. **Title**: `Windows Collector Logs`

## Troubleshooting

### If Canary Not Visible:
1. **Check collector status**:
   ```powershell
   pwsh -File verify-collector.ps1
   ```

2. **Verify log file exists**:
   ```powershell
   Get-Content 'C:\logs\test.log' -Tail 5
   ```

3. **Check SigNoz collector logs**:
   ```powershell
   docker logs signoz-otel-collector --tail 20
   ```

4. **Restart collector if needed**:
   ```powershell
   Restart-Service -Name otelcol-contrib
   ```

### Common Issues:
- **Port conflicts**: Ensure 14317/14318 are not blocked
- **File permissions**: Check C:\logs directory is accessible
- **Collector config**: Verify config.yaml has correct SigNoz endpoints
- **Timing**: Allow 30-60 seconds for log ingestion

## Verification Commands

### Generate New Canary:
```powershell
$timestamp = (Get-Date).ToUniversalTime().ToString('o')
$payload = [ordered]@{
    timestamp = $timestamp
    level     = 'INFO'
    message   = 'SigNoz test from hardened collector'
    service   = 'windows-host'
}
$json = $payload | ConvertTo-Json -Compress
Add-Content -Path 'C:\logs\test.log' -Value $json
```

### Check Recent Logs:
```powershell
Get-Content 'C:\logs\test.log' -Tail 3
```

### Verify SigNoz Health:
```powershell
Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health'
```

## Success Criteria

✅ **Canary visible in SigNoz Logs** with correct filters  
✅ **Timestamp is recent** (within last 5 minutes)  
✅ **All expected fields present** (service, message, level)  
✅ **File path shows** C:/logs/test.log  
✅ **No ingestion errors** in collector logs  

## Next Steps

1. **Verify canary appears** in SigNoz UI using filters above
2. **Save useful queries** for ongoing monitoring
3. **Set up alerts** if automated monitoring is needed
4. **Create dashboard panels** for visual monitoring
5. **Test regularly** with new canary entries to ensure pipeline health

---

*Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
