# SigNoz Alert Import Guide - ECRR Canary

## Quick Import Steps

### 1. Access SigNoz UI
- Open: http://localhost:8080
- Navigate to: **Alerts** → **Create Alert**

### 2. Import Alert Configuration
- Use the configuration from: `signoz-ecrr-canary-alert.json`
- Copy the JSON content and paste into SigNoz alert creation form

### 3. Verify Alert Settings
- **Alert Name**: ECRR Canary Missing
- **Query**: `service.name = 'ecrr-canary' AND attributes.canary.type = 'ecrr-enhanced'`
- **Threshold**: Below 1 canary in 15 minutes
- **Evaluation Window**: 15 minutes
- **Alert Frequency**: 5 minutes

### 4. Configure Notifications
- **Channels**: email-default, slack-default
- **Severity**: Warning
- **Labels**: service=ecrr-canary, component=health-check, framework=ecrr

### 5. Test the Alert
- **Test Query**: `message contains "ECRR-Canary-Test"`
- **Expected Result**: Should show recent canary logs every 10 minutes
- **Alert State**: Should remain "OK" when canaries are flowing

## Verification Commands

```powershell
# Check scheduled task status
Get-ScheduledTask -TaskName 'OTel-ECRR-Canary' | Get-ScheduledTaskInfo

# View latest canary report
Get-Content artifacts/canary-ecrr-report.txt -Tail 10

# Monitor log file
Get-Content C:\logs\ecrr-canary-test.log -Tail 5

# Check Windows Event Log
Get-WinEvent -LogName Application | Where-Object {$_.ProviderName -eq "SigNoz-Canary" -and $_.Id -eq 1001} | Select-Object -First 3 TimeCreated, Message
```

## Expected Behavior

- **Every 10 minutes**: New canary log entry created
- **SigNoz Logs**: Query `message contains "ECRR-Canary-Test"` shows recent entries
- **Alert Status**: Should remain "OK" (not firing) when canaries are flowing
- **Alert Firing**: Only if no canaries received in 15-minute window

## Failure Drill (Prove Alert End-to-End)

Run the automated failure drill to prove the alert fires and clears:

```powershell
pwsh -File scripts/ecrr-failure-drill.ps1
```

This will:
1. **Pause** the canary task for 15 minutes
2. **Wait** for the alert to fire (monitor SigNoz UI)
3. **Restore** the canary task
4. **Verify** the alert resolves

Expected behavior:
- **During pause**: Alert fires after 15 minutes of no canaries
- **After restore**: Alert resolves within 5 minutes when canaries resume

## Troubleshooting

- **No logs in SigNoz**: Check OTLP endpoint 5318 accessibility
- **Alert not working**: Verify query syntax and time range
- **Task not running**: Check Windows Task Scheduler for OTel-ECRR-Canary
- **Permission issues**: Ensure PowerShell running as Administrator for task management
- **Drill fails**: Ensure task name is 'OTel-ECRR-Canary' (not 'ECRR Canary')
