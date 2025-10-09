#Requires -Version 7.0

<#
.SYNOPSIS
    Manage latency baselines for DOE experiments

.DESCRIPTION
    Creates, updates, and compares latency baselines for regression detection.

.PARAMETER Action
    Action to perform: create, update, compare, list. Default: list

.PARAMETER BaselineName
    Name of the baseline to create/update. Default: control

.PARAMETER SourceRunId
    Run ID to use as baseline source

.PARAMETER SourceExperimentDir
    Experiment directory to find baseline runs

.PARAMETER BaselineFile
    Path to baseline file. Default: artifacts/doe/baselines/latency.json

.PARAMETER Threshold
    Regression threshold percentage. Default: 10

.EXAMPLE
    .\manage-latency-baselines.ps1 -Action create -BaselineName control -SourceRunId control-r1-20250921-190945
    Create a baseline from a specific run

.EXAMPLE
    .\manage-latency-baselines.ps1 -Action compare -SourceRunId test-run-001
    Compare a run against the current baseline
#>

param(
    [ValidateSet("create", "update", "compare", "list")]
    [string]$Action = "list",
    [string]$BaselineName = "control",
    [string]$SourceRunId,
    [string]$SourceExperimentDir,
    [string]$BaselineFile = "artifacts/doe/baselines/latency.json",
    [double]$Threshold = 10
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Latency Baseline Management" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green

# Ensure baselines directory exists
$baselinesDir = Split-Path $BaselineFile -Parent
if (-not (Test-Path $baselinesDir)) {
    New-Item -ItemType Directory -Path $baselinesDir -Force | Out-Null
}

# Function to load baseline
function Get-Baseline {
    param([string]$Path)
    
    if (Test-Path $Path) {
        try {
            return Get-Content $Path | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to load baseline from $Path`: $($_.Exception.Message)"
            return $null
        }
    }
    return $null
}

# Function to save baseline
function Set-Baseline {
    param(
        [string]$Path,
        [object]$Baseline
    )
    
    try {
        $Baseline | ConvertTo-Json -Depth 10 | Set-Content $Path
        Write-Host "[OK] Baseline saved to: $Path" -ForegroundColor Green
    } catch {
        throw "Failed to save baseline: $($_.Exception.Message)"
    }
}

# Function to extract measurements from run
function Get-RunMeasurements {
    param([string]$RunId)
    
    try {
        $measurements = & "pwsh" -File "scripts/extract-latency-measurements.ps1" -RunId $RunId -TimeRange 5 -FailOnMissingData
        return $measurements.latency
    } catch {
        throw "Failed to extract measurements for run $RunId`: $($_.Exception.Message)"
    }
}

# Function to find control run in experiment
function Find-ControlRun {
    param([string]$ExperimentDir)
    
    if (-not (Test-Path $ExperimentDir)) {
        throw "Experiment directory not found: $ExperimentDir"
    }
    
    $planFile = Join-Path $ExperimentDir "batch-plan.json"
    if (-not (Test-Path $planFile)) {
        throw "Batch plan file not found: $planFile"
    }
    
    $plan = Get-Content $planFile | ConvertFrom-Json
    $controlRuns = $plan.runs | Where-Object { $_.runLabel -like "*control*" -and $_.status -eq "completed" }
    
    if ($controlRuns.Count -eq 0) {
        throw "No completed control runs found in experiment"
    }
    
    # Use the first control run
    return $controlRuns[0].runId
}

# Main execution
switch ($Action) {
    "create" {
        if (-not $SourceRunId) {
            throw "SourceRunId is required for create action"
        }
        
        Write-Host "Creating baseline '$BaselineName' from run: $SourceRunId" -ForegroundColor Cyan
        
        try {
            $measurements = Get-RunMeasurements -RunId $SourceRunId
            
            $baseline = @{
                name = $BaselineName
                sourceRunId = $SourceRunId
                created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                latency = @{
                    p50_ms = $measurements.p50_ms
                    p95_ms = $measurements.p95_ms
                    p99_ms = $measurements.p99_ms
                    sample_count = $measurements.sample_count
                    source = $measurements.source
                }
                metadata = @{
                    threshold = $Threshold
                    description = "Baseline created from run $SourceRunId"
                }
            }
            
            Set-Baseline -Path $BaselineFile -Baseline $baseline
            
            Write-Host "Baseline created successfully:" -ForegroundColor Green
            Write-Host "  p50: $($baseline.latency.p50_ms)ms" -ForegroundColor White
            Write-Host "  p95: $($baseline.latency.p95_ms)ms" -ForegroundColor White
            Write-Host "  p99: $($baseline.latency.p99_ms)ms" -ForegroundColor White
            Write-Host "  Samples: $($baseline.latency.sample_count)" -ForegroundColor White
            Write-Host "  Source: $($baseline.latency.source)" -ForegroundColor White
            
        } catch {
            Write-Error "Failed to create baseline: $($_.Exception.Message)"
            exit 1
        }
    }
    
    "update" {
        if (-not $SourceRunId) {
            throw "SourceRunId is required for update action"
        }
        
        Write-Host "Updating baseline '$BaselineName' with run: $SourceRunId" -ForegroundColor Cyan
        
        try {
            $measurements = Get-RunMeasurements -RunId $SourceRunId
            
            $baseline = @{
                name = $BaselineName
                sourceRunId = $SourceRunId
                created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                latency = @{
                    p50_ms = $measurements.p50_ms
                    p95_ms = $measurements.p95_ms
                    p99_ms = $measurements.p99_ms
                    sample_count = $measurements.sample_count
                    source = $measurements.source
                }
                metadata = @{
                    threshold = $Threshold
                    description = "Baseline updated from run $SourceRunId"
                }
            }
            
            Set-Baseline -Path $BaselineFile -Baseline $baseline
            
            Write-Host "Baseline updated successfully" -ForegroundColor Green
            
        } catch {
            Write-Error "Failed to update baseline: $($_.Exception.Message)"
            exit 1
        }
    }
    
    "compare" {
        if (-not $SourceRunId) {
            throw "SourceRunId is required for compare action"
        }
        
        Write-Host "Comparing run '$SourceRunId' against baseline" -ForegroundColor Cyan
        
        try {
            $baseline = Get-Baseline -Path $BaselineFile
            if (-not $baseline) {
                throw "No baseline found at $BaselineFile"
            }
            
            $measurements = Get-RunMeasurements -RunId $SourceRunId
            
            # Calculate regression percentages
            $p50Regression = if ($baseline.latency.p50_ms -gt 0) { [math]::Round(($measurements.p50_ms - $baseline.latency.p50_ms) / $baseline.latency.p50_ms * 100, 2) } else { $null }
            $p95Regression = if ($baseline.latency.p95_ms -gt 0) { [math]::Round(($measurements.p95_ms - $baseline.latency.p95_ms) / $baseline.latency.p95_ms * 100, 2) } else { $null }
            $p99Regression = if ($baseline.latency.p99_ms -gt 0) { [math]::Round(($measurements.p99_ms - $baseline.latency.p99_ms) / $baseline.latency.p99_ms * 100, 2) } else { $null }
            
            # Check SLA compliance
            $p95MeetsSLA = if ($p95Regression) { $p95Regression -le $Threshold } else { $null }
            
            Write-Host "`nComparison Results:" -ForegroundColor Green
            Write-Host "==================" -ForegroundColor Green
            Write-Host "Baseline: $($baseline.name) (from $($baseline.sourceRunId))" -ForegroundColor White
            Write-Host "Created: $($baseline.created)" -ForegroundColor White
            Write-Host "" -ForegroundColor White
            
            Write-Host "Latency Comparison:" -ForegroundColor Cyan
            Write-Host "  p50: $($measurements.p50_ms)ms vs $($baseline.latency.p50_ms)ms (regression: $p50Regression%)" -ForegroundColor White
            Write-Host "  p95: $($measurements.p95_ms)ms vs $($baseline.latency.p95_ms)ms (regression: $p95Regression%)" -ForegroundColor White
            Write-Host "  p99: $($measurements.p99_ms)ms vs $($baseline.latency.p99_ms)ms (regression: $p99Regression%)" -ForegroundColor White
            Write-Host "" -ForegroundColor White
            
            Write-Host "SLA Compliance (threshold: $Threshold%):" -ForegroundColor Cyan
            $p95Status = if ($p95MeetsSLA -eq $true) { "[OK] PASS" } elseif ($p95MeetsSLA -eq $false) { "[FAIL] FAIL" } else { "? UNKNOWN" }
            $p95Color = if ($p95MeetsSLA -eq $true) { "Green" } elseif ($p95MeetsSLA -eq $false) { "Red" } else { "Yellow" }
            Write-Host "  p95 regression: $p95Regression% $p95Status" -ForegroundColor $p95Color
            
            # Save comparison results
            $comparison = @{
                runId = $SourceRunId
                baseline = $baseline
                measurements = $measurements
                regression = @{
                    p50_percent = $p50Regression
                    p95_percent = $p95Regression
                    p99_percent = $p99Regression
                }
                sla = @{
                    p95_meets = $p95MeetsSLA
                    threshold = $Threshold
                }
                comparedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
            
            $comparisonFile = "artifacts/doe/comparison-$SourceRunId.json"
            $comparison | ConvertTo-Json -Depth 10 | Set-Content $comparisonFile
            Write-Host "`nComparison saved to: $comparisonFile" -ForegroundColor Yellow
            
        } catch {
            Write-Error "Failed to compare run: $($_.Exception.Message)"
            exit 1
        }
    }
    
    "list" {
        Write-Host "Available baselines:" -ForegroundColor Cyan
        
        if (Test-Path $BaselineFile) {
            $baseline = Get-Baseline -Path $BaselineFile
            if ($baseline) {
                Write-Host "  $($baseline.name)" -ForegroundColor White
                Write-Host "    Source: $($baseline.sourceRunId)" -ForegroundColor Gray
                Write-Host "    Created: $($baseline.created)" -ForegroundColor Gray
                Write-Host "    p95: $($baseline.latency.p95_ms)ms" -ForegroundColor Gray
                Write-Host "    Threshold: $($baseline.metadata.threshold)%" -ForegroundColor Gray
            } else {
                Write-Host "  No valid baseline found" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  No baseline file found at $BaselineFile" -ForegroundColor Yellow
        }
    }
}
