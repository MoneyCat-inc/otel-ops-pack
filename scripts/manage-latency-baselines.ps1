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
    [ValidateSet("create", "update", "compare", "list", "create-schedule", "apply")]
    [string]$Action = "list",
    [string]$BaselineName = "control",
    [string]$SourceRunId,
    [string]$SourceExperimentDir,
    [string]$BaselineFile = "artifacts/doe/baselines/latency.json",
    [double]$Threshold = 10,
    [string]$ScheduleTime = "02:00",
    [switch]$DryRun
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Latency Baseline Management" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green

# Ensure baselines directory exists
$baselinesDir = Split-Path -Path $BaselineFile -Parent
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
    
    "create-schedule" {
        Write-Host "Creating daily baseline automation schedule" -ForegroundColor Cyan
        
        # Check administrator privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $isAdmin) {
            Write-Host "ERROR: Administrator privileges required for scheduling" -ForegroundColor Red
            Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
            exit 1
        }
        
        $taskName = "OTel-Latency-Baseline-Daily"
        $scriptPath = $PSCommandPath
        
        # Define the scheduled task action
        $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NonInteractive -File `"$scriptPath`" -Action apply -BaselineName $BaselineName" -WorkingDirectory "C:\otel"
        
        # Create daily trigger at specified time
        $trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing scheduled task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        if ($DryRun) {
            Write-Host "DRY RUN - Would create task with:" -ForegroundColor Cyan
            Write-Host "  Task Name: $taskName" -ForegroundColor White
            Write-Host "  Script: $scriptPath" -ForegroundColor White
            Write-Host "  Schedule: Daily at $ScheduleTime" -ForegroundColor White
            Write-Host "  Action: apply -BaselineName $BaselineName" -ForegroundColor White
            Write-Host "  Principal: SYSTEM" -ForegroundColor White
            exit 0
        }
        
        # Create the new scheduled task
        Write-Host "Creating scheduled task: $taskName" -ForegroundColor Yellow
        Write-Host "   Script: $scriptPath" -ForegroundColor Gray
        Write-Host "   Schedule: Daily at $ScheduleTime" -ForegroundColor Gray
        Write-Host "   Action: apply -BaselineName $BaselineName" -ForegroundColor Gray
        
        try {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Daily latency baseline management and SigNoz dashboard update"
            Write-Host "SUCCESS: Daily baseline automation scheduled!" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
        
        # Verify the task was created
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "`nTask Details:" -ForegroundColor Cyan
            Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
            Write-Host "  State: $($task.State)" -ForegroundColor White
            
            try {
                $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
                Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor White
                Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
                Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
            } catch {
                Write-Host "  Next Run: Not available yet" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`nManagement Commands:" -ForegroundColor Cyan
        Write-Host "  View task: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
        Write-Host "  Run now: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
        Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Gray
    }
    
    "apply" {
        Write-Host "Applying daily baseline automation" -ForegroundColor Cyan
        
        try {
            # Find the latest experiment run to use as baseline source
            $experimentDirs = Get-ChildItem -Path "artifacts/doe" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if (-not $experimentDirs) {
                Write-Host "No experiment directories found in artifacts/doe" -ForegroundColor Yellow
                Write-Host "Skipping baseline update - no source data available" -ForegroundColor Yellow
                exit 0
            }
            
            $latestExperiment = $experimentDirs.FullName
            Write-Host "Using latest experiment: $latestExperiment" -ForegroundColor White
            
            # Find control run in the latest experiment
            $controlRunId = Find-ControlRun -ExperimentDir $latestExperiment
            Write-Host "Found control run: $controlRunId" -ForegroundColor White
            
            # Update baseline with latest control run
            Write-Host "Updating baseline '$BaselineName' with latest control run..." -ForegroundColor Yellow
            $measurements = Get-RunMeasurements -RunId $controlRunId
            
            $baseline = @{
                name = $BaselineName
                sourceRunId = $controlRunId
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
                    description = "Daily automated baseline update from run $controlRunId"
                    automation = @{
                        scheduled = $true
                        lastUpdate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                        sourceExperiment = $latestExperiment
                    }
                }
            }
            
            Set-Baseline -Path $BaselineFile -Baseline $baseline
            
            Write-Host "Baseline updated successfully:" -ForegroundColor Green
            Write-Host "  p50: $($baseline.latency.p50_ms)ms" -ForegroundColor White
            Write-Host "  p95: $($baseline.latency.p95_ms)ms" -ForegroundColor White
            Write-Host "  p99: $($baseline.latency.p99_ms)ms" -ForegroundColor White
            Write-Host "  Samples: $($baseline.latency.sample_count)" -ForegroundColor White
            Write-Host "  Source: $($baseline.latency.source)" -ForegroundColor White
            
            # Export updated dashboard configuration
            Write-Host "`nExporting updated dashboard configuration..." -ForegroundColor Yellow
            & "pwsh" -File "scripts/export-dashboard-config.ps1" -BaselineFile $BaselineFile -OutputFile "artifacts/signoz-dashboard-config.json"
            
            # Import dashboard to SigNoz if available
            Write-Host "Importing dashboard to SigNoz..." -ForegroundColor Yellow
            & "pwsh" -File "scripts/import-dashboard.ps1" -DashboardFile "artifacts/signoz-dashboard-config.json" -ApplyMode
            
            Write-Host "`nDaily automation completed successfully!" -ForegroundColor Green
            Write-Host "  Baseline updated: $BaselineFile" -ForegroundColor White
            Write-Host "  Dashboard exported: artifacts/signoz-dashboard-config.json" -ForegroundColor White
            Write-Host "  SigNoz import: Check artifacts for import status" -ForegroundColor White
            
        } catch {
            Write-Error "Failed to apply daily automation: $($_.Exception.Message)"
            exit 1
        }
    }
}
