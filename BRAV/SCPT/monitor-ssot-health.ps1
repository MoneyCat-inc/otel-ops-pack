# SSOT Health Monitoring - Freshness and Accuracy
# ECRR Compliance: Examine → Clean → Report → Role

param(
    [string]$SSOTPath = ".artifacts/SSOT.md",
    [string]$TelemetryPath = "artifacts/ssot-telemetry-summary.json",
    [string]$RunbookPath = "RUN_AND_VERIFY.md",
    [int]$MaxAgeMinutes = 60,
    [switch]$Detailed = $false,
    [switch]$ExportMetrics = $false
)

# ECRR: Examine - Current State
Write-Host "🔍 SSOT Health Monitoring - Examine Current State" -ForegroundColor Cyan
Write-Host "SSOT Path: $SSOTPath" -ForegroundColor Gray
Write-Host "Telemetry Path: $TelemetryPath" -ForegroundColor Gray
Write-Host "Runbook Path: $RunbookPath" -ForegroundColor Gray
Write-Host "Max Age: $MaxAgeMinutes minutes" -ForegroundColor Gray

# Check file existence
$ssotExists = Test-Path $SSOTPath
$telemetryExists = Test-Path $TelemetryPath
$runbookExists = Test-Path $RunbookPath

Write-Host "SSOT exists: $ssotExists" -ForegroundColor $(if ($ssotExists) { "Green" } else { "Red" })
Write-Host "Telemetry exists: $telemetryExists" -ForegroundColor $(if ($telemetryExists) { "Green" } else { "Red" })
Write-Host "Runbook exists: $runbookExists" -ForegroundColor $(if ($runbookExists) { "Green" } else { "Red" })

# ECRR: Clean - Health Checks
function Test-SSOTFreshness {
    param([string]$Path, [int]$MaxAgeMinutes)
    
    if (-not (Test-Path $Path)) {
        return @{
            is_fresh = $false
            age_minutes = $null
            last_modified = $null
            status = "missing"
        }
    }
    
    $lastModified = (Get-Item $Path).LastWriteTime
    $age = (Get-Date) - $lastModified
    $ageMinutes = [math]::Round($age.TotalMinutes, 1)
    $isFresh = $ageMinutes -le $MaxAgeMinutes
    
    return @{
        is_fresh = $isFresh
        age_minutes = $ageMinutes
        last_modified = $lastModified.ToString("yyyy-MM-ddTHH:mm:ssZ")
        status = if ($isFresh) { "fresh" } else { "stale" }
    }
}

