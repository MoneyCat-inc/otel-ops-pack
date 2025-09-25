#Requires -Version 7.0

<#
.SYNOPSIS
    Monitor latency regressions in DOE experiments

.DESCRIPTION
    Monitors experiment results for latency regressions and surfaces alerts
    for monitoring systems.

.PARAMETER ExperimentDir
    Directory containing experiment results to monitor

.PARAMETER BaselineFile
    Path to baseline file. Default: artifacts/doe/baselines/latency.json

.PARAMETER AlertThreshold
    Regression threshold for alerts. Default: 10

.PARAMETER OutputFormat
    Output format: json, text, prometheus. Default: text

.PARAMETER AlertFile
    File to write alerts to. Default: artifacts/doe/latency-alerts.json

.EXAMPLE
    .\monitor-latency-regressions.ps1 -ExperimentDir artifacts/doe/stage1-20250921-190945
    Monitor specific experiment for regressions

.EXAMPLE
    .\monitor-latency-regressions.ps1 -OutputFormat json -AlertFile alerts.json
    Output JSON format alerts to specific file
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ExperimentDir,
    [string]$BaselineFile = "artifacts/doe/baselines/latency.json",
    [double]$AlertThreshold = 10,
    [ValidateSet("json", "text", "prometheus")]
    [string]$OutputFormat = "text",
    [string]$AlertFile = "artifacts/doe/latency-alerts.json"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Latency Regression Monitor" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Load baseline
$baseline = $null
if (Test-Path $BaselineFile) {
    try {
        $baseline = Get-Content $BaselineFile | ConvertFrom-Json
        Write-Host "Loaded baseline: $($baseline.name) (p95: $($baseline.latency.p95_ms)ms)" -ForegroundColor Cyan
    } catch {
        Write-Warning "Failed to load baseline: $($_.Exception.Message)"
    }
} else {
    Write-Warning "No baseline file found at $BaselineFile"
}

# Load experiment results
if (-not (Test-Path $ExperimentDir)) {
    throw "Experiment directory not found: $ExperimentDir"
}

$planFile = Join-Path $ExperimentDir "batch-plan.json"
if (-not (Test-Path $planFile)) {
    throw "Batch plan file not found: $planFile"
}

$plan = Get-Content $planFile | ConvertFrom-Json
$completedRuns = $plan.runs | Where-Object { $_.status -eq "completed" }

Write-Host "Monitoring $($completedRuns.Count) completed runs" -ForegroundColor Cyan

# Function to load latency measurements for a run
function Get-RunLatencyData {
    param([object]$Run)
    
    $latencyFile = $Run.artifacts.latencyFile
    if (Test-Path $latencyFile) {
        try {
            return Get-Content $latencyFile | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to load latency data for $($Run.runId): $($_.Exception.Message)"
            return $null
        }
    }
    return $null
}

