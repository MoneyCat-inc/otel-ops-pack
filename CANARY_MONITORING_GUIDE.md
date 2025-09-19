# Health Canary Monitoring Guide

## Quick Status Check

### Task Scheduler Status
```powershell
# Check task status and last run result
.\monitor-canary-task.ps1

# Or manually check
Get-ScheduledTask -TaskName OTelHealthCanary | Get-ScheduledTaskInfo
```

**Expected Results:**
- State: `Ready`
- Last Result: `0x0` (Success)
- Missed Runs: `0`
- Next Run: ~5 minutes from last run

### SigNoz Logs Verification
**URL:** http://localhost:8080 → Logs

**Filter:** `service.name = 'windows-collector' AND canary_id contains 'health-check'`

**Expected:** Recent entries every 5 minutes with format `health-check-YYYYMMDD-HHMMSS`

## Alert Configuration

### Import Alert
1. Open SigNoz UI: http://localhost:8080
2. Navigate to: **Alerts → Create Alert**
3. Use configuration from: `signoz-health-canary-alert.json`

**Alert Details:**
- **Name:** Health Canary Missing
- **Query:** `SELECT count() as value FROM logs WHERE body LIKE '%health-check-%' AND service.name = 'windows-collector' AND timestamp >= now() - INTERVAL 5 MINUTE`
- **Condition:** Below 1 canaries for 5 minutes
- **Severity:** Warning

### Manual Alert Import
```powershell
# Run the import helper
.\import-canary-alert.ps1
```

## Troubleshooting

### Task Not Running
1. **Check Task Scheduler UI:**
   - Open `taskschd.msc`
   - Navigate to: Task Scheduler Library → OTelHealthCanary
   - Check "Last Run Result" column

2. **Common Issues:**
   - Result `0x267011`: Task not run yet (scheduled for future) - **Normal**
   - Result `0x267012`: Task disabled - **Fix:** Enable task
   - Result `0x267013`: Task not found - **Fix:** Re-run `.\scripts\schedule-canary-simple.ps1`

### No Canaries in SigNoz
1. **Check Windows Event Log:**
   ```powershell
   Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object { $_.Message -like '*health-check-*' }
   ```

2. **Check File Logs:**
   ```powershell
   Get-Content "C:\logs\health\health-check-$(Get-Date -Format 'yyyyMMdd').log" -Tail 5
   ```

3. **Check Collector Service:**
   ```powershell
   Get-Service otelcol-contrib
   ```

### Manual Canary Test
```powershell
# Run immediate health check
.\health-enhanced.ps1

# Check for the generated canary in SigNoz
# Filter: log.body contains "health-check-YYYYMMDD-HHMMSS"
```

## Monitoring Checklist

### Daily Checks
- [ ] Task Scheduler shows `Last Run Result: 0x0`
- [ ] SigNoz Logs show recent canaries (last 5 minutes)
- [ ] No missed runs in Task Scheduler

### Weekly Checks
- [ ] Alert configuration is active in SigNoz
- [ ] Review any alert notifications
- [ ] Check collector service health

### Monthly Checks
- [ ] Review canary frequency and timing
- [ ] Update alert thresholds if needed
- [ ] Verify log retention policies

## Quick Commands

```powershell
# Full status check
.\monitor-canary-task.ps1

# Manual canary test
.\health-enhanced.ps1

# Import alert configuration
.\import-canary-alert.ps1

# Check recent canaries
Get-WinEvent -LogName Application -MaxEvents 5 | Where-Object { $_.Message -like '*health-check-*' }
```

## SigNoz UI Quick Links

- **Logs:** http://localhost:8080/logs
- **Alerts:** http://localhost:8080/alerts
- **Dashboards:** http://localhost:8080/dashboards

## Filter Templates

### Health Canaries Only
```
service.name = 'windows-collector' AND canary_id contains 'health-check'
```

### Recent Canaries (Last Hour)
```
service.name = 'windows-collector' AND canary_id contains 'health-check' AND timestamp >= now() - INTERVAL 1 HOUR
```

### Canary Errors
```
service.name = 'windows-collector' AND level = 'ERROR' AND canary_id contains 'health-check'
```
