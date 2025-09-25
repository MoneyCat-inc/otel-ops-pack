# Task Scheduler Setup Guide - Windows Logs Canary

## Manual Setup Instructions

### Step 1: Open Task Scheduler
1. Press `Win + R`, type `taskschd.msc`, and press Enter
2. Or search "Task Scheduler" in Start menu

### Step 2: Create New Task
1. In Task Scheduler, click **"Create Task..."** (not "Create Basic Task")
2. This opens the full task configuration dialog

### Step 3: General Tab Configuration
- **Name**: `WindowsLogsCanary`
- **Description**: `Automatically generate Windows Event Log canary entries for observability pipeline monitoring`
- **Security Options**:
  - Select **"Run whether user is logged on or not"**
  - Check **"Run with highest privileges"**
  - **Configure for**: Windows 10/11

### Step 4: Triggers Tab Configuration
1. Click **"New..."** to create a trigger
2. **Begin the task**: `On a schedule`
3. **Settings**: `Daily`
4. **Start**: Set to current time
5. **Advanced settings**:
   - Check **"Repeat task every"**: `15 minutes`
   - **For a duration of**: `Indefinitely`
   - Check **"Enabled"**
6. Click **"OK"**

### Step 5: Actions Tab Configuration
1. Click **"New..."** to create an action
2. **Action**: `Start a program`
3. **Program/script**: `pwsh.exe`
4. **Add arguments**: `-File "C:\otel\scripts\windows-logs-canary-test.ps1" -Count 2`
5. **Start in**: `C:\otel`
6. Click **"OK"**

### Step 6: Conditions Tab Configuration
- **Power**:
  - Uncheck **"Start the task only if the computer is on AC power"**
  - Uncheck **"Stop if the computer switches to battery power"**
- **Network**: Leave defaults
- **Idle**: Leave defaults

### Step 7: Settings Tab Configuration
- Check **"Allow task to be run on demand"**
- Check **"Run task as soon as possible after a scheduled start is missed"**
- Check **"If the task fails, restart every"**: `1 minute`
- **Attempt to restart up to**: `3 times`
- Check **"Stop the task if it runs longer than"**: `5 minutes`
- **If the running task does not end when requested, force it to stop**

### Step 8: Save and Test
1. Click **"OK"** to save the task
2. Enter administrator credentials when prompted
3. Right-click the task and select **"Run"** to test
4. Check Windows Event Log for canary entries

## Verification Steps

### 1. Check Task Status
- In Task Scheduler, find "WindowsLogsCanary"
- Verify **"Status"** shows "Ready"
- Check **"Last Run Result"** shows "0x0" (Success)

### 2. Monitor Execution
```powershell
# Check recent Windows Event Log entries
Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object { $_.Message -like '*windows-logs-canary*' }

# Check SigNoz for ingested canaries
# Navigate to: http://localhost:8080 → Logs
# Filter: attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%'
```

### 3. Test Alert System
```powershell
# Run monitoring script
.\scripts\monitor-windows-logs-canary.ps1 -TimeWindowMinutes 10
```

## PowerShell Commands for Management

### View Task Information
```powershell
Get-ScheduledTask -TaskName "WindowsLogsCanary"
Get-ScheduledTaskInfo -TaskName "WindowsLogsCanary"
```

### Start Task Manually
```powershell
Start-ScheduledTask -TaskName "WindowsLogsCanary"
```

### Disable Task
```powershell
Disable-ScheduledTask -TaskName "WindowsLogsCanary"
```

### Enable Task
```powershell
Enable-ScheduledTask -TaskName "WindowsLogsCanary"
```

### Remove Task
```powershell
Unregister-ScheduledTask -TaskName "WindowsLogsCanary" -Confirm:$false
```

## Troubleshooting

### Task Not Running
1. **Check Task Status**: Ensure task is "Ready" and enabled
2. **Check Last Run Result**:
   - `0x0`: Success
   - `0x1`: General error
   - `0x41301`: Task is running
   - `0x41302`: Task is disabled

### Permission Issues
1. **Run Task Scheduler as Administrator**
2. **Ensure task is configured to run with highest privileges**
3. **Check Windows Event Log for error messages**

### Script Not Found
1. **Verify script path**: `C:\otel\scripts\windows-logs-canary-test.ps1`
2. **Check PowerShell execution policy**:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### No Canary Entries Generated
1. **Check Windows Event Log permissions**
2. **Verify PowerShell script runs manually**
3. **Check Task Scheduler event log for errors**

## Expected Behavior

### Successful Execution
- Task runs every 15 minutes
- Creates 2 canary entries in Windows Event Log
- Entries appear in SigNoz within 1-2 minutes
- Alert system detects canaries and doesn't trigger

### Failure Scenarios
- Task fails to run → Check Task Scheduler status
- Canaries not generated → Check script execution
- Canaries not ingested → Check SigNoz pipeline
- Alert triggers → Check canary generation frequency

## Integration with Monitoring

### SigNoz Alert
- **Query**: `SELECT count() as value FROM logs WHERE attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%' AND timestamp >= now() - INTERVAL 1 HOUR`
- **Condition**: Below 1 for 60 minutes
- **Expected**: No alerts when task runs successfully

### Monitoring Script
```powershell
# Check canary ingestion every 10 minutes
.\scripts\monitor-windows-logs-canary.ps1 -TimeWindowMinutes 10
```

### Dashboard Integration
- Add canary count to monitoring dashboards
- Track canary generation frequency
- Monitor alert trigger history

## Next Steps

1. **Configure Notification Channels** for alert escalation
2. **Add Canary Status to Dashboards** for visual monitoring
3. **Set Up Log Rotation** for canary log files
4. **Implement Alert Escalation** procedures
5. **Document Runbooks** for incident response
