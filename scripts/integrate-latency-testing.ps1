#Requires -Version 7.0

<#
.SYNOPSIS
    Integration script for the enhanced latency testing system

.DESCRIPTION
    Provides a unified interface for the redesigned latency test system,
    including setup, execution, and monitoring.

.PARAMETER Action
    Action to perform: setup, test, monitor, cleanup, status. Default: status

.PARAMETER TestType
    Type of test: smoke, full, regression. Default: smoke

.PARAMETER Parallelism
    Number of parallel workers. Default: 2

.PARAMETER StageBudget
    Maximum duration per stage in seconds. Default: 120

.PARAMETER LatencySLA
    Latency SLA threshold in milliseconds. Default: 200

.PARAMETER AlertThreshold
    Regression alert threshold percentage. Default: 10

.EXAMPLE
    .\integrate-latency-testing.ps1 -Action setup
    Set up the latency testing system

.EXAMPLE
    .\integrate-latency-testing.ps1 -Action test -TestType smoke
    Run a smoke test

.EXAMPLE
    .\integrate-latency-testing.ps1 -Action monitor
    Monitor for regressions
#>

param(
    [ValidateSet("setup", "test", "monitor", "cleanup", "status")]
    [string]$Action = "status",
    [ValidateSet("smoke", "full", "regression")]
    [string]$TestType = "smoke",
    [int]$Parallelism = 2,
    [int]$StageBudget = 120,
    [int]$LatencySLA = 200,
    [double]$AlertThreshold = 10
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Enhanced Latency Testing Integration" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Configuration
$config = @{
    scripts = @{
        preflight = "scripts/check-latency-readiness.ps1"
        extractor = "scripts/extract-latency-measurements.ps1"
        doe = "scripts/run-otel-doe-enhanced.ps1"
        baselines = "scripts/manage-latency-baselines.ps1"
        monitor = "scripts/monitor-latency-regressions.ps1"
    }
    paths = @{
        baselines = "artifacts/doe/baselines"
        experiments = "artifacts/doe"
        alerts = "artifacts/doe/latency-alerts.json"
    }
    thresholds = @{
        latencySLA = $LatencySLA
        alertThreshold = $AlertThreshold
    }
}

# Function to check system status
function Get-SystemStatus {
    Write-Host "`nSystem Status Check" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $status = @{
        preflight = $false
        baselines = $false
        experiments = $false
        alerts = $false
    }
    
    # Check preflight script
    if (Test-Path $config.scripts.preflight) {
        Write-Host "[OK] Preflight script available" -ForegroundColor Green
        $status.preflight = $true
    } else {
        Write-Host "[FAIL] Preflight script missing" -ForegroundColor Red
    }
    
    # Check baseline directory
    if (Test-Path $config.paths.baselines) {
        $baselineFiles = Get-ChildItem $config.paths.baselines -Filter "*.json"
        if ($baselineFiles.Count -gt 0) {
            Write-Host "[OK] Baselines available ($($baselineFiles.Count) files)" -ForegroundColor Green
            $status.baselines = $true
        } else {
            Write-Host "[WARN] Baseline directory empty" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] Baseline directory missing" -ForegroundColor Yellow
    }
    
    # Check experiment directories
    if (Test-Path $config.paths.experiments) {
        $experimentDirs = Get-ChildItem $config.paths.experiments -Directory
        if ($experimentDirs.Count -gt 0) {
            Write-Host "[OK] Experiments available ($($experimentDirs.Count) directories)" -ForegroundColor Green
            $status.experiments = $true
        } else {
            Write-Host "[WARN] No experiments found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] Experiment directory missing" -ForegroundColor Yellow
    }
    
    # Check alerts
    if (Test-Path $config.paths.alerts) {
        Write-Host "[OK] Alert file exists" -ForegroundColor Green
        $status.alerts = $true
    } else {
        Write-Host "[WARN] No alert file found" -ForegroundColor Yellow
    }
    
    return $status
}

# Function to setup the system
function Initialize-System {
    Write-Host "`nSystem Setup" -ForegroundColor Cyan
    Write-Host "============" -ForegroundColor Cyan
    
    # Create directories
    $directories = @(
        $config.paths.baselines,
        $config.paths.experiments,
        "artifacts/doe/results",
        "artifacts/doe/logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "[OK] Created directory: $dir" -ForegroundColor Green
        } else {
            Write-Host "[OK] Directory exists: $dir" -ForegroundColor Green
        }
    }
    
    # Run preflight check
    Write-Host "`nRunning preflight check..." -ForegroundColor Yellow
    try {
        $preflightResult = & "pwsh" -File $config.scripts.preflight -SmokeMode
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Preflight check passed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Preflight check failed (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] Preflight check failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host "`n[OK] System setup completed" -ForegroundColor Green
}

# Function to run tests
function Invoke-Test {
    param([string]$Type)
    
    Write-Host "`nRunning $Type test" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    switch ($Type) {
        "smoke" {
            Write-Host "Running 60-second smoke test..." -ForegroundColor Yellow
            try {
                $null = & "pwsh" -File $config.scripts.doe -SmokeMode -SkipPreflight
                if ($LASTEXITCODE -ne 0) {
                    throw "Smoke test failed (exit code: $LASTEXITCODE)"
                }
                Write-Host "[OK] Smoke test passed" -ForegroundColor Green
            } catch {
                Write-Error "Smoke test failed: $($_.Exception.Message)"
                throw
            }
        }
        
        "full" {
            Write-Host "Running full experiment..." -ForegroundColor Yellow
            $args = @(
                "-Stage", "integration-test"
                "-Replicates", "2"
                "-Duration", "300"
                "-StageBudget", $StageBudget
                "-Parallelism", $Parallelism
                "-LatencySLA", $LatencySLA
                "-SkipPreflight"
            )
            
            try {
                $null = & "pwsh" -File $config.scripts.doe @args
                if ($LASTEXITCODE -ne 0) {
                    throw "Full test failed (exit code: $LASTEXITCODE)"
                }
                Write-Host "[OK] Full test completed" -ForegroundColor Green
            } catch {
                Write-Error "Full test failed: $($_.Exception.Message)"
                throw
            }
        }
        
        "regression" {
            Write-Host "Running regression test..." -ForegroundColor Yellow
            
            $experimentDirs = Get-ChildItem $config.paths.experiments -Directory | Sort-Object LastWriteTime -Descending
            if ($experimentDirs.Count -eq 0) {
                throw "No experiments found for regression testing"
            }
            
            $latestExperiment = $experimentDirs[0].FullName
            Write-Host "Using experiment: $latestExperiment" -ForegroundColor Yellow
            
            try {
                $null = & "pwsh" -File $config.scripts.extractor -ExperimentDir $latestExperiment
                if ($LASTEXITCODE -ne 0) {
                    throw "Measurement extraction failed (exit code: $LASTEXITCODE)"
                }
                Write-Host "[OK] Measurements extracted" -ForegroundColor Green
                
                $null = & "pwsh" -File $config.scripts.monitor -ExperimentDir $latestExperiment -AlertThreshold $AlertThreshold
                if ($LASTEXITCODE -ne 0) {
                    throw "Regression monitor detected issues (exit code: $LASTEXITCODE)"
                }
                Write-Host "[OK] No regressions detected" -ForegroundColor Green
            } catch {
                Write-Error "Regression test failed: $($_.Exception.Message)"
                throw
            }
        }
    }
}


# Function to monitor system
function Start-Monitoring {
    Write-Host "`nSystem Monitoring" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $experimentDirs = Get-ChildItem $config.paths.experiments -Directory | Sort-Object LastWriteTime -Descending
    if ($experimentDirs.Count -eq 0) {
        throw "No experiments found for monitoring"
    }
    
    $latestExperiment = $experimentDirs[0].FullName
    Write-Host "Monitoring experiment: $latestExperiment" -ForegroundColor Yellow
    
    try {
        $null = & "pwsh" -File $config.scripts.monitor -ExperimentDir $latestExperiment -AlertThreshold $AlertThreshold -OutputFormat text
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Monitoring reported issues (exit code: $exitCode)"
        }
        Write-Host "[OK] Monitoring completed - no issues detected" -ForegroundColor Green
    } catch {
        Write-Error "Monitoring failed: $($_.Exception.Message)"
        throw
    }
}


# Function to cleanup old data
function Clear-OldData {
    Write-Host "`nSystem Cleanup" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan
    
    # Clean up old experiments (keep last 5)
    if (Test-Path $config.paths.experiments) {
        $experimentDirs = Get-ChildItem $config.paths.experiments -Directory | Sort-Object LastWriteTime -Descending
        if ($experimentDirs.Count -gt 5) {
            $toDelete = $experimentDirs | Select-Object -Skip 5
            foreach ($dir in $toDelete) {
                Remove-Item $dir.FullName -Recurse -Force
                Write-Host "[OK] Deleted old experiment: $($dir.Name)" -ForegroundColor Green
            }
        } else {
            Write-Host "[OK] No old experiments to clean up" -ForegroundColor Green
        }
    }
    
    # Clean up old alert files (keep last 10)
    if (Test-Path $config.paths.alerts) {
        $alertDir = Split-Path -Path $config.paths.alerts -Parent
        $alertFiles = Get-ChildItem $alertDir -Filter "latency-alerts*.json" | Sort-Object LastWriteTime -Descending
        if ($alertFiles.Count -gt 10) {
            $toDelete = $alertFiles | Select-Object -Skip 10
            foreach ($file in $toDelete) {
                Remove-Item $file.FullName -Force
                Write-Host "[OK] Deleted old alert file: $($file.Name)" -ForegroundColor Green
            }
        } else {
            Write-Host "[OK] No old alert files to clean up" -ForegroundColor Green
        }
    }
    
    Write-Host "`n[OK] Cleanup completed" -ForegroundColor Green
}

# Main execution
switch ($Action) {
    "setup" {
        Initialize-System
    }
    
    "test" {
        Invoke-Test -Type $TestType
    }
    
    "monitor" {
        Start-Monitoring
    }
    
    "cleanup" {
        Clear-OldData
    }
    
    "status" {
        $status = Get-SystemStatus
        
        Write-Host "`nSystem Status Summary" -ForegroundColor Green
        Write-Host "=====================" -ForegroundColor Green
        Write-Host "Preflight: $(if ($status.preflight) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($status.preflight) { 'Green' } else { 'Red' })
        Write-Host "Baselines: $(if ($status.baselines) { '[OK]' } else { '[WARN]' })" -ForegroundColor $(if ($status.baselines) { 'Green' } else { 'Yellow' })
        Write-Host "Experiments: $(if ($status.experiments) { '[OK]' } else { '[WARN]' })" -ForegroundColor $(if ($status.experiments) { 'Green' } else { 'Yellow' })
        Write-Host "Alerts: $(if ($status.alerts) { '[OK]' } else { '[WARN]' })" -ForegroundColor $(if ($status.alerts) { 'Green' } else { 'Yellow' })
        
        Write-Host "`nAvailable Commands:" -ForegroundColor Cyan
        Write-Host "  Setup:    pwsh -File scripts/integrate-latency-testing.ps1 -Action setup" -ForegroundColor White
        Write-Host "  Smoke:    pwsh -File scripts/integrate-latency-testing.ps1 -Action test -TestType smoke" -ForegroundColor White
        Write-Host "  Full:     pwsh -File scripts/integrate-latency-testing.ps1 -Action test -TestType full" -ForegroundColor White
        Write-Host "  Monitor:  pwsh -File scripts/integrate-latency-testing.ps1 -Action monitor" -ForegroundColor White
        Write-Host "  Cleanup:  pwsh -File scripts/integrate-latency-testing.ps1 -Action cleanup" -ForegroundColor White
    }
}

Write-Host "`n[OK] Integration script completed" -ForegroundColor Green