function Test-SSOTAccuracy {
    param([string]$SSOTPath, [string]$TelemetryPath)
    
    if (-not (Test-Path $SSOTPath) -or -not (Test-Path $TelemetryPath)) {
        return @{
            is_accurate = $false
            mismatches = @()
            status = "missing_files"
        }
    }
    
    try {
        # Read SSOT content
        $ssotContent = Get-Content $SSOTPath -Raw
        
        # Extract values from SSOT block
        $ssotJobs = if ($ssotContent -match "Jobs processed:\s*\*\*(\d+)\*\*") { [int]$matches[1] } else { $null }
        $ssotFailed = if ($ssotContent -match "Jobs failed:\s*\*\*(\d+)\*\*") { [int]$matches[1] } else { $null }
        $ssotQueue = if ($ssotContent -match "Queue depth \(max\):\s*\*\*(\d+)\*\*") { [int]$matches[1] } else { $null }
        $ssotFlaky = if ($ssotContent -match "Flaky tests \(active\):\s*\*\*(\d+)\*\*") { [int]$matches[1] } else { $null }
        $ssotRehab = if ($ssotContent -match "Rehabilitated \(last 7d\):\s*\*\*(\d+)\*\*") { [int]$matches[1] } else { $null }
        
        # Read telemetry JSON
        $telemetryJson = Get-Content $TelemetryPath -Raw | ConvertFrom-Json
        
        # Compare values
        $mismatches = @()
        
        if ($ssotJobs -ne $telemetryJson.jobsProcessed) {
            $mismatches += "Jobs processed: SSOT=$ssotJobs, JSON=$($telemetryJson.jobsProcessed)"
        }
        
        if ($ssotFailed -ne $telemetryJson.jobsFailed) {
            $mismatches += "Jobs failed: SSOT=$ssotFailed, JSON=$($telemetryJson.jobsFailed)"
        }
        
        if ($ssotQueue -ne $telemetryJson.queueDepthMax) {
            $mismatches += "Queue depth: SSOT=$ssotQueue, JSON=$($telemetryJson.queueDepthMax)"
        }
        
        if ($ssotFlaky -ne $telemetryJson.flakyActive) {
            $mismatches += "Flaky tests: SSOT=$ssotFlaky, JSON=$($telemetryJson.flakyActive)"
        }
        
        if ($ssotRehab -ne $telemetryJson.rehabilitated7d) {
            $mismatches += "Rehabilitated: SSOT=$ssotRehab, JSON=$($telemetryJson.rehabilitated7d)"
        }
        
        return @{
            is_accurate = $mismatches.Count -eq 0
            mismatches = $mismatches
            status = if ($mismatches.Count -eq 0) { "accurate" } else { "mismatch" }
            ssot_values = @{
                jobs_processed = $ssotJobs
                jobs_failed = $ssotFailed
                queue_depth_max = $ssotQueue
                flaky_active = $ssotFlaky
                rehabilitated_7d = $ssotRehab
            }
            telemetry_values = @{
                jobs_processed = $telemetryJson.jobsProcessed
                jobs_failed = $telemetryJson.jobsFailed
                queue_depth_max = $telemetryJson.queueDepthMax
                flaky_active = $telemetryJson.flakyActive
                rehabilitated_7d = $telemetryJson.rehabilitated7d
            }
        }
    }
    catch {
        return @{
            is_accurate = $false
            mismatches = @("Error parsing files: $($_.Exception.Message)")
            status = "parse_error"
        }
    }
}

function Test-SSOTIntegration {
    param([string]$RunbookPath)
    
    if (-not (Test-Path $RunbookPath)) {
        return @{
            is_integrated = $false
            has_ssot_block = $false
            status = "runbook_missing"
        }
    }
    
    try {
        $runbookContent = Get-Content $RunbookPath -Raw
        $hasSSOTBlock = $runbookContent -match "<!-- SSOT:BEGIN -->"
        
        return @{
            is_integrated = $hasSSOTBlock
            has_ssot_block = $hasSSOTBlock
            status = if ($hasSSOTBlock) { "integrated" } else { "not_integrated" }
        }
    }
    catch {
        return @{
            is_integrated = $false
            has_ssot_block = $false
            status = "parse_error"
        }
    }
}

# Run health checks
Write-Host "🔍 Running SSOT health checks..." -ForegroundColor Yellow

$freshnessCheck = Test-SSOTFreshness -Path $SSOTPath -MaxAgeMinutes $MaxAgeMinutes
$accuracyCheck = Test-SSOTAccuracy -SSOTPath $SSOTPath -TelemetryPath $TelemetryPath
$integrationCheck = Test-SSOTIntegration -RunbookPath $RunbookPath

# ECRR: Report - Health Results
Write-Host "📊 SSOT Health Results" -ForegroundColor Cyan

# Freshness results
Write-Host "🕒 Freshness Check:" -ForegroundColor Yellow
Write-Host "  Status: $($freshnessCheck.status)" -ForegroundColor $(if ($freshnessCheck.is_fresh) { "Green" } else { "Red" })
if ($freshnessCheck.age_minutes -ne $null) {
    Write-Host "  Age: $($freshnessCheck.age_minutes) minutes" -ForegroundColor Gray
    Write-Host "  Last Modified: $($freshnessCheck.last_modified)" -ForegroundColor Gray
}

# Accuracy results
Write-Host "🎯 Accuracy Check:" -ForegroundColor Yellow
Write-Host "  Status: $($accuracyCheck.status)" -ForegroundColor $(if ($accuracyCheck.is_accurate) { "Green" } else { "Red" })
if ($accuracyCheck.mismatches.Count -gt 0) {
    Write-Host "  Mismatches:" -ForegroundColor Red
    foreach ($mismatch in $accuracyCheck.mismatches) {
        Write-Host "    - $mismatch" -ForegroundColor Red
    }
}

