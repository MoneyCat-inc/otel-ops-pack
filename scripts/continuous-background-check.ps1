param(
    [Parameter()]
    [ValidateRange(1, 1440)]
    [int]$VerifyIntervalMinutes = 15,

    [Parameter()]
    [ValidateRange(15, 600)]
    [int]$IdleSleepSeconds = 60,

    [Parameter()]
    [switch]$RunMonitor,

    [Parameter()]
    [string]$LogPath = "$PSScriptRoot/../artifacts/background-check.log",

    [Parameter()]
    [switch]$Once
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$logFullPath = [System.IO.Path]::GetFullPath($LogPath)
$logDir = Split-Path -Path $logFullPath -Parent
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$lockPath = Join-Path $repoRoot '.agent\LOCK'

function Write-LogEntry {
    param(
        [string]$Check,
        [string]$Status,
        [object]$Detail
    )

    $entry = [pscustomobject]@{
        timestamp = (Get-Date).ToUniversalTime().ToString('o')
        check     = $Check
        status    = $Status
        detail    = ($Detail | Out-String).Trim()
    } | ConvertTo-Json -Compress

    Add-Content -Path $logFullPath -Value $entry
    Write-Host $entry
}

function Invoke-Check {
    param(
        [string]$Name,
        [string]$ScriptPath
    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        Write-LogEntry -Check $Name -Status 'skipped' -Detail "Missing script at $ScriptPath"
        return
    }

    try {
        $output = & pwsh -NoProfile -File $ScriptPath 2>&1
        $status = if ($LASTEXITCODE -eq 0) { 'success' } else { 'failure' }
        Write-LogEntry -Check $Name -Status $status -Detail $output
    }
    catch {
        Write-LogEntry -Check $Name -Status 'failure' -Detail $_
    }
}

function Run-Iteration {
    if (Test-Path -LiteralPath $lockPath) {
        Write-LogEntry -Check 'background-loop' -Status 'paused' -Detail '.agent/LOCK present; sleeping'
        Start-Sleep -Seconds $IdleSleepSeconds
        return
    }

    $checks = @(
        @{ Name = 'verify-wiring'; Path = Join-Path $repoRoot 'scripts\verify-wiring.ps1'; Enabled = $true }
        @{ Name = 'monitor-analytics-ingestion'; Path = Join-Path $repoRoot 'scripts\monitor-analytics-ingestion.ps1'; Enabled = [bool]$RunMonitor }
    )

    foreach ($check in $checks) {
        if ($check.Enabled) {
            Invoke-Check -Name $check.Name -ScriptPath $check.Path
        }
    }
}

do {
    Run-Iteration

    if ($Once) {
        break
    }

    Start-Sleep -Seconds ($VerifyIntervalMinutes * 60)
} while ($true)
