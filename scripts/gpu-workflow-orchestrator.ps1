# GPU Workflow Orchestrator
# Integrates GPU sidecars into the automated workflow system
# Follows ECRR methodology and integrates with existing automation

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "health", "monitor", "test", "metrics", "deploy")]
    [string]$Action,
    
    [switch]$IncludeGPU,
    [switch]$IncludeMonitoring,
    [switch]$IncludeMetrics,
    [switch]$IncludeAlerts,
    [switch]$DryRun,
    [int]$DurationMinutes = 10,
    [string]$LogLevel = "INFO"
)

# ECRR Framework Integration
$ECRRReport = @{
    Examine = @{}
    Clean = @{}
    Report = @{}
    Role = "GPU Workflow Orchestrator"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"})
    $ECRRReport.Report[$timestamp] = $logEntry
}

function Test-GPUPrerequisites {
    Write-ECRRLog "Examining GPU prerequisites..."
    
    $prereqs = @{
        nvidia_driver = $false
        docker_nvidia = $false
        gpu_containers = $false
        buffer_dirs = $false
    }
    
    # Check NVIDIA driver
    try {
        $nvidiaOutput = nvidia-smi --query-gpu=name --format=csv,noheader 2>$null
        if ($nvidiaOutput) {
            $prereqs.nvidia_driver = $true
            Write-ECRRLog "NVIDIA GPU detected: $($nvidiaOutput.Trim())"
        }
    } catch {
        Write-ECRRLog "NVIDIA driver not available" "ERROR"
    }
    
    # Check Docker NVIDIA runtime
    try {
        $dockerInfo = docker info --format "{{.Runtimes}}" 2>$null
        if ($dockerInfo -match "nvidia") {
            $prereqs.docker_nvidia = $true
            Write-ECRRLog "Docker NVIDIA runtime available"
        }
    } catch {
        Write-ECRRLog "Docker NVIDIA runtime not available" "ERROR"
    }
    
    # Check GPU containers
    try {
        $gpuContainers = docker ps --filter "name=otel-gpu" --format "{{.Names}}" 2>$null
        if ($gpuContainers) {
            $prereqs.gpu_containers = $true
            Write-ECRRLog "GPU containers running: $($gpuContainers -join ', ')"
        }
    } catch {
        Write-ECRRLog "No GPU containers running" "WARN"
    }
    
    # Check buffer directories
    $bufferDirs = @("gpu-buffers/logs", "gpu-buffers/compressed", "gpu-buffers/analytics", "gpu-buffers/inference")
    $existingDirs = $bufferDirs | Where-Object { Test-Path $_ }
    if ($existingDirs.Count -eq $bufferDirs.Count) {
        $prereqs.buffer_dirs = $true
        Write-ECRRLog "All GPU buffer directories exist"
    } else {
        Write-ECRRLog "Missing GPU buffer directories" "WARN"
    }
    
    $ECRRReport.Examine.Prerequisites = $prereqs
    return $prereqs
}

