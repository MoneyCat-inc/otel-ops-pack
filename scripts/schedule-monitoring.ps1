#Requires -Version 5.1
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Write-Host "[schedule] Setting up OTel monitoring schedule" -ForegroundColor Green

# Create scheduled task for verification
$taskName = "OTel-Verification-Canary"
$scriptPath = Join-Path $PSScriptRoot "..\scripts\verify-integration.ps1"
$workingDir = Join-Path $PSScriptRoot ".."

Write-Host "[schedule] Creating scheduled task: $taskName" -ForegroundColor Yellow

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "[schedule] Removing existing task" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create new scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WorkingDirectory $workingDir
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 365)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "OTel Windows -> SigNoz verification canary (runs every 15 minutes)"

Write-Host "[schedule] ✓ Scheduled task created successfully" -ForegroundColor Green
Write-Host "[schedule] Task runs every 15 minutes starting now" -ForegroundColor Cyan
Write-Host "[schedule] To view task: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Yellow
Write-Host "[schedule] To remove task: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Yellow
