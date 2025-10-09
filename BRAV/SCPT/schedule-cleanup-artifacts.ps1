#Requires -Version 7.0
<#!
.SYNOPSIS
  Create or update a weekly Scheduled Task to prune stale artifacts.

.DESCRIPTION
  Registers a Windows Scheduled Task 'OTel-Artifacts-Cleanup' that runs
  scripts/cleanup-artifacts.ps1 weekly (default: Sundays 03:30). Idempotent.

.PARAMETER Days
  Age threshold in days passed to cleanup script. Default: 30

.PARAMETER IncludeLogs
  Include logs directory during cleanup.

.PARAMETER Hour
  Hour (0-23) to schedule. Default: 3

.PARAMETER Minute
  Minute (0-59) to schedule. Default: 30

.PARAMETER DayOfWeek
  Day of week (Sunday..Saturday). Default: Sunday

.EXAMPLE
  pwsh -File scripts/schedule-cleanup-artifacts.ps1

.EXAMPLE
  pwsh -File scripts/schedule-cleanup-artifacts.ps1 -Days 14 -IncludeLogs -DayOfWeek Saturday -Hour 2 -Minute 15
#>

param(
  [int]$Days = 30,
  [switch]$IncludeLogs,
  [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
  [string]$DayOfWeek = 'Sunday',
  [ValidateRange(0,23)][int]$Hour = 3,
  [ValidateRange(0,59)][int]$Minute = 30
)

$ErrorActionPreference = 'Stop'

$taskName = 'OTel-Artifacts-Cleanup'
$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..')
$scriptPath = Join-Path $repoRoot 'scripts/cleanup-artifacts.ps1'
if (-not (Test-Path $scriptPath)) { throw "Missing script: $scriptPath" }

# Build arguments
$argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $scriptPath, '-Days', $Days)
if ($IncludeLogs) { $argList += '-IncludeLogs' }
$argList += '-Force'
$argString = $argList -join ' '

$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $argString -WorkingDirectory $repoRoot
# -At requires a DateTime; construct today at the desired hour/minute
$atTime = [datetime]::Today.AddHours($Hour).AddMinutes($Minute)
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $atTime
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType S4U -RunLevel Highest

# Register or update
$exists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($exists) {
  Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
} else {
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Description 'Weekly prune of stale artifacts for OTel workspace' | Out-Null
}

Write-Host ("Scheduled task '{0}' set for {1} at {2:D2}:{3:D2} (Days={4}, IncludeLogs={5})." -f $taskName, $DayOfWeek, $Hour, $Minute, $Days, [bool]$IncludeLogs)

# Verification hints
Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo | Format-List *
