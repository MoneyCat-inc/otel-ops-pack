#!/usr/bin/env pwsh
# GPU Sidecar Watchdog Script
# Monitors queue depth, fallback rates, and health status

param(
    [int]$CheckInterval = 30,
    [int]$MaxQueueDepth = 1000,
    [double]$MaxFallbackRate = 0.1,
    [string]$LogFile = "logs/gpu-watchdog.log"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

function Check-SidecarHealth {
    param([string]$Name, [string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $data = $response.Content | ConvertFrom-Json
            return @{
                Healthy = $true
                Data = $data
            }
        }
    } catch {
        Write-Log "Health check failed for $Name`: $($_.Exception.Message)" "ERROR"
    }
    
    return @{ Healthy = $false; Data = $null }
}

function Check-QueueDepth {
    $bufferDirs = @("gpu-buffers/logs", "gpu-buffers/traces", "gpu-buffers/analytics", "gpu-buffers/inference")
    $totalFiles = 0
    
    foreach ($dir in $bufferDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem $dir -File
            $fileCount = if ($files) { $files.Count } else { 0 }
            $totalFiles += $fileCount
        }
    }
    
    return $totalFiles
}

Write-Log "GPU Sidecar Watchdog started (interval: ${CheckInterval}s)"

while ($true) {
    try {
        # Check sidecar health
        $compressionHealth = Check-SidecarHealth "Compression" "http://localhost:8001/health"
        $aggregationHealth = Check-SidecarHealth "Aggregation" "http://localhost:8002/health"
        $inferenceHealth = Check-SidecarHealth "Inference" "http://localhost:8003/health"
        
        # Check queue depth
        $queueDepth = Check-QueueDepth
        
        # Log status
        $healthyCount = @($compressionHealth.Healthy, $aggregationHealth.Healthy, $inferenceHealth.Healthy) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
        Write-Log "Health: $healthyCount/3 sidecars healthy, Queue depth: $queueDepth"
        
        # Check thresholds
        if ($queueDepth -gt $MaxQueueDepth) {
            Write-Log "ALERT: Queue depth $queueDepth exceeds threshold $MaxQueueDepth" "WARN"
        }
        
        if (-not $compressionHealth.Healthy) {
            Write-Log "ALERT: Compression sidecar unhealthy" "ERROR"
        }
        
        if (-not $aggregationHealth.Healthy) {
            Write-Log "ALERT: Aggregation sidecar unhealthy" "ERROR"
        }
        
        if (-not $inferenceHealth.Healthy) {
            Write-Log "ALERT: Inference sidecar unhealthy" "ERROR"
        }
        
    } catch {
        Write-Log "Watchdog error: $($_.Exception.Message)" "ERROR"
    }
    
    Start-Sleep -Seconds $CheckInterval
}
