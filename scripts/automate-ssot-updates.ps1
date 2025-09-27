# Automate SSOT Generator After Telemetry Updates
# ECRR Compliance: Examine → Clean → Report → Role

param(
    [string]$TelemetrySource = "artifacts/ssot-telemetry-summary.json",
    [string]$WatchInterval = "30",
    [switch]$Continuous = $false,
    [switch]$DryRun = $false
)

# ECRR: Examine - Current State
Write-Host "🔍 SSOT Automation - Examine Current State" -ForegroundColor Cyan
Write-Host "Telemetry Source: $TelemetrySource" -ForegroundColor Gray
Write-Host "Watch Interval: $WatchInterval seconds" -ForegroundColor Gray
Write-Host "Continuous Mode: $Continuous" -ForegroundColor Gray
Write-Host "Dry Run: $DryRun" -ForegroundColor Gray

# Check if telemetry source exists
if (-not (Test-Path $TelemetrySource)) {
    Write-Warning "Telemetry source not found: $TelemetrySource"
    Write-Host "Creating sample telemetry summary..." -ForegroundColor Yellow
    
    # Create sample telemetry summary
    $sampleData = @{
        jobsProcessed = 0
        jobsFailed = 0
        queueDepthMax = 0
        flakyActive = 0
        rehabilitated7d = 0
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        source = "automation-sample"
    } | ConvertTo-Json -Depth 3
    
    $sampleData | Out-File -FilePath $TelemetrySource -Encoding UTF8
    Write-Host "✅ Sample telemetry summary created" -ForegroundColor Green
}

# Track file modification times
$lastModified = (Get-Item $TelemetrySource).LastWriteTime
$lastSSOTUpdate = if (Test-Path ".artifacts/SSOT.md") { (Get-Item ".artifacts/SSOT.md").LastWriteTime } else { [DateTime]::MinValue }

Write-Host "Last telemetry update: $lastModified" -ForegroundColor Gray
Write-Host "Last SSOT update: $lastSSOTUpdate" -ForegroundColor Gray

# ECRR: Clean - Automation Logic
function Update-SSOTBlock {
    param([string]$Reason)
    
    Write-Host "🔄 Updating SSOT block - Reason: $Reason" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would execute: node scripts/ci-ssot-telemetry.ts" -ForegroundColor Magenta
        return $true
    }
    
    try {
        # Run SSOT generator
        $output = & node scripts/ci-ssot-telemetry.ts 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ SSOT block updated successfully" -ForegroundColor Green
            Write-Host "Output: $output" -ForegroundColor Gray
            return $true
        } else {
            Write-Warning "SSOT generator failed with exit code: $exitCode"
            Write-Host "Error output: $output" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Error "Failed to update SSOT block: $($_.Exception.Message)"
        return $false
    }
}

function Check-TelemetryChanges {
    $currentModified = (Get-Item $TelemetrySource).LastWriteTime
    
    if ($currentModified -gt $lastModified) {
        Write-Host "📊 Telemetry source updated: $currentModified" -ForegroundColor Cyan
        $script:lastModified = $currentModified
        return $true
    }
    
    return $false
}

function Check-SSOTFreshness {
    if (-not (Test-Path ".artifacts/SSOT.md")) {
        Write-Host "⚠️ SSOT block missing" -ForegroundColor Yellow
        return $false
    }
    
    $ssotAge = (Get-Date) - (Get-Item ".artifacts/SSOT.md").LastWriteTime
    $maxAge = [TimeSpan]::FromMinutes(60)  # 1 hour max age
    
    if ($ssotAge -gt $maxAge) {
        Write-Host "⚠️ SSOT block is stale (age: $($ssotAge.TotalMinutes.ToString('F1')) minutes)" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "✅ SSOT block is fresh (age: $($ssotAge.TotalMinutes.ToString('F1')) minutes)" -ForegroundColor Green
    return $true
}

# ECRR: Report - Automation Results
function Generate-AutomationReport {
    param(
        [int]$UpdatesCount,
        [int]$ErrorsCount,
        [string]$Status
    )
    
    $report = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        automation = @{
            updates_count = $UpdatesCount
            errors_count = $ErrorsCount
            status = $Status
            telemetry_source = $TelemetrySource
            watch_interval = $WatchInterval
            continuous_mode = $Continuous
            dry_run = $DryRun
        }
        ssot_status = @{
            block_exists = (Test-Path ".artifacts/SSOT.md")
            block_fresh = Check-SSOTFreshness
            last_update = if (Test-Path ".artifacts/SSOT.md") { (Get-Item ".artifacts/SSOT.md").LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }
        }
        telemetry_status = @{
            source_exists = (Test-Path $TelemetrySource)
            last_modified = (Get-Item $TelemetrySource).LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
    
    $reportPath = ".artifacts/ssot-automation-report.json"
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "📊 Automation report saved: $reportPath" -ForegroundColor Cyan
    return $reportPath
}

# Main automation loop
Write-Host "🚀 Starting SSOT automation..." -ForegroundColor Green

$updatesCount = 0
$errorsCount = 0
$status = "running"

try {
    # Initial SSOT update if needed
    if (-not (Check-SSOTFreshness)) {
        if (Update-SSOTBlock "Initial update - SSOT missing or stale") {
            $updatesCount++
        } else {
            $errorsCount++
        }
    }
    
    if ($Continuous) {
        Write-Host "🔄 Continuous mode enabled - watching for changes..." -ForegroundColor Cyan
        
        while ($true) {
            Start-Sleep -Seconds $WatchInterval
            
            if (Check-TelemetryChanges) {
                if (Update-SSOTBlock "Telemetry source updated") {
                    $updatesCount++
                } else {
                    $errorsCount++
                }
            }
            
            # Periodic freshness check
            if (-not (Check-SSOTFreshness)) {
                if (Update-SSOTBlock "Periodic freshness check") {
                    $updatesCount++
                } else {
                    $errorsCount++
                }
            }
            
            # Progress indicator
            Write-Host "⏰ $(Get-Date -Format 'HH:mm:ss') - Updates: $updatesCount, Errors: $errorsCount" -ForegroundColor Gray
        }
    } else {
        # Single run mode
        if (Check-TelemetryChanges) {
            if (Update-SSOTBlock "Single run - telemetry changed") {
                $updatesCount++
            } else {
                $errorsCount++
            }
        }
        
        $status = "completed"
    }
}
catch {
    Write-Error "Automation failed: $($_.Exception.Message)"
    $errorsCount++
    $status = "failed"
}
finally {
    # Generate final report
    $reportPath = Generate-AutomationReport -UpdatesCount $updatesCount -ErrorsCount $errorsCount -Status $status
    
    Write-Host "📋 SSOT Automation Summary" -ForegroundColor Cyan
    Write-Host "Updates: $updatesCount" -ForegroundColor Green
    Write-Host "Errors: $errorsCount" -ForegroundColor $(if ($errorsCount -eq 0) { "Green" } else { "Red" })
    Write-Host "Status: $status" -ForegroundColor $(if ($status -eq "completed") { "Green" } else { "Yellow" })
    Write-Host "Report: $reportPath" -ForegroundColor Gray
}

# ECRR: Role - Actor Declaration
Write-Host "🎭 SSOT Automation Complete" -ForegroundColor Magenta
Write-Host "Actor: Cursor Agent (Observability Copilot)" -ForegroundColor Gray
Write-Host "Role: Automated SSOT updates after telemetry changes" -ForegroundColor Gray
