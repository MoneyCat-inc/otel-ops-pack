[CmdletBinding()]
param(
    [switch]$Remove,
    [string]$TaskName = 'DiskUsageMonitor',
    [int]$IntervalMinutes = 15,
    [string]$Drive = 'C:',
    [switch]$EnableCleanupOnCritical,
    [switch]$RunNow
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$monitorScript = Join-Path $PSScriptRoot 'monitor-disk-usage.ps1'
if (-not (Test-Path $monitorScript)) { throw "monitor-disk-usage.ps1 not found in $PSScriptRoot" }

if ($IntervalMinutes -lt 5) { throw 'IntervalMinutes must be 5 or greater.' }

if ($Remove) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Yellow
    } else {
        Write-Host "Scheduled task '$TaskName' was not found." -ForegroundColor Gray
    }
    return
}

$actionArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$monitorScript`" -Drive `"$Drive`""
if ($EnableCleanupOnCritical) { $actionArgs += ' -AutoCleanup' }

$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $actionArgs

$startTime = (Get-Date).AddMinutes(1)
$repetitionDuration = New-TimeSpan -Days 365
$trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration $repetitionDuration

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "Scheduled task '$TaskName' registered to run every $IntervalMinutes minutes." -ForegroundColor Green
Write-Host "Script: $monitorScript" -ForegroundColor Gray
Write-Host "Drive: $Drive" -ForegroundColor Gray
if ($EnableCleanupOnCritical) { Write-Host "Auto cleanup on critical threshold is ENABLED." -ForegroundColor Yellow } else { Write-Host "Auto cleanup on critical threshold is DISABLED." -ForegroundColor Gray }

if ($RunNow) {
    Write-Host 'Running disk usage monitor immediately for baseline log entry...' -ForegroundColor Cyan
    & $monitorScript -Drive $Drive -DisableEventLog:$false | Out-Null
}

Write-Host "To remove the scheduled task, run this script with -Remove." -ForegroundColor Cyan