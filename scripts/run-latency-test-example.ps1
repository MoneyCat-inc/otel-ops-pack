#Requires -Version 7.0

<#
.SYNOPSIS
    Example script demonstrating the enhanced latency test system

.DESCRIPTION
    Shows how to use the new latency-focused DOE system with pre-flight checks,
    parallel execution, and regression monitoring.

.EXAMPLE
    .\run-latency-test-example.ps1
    Run a complete latency test example
#>

param(
    [switch]$SkipPreflight,
    [switch]$SkipSmoke,
    [int]$Parallelism = 2,
    [int]$StageBudget = 90
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Enhanced Latency Test Example" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Step 1: Pre-flight readiness check
if (-not $SkipPreflight) {
    Write-Host "`nStep 1: Pre-flight readiness check" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    try {
        $preflightArgs = @()
        if (-not $SkipSmoke) {
            $preflightArgs += "-SmokeMode"
        }
        
        $preflightResult = & "pwsh" -File "scripts/check-latency-readiness.ps1" @preflightArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Pre-flight checks failed"
        }
        Write-Host "[OK] Pre-flight checks passed" -ForegroundColor Green
    } catch {
        Write-Error "Pre-flight checks failed: $($_.Exception.Message)"
        exit 1
    }
}

# Step 2: Create baseline (if not exists)
Write-Host "`nStep 2: Baseline management" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$baselineFile = "artifacts/doe/baselines/latency.json"
if (-not (Test-Path $baselineFile)) {
    Write-Host "Creating baseline from control run..." -ForegroundColor Yellow
    
    # For demo purposes, create a synthetic baseline
    $baseline = @{
        name = "control"
        sourceRunId = "control-demo"
        created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        latency = @{
            p50_ms = 50
            p95_ms = 100
            p99_ms = 200
            sample_count = 1000
            source = "synthetic"
        }
        metadata = @{
            threshold = 10
            description = "Demo baseline for latency testing"
        }
    }
    
    $baselineDir = Split-Path -Path $baselineFile -Parent
    if (-not (Test-Path $baselineDir)) {
        New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null
    }
    
    $baseline | ConvertTo-Json -Depth 10 | Set-Content $baselineFile
    Write-Host "[OK] Baseline created" -ForegroundColor Green
} else {
    Write-Host "[OK] Baseline already exists" -ForegroundColor Green
}

# Step 3: Run enhanced DOE experiment
Write-Host "`nStep 3: Enhanced DOE experiment" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

$experimentArgs = @(
    "-Stage", "latency-test"
    "-Replicates", "2"
    "-Duration", "180"
    "-StageBudget", $StageBudget
    "-Parallelism", $Parallelism
    "-LatencySLA", "150"
    "-SkipPreflight"  # Already done above
)

Write-Host "Running experiment with args: $($experimentArgs -join ' ')" -ForegroundColor Yellow

try {
    $experimentResult = & "pwsh" -File "scripts/run-otel-doe-enhanced.ps1" @experimentArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Experiment failed"
    }
    Write-Host "[OK] Experiment completed" -ForegroundColor Green
} catch {
    Write-Error "Experiment failed: $($_.Exception.Message)"
    exit 1
}

# Step 4: Extract latency measurements
Write-Host "`nStep 4: Extract latency measurements" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Find the latest experiment directory
$experimentDirs = Get-ChildItem "artifacts/doe" -Directory | Where-Object { $_.Name -like "latency-test-*" } | Sort-Object LastWriteTime -Descending
if ($experimentDirs.Count -eq 0) {
    throw "No experiment directories found"
}

$latestExperimentDir = $experimentDirs[0].FullName
Write-Host "Processing experiment: $latestExperimentDir" -ForegroundColor Yellow

try {
    $extractResult = & "pwsh" -File "scripts/extract-latency-measurements.ps1" -ExperimentDir $latestExperimentDir -TimeRange 5
    if ($LASTEXITCODE -ne 0) {
        throw "Latency extraction failed"
    }
    Write-Host "[OK] Latency measurements extracted" -ForegroundColor Green
} catch {
    Write-Error "Latency extraction failed: $($_.Exception.Message)"
    exit 1
}

# Step 5: Monitor for regressions
Write-Host "`nStep 5: Regression monitoring" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

try {
    $monitorResult = & "pwsh" -File "scripts/monitor-latency-regressions.ps1" -ExperimentDir $latestExperimentDir -AlertThreshold 10 -OutputFormat text
    $monitorExitCode = $LASTEXITCODE
    
    if ($monitorExitCode -eq 0) {
        Write-Host "[OK] No regressions detected" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Regressions detected (exit code: $monitorExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Error "Regression monitoring failed: $($_.Exception.Message)"
    exit 1
}

# Step 6: Generate summary report
Write-Host "`nStep 6: Summary report" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# Load experiment summary
$summaryFile = Join-Path $latestExperimentDir "experiment-summary.json"
if (Test-Path $summaryFile) {
    $summary = Get-Content $summaryFile | ConvertFrom-Json
    
    Write-Host "Experiment Summary:" -ForegroundColor Green
    Write-Host "  Stage: $($summary.experiment.stage)" -ForegroundColor White
    Write-Host "  Total Runs: $($summary.totalRuns)" -ForegroundColor White
    Write-Host "  Completed: $($summary.completedRuns)" -ForegroundColor White
    Write-Host "  Failed: $($summary.failedRuns)" -ForegroundColor White
    Write-Host "  SLA Compliant: $($summary.slaCompliantRuns)" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    
    if ($summary.latencySummary) {
        Write-Host "Latency Summary:" -ForegroundColor Green
        Write-Host "  Average p95: $($summary.latencySummary.avgP95)ms" -ForegroundColor White
        Write-Host "  Minimum p95: $($summary.latencySummary.minP95)ms" -ForegroundColor White
        Write-Host "  Maximum p95: $($summary.latencySummary.maxP95)ms" -ForegroundColor White
    }
}

# Step 7: Show next steps
Write-Host "`nStep 7: Next steps" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

Write-Host "The enhanced latency test system is now ready!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "Key improvements implemented:" -ForegroundColor Yellow
Write-Host "  [OK] Pre-flight ClickHouse + collector health checks" -ForegroundColor White
Write-Host "  [OK] 60-second smoke mode for quick validation" -ForegroundColor White
Write-Host "  [OK] Parallel execution with configurable workers" -ForegroundColor White
Write-Host "  [OK] Stage budgets to stop early when SLA is met" -ForegroundColor White
Write-Host "  [OK] Fail-fast latency extraction (no fallback values)" -ForegroundColor White
Write-Host "  [OK] Baseline comparison with regression detection" -ForegroundColor White
Write-Host "  [OK] Real-time monitoring and alerting" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  # Run smoke test" -ForegroundColor White
Write-Host "  pwsh -File scripts/run-otel-doe-enhanced.ps1 -SmokeMode" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "  # Run full experiment" -ForegroundColor White
Write-Host "  pwsh -File scripts/run-otel-doe-enhanced.ps1 -Parallelism 3 -StageBudget 120" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "  # Monitor regressions" -ForegroundColor White
Write-Host "  pwsh -File scripts/monitor-latency-regressions.ps1 -ExperimentDir artifacts/doe/latest" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "  # Manage baselines" -ForegroundColor White
Write-Host "  pwsh -File scripts/manage-latency-baselines.ps1 -Action list" -ForegroundColor Gray

Write-Host "`n[OK] Enhanced latency test example completed!" -ForegroundColor Green
