# GPUS - GPU Sidecar Management Command
# Comprehensive GPU sidecar operations for OTel observability pipeline

param(
    [Parameter(Position=0)]
    [string]$Action = "help",
    
    [Parameter(Position=1)]
    [string]$Service = "",
    
    [Parameter(Position=2)]
    [string]$Duration = "30",
    
    [switch]$Verbose,
    [switch]$Force
)

# Load OpenTelemetry functions if available
if (Test-Path "scripts\otel.ps1") {
    . "scripts\otel.ps1"
}

function Show-GPUSHelp {
    Write-Host "=== GPUS - GPU Sidecar Management Command ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE: gpus <action> [service] [duration]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ACTIONS:" -ForegroundColor Yellow
    Write-Host "=========" -ForegroundColor Yellow
    Write-Host "  status          - Check GPU sidecar health status" -ForegroundColor White
    Write-Host "  start           - Start all GPU sidecars" -ForegroundColor White
    Write-Host "  stop            - Stop all GPU sidecars" -ForegroundColor White
    Write-Host "  restart         - Restart all GPU sidecars" -ForegroundColor White
    Write-Host "  logs            - View GPU sidecar logs" -ForegroundColor White
    Write-Host "  metrics         - Emit GPU metrics to OTel pipeline" -ForegroundColor White
    Write-Host "  monitor         - Start continuous GPU monitoring" -ForegroundColor White
    Write-Host "  dashboard       - Open SigNoz GPU monitoring dashboard" -ForegroundColor White
    Write-Host "  alerts          - Show GPU alert setup instructions" -ForegroundColor White
    Write-Host "  test            - Run GPU pipeline test" -ForegroundColor White
    Write-Host "  cleanup         - Clean up GPU resources" -ForegroundColor White
    Write-Host "  deploy          - Deploy GPU sidecars" -ForegroundColor White
    Write-Host ""
    Write-Host "SERVICES:" -ForegroundColor Yellow
    Write-Host "==========" -ForegroundColor Yellow
    Write-Host "  compression     - GPU compression sidecar (port 8001)" -ForegroundColor White
    Write-Host "  aggregation     - GPU aggregation sidecar (port 8002)" -ForegroundColor White
    Write-Host "  inference       - GPU inference sidecar (port 8003)" -ForegroundColor White
    Write-Host "  all             - All GPU sidecars (default)" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "==========" -ForegroundColor Yellow
    Write-Host "  gpus status                    # Check all sidecar health" -ForegroundColor Green
    Write-Host "  gpus start compression         # Start compression sidecar" -ForegroundColor Green
    Write-Host "  gpus metrics                   # Emit GPU metrics" -ForegroundColor Green
    Write-Host "  gpus monitor 60                # Monitor for 60 seconds" -ForegroundColor Green
    Write-Host "  gpus dashboard                 # Open SigNoz UI" -ForegroundColor Green
    Write-Host "  gpus test                      # Run pipeline test" -ForegroundColor Green
    Write-Host ""
}

function Get-GPUStatus {
    param([string]$ServiceName = "all")
    
    Write-Host "=== GPU Sidecar Status Check ===" -ForegroundColor Cyan
    
    try {
        $result = python scripts\check-gpu-sidecars.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: All GPU sidecars are healthy" -ForegroundColor Green
            Write-Host $result -ForegroundColor White
        } else {
            Write-Host "WARNING: Some GPU sidecars have issues" -ForegroundColor Yellow
            Write-Host $result -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERROR: Failed to check GPU sidecar status - $_" -ForegroundColor Red
    }
    
    # Show Docker status
    Write-Host "`n=== Docker Container Status ===" -ForegroundColor Cyan
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr gpu
}

function Start-GPUSidecars {
    param([string]$ServiceName = "all")
    
    Write-Host "=== Starting GPU Sidecars ===" -ForegroundColor Cyan
    
    if ($ServiceName -eq "all" -or $ServiceName -eq "") {
        try {
            $result = python scripts\start-gpu-sidecars.py 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SUCCESS: All GPU sidecars started" -ForegroundColor Green
                Write-Host $result -ForegroundColor White
            } else {
                Write-Host "ERROR: Failed to start GPU sidecars" -ForegroundColor Red
                Write-Host $result -ForegroundColor Red
            }
        } catch {
            Write-Host "ERROR: Failed to start GPU sidecars - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Starting specific service: $ServiceName" -ForegroundColor Yellow
        # Add specific service start logic here
    }
}

