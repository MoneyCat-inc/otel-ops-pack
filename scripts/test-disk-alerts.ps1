#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$TestWarning,
    [switch]$TestCritical,
    [switch]$RestoreDefaults,
    [string]$BackupFile = 'scripts/monitor-disk-usage.ps1.backup'
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[TestAlerts] $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "[TestAlerts] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[TestAlerts] $Message" -ForegroundColor Red }
function Write-Success { param([string]$Message) Write-Host "[TestAlerts] $Message" -ForegroundColor Green }

$scriptPath = 'scripts/monitor-disk-usage.ps1'

if ($RestoreDefaults) {
    Write-Info "Restoring original disk monitoring script"
    if (Test-Path $BackupFile) {
        Copy-Item $BackupFile $scriptPath -Force
        Write-Success "✓ Original script restored"
        
        # Test with restored script
        Write-Info "Testing with restored thresholds..."
        & $scriptPath
        Write-Success "✓ Script working with default thresholds (80%/90%)"
    } else {
        Write-ErrorMsg "✗ Backup file not found: $BackupFile"
        exit 1
    }
    exit 0
}

# Get current disk usage
Write-Info "Checking current disk usage..."
try {
    $currentLog = Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1 | ConvertFrom-Json
    $currentUsage = $currentLog.percent_used
    Write-Info "Current disk usage: $currentUsage%"
} catch {
    Write-ErrorMsg "Could not read current disk usage"
    exit 1
}

if ($TestWarning -and $currentUsage -lt 80) {
    Write-Info "Testing warning alert (current usage: $currentUsage%)"
    
    # Create backup if it doesn't exist
    if (-not (Test-Path $BackupFile)) {
        Copy-Item $scriptPath $BackupFile
        Write-Success "✓ Created backup: $BackupFile"
    }
    
    # Modify warning threshold to trigger alert
    $newWarningThreshold = [math]::Max(1, $currentUsage - 5)  # 5% below current usage
    Write-Info "Temporarily setting warning threshold to: $newWarningThreshold%"
    
    $scriptContent = Get-Content $scriptPath -Raw
    $modifiedContent = $scriptContent -replace '\[int\]\$WarningPercent = 80', "[int]`$WarningPercent = $newWarningThreshold"
    
    if ($modifiedContent -ne $scriptContent) {
        $modifiedContent | Set-Content $scriptPath -Encoding UTF8
        Write-Success "✓ Warning threshold modified to $newWarningThreshold%"
        
        # Run the modified script
        Write-Info "Running disk monitoring with modified threshold..."
        & $scriptPath
        
        if ($LASTEXITCODE -eq 1) {
            Write-Success "✓ Warning alert triggered! (Exit code: 1)"
            Write-Info "Check SigNoz Alerts for the warning notification"
        } else {
            Write-Warn "⚠ Warning alert not triggered (Exit code: $LASTEXITCODE)"
        }
        
        Write-Info ""
        Write-Warn "IMPORTANT: Run with -RestoreDefaults to restore original thresholds"
        Write-Host "Command: pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults" -ForegroundColor Yellow
    } else {
        Write-ErrorMsg "Failed to modify warning threshold"
    }
}
elseif ($TestCritical -and $currentUsage -lt 90) {
    Write-Info "Testing critical alert (current usage: $currentUsage%)"
    
    # Create backup if it doesn't exist
    if (-not (Test-Path $BackupFile)) {
        Copy-Item $scriptPath $BackupFile
        Write-Success "✓ Created backup: $BackupFile"
    }
    
    # Modify critical threshold to trigger alert
    $newCriticalThreshold = [math]::Max(1, $currentUsage - 5)  # 5% below current usage
    Write-Info "Temporarily setting critical threshold to: $newCriticalThreshold%"
    
    $scriptContent = Get-Content $scriptPath -Raw
    $modifiedContent = $scriptContent -replace '\[int\]\$CriticalPercent = 90', "[int]`$CriticalPercent = $newCriticalThreshold"
    
    if ($modifiedContent -ne $scriptContent) {
        $modifiedContent | Set-Content $scriptPath -Encoding UTF8
        Write-Success "✓ Critical threshold modified to $newCriticalThreshold%"
        
        # Run the modified script
        Write-Info "Running disk monitoring with modified threshold..."
        & $scriptPath
        
        if ($LASTEXITCODE -eq 2) {
            Write-Success "✓ Critical alert triggered! (Exit code: 2)"
            Write-Info "Check SigNoz Alerts for the critical notification"
        } else {
            Write-Warn "⚠ Critical alert not triggered (Exit code: $LASTEXITCODE)"
        }
        
        Write-Info ""
        Write-Warn "IMPORTANT: Run with -RestoreDefaults to restore original thresholds"
        Write-Host "Command: pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults" -ForegroundColor Yellow
    } else {
        Write-ErrorMsg "Failed to modify critical threshold"
    }
}
else {
    Write-Info "Current disk usage: $currentUsage%"
    Write-Info "Available test options:"
    Write-Host ""
    Write-Host "Test Warning Alert:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/test-disk-alerts.ps1 -TestWarning" -ForegroundColor Yellow
    Write-Host "  (Temporarily lowers warning threshold to trigger alert)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Test Critical Alert:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/test-disk-alerts.ps1 -TestCritical" -ForegroundColor Yellow
    Write-Host "  (Temporarily lowers critical threshold to trigger alert)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Restore Original Thresholds:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults" -ForegroundColor Yellow
    Write-Host "  (Restores 80%/90% thresholds)" -ForegroundColor Gray
    Write-Host ""
    
    if ($currentUsage -ge 80) {
        Write-Warn "⚠ Current usage ($currentUsage%) is already at or above warning threshold (80%)"
        Write-Info "Warning alerts should already be triggering"
    }
    if ($currentUsage -ge 90) {
        Write-Warn "⚠ Current usage ($currentUsage%) is already at or above critical threshold (90%)"
        Write-Info "Critical alerts should already be triggering"
    }
    
    Write-Info ""
    Write-Info "Check SigNoz UI for current alert status:"
    Write-Host "  Alerts: http://localhost:8080/alerts" -ForegroundColor Yellow
    Write-Host "  Logs: http://localhost:8080/logs (filter: attributes.dataset = \"disk-monitor\")" -ForegroundColor Yellow
}
