# See C:\otel\docs\comfort cat
# BossCat OEM - Gate AutoBot Deployment
# Sets up automated monitoring and recovery for Windows Collector service

#Requires -RunAsAdministrator

param(
    [switch]$Remove = $false,
    [switch]$TestMode = $false
)

$ErrorActionPreference = "Stop"

Write-Host @"

🐾 BossCat OEM - Gate AutoBot Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deploying two specialized autobots to guard the observability gate:
  1. Service Guardian - Auto-recovery agent (every 2 minutes)
  2. Gate Auditor     - Forensic analyst (hourly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@ -ForegroundColor Cyan

$workDir = Get-Location
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
}

# Task 1: Service Guardian (runs every 2 minutes)
$guardianTaskName = "BossCat-ServiceGuardian"
$guardianScript = Join-Path $workDir "scripts\autobot-service-guardian.ps1"
$guardianAction = New-ScheduledTaskAction -Execute $pwshPath -Argument "-NoProfile -NonInteractive -File `"$guardianScript`"" -WorkingDirectory $workDir
$guardianTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 9999)
$guardianSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
$guardianPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Task 2: Gate Auditor (runs hourly)
$auditorTaskName = "BossCat-GateAuditor"
$auditorScript = Join-Path $workDir "scripts\autobot-gate-auditor.ps1"
$auditorAction = New-ScheduledTaskAction -Execute $pwshPath -Argument "-NoProfile -NonInteractive -File `"$auditorScript`"" -WorkingDirectory $workDir
$auditorTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 9999)
$auditorSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$auditorPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

if ($Remove) {
    Write-Host "🗑️  Removing existing autobots..." -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName $guardianTaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  ✅ Removed: $guardianTaskName" -ForegroundColor Green
    }
    catch {
        Write-Host "  ℹ️  $guardianTaskName not found" -ForegroundColor Gray
    }
    
    try {
        Unregister-ScheduledTask -TaskName $auditorTaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  ✅ Removed: $auditorTaskName" -ForegroundColor Green
    }
    catch {
        Write-Host "  ℹ️  $auditorTaskName not found" -ForegroundColor Gray
    }
    
    Write-Host "`n✅ AutoBots removed" -ForegroundColor Green
    exit 0
}

Write-Host "📦 Deploying AutoBots..." -ForegroundColor Cyan

# Remove existing tasks if present
Unregister-ScheduledTask -TaskName $guardianTaskName -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $auditorTaskName -Confirm:$false -ErrorAction SilentlyContinue

# Deploy Service Guardian
Write-Host "`n1️⃣  Deploying Service Guardian..." -ForegroundColor Yellow
$guardianTask = Register-ScheduledTask -TaskName $guardianTaskName -Action $guardianAction -Trigger $guardianTrigger -Settings $guardianSettings -Principal $guardianPrincipal -Description "BossCat AutoBot: Monitors Windows Collector service and auto-recovers if stopped/disabled. Runs every 2 minutes."

if ($guardianTask) {
    Write-Host "  ✅ Service Guardian deployed" -ForegroundColor Green
    Write-Host "     Task: $guardianTaskName" -ForegroundColor Gray
    Write-Host "     Interval: Every 2 minutes" -ForegroundColor Gray
    Write-Host "     Script: $guardianScript" -ForegroundColor Gray
}
else {
    Write-Host "  ❌ Failed to deploy Service Guardian" -ForegroundColor Red
}

# Deploy Gate Auditor
Write-Host "`n2️⃣  Deploying Gate Auditor..." -ForegroundColor Yellow
$auditorTask = Register-ScheduledTask -TaskName $auditorTaskName -Action $auditorAction -Trigger $auditorTrigger -Settings $auditorSettings -Principal $auditorPrincipal -Description "BossCat AutoBot: Forensic analysis of service state changes. Tracks who/what is modifying the service. Runs hourly."

if ($auditorTask) {
    Write-Host "  ✅ Gate Auditor deployed" -ForegroundColor Green
    Write-Host "     Task: $auditorTaskName" -ForegroundColor Gray
    Write-Host "     Interval: Every 1 hour" -ForegroundColor Gray
    Write-Host "     Script: $auditorScript" -ForegroundColor Gray
}
else {
    Write-Host "  ❌ Failed to deploy Gate Auditor" -ForegroundColor Red
}

# Test mode: Run auditor now to show current state
if ($TestMode) {
    Write-Host "`n🧪 TEST MODE: Running Gate Auditor now..." -ForegroundColor Cyan
    & pwsh -File $auditorScript -LookbackHours 48
}

Write-Host @"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ AutoBot Deployment Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 Active AutoBots:

  1. SERVICE GUARDIAN
     ├─ Monitors service health every 2 minutes
     ├─ Auto-recovers if service stops or becomes disabled
     ├─ Generates ECRR reports on each recovery
     └─ Logs: artifacts\autobot-guardian-*.log

  2. GATE AUDITOR
     ├─ Runs forensic analysis hourly
     ├─ Tracks service state changes
     ├─ Detects suspicious patterns
     └─ Reports: artifacts\gate-audit-*.json

📊 Monitoring:

  View tasks:
    Get-ScheduledTask -TaskName "BossCat-*"

  View Guardian logs:
    Get-Content artifacts\autobot-guardian-$(Get-Date -Format 'yyyyMMdd').log -Tail 50

  View Auditor reports:
    Get-ChildItem artifacts\gate-audit-*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 5

  Disable autobots:
    Disable-ScheduledTask -TaskName "BossCat-ServiceGuardian"
    Disable-ScheduledTask -TaskName "BossCat-GateAuditor"

  Remove autobots:
    pwsh -File scripts\setup-gate-autobots.ps1 -Remove

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐾 BossCat OEM - Your gate is now guarded 24/7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@ -ForegroundColor Green