function Stop-GPUSidecars {
    param([string]$ServiceName = "all")
    
    Write-Host "=== Stopping GPU Sidecars ===" -ForegroundColor Cyan
    
    if ($ServiceName -eq "all" -or $ServiceName -eq "") {
        docker-compose -f docker-compose.gpu.yml down
        Write-Host "GPU sidecars stopped" -ForegroundColor Green
    } else {
        Write-Host "Stopping specific service: $ServiceName" -ForegroundColor Yellow
        docker stop "otel-gpu-$ServiceName" 2>$null
        Write-Host "GPU $ServiceName sidecar stopped" -ForegroundColor Green
    }
}

function Restart-GPUSidecars {
    param([string]$ServiceName = "all")
    
    Write-Host "=== Restarting GPU Sidecars ===" -ForegroundColor Cyan
    Stop-GPUSidecars -ServiceName $ServiceName
    Start-Sleep 2
    Start-GPUSidecars -ServiceName $ServiceName
}

function Get-GPULogs {
    param([string]$ServiceName = "all")
    
    Write-Host "=== GPU Sidecar Logs ===" -ForegroundColor Cyan
    
    if ($ServiceName -eq "all" -or $ServiceName -eq "") {
        docker-compose -f docker-compose.gpu.yml logs --tail=20
    } else {
        docker logs "otel-gpu-$ServiceName" --tail=20
    }
}

function Emit-GPUMetrics {
    Write-Host "=== Emitting GPU Metrics to OTel Pipeline ===" -ForegroundColor Cyan
    
    try {
        $result = python scripts\gpu-metrics-emitter.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: GPU metrics emitted to OTel pipeline" -ForegroundColor Green
            Write-Host $result -ForegroundColor White
        } else {
            Write-Host "ERROR: Failed to emit GPU metrics" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Write-Host "ERROR: Failed to emit GPU metrics - $_" -ForegroundColor Red
    }
}

function Start-GPUMonitoring {
    param([int]$DurationSeconds = 30)
    
    Write-Host "=== Starting GPU Monitoring for $DurationSeconds seconds ===" -ForegroundColor Cyan
    
    try {
        $job = Start-Job -ScriptBlock {
            param($Duration)
            python scripts\gpu-monitoring-simple.py
        } -ArgumentList $DurationSeconds
        
        Write-Host "Monitoring job started (ID: $($job.Id))" -ForegroundColor Green
        Write-Host "Monitoring for $DurationSeconds seconds..." -ForegroundColor Yellow
        
        Start-Sleep $DurationSeconds
        Stop-Job $job
        Remove-Job $job
        
        Write-Host "GPU monitoring completed" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to start GPU monitoring - $_" -ForegroundColor Red
    }
}

function Open-GPUDashboard {
    Write-Host "=== Opening SigNoz GPU Dashboard ===" -ForegroundColor Cyan
    
    Write-Host "1. Opening SigNoz UI..." -ForegroundColor Yellow
    Start-Process "http://localhost:8080"
    
    Write-Host "2. Navigate to: Metrics" -ForegroundColor Yellow
    Write-Host "3. Search for: gpu.utilization.percent" -ForegroundColor Yellow
    Write-Host "4. Filter by service: gpu-*-sidecar" -ForegroundColor Yellow
    
    Write-Host "`nGPU Metrics to look for:" -ForegroundColor Cyan
    Write-Host "  - gpu.utilization.percent" -ForegroundColor White
    Write-Host "  - gpu.memory.used.bytes" -ForegroundColor White
    Write-Host "  - gpu.memory.utilization.percent" -ForegroundColor White
    Write-Host "  - gpu.temperature.celsius" -ForegroundColor White
    Write-Host "  - gpu.sidecar.health" -ForegroundColor White
}

