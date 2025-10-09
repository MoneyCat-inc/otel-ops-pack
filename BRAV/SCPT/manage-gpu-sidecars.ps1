# GPU Sidecar Management Script
# Start, stop, and monitor GPU sidecar services

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "test")]
    [string]$Action
)

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail { param([string]$Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red }

function Start-GPUSidecars {
    Write-Host "Starting GPU Sidecars..." -ForegroundColor Yellow
    
    # Start compression sidecar
    try {
        $compressionContainer = docker run -d --name gpu-compression-sidecar --runtime=nvidia --gpus all -p 8001:8001 -v ${PWD}/gpu-buffers:/app/gpu-buffers otel-gpu-sidecar:latest python3 /app/sidecars/compression/compression_sidecar.py
        Write-Pass "Compression sidecar started"
    } catch {
        Write-Fail "Failed to start compression sidecar: $($_.Exception.Message)"
    }
    
    # Start aggregation sidecar
    try {
        $aggregationContainer = docker run -d --name gpu-aggregation-sidecar --runtime=nvidia --gpus all -p 8002:8002 -v ${PWD}/gpu-buffers:/app/gpu-buffers otel-gpu-sidecar:latest python3 /app/sidecars/aggregation/aggregation_sidecar.py
        Write-Pass "Aggregation sidecar started"
    } catch {
        Write-Fail "Failed to start aggregation sidecar: $($_.Exception.Message)"
    }
    
    # Start inference sidecar
    try {
        $inferenceContainer = docker run -d --name gpu-inference-sidecar --runtime=nvidia --gpus all -p 8003:8003 -v ${PWD}/gpu-buffers:/app/gpu-buffers otel-gpu-sidecar:latest python3 /app/sidecars/inference/inference_sidecar.py
        Write-Pass "Inference sidecar started"
    } catch {
        Write-Fail "Failed to start inference sidecar: $($_.Exception.Message)"
    }
    
    Write-Host "`nWaiting for services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Test health endpoints
    Test-GPUSidecarHealth
}

function Stop-GPUSidecars {
    Write-Host "Stopping GPU Sidecars..." -ForegroundColor Yellow
    
    $containers = @("gpu-compression-sidecar", "gpu-aggregation-sidecar", "gpu-inference-sidecar")
    
    foreach ($container in $containers) {
        try {
            docker stop $container 2>$null
            docker rm $container 2>$null
            Write-Pass "Stopped $container"
        } catch {
            Write-Detail "Container $container not running"
        }
    }
}

function Get-GPUSidecarStatus {
    Write-Host "GPU Sidecar Status:" -ForegroundColor Yellow
    
    $containers = @("gpu-compression-sidecar", "gpu-aggregation-sidecar", "gpu-inference-sidecar")
    $ports = @(8001, 8002, 8003)
    $names = @("Compression", "Aggregation", "Inference")
    
    for ($i = 0; $i -lt $containers.Length; $i++) {
        $container = $containers[$i]
        $port = $ports[$i]
        $name = $names[$i]
        
        # Check if container is running
        $containerStatus = docker ps --filter "name=$container" --format "{{.Status}}" 2>$null
        if ($containerStatus) {
            Write-Pass "$name sidecar is running"
            Write-Detail "Container: $containerStatus"
            
            # Check health endpoint
            try {
                $healthResponse = Invoke-WebRequest -Uri "http://localhost:$port/health" -UseBasicParsing -TimeoutSec 5
                if ($healthResponse.StatusCode -eq 200) {
                    $healthData = $healthResponse.Content | ConvertFrom-Json
                    Write-Detail "Health: $($healthData.status)"
                    if ($healthData.gpu_available) {
                        Write-Detail "GPU: Available"
                    } else {
                        Write-Detail "GPU: Not available"
                    }
                } else {
                    Write-Detail "Health: HTTP $($healthResponse.StatusCode)"
                }
            } catch {
                Write-Detail "Health: Not reachable"
            }
        } else {
            Write-Fail "$name sidecar is not running"
        }
    }
}

function Show-GPUSidecarLogs {
    param([string]$Service = "all")
    
    Write-Host "GPU Sidecar Logs:" -ForegroundColor Yellow
    
    if ($Service -eq "all" -or $Service -eq "compression") {
        Write-Host "`n--- Compression Sidecar Logs ---" -ForegroundColor Cyan
        docker logs gpu-compression-sidecar --tail 20 2>$null
    }
    
    if ($Service -eq "all" -or $Service -eq "aggregation") {
        Write-Host "`n--- Aggregation Sidecar Logs ---" -ForegroundColor Cyan
        docker logs gpu-aggregation-sidecar --tail 20 2>$null
    }
    
    if ($Service -eq "all" -or $Service -eq "inference") {
        Write-Host "`n--- Inference Sidecar Logs ---" -ForegroundColor Cyan
        docker logs gpu-inference-sidecar --tail 20 2>$null
    }
}

function Test-GPUSidecarHealth {
    Write-Host "Testing GPU Sidecar Health..." -ForegroundColor Yellow
    
    $endpoints = @(
        @{Name="Compression"; Port=8001; Path="/health"},
        @{Name="Aggregation"; Port=8002; Path="/health"},
        @{Name="Inference"; Port=8003; Path="/health"}
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$($endpoint.Port)$($endpoint.Path)" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                $data = $response.Content | ConvertFrom-Json
                Write-Pass "$($endpoint.Name) sidecar healthy"
                Write-Detail "Status: $($data.status)"
                if ($data.gpu_available) {
                    Write-Detail "GPU: Available"
                }
            } else {
                Write-Fail "$($endpoint.Name) sidecar unhealthy: HTTP $($response.StatusCode)"
            }
        } catch {
            Write-Fail "$($endpoint.Name) sidecar not reachable: $($_.Exception.Message)"
        }
    }
}

# Main execution
switch ($Action) {
    "start" {
        Start-GPUSidecars
    }
    "stop" {
        Stop-GPUSidecars
    }
    "restart" {
        Stop-GPUSidecars
        Start-Sleep -Seconds 2
        Start-GPUSidecars
    }
    "status" {
        Get-GPUSidecarStatus
    }
    "logs" {
        Show-GPUSidecarLogs
    }
    "test" {
        Test-GPUSidecarHealth
    }
}

Write-Host "`nGPU Sidecar Management Complete" -ForegroundColor Green
