<#
Usage: .\agent-scheduler.ps1
Run once to evaluate scheduled maintenance tasks; add to Task Scheduler, cron, or GitHub Actions for automation.
#>
[CmdletBinding()]
param()

function ConvertTo-OrderedHashtable {
    param($InputObject)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $ordered[$key] = ConvertTo-OrderedHashtable $InputObject[$key]
        }
        return $ordered
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $ordered = [ordered]@{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $ordered[$prop.Name] = ConvertTo-OrderedHashtable $prop.Value
        }
        return $ordered
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $list = @()
        foreach ($item in $InputObject) {
            $list += ,(ConvertTo-OrderedHashtable $item)
        }
        return $list
    }

    return $InputObject
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Path -Parent $PSCommandPath
if (-not $root) {
    $root = (Get-Location).Path
}

$agentDir = Join-Path $root '.agent'
$lockPath = Join-Path $agentDir 'LOCK'

if (Test-Path -LiteralPath $lockPath) {
    Write-Output "LOCK present at $lockPath; skipping scheduler run."
    exit 0
}

$logDir = Join-Path $agentDir 'logs'
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$logFile = Join-Path $logDir "scheduler-$timestamp.log"

$transcriptStarted = $false
$state = $null
try {
    Start-Transcript -Path $logFile | Out-Null
    $transcriptStarted = $true

    Write-Output "Starting agent scheduler at $(Get-Date -Format o)"

    $schedulePath = Join-Path $agentDir 'schedule.json'
    if (-not (Test-Path -LiteralPath $schedulePath)) {
        throw "Schedule file not found: $schedulePath"
    }

    $statePath = Join-Path $agentDir 'state.json'
    if (Test-Path -LiteralPath $statePath) {
        $stateRaw = Get-Content -Raw -Path $statePath
        if ($stateRaw.Trim()) {
            $stateObject = ConvertFrom-Json -InputObject $stateRaw
            $state = ConvertTo-OrderedHashtable $stateObject
        }
    }

    if (-not $state -or $state -isnot [System.Collections.IDictionary]) {
        $state = [ordered]@{}
    }

    foreach ($key in 'lastDailyRun','lastWeeklyRun','lastMonthlyRun','lastQuarterlyRun','lastYearlyRun') {
        if (-not $state.Contains($key)) {
            $state[$key] = $null
        }
    }

    $scheduleData = Get-Content -Raw -Path $schedulePath | ConvertFrom-Json
    if (-not $scheduleData -or -not $scheduleData.tasks) {
        Write-Warning "schedule.json contains no tasks."
        $scheduleData = [pscustomobject]@{ tasks = @() }
    }

    $frequencyDurations = @{
        daily = New-TimeSpan -Days 1
        weekly = New-TimeSpan -Days 7
        monthly = New-TimeSpan -Days 30
        quarterly = New-TimeSpan -Days 90
        yearly = New-TimeSpan -Days 365
    }

    $frequencyStateKeys = @{
        daily = 'lastDailyRun'
        weekly = 'lastWeeklyRun'
        monthly = 'lastMonthlyRun'
        quarterly = 'lastQuarterlyRun'
        yearly = 'lastYearlyRun'
    }

    $nowUtc = (Get-Date).ToUniversalTime()

    Push-Location -Path $root
    try {
        foreach ($task in $scheduleData.tasks) {
            if (-not $task) { continue }

            $taskName = if ($task.PSObject.Properties['name']) { [string]$task.name } else { '(unnamed task)' }
            $freqValue = if ($task.PSObject.Properties['frequency']) { [string]$task.frequency } else { '' }
            $commandText = if ($task.PSObject.Properties['command']) { [string]$task.command } else { '' }

            $freq = $freqValue.ToLowerInvariant()

            if (-not $frequencyDurations.ContainsKey($freq)) {
                Write-Warning "Skipping ${taskName}: unsupported frequency '$freqValue'."
                continue
            }

            $stateKey = $frequencyStateKeys[$freq]
            $lastRunRaw = $state[$stateKey]
            $lastRunTime = $null
            if ($lastRunRaw) {
                try {
                    $parsedLast = [DateTime]::Parse($lastRunRaw.ToString()).ToUniversalTime()
                    $lastRunTime = $parsedLast
                } catch {
                    Write-Warning "Unable to parse last run timestamp '$lastRunRaw' for ${taskName}."
                }
            }

            $due = $true
            if ($lastRunTime) {
                $due = ($nowUtc - $lastRunTime) -ge $frequencyDurations[$freq]
            }

            $lastRunDisplay = if ($lastRunTime) { $lastRunTime.ToString('o') } else { 'never' }

            if (-not $due) {
                Write-Output "Skipping $taskName; last run $lastRunDisplay (UTC)."
                continue
            }

            if ([string]::IsNullOrWhiteSpace($commandText)) {
                Write-Warning "Skipping ${taskName}: command missing."
                $state[$stateKey] = (Get-Date).ToUniversalTime().ToString('o')
                continue
            }

            Write-Output "Running $taskName ($freq)"
            Write-Output "Command: $commandText"

            Set-Variable -Name LASTEXITCODE -Scope Global -Value 0
            $taskSucceeded = $true
            try {
                $commandOutput = Invoke-Expression -Command $commandText 2>&1
                if ($commandOutput) {
                    foreach ($line in $commandOutput) {
                        Write-Output "  $line"
                    }
                }
                $exitCodeVar = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
                if ($exitCodeVar -and $exitCodeVar.Value -ne 0) {
                    $taskSucceeded = $false
                    Write-Output "Command exited with code $($exitCodeVar.Value)"
                }
            }
            catch {
                $taskSucceeded = $false
                Write-Output "Task $taskName failed: $($_.Exception.Message)"
                if ($_.ScriptStackTrace) {
                    Write-Output $_.ScriptStackTrace
                }
            }
            finally {
                $state[$stateKey] = (Get-Date).ToUniversalTime().ToString('o')
            }

            if ($taskSucceeded) {
                Write-Output "$taskName completed successfully."
            }
            else {
                Write-Output "$taskName recorded as failed (timestamp updated)."
            }
            Write-Output ''
        }
    }
    finally {
        Pop-Location
    }

    $orderedState = [ordered]@{}
    foreach ($k in $state.Keys) {
        $orderedState[$k] = $state[$k]
    }

    $stateJson = $orderedState | ConvertTo-Json -Depth 6
    $utf8NoBomWriter = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($statePath, $stateJson + [Environment]::NewLine, $utf8NoBomWriter)

    Write-Output "Scheduler finished at $(Get-Date -Format o)"
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
}
