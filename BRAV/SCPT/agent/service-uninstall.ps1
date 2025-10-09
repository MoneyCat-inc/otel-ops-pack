# scripts/agent/service-uninstall.ps1 - Uninstall codex-local Windows Service

param(
    [string]$ServiceName = "codex-local",
    [string]$NssmPath = "$PSScriptRoot\nssm.exe",
    [switch]$Force,
    [switch]$KeepLogs
)

$ErrorActionPreference = "Stop"

function Write-ServiceResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

Write-Host "🗑️ codex-local Windows Service Uninstallation" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ServiceResult -Message "Administrator privileges required for service uninstallation" -Success $false
    exit 1
}

# Check if service exists
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $existingService) {
    Write-ServiceResult -Message "Service '$ServiceName' not found"
    exit 0
}

# Check if NSSM is available
if (-not (Test-Path $NssmPath)) {
    Write-ServiceResult -Message "NSSM not found at $NssmPath" -Success $false
    Write-Host "Please download NSSM from: https://nssm.cc/download" -ForegroundColor Yellow
    exit 1
}

# Get service info before removal
$serviceInfoPath = ".agent/service-info.json"
$serviceInfo = $null
if (Test-Path $serviceInfoPath) {
    try {
        $serviceInfo = Get-Content $serviceInfoPath -Raw | ConvertFrom-Json
        Write-ServiceResult -Message "Service info loaded from: $serviceInfoPath"
    } catch {
        Write-Host "Warning: Could not load service info" -ForegroundColor Yellow
    }
}

# Stop service
Write-Host "`n🛑 Stopping service..." -ForegroundColor Yellow
try {
    if ($existingService.Status -eq "Running") {
        Stop-Service -Name $ServiceName -Force
        Write-ServiceResult -Message "Service stopped"
        
        # Wait for service to stop
        $timeout = 30
        $elapsed = 0
        while ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue).Status -eq "Running" -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 1
            $elapsed++
        }
        
        if ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue).Status -eq "Running") {
            Write-ServiceResult -Message "Service did not stop within $timeout seconds" -Success $false
            if (-not $Force) {
                exit 1
            }
        } else {
            Write-ServiceResult -Message "Service stopped successfully"
        }
    } else {
        Write-ServiceResult -Message "Service was not running"
    }
} catch {
    Write-ServiceResult -Message "Failed to stop service: $($_.Exception.Message)" -Success $false
    if (-not $Force) {
        exit 1
    }
}

# Remove service
Write-Host "`n🗑️ Removing service..." -ForegroundColor Yellow
try {
    & $NssmPath remove $ServiceName confirm
    Write-ServiceResult -Message "Service removed successfully"
} catch {
    Write-ServiceResult -Message "Failed to remove service: $($_.Exception.Message)" -Success $false
    if (-not $Force) {
        exit 1
    }
}

# Clean up service info
if (Test-Path $serviceInfoPath) {
    Remove-Item $serviceInfoPath -Force
    Write-ServiceResult -Message "Service info file removed"
}

# Clean up log files (unless KeepLogs is specified)
if (-not $KeepLogs -and $serviceInfo) {
    $logDir = Split-Path $serviceInfo.logFiles.stdout -Parent
    if (Test-Path $logDir) {
        Write-Host "`n🧹 Cleaning up log files..." -ForegroundColor Yellow
        Remove-Item $logDir -Recurse -Force
        Write-ServiceResult -Message "Log files removed from: $logDir"
    }
} elseif ($KeepLogs) {
    Write-Host "`n📝 Log files preserved (use -KeepLogs to keep them)" -ForegroundColor Yellow
}

# Clean up .agent/WATCHDOG.PID if it exists
$pidFile = ".agent/WATCHDOG.PID"
if (Test-Path $pidFile) {
    Remove-Item $pidFile -Force
    Write-ServiceResult -Message "Watchdog PID file removed"
}

Write-Host "`n🎉 Service Uninstallation Complete" -ForegroundColor Green
Write-Host "Service '$ServiceName' has been removed" -ForegroundColor Gray

if ($KeepLogs -and $serviceInfo) {
    Write-Host "`nLog files preserved at:" -ForegroundColor Cyan
    Write-Host "  $($serviceInfo.logFiles.stdout)" -ForegroundColor Gray
    Write-Host "  $($serviceInfo.logFiles.stderr)" -ForegroundColor Gray
}

Write-Host "`nVerification:" -ForegroundColor Cyan
$verification = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($verification) {
    Write-ServiceResult -Message "WARNING: Service still exists after removal" -Success $false
} else {
    Write-ServiceResult -Message "Service successfully removed"
}