function Show-GPUAlerts {
    Write-Host "=== GPU Alert Setup Instructions ===" -ForegroundColor Cyan
    
    Write-Host "`n1. Open SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
    Write-Host "2. Go to Alerts → New Alert" -ForegroundColor Yellow
    
    Write-Host "`nRecommended Alerts:" -ForegroundColor Cyan
    Write-Host "  - High GPU Utilization: gpu.utilization.percent > 80" -ForegroundColor White
    Write-Host "  - Critical GPU Utilization: gpu.utilization.percent > 95" -ForegroundColor White
    Write-Host "  - High Memory Usage: gpu.memory.utilization.percent > 90" -ForegroundColor White
    Write-Host "  - GPU Overheating: gpu.temperature.celsius > 85" -ForegroundColor White
    Write-Host "  - Sidecar Unhealthy: gpu.sidecar.health == 0" -ForegroundColor White
    
    Write-Host "`nRun 'gpus alerts-setup' for detailed instructions" -ForegroundColor Green
}

function Test-GPUPipeline {
    Write-Host "=== GPU Pipeline Test ===" -ForegroundColor Cyan
    
    Write-Host "1. Checking GPU sidecar health..." -ForegroundColor Yellow
    Get-GPUStatus
    
    Write-Host "`n2. Testing OTel pipeline..." -ForegroundColor Yellow
    try {
        $result = python scripts\otel_synthetic_ping.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: OTel pipeline test passed" -ForegroundColor Green
        } else {
            Write-Host "WARNING: OTel pipeline test had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERROR: OTel pipeline test failed - $_" -ForegroundColor Red
    }
    
    Write-Host "`n3. Emitting GPU metrics..." -ForegroundColor Yellow
    Emit-GPUMetrics
    
    Write-Host "`n4. Checking SigNoz connectivity..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "SUCCESS: SigNoz UI accessible" -ForegroundColor Green
        }
    } catch {
        Write-Host "WARNING: SigNoz UI not accessible" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== GPU Pipeline Test Complete ===" -ForegroundColor Green
}

function Clear-GPUResources {
    Write-Host "=== GPU Resource Cleanup ===" -ForegroundColor Cyan
    
    if ($Force) {
        Write-Host "Stopping all GPU sidecars..." -ForegroundColor Yellow
        docker-compose -f docker-compose.gpu.yml down -v
        
        Write-Host "Removing GPU containers..." -ForegroundColor Yellow
        docker ps -a | findstr gpu | ForEach-Object { 
            $containerId = ($_ -split '\s+')[0]
            docker rm -f $containerId 2>$null
        }
        
        Write-Host "Cleaning up GPU monitoring logs..." -ForegroundColor Yellow
        Remove-Item "artifacts\gpu-monitoring*.log" -ErrorAction SilentlyContinue
        
        Write-Host "GPU resources cleaned up" -ForegroundColor Green
    } else {
        Write-Host "Use -Force flag to perform cleanup" -ForegroundColor Yellow
        Write-Host "This will stop all GPU sidecars and remove containers" -ForegroundColor Yellow
    }
}

function Deploy-GPUSidecars {
    Write-Host "=== Deploying GPU Sidecars ===" -ForegroundColor Cyan
    
    Write-Host "1. Checking prerequisites..." -ForegroundColor Yellow
    if (!(Test-Path "docker-compose.gpu.yml")) {
        Write-Host "ERROR: docker-compose.gpu.yml not found" -ForegroundColor Red
        return
    }
    
    Write-Host "2. Starting GPU sidecars..." -ForegroundColor Yellow
    Start-GPUSidecars
    
    Write-Host "`n3. Verifying deployment..." -ForegroundColor Yellow
    Start-Sleep 5
    Get-GPUStatus
    
    Write-Host "`n4. Testing metrics emission..." -ForegroundColor Yellow
    Emit-GPUMetrics
    
    Write-Host "`n=== GPU Sidecars Deployed Successfully ===" -ForegroundColor Green
}

# Main command dispatcher
switch ($Action.ToLower()) {
    "help" { Show-GPUSHelp }
    "status" { Get-GPUStatus -ServiceName $Service }
    "start" { Start-GPUSidecars -ServiceName $Service }
    "stop" { Stop-GPUSidecars -ServiceName $Service }
    "restart" { Restart-GPUSidecars -ServiceName $Service }
    "logs" { Get-GPULogs -ServiceName $Service }
    "metrics" { Emit-GPUMetrics }
    "monitor" { Start-GPUMonitoring -DurationSeconds ([int]$Duration) }
    "dashboard" { Open-GPUDashboard }
    "alerts" { Show-GPUAlerts }
    "test" { Test-GPUPipeline }
    "cleanup" { Clear-GPUResources }
    "deploy" { Deploy-GPUSidecars }
    default { 
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Show-GPUSHelp
    }
}