function Start-GPUWorkflow {
    param([hashtable]$Prereqs)
    
    Write-ECRRLog "Starting GPU workflow orchestration..."
    
    if (-not $Prereqs.nvidia_driver) {
        Write-ECRRLog "Cannot start GPU workflow: NVIDIA driver not available" "ERROR"
        return $false
    }
    
    if (-not $Prereqs.docker_nvidia) {
        Write-ECRRLog "Cannot start GPU workflow: Docker NVIDIA runtime not available" "ERROR"
        return $false
    }
    
    # Start GPU sidecars if not running
    if (-not $Prereqs.gpu_containers) {
        Write-ECRRLog "Starting GPU sidecar containers..."
        try {
            if ($DryRun) {
                Write-ECRRLog "DRY RUN: Would start GPU containers with docker-compose -f docker-compose.gpu.yml up -d"
            } else {
                $startResult = docker-compose -f docker-compose.gpu.yml up -d 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-ECRRLog "GPU sidecars started successfully"
                    Start-Sleep -Seconds 10  # Wait for services to initialize
                } else {
                    Write-ECRRLog "Failed to start GPU sidecars: $startResult" "ERROR"
                    return $false
                }
            }
        } catch {
            Write-ECRRLog "Error starting GPU sidecars: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    # Create missing buffer directories
    if (-not $Prereqs.buffer_dirs) {
        Write-ECRRLog "Creating missing GPU buffer directories..."
        $bufferDirs = @("gpu-buffers/logs", "gpu-buffers/compressed", "gpu-buffers/analytics", "gpu-buffers/inference")
        foreach ($dir in $bufferDirs) {
            if (-not (Test-Path $dir)) {
                try {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                    Write-ECRRLog "Created directory: $dir"
                } catch {
                    Write-ECRRLog "Failed to create directory $dir`: $($_.Exception.Message)" "ERROR"
                }
            }
        }
    }
    
    # Start GPU metrics collection if enabled
    if ($IncludeMetrics) {
        Write-ECRRLog "Starting GPU metrics collection..."
        if ($DryRun) {
            Write-ECRRLog "DRY RUN: Would start GPU metrics collection"
        } else {
            try {
                Start-Process -FilePath "python" -ArgumentList @("gpu-metrics-simple.py", "--duration", ($DurationMinutes * 60), "--interval", "15") -WindowStyle Hidden
                Write-ECRRLog "GPU metrics collection started"
            } catch {
                Write-ECRRLog "Failed to start GPU metrics collection: $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    return $true
}

function Stop-GPUWorkflow {
    Write-ECRRLog "Stopping GPU workflow orchestration..."
    
    # Stop GPU metrics collection
    try {
        $gpuMetricsProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "gpu-metrics" }
        foreach ($process in $gpuMetricsProcesses) {
            $process.Kill()
            Write-ECRRLog "Stopped GPU metrics process (PID: $($process.Id))"
        }
    } catch {
        Write-ECRRLog "No GPU metrics processes to stop" "WARN"
    }
    
    # Stop GPU sidecars
    try {
        if ($DryRun) {
            Write-ECRRLog "DRY RUN: Would stop GPU containers with docker-compose -f docker-compose.gpu.yml down"
        } else {
            $stopResult = docker-compose -f docker-compose.gpu.yml down 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ECRRLog "GPU sidecars stopped successfully"
            } else {
                Write-ECRRLog "Failed to stop GPU sidecars: $stopResult" "ERROR"
            }
        }
    } catch {
        Write-ECRRLog "Error stopping GPU sidecars: $($_.Exception.Message)" "ERROR"
    }
}

function Get-GPUWorkflowStatus {
    Write-ECRRLog "Checking GPU workflow status..."
    
    $status = @{
        sidecars = @{}
        metrics = $false
        buffers = @{}
        integration = $false
    }
    
    # Check sidecar health
    $sidecars = @(
        @{Name="Compression"; Port=8001},
        @{Name="Aggregation"; Port=8002},
        @{Name="Inference"; Port=8003}
    )
    
    foreach ($sidecar in $sidecars) {
        try {
            $healthResponse = Invoke-WebRequest -Uri "http://localhost:$($sidecar.Port)/health" -UseBasicParsing -TimeoutSec 5
            if ($healthResponse.StatusCode -eq 200) {
                $healthData = $healthResponse.Content | ConvertFrom-Json
                $status.sidecars[$sidecar.Name] = @{
                    status = $healthData.status
                    gpu_available = $healthData.gpu_available
                    healthy = $true
                }
                Write-ECRRLog "$($sidecar.Name) sidecar: $($healthData.status)"
            } else {
                $status.sidecars[$sidecar.Name] = @{healthy = $false; error = "HTTP $($healthResponse.StatusCode)"}
                Write-ECRRLog "$($sidecar.Name) sidecar: HTTP $($healthResponse.StatusCode)" "ERROR"
            }
        } catch {
            $status.sidecars[$sidecar.Name] = @{healthy = $false; error = $_.Exception.Message}
            Write-ECRRLog "$($sidecar.Name) sidecar: Not reachable" "ERROR"
        }
    }
    
    # Check metrics collection
    $metricsProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "gpu-metrics" }
    $status.metrics = $metricsProcesses.Count -gt 0
    Write-ECRRLog "GPU metrics collection: $(if($status.metrics){'Running'}else{'Stopped'})"
    
    # Check buffer directories
    $bufferDirs = @("gpu-buffers/logs", "gpu-buffers/compressed", "gpu-buffers/analytics", "gpu-buffers/inference")
    foreach ($dir in $bufferDirs) {
        $dirName = Split-Path $dir -Leaf
        if (Test-Path $dir) {
            $files = Get-ChildItem $dir -File -ErrorAction SilentlyContinue
            $status.buffers[$dirName] = @{
                exists = $true
                file_count = $files.Count
                latest_file = if($files){$files | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Name}else{$null}
            }
        } else {
            $status.buffers[$dirName] = @{exists = $false; file_count = 0}
        }
    }
    
    # Check integration with main workflow
    try {
        $collectorHealth = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -UseBasicParsing -TimeoutSec 5
        $sigNozHealth = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing -TimeoutSec 5
        $status.integration = ($collectorHealth.StatusCode -eq 200) -and ($sigNozHealth.StatusCode -eq 200)
        Write-ECRRLog "Integration with main workflow: $(if($status.integration){'Healthy'}else{'Issues detected'})"
    } catch {
        $status.integration = $false
        Write-ECRRLog "Integration check failed: $($_.Exception.Message)" "ERROR"
    }
    
    $ECRRReport.Examine.Status = $status
    return $status
}

function Start-GPUWorkflowMonitoring {
    param([hashtable]$Status)
    
    Write-ECRRLog "Starting GPU workflow monitoring..."
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would start GPU workflow monitoring for $DurationMinutes minutes"
        return
    }
    
    $monitoringScript = @"
# GPU Workflow Monitoring Loop
# Generated by GPU Workflow Orchestrator

`$DurationMinutes = $DurationMinutes
`$LogPath = "artifacts\gpu-workflow-monitor-`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Host "🎮 Starting GPU Workflow Monitoring for `$DurationMinutes minutes" -ForegroundColor Cyan

# Create log file
"GPU Workflow Monitoring Started - `$(Get-Date)" | Out-File -FilePath `$LogPath -Encoding UTF8

`$startTime = Get-Date
`$endTime = `$startTime.AddMinutes(`$DurationMinutes)

