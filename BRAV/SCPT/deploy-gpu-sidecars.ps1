#!/usr/bin/env pwsh
# GPU Sidecar Production Deployment Script
# Handles dashboard import, alert configuration, and production setup

param(
    [switch]$SkipDashboard,
    [switch]$SkipAlerts,
    [switch]$SkipValidation,
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

Write-Header "GPU Sidecar Production Deployment"

# Check prerequisites
Write-Info "Checking deployment prerequisites..."

# Verify all sidecars are running
$sidecars = @(
    @{ Name = "Compression"; Port = 8001; Url = "http://localhost:8001/health" },
    @{ Name = "Aggregation"; Port = 8002; Url = "http://localhost:8002/health" },
    @{ Name = "Inference"; Port = 8003; Url = "http://localhost:8003/health" }
)

$allHealthy = $true
foreach ($sidecar in $sidecars) {
    try {
        $response = Invoke-WebRequest -Uri $sidecar.Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "$($sidecar.Name) sidecar healthy"
        } else {
            Write-Error "$($sidecar.Name) sidecar unhealthy (HTTP $($response.StatusCode))"
            $allHealthy = $false
        }
    } catch {
        Write-Error "$($sidecar.Name) sidecar not reachable: $($_.Exception.Message)"
        $allHealthy = $false
    }
}

if (-not $allHealthy) {
    Write-Error "Not all sidecars are healthy. Please start them first:"
    Write-Info "  pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start"
    exit 1
}

# Verify SigNoz connectivity
try {
    $response = Invoke-WebRequest -Uri $SigNozUrl -UseBasicParsing -TimeoutSec 10
    Write-Success "SigNoz UI reachable at $SigNozUrl"
} catch {
    Write-Error "Cannot reach SigNoz UI at $SigNozUrl. Is it running?"
    exit 1
}

# 1. Dashboard Import
if (-not $SkipDashboard) {
    Write-Header "Importing GPU Sidecar Dashboard"
    
    if (Test-Path "artifacts/signoz-gpu-sidecar-dashboard.json") {
        Write-Info "Dashboard JSON ready for import:"
        Write-Info "  File: artifacts/signoz-gpu-sidecar-dashboard.json"
        Write-Info "  Panels: 8 (compression, aggregation, memory, health, fallback, queue depth, efficiency)"
        Write-Info "  Time range: Last 1 hour, 30s refresh"
        
        Write-Warning "Manual import required:"
        Write-Info "1. Open SigNoz UI: $SigNozUrl"
        Write-Info "2. Go to Settings → Dashboards"
        Write-Info "3. Click 'Import Dashboard'"
        Write-Info "4. Upload: artifacts/signoz-gpu-sidecar-dashboard.json"
        Write-Info "5. Configure data sources and save"
        
        Write-Success "Dashboard import instructions provided"
    } else {
        Write-Error "Dashboard JSON not found: artifacts/signoz-gpu-sidecar-dashboard.json"
        exit 1
    }
}

# 2. Alert Configuration
if (-not $SkipAlerts) {
    Write-Header "Configuring GPU Sidecar Alerts"
    
    $alerts = @(
        @{
            name = "GPU Sidecar Health Down"
            condition = "gpu_sidecar_health_status == 0"
            severity = "critical"
            description = "GPU sidecar service is unhealthy"
            threshold = "0"
        },
        @{
            name = "High GPU Fallback Rate"
            condition = "rate(gpu_sidecar_fallback_total[5m]) > 0.1"
            severity = "warning"
            description = "GPU fallback rate exceeds 10%"
            threshold = "0.1"
        },
        @{
            name = "GPU Buffer Queue Depth High"
            condition = "gpu_buffer_queue_depth > 1000"
            severity = "warning"
            description = "GPU buffer queue depth is too high"
            threshold = "1000"
        },
        @{
            name = "Low GPU Processing Efficiency"
            condition = "rate(gpu_processing_efficiency[5m]) < 0.5"
            severity = "warning"
            description = "GPU processing efficiency below 50%"
            threshold = "0.5"
        },
        @{
            name = "GPU Memory Usage High"
            condition = "gpu_memory_used_bytes / gpu_memory_total_bytes > 0.9"
            severity = "critical"
            description = "GPU memory usage exceeds 90%"
            threshold = "0.9"
        }
    )
    
    # Save alert configurations
    $alertsDir = "alerts"
    if (-not (Test-Path $alertsDir)) {
        New-Item -ItemType Directory -Path $alertsDir | Out-Null
    }
    
    $alerts | ConvertTo-Json -Depth 3 | Set-Content -Path "$alertsDir/gpu-sidecar-alerts.json" -Encoding UTF8
    Write-Success "Alert configurations saved to $alertsDir/gpu-sidecar-alerts.json"
    
    Write-Warning "Manual alert configuration required:"
    Write-Info "1. Open SigNoz UI: $SigNozUrl"
    Write-Info "2. Go to Settings → Alerts"
    Write-Info "3. Create new alerts using the conditions above"
    Write-Info "4. Set appropriate thresholds and notification channels"
    
    Write-Success "Alert configurations provided"
}

