<#
.SYNOPSIS
    Ensure the SigNoz compose stack is up after Docker Desktop restarts.
.DESCRIPTION
    Docker Desktop on Windows often leaves containers stopped after an engine
    restart even with compose restart policies. This script waits for the
    Docker engine, then runs `docker compose up -d` on the repo root stack.

    Idempotent: safe to run when already healthy.
.PARAMETER Register
    Register a logon scheduled task (current user) and exit.
.PARAMETER Unregister
    Remove the logon scheduled task (current user) and exit. This is the kill switch.
.PARAMETER TimeoutSeconds
    Max seconds to wait for the Docker engine (default: 180).
.NOTES
    Recurring writer registration (docs/PURPOSE.md: owner, review date, kill switch):
      Owner:       @fubumaki (machine operator)
      Task:        OTel-Ensure-SigNoz-Stack (AtLogOn, current user, 10 min limit)
      Writes:      logs/ensure-signoz-stack.log inside the checkout (gitignored)
      Review:      2026-12-20 (quarterly cadence; PR #794 review thread)
      Kill switch: pwsh -File scripts/windows/ensure-signoz-stack.ps1 -Unregister
    Exit test at review: every logon entry in the log reads "already up" under
    restart: always -> the task has proven redundant, unregister it. Any entry
    that reads "started" -> the compose comment on unless-stopped is wrong;
    keep the task and correct the comment.
#>

[CmdletBinding()]
param(
    [switch]$Register,
    [switch]$Unregister,
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$composeFile = Join-Path $repoRoot 'docker-compose.yml'
$taskName = 'OTel-Ensure-SigNoz-Stack'
$logDir = Join-Path $repoRoot 'logs'
$logFile = Join-Path $logDir 'ensure-signoz-stack.log'

function Write-EnsureLog {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $line -Encoding utf8
}

if ($Unregister) {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-EnsureLog "Unregistered scheduled task: $taskName"
    } else {
        Write-EnsureLog "Scheduled task not present: $taskName (nothing to unregister)"
    }
    exit 0
}

if ($Register) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" `
        -WorkingDirectory $repoRoot
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
        -Settings $settings -Principal $principal `
        -Description 'Bring SigNoz/OTel compose stack up after logon / Docker Desktop restart' `
        -Force | Out-Null
    Write-EnsureLog "Registered scheduled task: $taskName (AtLogOn)"
    exit 0
}

if (-not (Test-Path $composeFile)) {
    Write-EnsureLog "ERROR: compose file missing: $composeFile"
    exit 1
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
Write-EnsureLog "Waiting for Docker engine (timeout ${TimeoutSeconds}s)..."
while ((Get-Date) -lt $deadline) {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 5
}
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-EnsureLog 'ERROR: Docker engine not ready'
    exit 2
}

$before = @(docker ps --filter 'name=signoz' --format '{{.Names}}' 2>$null)
Write-EnsureLog "Running docker compose up -d ($composeFile); signoz containers running before: $($before.Count)"
Push-Location $repoRoot
try {
    docker compose -f $composeFile up -d 2>&1 | ForEach-Object { Write-EnsureLog "  $_" }
    $exit = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($exit -ne 0) {
    Write-EnsureLog "ERROR: compose up failed (exit $exit)"
    exit $exit
}

$running = @(docker ps --filter 'name=signoz' --format '{{.Names}}' 2>$null)
$verdict = if ($running.Count -gt $before.Count) { 'started' } else { 'already up' }
Write-EnsureLog ("OK ({0}): signoz containers running: {1}" -f $verdict, ($running -join ', '))
exit 0
