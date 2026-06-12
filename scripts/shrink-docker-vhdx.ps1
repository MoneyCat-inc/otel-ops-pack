#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Shrink Docker WSL VHDX by pruning unused data and compacting the disk.
.DESCRIPTION
    Reduces docker_data.vhdx size by:
    1. Pruning unused Docker images, containers, volumes, and build cache
    2. Quitting Docker Desktop and shutting down WSL
    3. Compacting the VHDX file (Optimize-VHD or diskpart)

    Preserves images/volumes in use by running containers.
    Target: ~50%+ reduction for a 200GB VHDX.
.PARAMETER VhdxPath
    Path to docker_data.vhdx (default: %LOCALAPPDATA%\Docker\wsl\disk\docker_data.vhdx)
.PARAMETER SkipPrune
    Skip Docker prune (only compact - use if you already pruned)
.PARAMETER Force
    Skip confirmation prompt
.PARAMETER AfterReboot
    Compact-only mode: skip Docker steps. Run immediately after reboot, BEFORE starting Docker.
    Use when the VHDX stays locked (e.g. by vmwp). Ensures no process has the file open.
#>

[CmdletBinding()]
param(
    [string]$VhdxPath = "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx",
    [switch]$SkipPrune,
    [switch]$Force,
    [switch]$AfterReboot
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Msg, [string]$Color = 'Cyan') Write-Host "`n$Msg" -ForegroundColor $Color }
function Write-Ok { param([string]$Msg) Write-Host "  OK: $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  WARN: $Msg" -ForegroundColor Yellow }

# Resolve path
$VhdxPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($VhdxPath)

if (-not (Test-Path $VhdxPath)) {
    Write-Host "VHDX not found: $VhdxPath" -ForegroundColor Red
    Write-Host "Check Docker Desktop WSL disk location (e.g. wsl\data\ext4.vhdx on older installs)" -ForegroundColor Yellow
    exit 1
}

$sizeBefore = (Get-Item $VhdxPath).Length
$sizeGB = [math]::Round($sizeBefore / 1GB, 2)
Write-Host "`n== Shrink Docker VHDX ==" -ForegroundColor Cyan
Write-Host "  Path: $VhdxPath"
Write-Host "  Current size: $sizeGB GB"
Write-Host "  Target: ~50% reduction"

if (-not $Force) {
    Write-Host "`nThis will:"
    Write-Host "  1. Remove unused Docker images, volumes, build cache (~60-90 GB typical)"
    Write-Host "  2. Quit Docker Desktop and shut down WSL"
    Write-Host "  3. Compact the VHDX file"
    Write-Host "`nRunning containers and their images/volumes will be preserved."
    $confirm = Read-Host "`nType YES to continue"
    if ($confirm -ne 'YES') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# --- 1. Docker prune ---
if ($AfterReboot) {
    Write-Step "1. AfterReboot mode: skipping Docker steps"
} elseif (-not $SkipPrune) {
    Write-Step "1. Pruning Docker (unused images, volumes, build cache)..."
    try {
        docker system df 2>$null | Out-Host
        docker system prune -a --volumes -f 2>&1 | Out-Host
        docker builder prune -a -f 2>&1 | Out-Host
        Write-Ok "Prune complete"
    }
    catch {
        Write-Warn "Prune failed or Docker not running: $_"
    }
}
else {
    Write-Step "1. Skipping prune (SkipPrune)"
}

# --- 2. Quit Docker Desktop ---
if ($AfterReboot) {
    Write-Step "2. AfterReboot: skipping (Docker not started)"
} else {
    Write-Step "2. Quitting Docker Desktop..."
    Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Ok "Docker Desktop stopped"
}

# --- 3. Shut down WSL ---
Write-Step "3. Shutting down WSL..."
wsl --shutdown
Write-Host "  Waiting 30s for WSL to release VHDX..." -ForegroundColor Gray
Start-Sleep -Seconds 30
# WSL/Hyper-V processes that can hold the VHDX lock
$wslProcs = @('vmwp', 'wslhost', 'wslservice', 'vmmem')
foreach ($proc in $wslProcs) {
    $p = Get-Process $proc -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host "  Stopping $proc.exe to release lock..." -ForegroundColor Gray
        $p | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
if (Get-Process vmwp, wslhost, wslservice, vmmem -ErrorAction SilentlyContinue) {
    Start-Sleep -Seconds 10
}
Write-Ok "WSL shut down"

# --- 4. Compact VHDX ---
Write-Step "4. Compacting VHDX (this may take several minutes)..."

$compactOk = $false

# Try Optimize-VHD (Windows Pro/Enterprise with Hyper-V), retry if file locked
if (Get-Command Optimize-VHD -ErrorAction SilentlyContinue) {
    foreach ($attempt in 1..3) {
        try {
            Optimize-VHD -Path $VhdxPath -Mode Full
            $compactOk = $true
            Write-Ok "Optimize-VHD completed"
            break
        } catch {
            Write-Warn "Optimize-VHD attempt $attempt failed: $_"
            if ($attempt -lt 3) {
                Write-Host "  Waiting 30s before retry..." -ForegroundColor Gray
                Start-Sleep -Seconds 30
            }
        }
    }
}

# Fallback: diskpart (works on Windows Home)
if (-not $compactOk) {
    $diskpartScript = "select vdisk file=`"$VhdxPath`"`nattach vdisk readonly`ncompact vdisk`ndetach vdisk`nexit`n"
    $scriptPath = Join-Path $env:TEMP "diskpart_shrink_$(Get-Random).txt"
    [System.IO.File]::WriteAllText($scriptPath, $diskpartScript, [System.Text.Encoding]::ASCII)
    try {
        diskpart /s $scriptPath
        $compactOk = $true
        Write-Ok "diskpart compact completed"
    }
    catch {
        Write-Warn "diskpart compact failed: $_"
    }
    finally {
        Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

if (-not $compactOk) {
    Write-Host "  Failed to compact VHDX (file locked). Try:" -ForegroundColor Yellow
    Write-Host "  1. Reboot, then run BEFORE starting Docker:" -ForegroundColor Gray
    Write-Host "     .\shrink-docker-vhdx.ps1 -AfterReboot -Force" -ForegroundColor Gray
    Write-Host "  2. Or run manually as Admin after reboot: Optimize-VHD -Path '$VhdxPath' -Mode Full" -ForegroundColor Gray
}

# --- Summary ---
$sizeAfter = (Get-Item $VhdxPath).Length
$sizeAfterGB = [math]::Round($sizeAfter / 1GB, 2)
$freedGB = [math]::Round(($sizeBefore - $sizeAfter) / 1GB, 2)
$pct = if ($sizeBefore -gt 0) { [math]::Round(100 * ($sizeBefore - $sizeAfter) / $sizeBefore, 1) } else { 0 }

Write-Host "`n== Result ==" -ForegroundColor Cyan
Write-Host "  Before: $sizeGB GB"
Write-Host "  After:  $sizeAfterGB GB"
Write-Host "  Freed:  $freedGB GB ($pct% reduction)" -ForegroundColor $(if ($pct -ge 50) { 'Green' } else { 'Yellow' })
Write-Host "`nStart Docker Desktop to resume. VHDX will grow again as you use Docker." -ForegroundColor Cyan
