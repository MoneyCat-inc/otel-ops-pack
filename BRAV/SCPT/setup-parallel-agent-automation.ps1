#Requires -Version 7.0

<#
.SYNOPSIS
    Registers scheduled tasks for the BossCat watchdog and nightly parallel agent orchestration.

.DESCRIPTION
    Creates (or updates) two Windows Scheduled Tasks:
      - BossCatAgentWatchdog: keeps the local watchdog running on every user logon.
      - BossCatNightlyOrchestration: runs the nightly parallel-agent orchestrator at the requested UTC time.

    Both tasks run under the current user context and use pwsh.exe to execute the associated scripts.

.PARAMETER NightlyUtcTime
    UTC time (HH:mm) for the nightly orchestration run. Defaults to 02:00.

.PARAMETER TaskFolder
    Scheduled task folder (defaults to \BossCat).

.PARAMETER Force
    Overwrite existing tasks without prompting.

.EXAMPLE
    pwsh -File scripts/setup-parallel-agent-automation.ps1

.EXAMPLE
    pwsh -File scripts/setup-parallel-agent-automation.ps1 -NightlyUtcTime "03:30" -Force
#>

[CmdletBinding()]
param(
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$NightlyUtcTime = '02:00',

    [string]$TaskFolder = '\BossCat',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[setup] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[setup] $Message" -ForegroundColor Yellow
}

function Ensure-TaskFolder {
    param([string]$FolderPath)
    if ([string]::IsNullOrWhiteSpace($FolderPath) -or $FolderPath -eq '\') { return }

    $normalized = if ($FolderPath.StartsWith("\")) { $FolderPath.TrimStart('\') } else { $FolderPath }

    $service = New-Object -ComObject 'Schedule.Service'
    try {
        $service.Connect()
        try {
            $null = $service.GetFolder("\$normalized")
        } catch {
            Write-Info "Creating scheduled task folder \${normalized}"
            $root = $service.GetFolder('\')
            $root.CreateFolder($normalized) | Out-Null
        }
    } finally {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($service) | Out-Null
    }
}

function Register-WatchdogTask {
    param(
        [string]$TaskPath,
        [switch]$Overwrite
    )

    $taskName = 'BossCatAgentWatchdog'
    $fullName = Join-Path $TaskPath $taskName

    $scriptPath = Join-Path $PSScriptRoot 'agent/watchdog.ps1'
    if (-not (Test-Path $scriptPath)) {
        throw "Watchdog script not found at $scriptPath"
    }

    $arguments = "-NoLogo -NoProfile -File `"$scriptPath`""
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $arguments -WorkingDirectory (Split-Path $scriptPath -Parent)
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::FromHours(6)) `
                                            -AllowStartIfOnBatteries `
                                            -DontStopIfGoingOnBatteries `
                                            -StartWhenAvailable

    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

    $registerParams = @{
        TaskName = $taskName
        TaskPath = $TaskPath
        InputObject = $task
    }
    if ($Overwrite) { $registerParams['Force'] = $true }

    Write-Info "Registering watchdog scheduled task at $fullName"
    Register-ScheduledTask @registerParams | Out-Null
}

function Register-NightlyTask {
    param(
        [string]$TaskPath,
        [string]$UtcTimeText,
        [switch]$Overwrite
    )

    $taskName = 'BossCatNightlyOrchestration'
    $fullName = Join-Path $TaskPath $taskName

    $scriptPath = Join-Path $PSScriptRoot 'nightly-parallel-agent-orchestration.ps1'
    if (-not (Test-Path $scriptPath)) {
        throw "Nightly orchestration script not found at $scriptPath"
    }

    $utcTimeSpan = [TimeSpan]::ParseExact($UtcTimeText, 'hh\:mm', [System.Globalization.CultureInfo]::InvariantCulture)
    $baseUtc = [DateTime]::UtcNow.Date.Add($utcTimeSpan)
    $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($baseUtc, [System.TimeZoneInfo]::Local)
    $localTriggerTime = [DateTime]::Today.Add($localTime.TimeOfDay)

    $arguments = "-NoLogo -NoProfile -File `"$scriptPath`""
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $arguments -WorkingDirectory (Split-Path $scriptPath -Parent)
    $trigger = New-ScheduledTaskTrigger -Daily -At $localTriggerTime

    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::FromHours(2)) `
                                            -AllowStartIfOnBatteries `
                                            -DontStopIfGoingOnBatteries `
                                            -StartWhenAvailable `
                                            -WakeToRun

    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

    $registerParams = @{
        TaskName = $taskName
        TaskPath = $TaskPath
        InputObject = $task
    }
    if ($Overwrite) { $registerParams['Force'] = $true }

    Write-Info "Registering nightly orchestration task at $fullName (local run time: $($localTriggerTime.ToString('HH:mm')))"
    Register-ScheduledTask @registerParams | Out-Null
}

Ensure-TaskFolder -FolderPath $TaskFolder

Register-WatchdogTask -TaskPath $TaskFolder -Overwrite:$Force
Register-NightlyTask -TaskPath $TaskFolder -UtcTimeText $NightlyUtcTime -Overwrite:$Force

Write-Info "Scheduled tasks configured successfully."
