#!/usr/bin/env pwsh
# Production GPU Sidecar Monitoring Schedule
# Runs validation tests and generates reports
# Updated with progress indicators for better user experience

# Import progress indicators module
. .\BRAV\SCPT\progress-indicators.ps1

param(
    [string]$Environment = "production",
    [string]$ReportDir = "reports/gpu-sidecar",
    [int]$Iterations = 20,
    [int]$DelayMs = 1000
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path "logs/gpu-sidecar-monitoring.log" -Value $logEntry
}

function Run-Validation {
    param([int]$Iterations, [int]$DelayMs)
    
    Write-Log "Starting GPU sidecar validation (iterations: $Iterations)"
    
    $spinnerJob = Start-SpinnerJob -Message "Running GPU sidecar validation..." -UpdateIntervalMs 150
    try {
        $result = pwsh -File scripts/validate-production-gpu.ps1 -Iterations $Iterations -DelayMs $DelayMs
        Stop-SpinnerJob -Job $spinnerJob
        Write-Log "Validation completed successfully"
        return $true
    } catch {
        Stop-SpinnerJob -Job $spinnerJob
        Write-Log "Validation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Generate-Report {
    param([string]$ReportDir, [bool]$ValidationSuccess)
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportFile = "$ReportDir/gpu-sidecar-report-$timestamp.json"
    
    $spinnerJob = Start-SpinnerJob -Message "Generating report..." -UpdateIntervalMs 150
    if (-not (Test-Path $ReportDir)) {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    }
    
    $report = @{
        timestamp = $timestamp
        environment = $Environment
        validation_success = $ValidationSuccess
        sidecar_health = @{
            compression = $null
            aggregation = $null
            inference = $null
        }
        metrics = @{
            queue_depth = 0
            fallback_rate = 0
            processing_efficiency = 0
        }
    }
    
    # Check sidecar health
    $sidecars = @(
        @{ Name = "compression"; Url = "http://localhost:8001/health" },
        @{ Name = "aggregation"; Url = "http://localhost:8002/health" },
        @{ Name = "inference"; Url = "http://localhost:8003/health" }
    )
    
    foreach ($sidecar in $sidecars) {
        try {
            $response = Invoke-WebRequest -Uri $sidecar.Url -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                $data = $response.Content | ConvertFrom-Json
                $report.sidecar_health[$sidecar.Name] = $data
            }
        } catch {
            $report.sidecar_health[$sidecar.Name] = @{ error = $_.Exception.Message }
        }
    }
    
    # Check queue depth
    $bufferDirs = @("gpu-buffers/logs", "gpu-buffers/traces", "gpu-buffers/analytics", "gpu-buffers/inference")
    $totalFiles = 0
    foreach ($dir in $bufferDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem $dir -File
            $fileCount = if ($files) { $files.Count } else { 0 }
            $totalFiles += $fileCount
        }
    }
    $report.metrics.queue_depth = $totalFiles
    
    # Save report
    $report | ConvertTo-Json -Depth 3 | Set-Content -Path $reportFile -Encoding UTF8
    Stop-SpinnerJob -Job $spinnerJob
    Write-Log "Report generated: $reportFile"
    
    return $reportFile
}

# Main execution
Write-Log "Starting GPU sidecar production monitoring"

$validationSuccess = Run-Validation -Iterations $Iterations -DelayMs $DelayMs
$reportFile = Generate-Report -ReportDir $ReportDir -ValidationSuccess $validationSuccess

if ($validationSuccess) {
    Write-Log "Production monitoring completed successfully"
    exit 0
} else {
    Write-Log "Production monitoring completed with errors" "ERROR"
    exit 1
}