# Integration results
Write-Host "🔗 Integration Check:" -ForegroundColor Yellow
Write-Host "  Status: $($integrationCheck.status)" -ForegroundColor $(if ($integrationCheck.is_integrated) { "Green" } else { "Red" })
Write-Host "  SSOT Block in Runbook: $($integrationCheck.has_ssot_block)" -ForegroundColor Gray

# Detailed results
if ($Detailed) {
    Write-Host "📋 Detailed Results:" -ForegroundColor Cyan
    
    if ($accuracyCheck.ssot_values) {
        Write-Host "  SSOT Values:" -ForegroundColor Gray
        $accuracyCheck.ssot_values.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Gray
        }
    }
    
    if ($accuracyCheck.telemetry_values) {
        Write-Host "  Telemetry Values:" -ForegroundColor Gray
        $accuracyCheck.telemetry_values.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Gray
        }
    }
}

# Overall health score
$healthScore = 0
$totalChecks = 3

if ($freshnessCheck.is_fresh) { $healthScore++ }
if ($accuracyCheck.is_accurate) { $healthScore++ }
if ($integrationCheck.is_integrated) { $healthScore++ }

$healthPercentage = [math]::Round(($healthScore / $totalChecks) * 100, 1)
$healthStatus = if ($healthPercentage -ge 100) { "excellent" } elseif ($healthPercentage -ge 67) { "good" } elseif ($healthPercentage -ge 33) { "fair" } else { "poor" }

Write-Host "🏥 Overall Health: $healthPercentage% ($healthStatus)" -ForegroundColor $(switch ($healthStatus) {
    "excellent" { "Green" }
    "good" { "Green" }
    "fair" { "Yellow" }
    "poor" { "Red" }
})

# Generate health report
$healthReport = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    overall_health = @{
        score_percentage = $healthPercentage
        status = $healthStatus
        checks_passed = $healthScore
        total_checks = $totalChecks
    }
    freshness = $freshnessCheck
    accuracy = $accuracyCheck
    integration = $integrationCheck
    files = @{
        ssot_path = $SSOTPath
        telemetry_path = $TelemetryPath
        runbook_path = $RunbookPath
        ssot_exists = $ssotExists
        telemetry_exists = $telemetryExists
        runbook_exists = $runbookExists
    }
    configuration = @{
        max_age_minutes = $MaxAgeMinutes
        detailed_mode = $Detailed
        export_metrics = $ExportMetrics
    }
}

$reportPath = ".artifacts/ssot-health-report.json"
$healthReport | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "📊 Health report saved: $reportPath" -ForegroundColor Cyan

# Export metrics if requested
if ($ExportMetrics) {
    Write-Host "📈 Exporting metrics..." -ForegroundColor Yellow
    
    $metrics = @{
        ssot_health_score = $healthPercentage
        ssot_freshness_ok = if ($freshnessCheck.is_fresh) { 1 } else { 0 }
        ssot_accuracy_ok = if ($accuracyCheck.is_accurate) { 1 } else { 0 }
        ssot_integration_ok = if ($integrationCheck.is_integrated) { 1 } else { 0 }
        ssot_age_minutes = $freshnessCheck.age_minutes
        ssot_mismatch_count = $accuracyCheck.mismatches.Count
    }
    
    $metricsPath = ".artifacts/ssot-metrics.json"
    $metrics | ConvertTo-Json | Out-File -FilePath $metricsPath -Encoding UTF8
    
    Write-Host "📈 Metrics exported: $metricsPath" -ForegroundColor Green
}

# ECRR: Role - Actor Declaration
Write-Host "🎭 SSOT Health Monitoring Complete" -ForegroundColor Magenta
Write-Host "Actor: Cursor Agent (Observability Copilot)" -ForegroundColor Gray
Write-Host "Role: SSOT health monitoring and validation" -ForegroundColor Gray

# Return exit code based on health
if ($healthPercentage -ge 67) {
    exit 0  # Success
} else {
    exit 1  # Warning/Failure
}
