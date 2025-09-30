# SigNoz Monitoring Setup Guide

## Current Status ✅

**Fresh Canary Generated:**
- **Timestamp**: `2025-09-28T17:22:04.4251046Z`
- **Test ID**: `a7e6e5ab`
- **File**: `C:\logs\test.log`

**SigNoz Connectivity Confirmed:**
- ✅ SigNoz UI (8080): OPEN
- ✅ SigNoz OTLP gRPC (14317): OPEN
- ✅ SigNoz OTLP HTTP (14318): OPEN
- ✅ SigNoz Health: ok

## SigNoz UI Verification

### Step 1: Access SigNoz
1. Open browser to: `http://localhost:8080`
2. Login if required (default: admin@signoz.io / admin)

### Step 2: Navigate to Logs
1. Click **"Logs"** in left sidebar
2. Select **"Logs Explorer"** tab

### Step 3: Apply Filters
**Primary Filter:**
```
service.name = "windows-host"
```

**Specific Canary Filter:**
```
service.name = "windows-host" AND message contains "SigNoz test from hardened collector"
```

### Step 4: Verify Canary Entry
Look for entry with:
- **Timestamp**: `2025-09-28T17:22:04Z`
- **Message**: "SigNoz test from hardened collector"
- **Test ID**: `a7e6e5ab` (in attributes/body)
- **Service**: windows-host

## Alert Configuration

### 1. Ingestion Down Alert
**Purpose**: Detect when Windows collector stops sending logs

**Configuration:**
- **Name**: `Windows Collector Ingestion Down`
- **Query**: `service.name = "windows-host"`
- **Condition**: No logs received in last 5 minutes
- **Severity**: Warning
- **Notification**: Email/Slack (configure as needed)

**Steps:**
1. Go to **"Alerts"** section
2. Click **"New Alert"**
3. Set query: `service.name = "windows-host"`
4. Set condition: `count() == 0 for 5m`
5. Configure notification channels

### 2. Error Rate Alert
**Purpose**: Detect high error rates from Windows collector

**Configuration:**
- **Name**: `Windows Collector High Error Rate`
- **Query**: `service.name = "windows-host" AND level = "ERROR"`
- **Condition**: Error count > 10 in last 10 minutes
- **Severity**: Critical

## Scheduled Monitoring

### Task Scheduler Setup
**Purpose**: Automatically generate canary tests

**Steps:**
1. Open **Task Scheduler** (taskschd.msc)
2. Click **"Create Basic Task"**
3. **Name**: `SigNoz Canary Test`
4. **Trigger**: Daily, every 4 hours
5. **Action**: Start a program
6. **Program**: `pwsh.exe`
7. **Arguments**: `-NoLogo -NoProfile -Command "C:\otel\scripts\signoz-canary-monitor.ps1 -GenerateCanary"`
8. **Start in**: `C:\otel`

### PowerShell Script Schedule
**Alternative**: Use PowerShell scheduled jobs

```powershell
# Create scheduled job (run as Administrator)
$trigger = New-JobTrigger -Daily -At "00:00", "04:00", "08:00", "12:00", "16:00", "20:00"
$action = {
    Set-Location "C:\otel"
    pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -GenerateCanary"
}
Register-ScheduledJob -Name "SigNozCanary" -Trigger $trigger -ScriptBlock $action
```

## Dashboard Setup

### 1. Log Volume Dashboard
**Panel Configuration:**
- **Title**: `Windows Collector Log Volume`
- **Query**: `service.name = "windows-host"`
- **Visualization**: Line chart
- **Time Range**: Last 24 hours
- **Group By**: timestamp (1 hour buckets)

### 2. Error Rate Dashboard
**Panel Configuration:**
- **Title**: `Windows Collector Error Rate`
- **Query**: `service.name = "windows-host" AND level = "ERROR"`
- **Visualization**: Bar chart
- **Time Range**: Last 7 days
- **Group By**: timestamp (1 day buckets)

### 3. Canary Test Dashboard
**Panel Configuration:**
- **Title**: `Canary Test Status`
- **Query**: `message contains "SigNoz test from hardened collector"`
- **Visualization**: Logs table
- **Time Range**: Last 24 hours
- **Columns**: timestamp, message, test_id

## Monitoring Commands

### Daily Health Check
```powershell
# Run full verification
pwsh -File verify-collector.ps1

# Generate canary and check connectivity
pwsh -File scripts/signoz-canary-monitor.ps1 -GenerateCanary -VerifySigNoz
```

### Troubleshooting Commands
```powershell
# Check recent logs
pwsh -File scripts/signoz-canary-monitor.ps1 -CheckRecent

# Verify SigNoz connectivity
pwsh -File scripts/signoz-canary-monitor.ps1 -VerifySigNoz

# Check collector service
Get-Service -Name otelcol-contrib
```

## Success Criteria

✅ **Canary visible in SigNoz UI** with correct filters  
✅ **Test ID `a7e6e5ab` appears** in log attributes/body  
✅ **All SigNoz endpoints reachable** (8080, 14317, 14318)  
✅ **Health endpoint returns ok**  
✅ **Monitoring alerts configured** for ingestion failures  
✅ **Scheduled canary generation** set up  

## Next Steps

1. **Verify canary in SigNoz UI** using the filters above
2. **Set up ingestion down alert** (no logs in 5 minutes)
3. **Configure scheduled canary generation** (every 4 hours)
4. **Create dashboard panels** for visual monitoring
5. **Test alert notifications** by stopping collector temporarily

---

*Monitoring setup completed: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`*