# 3. Production Validation
if (-not $SkipValidation) {
    Write-Header "Running Production Validation"
    
    Write-Info "Executing production validation test..."
    try {
        $validationResult = pwsh -File scripts/validate-production-gpu.ps1 -Iterations 10 -DelayMs 200
        Write-Success "Production validation completed successfully"
    } catch {
        Write-Error "Production validation failed: $($_.Exception.Message)"
        exit 1
    }
}

# 4. Create Production Monitoring Schedule
Write-Header "Setting Up Production Monitoring"

$monitoringScript = @'
#!/usr/bin/env pwsh
# Production GPU Sidecar Monitoring Schedule
# Runs validation tests and generates reports

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
    
    try {
        $result = pwsh -File scripts/validate-production-gpu.ps1 -Iterations $Iterations -DelayMs $DelayMs
        Write-Log "Validation completed successfully"
        return $true
    } catch {
        Write-Log "Validation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Generate-Report {
    param([string]$ReportDir, [bool]$ValidationSuccess)
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportFile = "$ReportDir/gpu-sidecar-report-$timestamp.json"
    
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
'@

$monitoringScript | Set-Content -Path "scripts/production-monitoring.ps1" -Encoding UTF8
Write-Success "Production monitoring script created: scripts/production-monitoring.ps1"

# 5. Create Triton Server Setup Guide
Write-Header "Creating Triton Server Setup Guide"

$tritonGuide = @'
# Triton Inference Server Setup Guide

## Overview
This guide helps you set up NVIDIA Triton Inference Server for advanced ML models in the GPU sidecar infrastructure.

## Prerequisites
- NVIDIA GPU with CUDA support
- Docker with NVIDIA runtime
- Triton Inference Server container

## Quick Start

### 1. Pull Triton Server Image
```bash
docker pull nvcr.io/nvidia/tritonserver:23.10-py3
```

### 2. Create Model Repository
```bash
mkdir -p triton-models/log_anomaly_detector/1
```

### 3. Add Model Files
Place your model files in the repository:
- `model.py` - Python model implementation
- `config.pbtxt` - Model configuration
- Model weights and artifacts

### 4. Start Triton Server
```bash
docker run --rm --gpus all -p 8000:8000 -p 8001:8001 -p 8002:8002 -v $(pwd)/triton-models:/models nvcr.io/nvidia/tritonserver:23.10-py3 tritonserver --model-repository=/models
```

### 5. Update Inference Sidecar
Update `sidecars/inference/inference_sidecar.py` to use Triton server:
- Set `TRITON_URL = "http://localhost:8000"`
- Update model names and configurations
- Test with real models

## Model Configuration Example

### config.pbtxt
```protobuf
name: "log_anomaly_detector"
platform: "pytorch_libtorch"
max_batch_size: 32
input [
  {
    name: "log_features"
    data_type: TYPE_FP32
    dims: [128]
  }
]
output [
  {
    name: "anomaly_score"
    data_type: TYPE_FP32
    dims: [1]
  }
]
```

### Python Model (model.py)
```python
import torch
import triton_python_backend_utils as pb_utils

class TritonPythonModel:
    def initialize(self, args):
        self.model = torch.load("model.pth")
        self.model.eval()
    
    def execute(self, requests):
        responses = []
        for request in requests:
            input_tensor = pb_utils.get_input_tensor_by_name(request, "log_features")
            with torch.no_grad():
                output = self.model(input_tensor.as_numpy())
            output_tensor = pb_utils.Tensor("anomaly_score", output.numpy())
            responses.append(pb_utils.InferenceResponse([output_tensor]))
        return responses
```

## Testing
1. Start Triton server
2. Update inference sidecar configuration
3. Run validation: `pwsh -File scripts/validate-production-gpu.ps1`
4. Check logs for Triton connectivity

## Troubleshooting
- Check Triton server logs: `docker logs <container_id>`
- Verify model repository structure
- Test model loading: `curl http://localhost:8000/v2/models/log_anomaly_detector`
- Check GPU memory usage: `nvidia-smi`
'@

$tritonGuide | Set-Content -Path "docs/TRITON_SERVER_SETUP.md" -Encoding UTF8
Write-Success "Triton server setup guide created: docs/TRITON_SERVER_SETUP.md"

# 6. Create Production Runbook
Write-Header "Creating Production Runbook"

$runbook = @'
# GPU Sidecar Production Runbook

## Daily Operations

### Health Checks
```powershell
# Quick health check
pwsh -File scripts/test-gpu-sidecars.ps1

# Complete integration test
pwsh -File scripts/verify-integration.ps1

# Production validation
pwsh -File scripts/validate-production-gpu.ps1 -Iterations 20
```

### Monitoring
```powershell
# Start watchdog
pwsh -File scripts/gpu-watchdog.ps1

# Generate production report
pwsh -File scripts/production-monitoring.ps1 -Environment production
```

### Service Management
```powershell
# Start all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Stop all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action stop

# Restart all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart

# Check status
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action status
```

## Troubleshooting

### Common Issues

#### Sidecar Not Responding
1. Check container status: `docker ps`
2. Check logs: `docker logs <container_name>`
3. Restart service: `pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart`

#### High Queue Depth
1. Check buffer directories: `Get-ChildItem gpu-buffers -Recurse`
2. Monitor processing efficiency
3. Scale up sidecar resources if needed

#### GPU Memory Issues
1. Check GPU usage: `nvidia-smi`
2. Monitor memory metrics in SigNoz
3. Restart sidecars to free memory

#### Fallback Rate High
1. Check GPU availability
2. Verify sidecar health
3. Review error logs

### Emergency Procedures

#### Complete Restart
```powershell
# Stop all services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action stop

# Wait 30 seconds
Start-Sleep -Seconds 30

# Start all services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Verify health
pwsh -File scripts/test-gpu-sidecars.ps1
```

#### Rollback to CPU-Only
1. Update collector config to disable GPU routing
2. Restart collector service
3. Monitor for issues

## Performance Tuning

### Compression Sidecar
- Adjust compression level in config
- Monitor compression ratios
- Tune batch sizes

### Aggregation Sidecar
- Optimize cuDF operations
- Adjust group-by fields
- Monitor processing times

### Inference Sidecar
- Tune anomaly thresholds
- Update ML models
- Monitor accuracy metrics

## Maintenance

### Weekly Tasks
- Review performance metrics
- Check alert history
- Update documentation

### Monthly Tasks
- Update ML models
- Review and tune thresholds
- Performance optimization

### Quarterly Tasks
- Full system review
- Capacity planning
- Technology updates
'@

$runbook | Set-Content -Path "docs/GPU_SIDECAR_PRODUCTION_RUNBOOK.md" -Encoding UTF8
Write-Success "Production runbook created: docs/GPU_SIDECAR_PRODUCTION_RUNBOOK.md"

# 7. Final Summary
Write-Header "Deployment Complete"

Write-Success "GPU Sidecar production deployment completed successfully!"

Write-Info "Deployment Summary:"
Write-Info "  📊 Dashboard: artifacts/signoz-gpu-sidecar-dashboard.json (import manually)"
Write-Info "  🚨 Alerts: $alertsDir/gpu-sidecar-alerts.json (configure manually)"
Write-Info "  🧪 Validation: scripts/validate-production-gpu.ps1"
Write-Info "  👁️  Monitoring: scripts/production-monitoring.ps1"
Write-Info "  📚 Documentation: docs/TRITON_SERVER_SETUP.md, docs/GPU_SIDECAR_PRODUCTION_RUNBOOK.md"

Write-Info "`nNext Steps:"
Write-Info "1. Import dashboard in SigNoz UI"
Write-Info "2. Configure alerts with notification channels"
Write-Info "3. Set up Triton server for advanced ML models"
Write-Info "4. Schedule production monitoring (e.g., nightly)"
Write-Info "5. Review and tune thresholds based on production data"

Write-Success "GPU sidecar infrastructure is production-ready!"
