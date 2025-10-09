# SigNoz Logs Query Reference Card

## Quick Access URLs
- **SigNoz UI**: http://localhost:8080
- **Logs Explorer**: http://localhost:8080/logs
- **Health Check**: http://localhost:8080/api/v1/health

## Essential Filters for Windows Collector

### Primary Monitoring Query
```
service.name = "windows-host"
```
*Use this to see all logs from the Windows collector*

### Canary Test Detection
```
message contains "SigNoz test from hardened collector"
```
*Use this to find specific test entries*

### File Log Monitoring
```
log.file.path contains "C:/logs/test.log"
```
*Use this to monitor specific log files*

### Error Detection
```
service.name = "windows-host" AND level = "ERROR"
```
*Use this to find errors from Windows collector*

### Recent Activity (Last 15 minutes)
```
service.name = "windows-host" AND timestamp > now() - 15m
```
*Use this to see recent activity*

## Saved Query Names (Recommended)

1. **"Windows Collector - All Logs"**
   - Query: `service.name = "windows-host"`
   - Purpose: General monitoring

2. **"Windows Collector - Canary Tests"**
   - Query: `message contains "SigNoz test from hardened collector"`
   - Purpose: Health check verification

3. **"Windows Collector - Errors"**
   - Query: `service.name = "windows-host" AND level = "ERROR"`
   - Purpose: Error monitoring

4. **"Windows Collector - Recent Activity"**
   - Query: `service.name = "windows-host" AND timestamp > now() - 15m`
   - Purpose: Real-time monitoring

## Alert Conditions

### Ingestion Down Alert
- **Query**: `service.name = "windows-host"`
- **Condition**: No logs received in last 5 minutes
- **Severity**: Warning
- **Action**: Send notification

### Error Rate Alert
- **Query**: `service.name = "windows-host" AND level = "ERROR"`
- **Condition**: Error count > 10 in last 10 minutes
- **Severity**: Critical
- **Action**: Immediate notification

## Dashboard Panels

### Log Volume Over Time
- **Query**: `service.name = "windows-host"`
- **Visualization**: Line chart
- **Time Range**: Last 24 hours
- **Group By**: timestamp (1 hour buckets)

### Error Rate Trend
- **Query**: `service.name = "windows-host" AND level = "ERROR"`
- **Visualization**: Bar chart
- **Time Range**: Last 7 days
- **Group By**: timestamp (1 day buckets)

### Top Log Sources
- **Query**: `service.name = "windows-host"`
- **Visualization**: Pie chart
- **Group By**: log.file.path
- **Limit**: Top 10

## Troubleshooting Queries

### Check Collector Health
```
service.name = "windows-host" AND message contains "health"
```

### Monitor File Ingestion
```
log.file.path contains "C:/logs/" AND service.name = "windows-host"
```

### Check for Configuration Issues
```
service.name = "windows-host" AND message contains "config"
```

### Monitor Batch Processing
```
service.name = "windows-host" AND message contains "batch"
```

## PowerShell Commands for Testing

### Generate New Canary
```powershell
pwsh -File scripts/signoz-canary-monitor.ps1 -GenerateCanary
```

### Check Recent Logs
```powershell
pwsh -File scripts/signoz-canary-monitor.ps1 -CheckRecent
```

### Verify SigNoz Connectivity
```powershell
pwsh -File scripts/signoz-canary-monitor.ps1 -VerifySigNoz
```

### Run Full Verification
```powershell
pwsh -File verify-collector.ps1
```

---

*Keep this reference handy for quick SigNoz log analysis and monitoring setup.*
