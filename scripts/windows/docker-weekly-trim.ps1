<#
.SYNOPSIS
    Weekly, non-elevated Docker disk maintenance: conservative prune + fstrim.
.DESCRIPTION
    Prevents docker_data.vhdx regrowth (see docs/DOCKER_VHDX_MAINTENANCE.md):
    1. Prunes dangling images and build cache older than 7 days (never touches
       volumes, running containers, or tagged images).
    2. Runs fstrim inside the docker-desktop distro so freed ext4 blocks are
       returned to the VHDX layer. With sparse mode enabled on the VHDX this
       shrinks the host file immediately; without it, it keeps the file from
       growing past real usage and makes the next offline compact effective.
    3. Appends before/after sizes to artifacts/docker-trim-log.txt.

    Full offline compaction (elevated) remains scripts/shrink-docker-vhdx.ps1.
.PARAMETER Register
    Register a weekly scheduled task (Mon 09:00, current user) and exit.
.PARAMETER LogPath
    Log file (default: artifacts/docker-trim-log.txt under the repo root).
#>

[CmdletBinding()]
param(
    [switch]$Register,
    [string]$LogPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'artifacts\docker-trim-log.txt')
)

$ErrorActionPreference = 'Continue'
$vhdxPath = "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx"
$logFile = $LogPath

function Get-VhdxGB {
    if (Test-Path $vhdxPath) { [math]::Round((Get-Item $vhdxPath).Length / 1GB, 2) } else { 0 }
}

function Write-TrimLog {
    param([string]$Message, [string]$Path = $logFile)
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $Path -Value $line
}

if ($Register) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 09:00
    Register-ScheduledTask -TaskName 'OTel-Docker-Weekly-Trim' -Action $action `
        -Trigger $trigger -Description 'Weekly Docker prune + fstrim to prevent docker_data.vhdx bloat' -Force | Out-Null
    Write-Output "Registered scheduled task 'OTel-Docker-Weekly-Trim' (weekly, Mon 09:00)."
    exit 0
}

$before = Get-VhdxGB
Write-TrimLog "START vhdx=${before}GB"

# --- 1. Conservative prune (docker may be down; that's fine, fstrim still runs) ---
$engineUp = $false
try {
    $null = docker info --format '{{.ServerVersion}}' 2>$null
    if ($LASTEXITCODE -eq 0) { $engineUp = $true }
} catch {
    $engineUp = $false
}

if ($engineUp) {
    docker image prune -f 2>&1 | Out-Null
    docker builder prune -f --filter 'until=168h' 2>&1 | Out-Null
    Write-TrimLog "prune: done (dangling images + build cache >7d)"
} else {
    Write-TrimLog "prune: SKIPPED (docker engine not reachable)"
}

# --- 2. fstrim the data disk inside the docker-desktop distro ---
$trimOut = wsl -d docker-desktop fstrim -v /mnt/docker-desktop-disk 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-TrimLog ("fstrim: " + $trimOut.Trim())
} else {
    Write-TrimLog ("fstrim: FAILED - " + $trimOut.Trim())
}

# --- 3. Report ---
$after = Get-VhdxGB
Write-TrimLog "END vhdx=${after}GB (delta $([math]::Round($after - $before, 2))GB)"
if ($after -gt 200) {
    Write-TrimLog "WARN vhdx over 200GB - run scripts/shrink-docker-vhdx.ps1 (elevated) to compact"
}