# Process runs and detect regressions
$alerts = @()
$summary = @{
    totalRuns = $completedRuns.Count
    runsWithData = 0
    regressions = 0
    slaViolations = 0
    avgP95 = 0
    minP95 = 0
    maxP95 = 0
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

$latencyValues = @()

foreach ($run in $completedRuns) {
    $latencyData = Get-RunLatencyData -Run $run
    if (-not $latencyData) {
        continue
    }
    
    $summary.runsWithData++
    $latencyValues += $latencyData.latency.p95_ms
    
    # Check for regressions if baseline available
    if ($baseline -and $latencyData.latency.p95_ms) {
        $p95Regression = ($latencyData.latency.p95_ms - $baseline.latency.p95_ms) / $baseline.latency.p95_ms * 100
        
        if ($p95Regression -gt $AlertThreshold) {
            $summary.regressions++
            
            $alert = @{
                runId = $run.runId
                runLabel = $run.runLabel
                replicate = $run.replicate
                timestamp = $run.endTime
                regression = @{
                    p95_ms = $latencyData.latency.p95_ms
                    baseline_p95_ms = $baseline.latency.p95_ms
                    regression_percent = [math]::Round($p95Regression, 2)
                    threshold_percent = $AlertThreshold
                }
                severity = if ($p95Regression -gt $AlertThreshold * 2) { "critical" } elseif ($p95Regression -gt $AlertThreshold * 1.5) { "high" } else { "medium" }
                factors = $run.factors
            }
            
            $alerts += $alert
        }
    }
    
    # Check SLA compliance
    if ($run.meetsSLA -eq $false) {
        $summary.slaViolations++
    }
}

# Calculate summary statistics
if ($latencyValues.Count -gt 0) {
    $summary.avgP95 = [math]::Round(($latencyValues | Measure-Object -Average).Average, 2)
    $summary.minP95 = [math]::Round(($latencyValues | Measure-Object -Minimum).Minimum, 2)
    $summary.maxP95 = [math]::Round(($latencyValues | Measure-Object -Maximum).Maximum, 2)
}

# Generate output based on format
switch ($OutputFormat) {
    "json" {
        $output = @{
            summary = $summary
            alerts = $alerts
            baseline = $baseline
            experiment = $plan.experiment
        }
        
        $output | ConvertTo-Json -Depth 10 | Write-Output
    }
    
    "prometheus" {
        # Prometheus metrics format
        Write-Output "# HELP doe_latency_p95_milliseconds P95 latency in milliseconds"
        Write-Output "# TYPE doe_latency_p95_milliseconds gauge"
        Write-Output "doe_latency_p95_milliseconds{experiment=`"$($plan.experiment.stage)`"} $($summary.avgP95)"
        
        Write-Output "# HELP doe_regressions_total Total number of latency regressions"
        Write-Output "# TYPE doe_regressions_total counter"
        Write-Output "doe_regressions_total{experiment=`"$($plan.experiment.stage)`"} $($summary.regressions)"
        
        Write-Output "# HELP doe_sla_violations_total Total number of SLA violations"
        Write-Output "# TYPE doe_sla_violations_total counter"
        Write-Output "doe_sla_violations_total{experiment=`"$($plan.experiment.stage)`"} $($summary.slaViolations)"
    }
    
    "text" {
        Write-Host "`nLatency Regression Summary" -ForegroundColor Green
        Write-Host "=========================" -ForegroundColor Green
        Write-Host "Experiment: $($plan.experiment.stage)" -ForegroundColor White
        Write-Host "Total Runs: $($summary.totalRuns)" -ForegroundColor White
        Write-Host "Runs with Data: $($summary.runsWithData)" -ForegroundColor White
        Write-Host "Regressions: $($summary.regressions)" -ForegroundColor $(if ($summary.regressions -gt 0) { "Red" } else { "Green" })
        Write-Host "SLA Violations: $($summary.slaViolations)" -ForegroundColor $(if ($summary.slaViolations -gt 0) { "Red" } else { "Green" })
        Write-Host "" -ForegroundColor White
        
        Write-Host "Latency Statistics:" -ForegroundColor Cyan
        Write-Host "  Average p95: $($summary.avgP95)ms" -ForegroundColor White
        Write-Host "  Minimum p95: $($summary.minP95)ms" -ForegroundColor White
        Write-Host "  Maximum p95: $($summary.maxP95)ms" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        
        if ($alerts.Count -gt 0) {
            Write-Host "Regression Alerts:" -ForegroundColor Red
            Write-Host "=================" -ForegroundColor Red
            
            foreach ($alert in $alerts) {
                $color = switch ($alert.severity) {
                    "critical" { "Red" }
                    "high" { "Magenta" }
                    "medium" { "Yellow" }
                    default { "White" }
                }
                
                Write-Host "  $($alert.severity.ToUpper()): $($alert.runId)" -ForegroundColor $color
                Write-Host "    p95: $($alert.regression.p95_ms)ms (baseline: $($alert.regression.baseline_p95_ms)ms)" -ForegroundColor White
                Write-Host "    Regression: $($alert.regression.regression_percent)% (threshold: $($alert.regression.threshold_percent)%)" -ForegroundColor White
                Write-Host "    Factors: $($alert.factors | ConvertTo-Json -Compress)" -ForegroundColor Gray
                Write-Host "" -ForegroundColor White
            }
        } else {
            Write-Host "[OK] No regressions detected" -ForegroundColor Green
        }
    }
}

# Save alerts to file
if ($alerts.Count -gt 0) {
    $alertDir = Split-Path -Path $AlertFile -Parent
    if (-not (Test-Path $alertDir)) {
        New-Item -ItemType Directory -Path $alertDir -Force | Out-Null
    }
    
    $alertData = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        experiment = $plan.experiment
        summary = $summary
        alerts = $alerts
    }
    
    $alertData | ConvertTo-Json -Depth 10 | Set-Content $AlertFile
    Write-Host "`nAlerts saved to: $AlertFile" -ForegroundColor Yellow
}

# Exit with appropriate code
if ($summary.regressions -gt 0 -or $summary.slaViolations -gt 0) {
    Write-Host "`n[WARN] Regression monitoring detected issues" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n[OK] No regressions detected" -ForegroundColor Green
    exit 0
}

