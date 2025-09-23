[CmdletBinding()]
param(
    [Parameter()]
    [string]$TaskName = "OTelHealthCanary",

    [Parameter()]
    [string]$ScriptPath = (Join-Path $PSScriptRoot "..\health-enhanced.ps1"),

    [Parameter()]
    [ValidateRange(1, 1440)]
    [int]$IntervalMinutes = 5,

    [switch]$DryRun
)

Set-StrictMode -Version Latest

$principalContext = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principalContext.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell session."
}

if (-not (Test-Path -Path $ScriptPath)) {
    throw "Target script not found: $ScriptPath"
}

$resolvedScript = (Resolve-Path -Path $ScriptPath).Path
$interval = New-TimeSpan -Minutes $IntervalMinutes

$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NonInteractive -File `"$resolvedScript`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval $interval -RepetitionDuration ([TimeSpan]::FromDays(365))

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$preview = [pscustomobject]@{
    TaskName  = $TaskName
    Script    = $resolvedScript
    Interval  = "$IntervalMinutes minute(s)"
    Principal = $principal.UserId
}

if ($DryRun) {
    return $preview
}

$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "OpenTelemetry health canary ($resolvedScript)"

$taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State, @{Name = "NextRunTime"; Expression = { $taskInfo.NextRunTime }}, Actions

