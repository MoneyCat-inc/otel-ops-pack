# Scheduled Tasks Deployment Checklist

## ✅ Pre-Deployment Status
- [x] SigNoz healthy at http://localhost:8080
- [x] OTLP gRPC (14317): Accessible
- [x] OTLP HTTP (14318): Accessible
- [x] Monitoring scripts tested and working
- [x] Admin deployment script ready

## 🚀 Deployment Steps

### Step 1: Launch Elevated PowerShell
```powershell
Start-Process powershell -Verb RunAs
```

### Step 2: Navigate to OTel Directory
```powershell
cd C:\otel
```

### Step 3: Deploy Scheduled Tasks
```powershell
pwsh -File scripts\setup-scheduled-monitoring-admin.ps1
```

### Step 4: Verify Deployment
```powershell
Get-ScheduledTask -TaskName "*OTel*"
```

**Expected Output:**
```
TaskName                    State
--------                    -----
OTel-QuickHealthCheck      Ready
OTel-CanaryTest            Ready
OTel-DetailedMonitor       Ready
OTel-WeeklyReport          Ready
```

### Step 5: Optional Verification Script
```powershell
pwsh -File scripts\verify-scheduled-tasks.ps1
```

## 📋 Task Schedule Overview

| Task | Frequency | Duration | Purpose |
|------|-----------|----------|---------|
| OTel-QuickHealthCheck | Every 5 minutes | ~30 seconds | Quick health status |
| OTel-CanaryTest | Every 15 minutes | ~1 minute | ECRR canary testing |
| OTel-DetailedMonitor | Every hour | 10 minutes | Detailed pipeline analysis |
| OTel-WeeklyReport | Every Sunday 9 AM | ~2 minutes | Weekly trend report |

## 🔍 Post-Deployment Monitoring

### Check Task Status
```powershell
Get-ScheduledTask -TaskName "*OTel*" | Select-Object TaskName, State, NextRunTime
```

### Monitor Artifacts
```powershell
Get-ChildItem artifacts\*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### Test Manual Execution
```powershell
Start-ScheduledTask -TaskName "OTel-QuickHealthCheck"
Get-ScheduledTaskInfo -TaskName "OTel-QuickHealthCheck"
```

## 📊 Expected Artifacts

After deployment, you should see these new files:
- `artifacts/quick-monitor-YYYYMMDD-HHMMSS.json` (every 5 minutes)
- `artifacts/canary-ecrr-report.txt` (every 15 minutes)
- `artifacts/monitoring-report-YYYYMMDD-HHMMSS.json` (every hour)
- `artifacts/weekly-report-YYYYMMDD.json` (weekly)

## 🚨 Troubleshooting

### If Tasks Don't Create
```powershell
# Check if running as admin
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
```

### If Tasks Don't Run
```powershell
# Check task history
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201} | 
    Where-Object {$_.Message -like '*OTel*'}
```

### If No Artifacts Generated
```powershell
# Test scripts manually
pwsh -File scripts\quick-monitor.ps1
pwsh -File scripts\canary-ecrr.ps1
```

## 🎯 Success Criteria

- [ ] 4 scheduled tasks created and in "Ready" state
- [ ] Tasks automatically execute on schedule
- [ ] Artifacts generated in `artifacts/` folder
- [ ] No authentication errors in task execution
- [ ] Canary tests successfully send logs to SigNoz

## 📞 Next Steps After Deployment

1. **Monitor for 24 hours** to ensure stable operation
2. **Check SigNoz UI** for canary logs: http://localhost:8080/logs (filter: "canary test")
3. **Review weekly report** after first Sunday
4. **Configure SigNoz alerts** if needed for production use
5. **Set up notifications** for critical alerts if desired

---
**Deployment Date**: _[To be filled after deployment]_  
**Deployed By**: _[To be filled]_  
**Status**: _[To be filled]_