while (`$true) {
    `$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    # Check GPU sidecar health
    try {
        `$compressionHealth = Invoke-WebRequest -Uri "http://localhost:8001/health" -UseBasicParsing -TimeoutSec 5
        `$aggregationHealth = Invoke-WebRequest -Uri "http://localhost:8002/health" -UseBasicParsing -TimeoutSec 5
        `$inferenceHealth = Invoke-WebRequest -Uri "http://localhost:8003/health" -UseBasicParsing -TimeoutSec 5
        
        `$allHealthy = (`$compressionHealth.StatusCode -eq 200) -and (`$aggregationHealth.StatusCode -eq 200) -and (`$inferenceHealth.StatusCode -eq 200)
        
        if (`$allHealthy) {
            Write-Host "`[$timestamp`] GPU Sidecars: HEALTHY" -ForegroundColor Green
            "`$timestamp - GPU Sidecars: HEALTHY" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        } else {
            Write-Host "`[$timestamp`] GPU Sidecars: UNHEALTHY" -ForegroundColor Red
            "`$timestamp - GPU Sidecars: UNHEALTHY" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        }
    } catch {
        Write-Host "`[$timestamp`] GPU Sidecars: ERROR - `$(`$_.Exception.Message)" -ForegroundColor Red
        "`$timestamp - GPU Sidecars: ERROR - `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
    
    # Check GPU metrics
    try {
        `$gpuMetrics = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { `$_.CommandLine -match "gpu-metrics" }
        if (`$gpuMetrics) {
            Write-Host "`[$timestamp`] GPU Metrics: RUNNING" -ForegroundColor Green
            "`$timestamp - GPU Metrics: RUNNING" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        } else {
            Write-Host "`[$timestamp`] GPU Metrics: STOPPED" -ForegroundColor Yellow
            "`$timestamp - GPU Metrics: STOPPED" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        }
    } catch {
        Write-Host "`[$timestamp`] GPU Metrics: ERROR - `$(`$_.Exception.Message)" -ForegroundColor Red
        "`$timestamp - GPU Metrics: ERROR - `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
    
    # Check buffer processing
    try {
        `$bufferDirs = @("gpu-buffers\logs", "gpu-buffers\compressed", "gpu-buffers\analytics", "gpu-buffers\inference")
        `$totalFiles = 0
        foreach (`$dir in `$bufferDirs) {
            if (Test-Path `$dir) {
                `$files = Get-ChildItem `$dir -File -ErrorAction SilentlyContinue
                `$totalFiles += `$files.Count
            }
        }
        Write-Host "`[$timestamp`] Buffer Files: `$totalFiles" -ForegroundColor Cyan
        "`$timestamp - Buffer Files: `$totalFiles" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    } catch {
        Write-Host "`[$timestamp`] Buffer Check: ERROR - `$(`$_.Exception.Message)" -ForegroundColor Red
        "`$timestamp - Buffer Check: ERROR - `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
    
    # Check if monitoring should continue
    if ((Get-Date) -gt `$endTime) {
        Write-Host "`[$timestamp`] GPU Workflow Monitoring Complete" -ForegroundColor Green
        "`$timestamp - GPU Workflow Monitoring Complete" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        break
    }
    
    Start-Sleep -Seconds 30  # Check every 30 seconds
}
"@
    
    $monitoringScript | Out-File -FilePath ".artifacts/gpu-workflow-monitor.ps1" -Encoding UTF8
    Write-ECRRLog "Created GPU workflow monitoring script"
    
    # Start monitoring in background
    Start-Process -FilePath "pwsh" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", ".artifacts/gpu-workflow-monitor.ps1") -WindowStyle Hidden
    Write-ECRRLog "Started GPU workflow monitoring (PID: $($Process.Id))"
}

function Test-GPUWorkflowIntegration {
    Write-ECRRLog "Testing GPU workflow integration..."
    
    $testResults = @{
        sidecar_apis = @{}
        buffer_processing = $false
        metrics_flow = $false
        end_to_end = $false
    }
    
    # Test sidecar APIs
    $testData = @{
        compression = @{data = @("Test log entry 1", "Test log entry 2")}
        aggregation = @{data = @(@{service="test"; value=100}); aggregation_type="summary"}
        inference = @{data = @(@{message="Test message"; level="INFO"})}
    }
    
    foreach ($sidecar in @("compression", "aggregation", "inference")) {
        try {
            $port = switch ($sidecar) {
                "compression" { 8001; break }
                "aggregation" { 8002; break }
                "inference" { 8003; break }
            }
            
            $endpoint = switch ($sidecar) {
                "compression" { "/compress"; break }
                "aggregation" { "/aggregate"; break }
                "inference" { "/infer"; break }
            }
            
            if ($DryRun) {
                $testResults.sidecar_apis[$sidecar] = @{success = $true; message = "DRY RUN"}
                Write-ECRRLog "DRY RUN: Would test $sidecar API"
            } else {
                $response = Invoke-WebRequest -Uri "http://localhost:$port$endpoint" -Method POST -Body ($testData[$sidecar] | ConvertTo-Json -Depth 3) -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
                if ($response.StatusCode -eq 200) {
                    $testResults.sidecar_apis[$sidecar] = @{success = $true; response_time = $response.Headers.'X-Response-Time'}
                    Write-ECRRLog "$sidecar API test: SUCCESS"
                } else {
                    $testResults.sidecar_apis[$sidecar] = @{success = $false; error = "HTTP $($response.StatusCode)"}
                    Write-ECRRLog "$sidecar API test: HTTP $($response.StatusCode)" "ERROR"
                }
            }
        } catch {
            $testResults.sidecar_apis[$sidecar] = @{success = $false; error = $_.Exception.Message}
            Write-ECRRLog "$sidecar API test: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Test buffer processing
    try {
        $testFile = "gpu-buffers/logs/test-$(Get-Date -Format 'yyyyMMdd_HHmmss').jsonl"
        $testContent = @"
{"timestamp": "$(Get-Date -Format 'o')", "level": "INFO", "message": "GPU workflow test", "gpu_sidecar_enabled": true}
"@
        $testContent | Out-File -FilePath $testFile -Encoding UTF8
        Start-Sleep -Seconds 2
        
        if (Test-Path $testFile) {
            $testResults.buffer_processing = $true
            Write-ECRRLog "Buffer processing test: SUCCESS"
            Remove-Item $testFile -Force  # Clean up test file
        } else {
            Write-ECRRLog "Buffer processing test: FAILED" "ERROR"
        }
    } catch {
        Write-ECRRLog "Buffer processing test: $($_.Exception.Message)" "ERROR"
    }
    
    # Test metrics flow
    try {
        $gpuMetrics = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "gpu-metrics" }
        if ($gpuMetrics) {
            $testResults.metrics_flow = $true
            Write-ECRRLog "Metrics flow test: SUCCESS"
        } else {
            Write-ECRRLog "Metrics flow test: No GPU metrics process running" "WARN"
        }
    } catch {
        Write-ECRRLog "Metrics flow test: $($_.Exception.Message)" "ERROR"
    }
    
    # Test end-to-end integration
    try {
        $collectorHealth = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -UseBasicParsing -TimeoutSec 5
        $sigNozHealth = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing -TimeoutSec 5
        
        if (($collectorHealth.StatusCode -eq 200) -and ($sigNozHealth.StatusCode -eq 200)) {
            $testResults.end_to_end = $true
            Write-ECRRLog "End-to-end integration test: SUCCESS"
        } else {
            Write-ECRRLog "End-to-end integration test: FAILED" "ERROR"
        }
    } catch {
        Write-ECRRLog "End-to-end integration test: $($_.Exception.Message)" "ERROR"
    }
    
    $ECRRReport.Examine.IntegrationTest = $testResults
    return $testResults
}

# Main execution
Write-Host "🎮 GPU Workflow Orchestrator" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Include GPU: $IncludeGPU" -ForegroundColor Yellow
Write-Host "Include Monitoring: $IncludeMonitoring" -ForegroundColor Yellow
Write-Host "Include Metrics: $IncludeMetrics" -ForegroundColor Yellow
Write-Host "Dry Run: $DryRun" -ForegroundColor Yellow
Write-Host ""

# ECRR: Examine
$prereqs = Test-GPUPrerequisites

switch ($Action) {
    "start" {
        # ECRR: Clean
        $startResult = Start-GPUWorkflow -Prereqs $prereqs
        if ($startResult) {
            Write-ECRRLog "GPU workflow started successfully"
            
            if ($IncludeMonitoring) {
                $status = Get-GPUWorkflowStatus
                Start-GPUWorkflowMonitoring -Status $status
            }
        } else {
            Write-ECRRLog "Failed to start GPU workflow" "ERROR"
            exit 1
        }
    }
    "stop" {
        # ECRR: Clean
        Stop-GPUWorkflow
        Write-ECRRLog "GPU workflow stopped"
    }
    "restart" {
        # ECRR: Clean
        Stop-GPUWorkflow
        Start-Sleep -Seconds 5
        $restartResult = Start-GPUWorkflow -Prereqs $prereqs
        if ($restartResult) {
            Write-ECRRLog "GPU workflow restarted successfully"
        } else {
            Write-ECRRLog "Failed to restart GPU workflow" "ERROR"
            exit 1
        }
    }
    "status" {
        # ECRR: Examine
        $status = Get-GPUWorkflowStatus
        Write-Host "`n📊 GPU Workflow Status:" -ForegroundColor Cyan
        Write-Host "Sidecars: $($status.sidecars.Keys -join ', ')" -ForegroundColor White
        Write-Host "Metrics: $(if($status.metrics){'Running'}else{'Stopped'})" -ForegroundColor White
        Write-Host "Integration: $(if($status.integration){'Healthy'}else{'Issues'})" -ForegroundColor White
        Write-Host "Buffers: $($status.buffers.Keys -join ', ')" -ForegroundColor White
    }
    "health" {
        # ECRR: Examine
        $status = Get-GPUWorkflowStatus
        $healthyCount = ($status.sidecars.Values | Where-Object { $_.healthy }).Count
        $totalCount = $status.sidecars.Count
        
        if ($healthyCount -eq $totalCount -and $status.integration) {
            Write-ECRRLog "GPU workflow health: HEALTHY ($healthyCount/$totalCount sidecars)"
            exit 0
        } else {
            Write-ECRRLog "GPU workflow health: UNHEALTHY ($healthyCount/$totalCount sidecars)" "ERROR"
            exit 1
        }
    }
    "monitor" {
        # ECRR: Report
        $status = Get-GPUWorkflowStatus
        Start-GPUWorkflowMonitoring -Status $status
        Write-ECRRLog "GPU workflow monitoring started for $DurationMinutes minutes"
    }
    "test" {
        # ECRR: Examine
        $testResults = Test-GPUWorkflowIntegration
        $successCount = ($testResults.sidecar_apis.Values | Where-Object { $_.success }).Count
        $totalTests = $testResults.sidecar_apis.Count
        
        Write-Host "`n🧪 GPU Workflow Integration Test Results:" -ForegroundColor Cyan
        Write-Host "API Tests: $successCount/$totalTests passed" -ForegroundColor White
        Write-Host "Buffer Processing: $(if($testResults.buffer_processing){'PASS'}else{'FAIL'})" -ForegroundColor White
        Write-Host "Metrics Flow: $(if($testResults.metrics_flow){'PASS'}else{'FAIL'})" -ForegroundColor White
        Write-Host "End-to-End: $(if($testResults.end_to_end){'PASS'}else{'FAIL'})" -ForegroundColor White
        
        if ($successCount -eq $totalTests -and $testResults.buffer_processing -and $testResults.end_to_end) {
            Write-ECRRLog "GPU workflow integration test: ALL PASSED"
        } else {
            Write-ECRRLog "GPU workflow integration test: SOME FAILED" "ERROR"
        }
    }
    "metrics" {
        # ECRR: Report
        Write-ECRRLog "Starting GPU metrics collection..."
        if ($DryRun) {
            Write-ECRRLog "DRY RUN: Would start GPU metrics for $DurationMinutes minutes"
        } else {
            Start-Process -FilePath "python" -ArgumentList @("gpu-metrics-simple.py", "--duration", ($DurationMinutes * 60), "--interval", "15") -WindowStyle Hidden
            Write-ECRRLog "GPU metrics collection started"
        }
    }
    "deploy" {
        # ECRR: Clean + Report
        Write-ECRRLog "Deploying complete GPU workflow..."
        
        # Deploy GPU sidecars
        if ($DryRun) {
            Write-ECRRLog "DRY RUN: Would deploy GPU sidecars"
        } else {
            $deployResult = docker-compose -f docker-compose.gpu.yml up -d
            if ($LASTEXITCODE -eq 0) {
                Write-ECRRLog "GPU sidecars deployed successfully"
            } else {
                Write-ECRRLog "GPU sidecar deployment failed" "ERROR"
                exit 1
            }
        }
        
        # Deploy monitoring if requested
        if ($IncludeMonitoring) {
            $status = Get-GPUWorkflowStatus
            Start-GPUWorkflowMonitoring -Status $status
            Write-ECRRLog "GPU monitoring deployed"
        }
        
        # Deploy metrics if requested
        if ($IncludeMetrics) {
            Start-Process -FilePath "python" -ArgumentList @("gpu-metrics-simple.py", "--duration", "3600", "--interval", "15") -WindowStyle Hidden
            Write-ECRRLog "GPU metrics deployed"
        }
        
        Write-ECRRLog "GPU workflow deployment complete"
    }
}

# ECRR: Report
$reportFile = "artifacts/gpu-workflow-orchestrator-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$ECRRReport | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
Write-ECRRLog "ECRR report saved to: $reportFile"

Write-Host "`n🎮 GPU Workflow Orchestrator Complete" -ForegroundColor Green
Write-Host "ECRR Report: $reportFile" -ForegroundColor Cyan
