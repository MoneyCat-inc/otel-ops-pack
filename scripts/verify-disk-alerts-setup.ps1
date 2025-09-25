#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080'
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[Verify] $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "[Verify] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[Verify] $Message" -ForegroundColor Red }
function Write-Success { param([string]$Message) Write-Host "[Verify] $Message" -ForegroundColor Green }

Write-Info "Verifying disk alerts and monitoring setup"

$allTestsPassed = $true

# Test 1: SigNoz Health
Write-Info "Test 1: Checking SigNoz health"
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.status -eq 'ok') {
        Write-Success "✓ SigNoz is healthy"
    } else {
        Write-ErrorMsg "✗ SigNoz health check failed: $($healthResponse.status)"
        $allTestsPassed = $false
    }
} catch {
    Write-ErrorMsg "✗ Cannot connect to SigNoz: $($_.Exception.Message)"
    $allTestsPassed = $false
}

# Test 2: Disk Monitoring Script
Write-Info "Test 2: Testing disk monitoring script"
try {
    $result = & 'C:/otel/scripts/monitor-disk-usage.ps1'
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Disk monitoring script executed successfully"
        Write-Host "  Output: $result" -ForegroundColor Gray
    } else {
        Write-ErrorMsg "✗ Disk monitoring script failed with exit code: $LASTEXITCODE"
        $allTestsPassed = $false
    }
} catch {
    Write-ErrorMsg "✗ Disk monitoring script error: $($_.Exception.Message)"
    $allTestsPassed = $false
}

# Test 3: Log File Generation
Write-Info "Test 3: Verifying log file generation"
$logFile = 'C:/logs/disk-monitor/disk-usage.log'
if (Test-Path $logFile) {
    $lastEntry = Get-Content $logFile -Tail 1
    if ($lastEntry) {
        try {
            $logData = $lastEntry | ConvertFrom-Json
            if ($logData.dataset -eq 'disk-monitor' -and $logData.status -eq 'ok') {
                Write-Success "✓ Log file contains valid disk monitoring data"
                Write-Host "  Drive: $($logData.drive)" -ForegroundColor Gray
                Write-Host "  Usage: $($logData.percent_used)%" -ForegroundColor Gray
                Write-Host "  Status: $($logData.status)" -ForegroundColor Gray
            } else {
                Write-ErrorMsg "✗ Log file contains invalid data structure"
                $allTestsPassed = $false
            }
        } catch {
            Write-ErrorMsg "✗ Log file contains invalid JSON: $($_.Exception.Message)"
            $allTestsPassed = $false
        }
    } else {
        Write-ErrorMsg "✗ Log file is empty"
        $allTestsPassed = $false
    }
} else {
    Write-ErrorMsg "✗ Log file not found: $logFile"
    $allTestsPassed = $false
}

# Test 4: Windows Event Log
Write-Info "Test 4: Checking Windows Event Log entries"
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='DiskUsageMonitor';StartTime=(Get-Date).AddMinutes(-10)} -ErrorAction SilentlyContinue
    if ($events) {
        $latestEvent = $events | Select-Object -First 1
        Write-Success "✓ Windows Event Log contains disk monitoring entries"
        Write-Host "  Latest EventID: $($latestEvent.Id)" -ForegroundColor Gray
        Write-Host "  Time: $($latestEvent.TimeCreated)" -ForegroundColor Gray
    } else {
        Write-Warn "⚠ No recent disk monitoring events found in Windows Event Log"
    }
} catch {
    Write-ErrorMsg "✗ Error checking Windows Event Log: $($_.Exception.Message)"
    $allTestsPassed = $false
}

# Test 5: Scheduled Task
Write-Info "Test 5: Verifying scheduled task"
try {
    $taskInfo = Get-ScheduledTaskInfo -TaskName 'DiskUsageMonitor' -ErrorAction SilentlyContinue
    if ($taskInfo) {
        if ($taskInfo.LastTaskResult -eq 0) {
            Write-Success "✓ Scheduled task is running successfully"
            Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
            Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
            Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor Gray
        } else {
            Write-Warn "⚠ Scheduled task last run failed with result: $($taskInfo.LastTaskResult)"
        }
    } else {
        Write-ErrorMsg "✗ Scheduled task 'DiskUsageMonitor' not found"
        $allTestsPassed = $false
    }
} catch {
    Write-ErrorMsg "✗ Error checking scheduled task: $($_.Exception.Message)"
    $allTestsPassed = $false
}

# Test 6: SigNoz Log Ingestion (Basic Check)
Write-Info "Test 6: Checking SigNoz log ingestion capability"
try {
    # This is a basic check - in a real scenario you'd query the SigNoz API
    # For now, we'll just verify the collector is configured to ingest the logs
    $configPath = 'C:/otel/config.yaml'
    if (Test-Path $configPath) {
        $configContent = Get-Content $configPath -Raw
        if ($configContent -match 'C:/logs/\*\*/\*\.log') {
            Write-Success "✓ OTel collector configured to ingest disk monitoring logs"
        } else {
            Write-Warn "⚠ OTel collector may not be configured for disk monitoring logs"
        }
    } else {
        Write-ErrorMsg "✗ OTel collector config not found: $configPath"
        $allTestsPassed = $false
    }
} catch {
    Write-ErrorMsg "✗ Error checking OTel configuration: $($_.Exception.Message)"
    $allTestsPassed = $false
}

# Summary
Write-Host ""
if ($allTestsPassed) {
    Write-Success "🎉 All disk monitoring tests passed!"
    Write-Host ""
    Write-Info "Next steps to complete setup:"
    Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor Yellow
    Write-Host "2. Go to Alerts → Manually create the 3 disk alerts from the configuration" -ForegroundColor Yellow
    Write-Host "3. Go to Logs → Create saved view with filter: attributes.dataset = \"disk-monitor\"" -ForegroundColor Yellow
    Write-Host "4. Test alerts by monitoring disk usage trends" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "Manual SigNoz Setup Required:"
    Write-Host "- The import script provided the alert configurations" -ForegroundColor Gray
    Write-Host "- You need to manually create alerts in SigNoz UI using the provided queries" -ForegroundColor Gray
    Write-Host "- See SIGNOZ_DISK_ALERTS_SETUP_GUIDE.md for detailed instructions" -ForegroundColor Gray
} else {
    Write-ErrorMsg "❌ Some tests failed. Please review the errors above."
    exit 1
}
