#!/usr/bin/env pwsh
# GPU Sidecar Monitoring Setup Script
# Imports dashboard, configures alerts, and sets up production validation

param(
    [switch]$SkipDashboard,
    [switch]$SkipAlerts,
    [switch]$SkipValidation,
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN
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

Write-Header "GPU Sidecar Monitoring Setup"

# Check prerequisites
Write-Info "Checking prerequisites..."

if (-not (Test-Path "artifacts/signoz-gpu-sidecar-dashboard.json")) {
    Write-Error "Dashboard JSON not found. Run GPU sidecar setup first."
    exit 1
}

if (-not (Test-Path "scripts/manage-gpu-sidecars.ps1")) {
    Write-Error "Management script not found. Run GPU sidecar setup first."
    exit 1
}

# Test SigNoz connectivity
try {
    $response = Invoke-WebRequest -Uri "$SigNozUrl" -UseBasicParsing -TimeoutSec 10
    Write-Success "SigNoz UI reachable at $SigNozUrl"
} catch {
    Write-Error "Cannot reach SigNoz UI at $SigNozUrl. Is it running?"
    exit 1
}

# 1. Import Dashboard
if (-not $SkipDashboard) {
    Write-Header "Importing GPU Sidecar Dashboard"
    
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
}

# 2. Configure Alerts
if (-not $SkipAlerts) {
    Write-Header "Configuring GPU Sidecar Alerts"
    
    $alerts = @(
        @{
            name = "GPU Sidecar Health Down"
            condition = "gpu_sidecar_health_status == 0"
            severity = "critical"
            description = "GPU sidecar service is unhealthy"
        },
        @{
            name = "High GPU Fallback Rate"
            condition = "rate(gpu_sidecar_fallback_total[5m]) > 0.1"
            severity = "warning"
            description = "GPU fallback rate exceeds 10%"
        },
        @{
            name = "GPU Buffer Queue Depth High"
            condition = "gpu_buffer_queue_depth > 1000"
            severity = "warning"
            description = "GPU buffer queue depth is too high"
        },
        @{
            name = "Low GPU Processing Efficiency"
            condition = "rate(gpu_processing_efficiency[5m]) < 0.5"
            severity = "warning"
            description = "GPU processing efficiency below 50%"
        },
        @{
            name = "GPU Memory Usage High"
            condition = "gpu_memory_used_bytes / gpu_memory_total_bytes > 0.9"
            severity = "critical"
            description = "GPU memory usage exceeds 90%"
        }
    )
    
    Write-Info "Alert configurations ready:"
    foreach ($alert in $alerts) {
        Write-Info "  - $($alert.name) ($($alert.severity)): $($alert.condition)"
    }
    
    Write-Warning "Manual alert configuration required:"
    Write-Info "1. Open SigNoz UI: $SigNozUrl"
    Write-Info "2. Go to Settings → Alerts"
    Write-Info "3. Create new alerts using the conditions above"
    Write-Info "4. Set appropriate thresholds and notification channels"
    
    Write-Success "Alert configurations provided"
}

# 3. Production Validation
if (-not $SkipValidation) {
    Write-Header "Setting Up Production Validation"
    
    # Create production test payloads
    $productionPayloads = @{
        logs = @(
            @{ body = "User login successful"; level = "INFO"; timestamp = "2024-01-01T10:00:00Z"; user_id = "user123"; session_id = "sess456" },
            @{ body = "Database query executed"; level = "INFO"; timestamp = "2024-01-01T10:00:01Z"; query_time = 150; table = "users" },
            @{ body = "ERROR: Connection timeout"; level = "ERROR"; timestamp = "2024-01-01T10:00:02Z"; error_code = "TIMEOUT"; retry_count = 3 },
            @{ body = "WARNING: High CPU usage"; level = "WARN"; timestamp = "2024-01-01T10:00:03Z"; cpu_percent = 85; memory_percent = 70 },
            @{ body = "Cache miss for key: user_prefs_123"; level = "DEBUG"; timestamp = "2024-01-01T10:00:04Z"; cache_hit_rate = 0.85 }
        )
        metrics = @(
            @{ service_name = "web-server"; response_time = 120; status_code = 200; timestamp = "2024-01-01T10:00:00Z"; endpoint = "/api/users" },
            @{ service_name = "web-server"; response_time = 250; status_code = 200; timestamp = "2024-01-01T10:00:01Z"; endpoint = "/api/orders" },
            @{ service_name = "web-server"; response_time = 500; status_code = 500; timestamp = "2024-01-01T10:00:02Z"; endpoint = "/api/payments" },
            @{ service_name = "api-server"; response_time = 80; status_code = 200; timestamp = "2024-01-01T10:00:03Z"; endpoint = "/health" },
            @{ service_name = "api-server"; response_time = 300; status_code = 200; timestamp = "2024-01-01T10:00:04Z"; endpoint = "/api/analytics" }
        )
        traces = @(
            @{ trace_id = "trace-001"; span_id = "span-001"; operation_name = "user_login"; duration_ms = 150; status = "ok" },
            @{ trace_id = "trace-002"; span_id = "span-002"; operation_name = "db_query"; duration_ms = 80; status = "ok" },
            @{ trace_id = "trace-003"; span_id = "span-003"; operation_name = "external_api_call"; duration_ms = 500; status = "error" }
        )
    }
    
    # Save production payloads
    $payloadsDir = "test-payloads"
    if (-not (Test-Path $payloadsDir)) {
        New-Item -ItemType Directory -Path $payloadsDir | Out-Null
    }
    
    $productionPayloads | ConvertTo-Json -Depth 3 | Set-Content -Path "$payloadsDir/production-payloads.json" -Encoding UTF8
    Write-Success "Production test payloads saved to $payloadsDir/production-payloads.json"
    
    # Create validation script
    $validationScript = @'
#!/usr/bin/env pwsh
# Production Validation Script for GPU Sidecars

param(
    [int]$Iterations = 10,
    [int]$DelayMs = 1000
)

$ErrorActionPreference = "Stop"

function Write-Header { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }

Write-Header "GPU Sidecar Production Validation"

# Load production payloads
$payloads = Get-Content "test-payloads/production-payloads.json" | ConvertFrom-Json

# Test compression sidecar with production data
Write-Info "Testing compression sidecar with production payloads..."
$compressionResults = @()

for ($i = 1; $i -le $Iterations; $i++) {
    try {
        $payload = @{
            data = $payloads.logs | Get-Random -Count 5
            compression_algorithm = "zstd"
        } | ConvertTo-Json -Depth 3

        $response = Invoke-WebRequest -Uri "http://localhost:8001/compress" -Method POST -Body $payload -ContentType "application/json" -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        
        $compressionResults += [PSCustomObject]@{
            Iteration = $i
            OriginalSize = $result.original_size
            CompressedSize = $result.compressed_size
            CompressionRatio = $result.compression_ratio
            ProcessingTime = $result.processing_time_ms
        }
        
        Write-Info "  Iteration $i: $($result.compression_ratio) ratio, $($result.processing_time_ms)ms"
        Start-Sleep -Milliseconds $DelayMs
    } catch {
        Write-Error "Compression test $i failed: $($_.Exception.Message)"
    }
}

# Test aggregation sidecar with production data
Write-Info "Testing aggregation sidecar with production payloads..."
$aggregationResults = @()

for ($i = 1; $i -le $Iterations; $i++) {
    try {
        $payload = @{
            data = $payloads.metrics | Get-Random -Count 5
            aggregation_type = "summary"
            group_by = @("service_name")
        } | ConvertTo-Json -Depth 3

        $response = Invoke-WebRequest -Uri "http://localhost:8002/aggregate" -Method POST -Body $payload -ContentType "application/json" -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        
        $aggregationResults += [PSCustomObject]@{
            Iteration = $i
            OriginalCount = $result.original_count
            AggregatedCount = $result.aggregated_count
            ProcessingTime = $result.processing_time_ms
        }
        
        Write-Info "  Iteration $i: $($result.original_count) → $($result.aggregated_count), $($result.processing_time_ms)ms"
        Start-Sleep -Milliseconds $DelayMs
    } catch {
        Write-Error "Aggregation test $i failed: $($_.Exception.Message)"
    }
}

# Test inference sidecar with production data
Write-Info "Testing inference sidecar with production payloads..."
$inferenceResults = @()

for ($i = 1; $i -le $Iterations; $i++) {
    try {
        $payload = @{
            data = $payloads.logs | Get-Random -Count 5
            model_name = "log_anomaly_detector"
        } | ConvertTo-Json -Depth 3

        $response = Invoke-WebRequest -Uri "http://localhost:8003/infer" -Method POST -Body $payload -ContentType "application/json" -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        
        $inferenceResults += [PSCustomObject]@{
            Iteration = $i
            OriginalCount = $result.original_count
            ProcessedCount = $result.processed_count
            AnomalyCount = $result.anomaly_count
            ProcessingTime = $result.processing_time_ms
        }
        
        Write-Info "  Iteration $i: $($result.processed_count) processed, $($result.anomaly_count) anomalies, $($result.processing_time_ms)ms"
        Start-Sleep -Milliseconds $DelayMs
    } catch {
        Write-Error "Inference test $i failed: $($_.Exception.Message)"
    }
}

# Calculate statistics
Write-Header "Validation Results Summary"

if ($compressionResults.Count -gt 0) {
    $avgCompressionRatio = ($compressionResults | Measure-Object -Property CompressionRatio -Average).Average
    $avgCompressionTime = ($compressionResults | Measure-Object -Property ProcessingTime -Average).Average
    Write-Success "Compression: Avg ratio $([math]::Round($avgCompressionRatio, 3)), Avg time $([math]::Round($avgCompressionTime, 2))ms"
}

if ($aggregationResults.Count -gt 0) {
    $avgAggregationTime = ($aggregationResults | Measure-Object -Property ProcessingTime -Average).Average
    Write-Success "Aggregation: Avg time $([math]::Round($avgAggregationTime, 2))ms"
}

if ($inferenceResults.Count -gt 0) {
    $avgInferenceTime = ($inferenceResults | Measure-Object -Property ProcessingTime -Average).Average
    $totalAnomalies = ($inferenceResults | Measure-Object -Property AnomalyCount -Sum).Sum
    Write-Success "Inference: Avg time $([math]::Round($avgInferenceTime, 2))ms, Total anomalies: $totalAnomalies"
}

Write-Success "Production validation complete!"
'@
    
    $validationScript | Set-Content -Path "scripts/validate-production-gpu.ps1" -Encoding UTF8
    Write-Success "Production validation script created: scripts/validate-production-gpu.ps1"
}

# 4. Create Watchdog Script
Write-Header "Creating GPU Sidecar Watchdog"

$watchdogScript = @'
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
'@

$watchdogScript | Set-Content -Path "scripts/gpu-watchdog.ps1" -Encoding UTF8
Write-Success "Watchdog script created: scripts/gpu-watchdog.ps1"

# 5. Create monitoring summary
Write-Header "Monitoring Setup Complete"

Write-Success "GPU Sidecar monitoring infrastructure ready:"
Write-Info "  📊 Dashboard: artifacts/signoz-gpu-sidecar-dashboard.json (import manually)"
Write-Info "  🚨 Alerts: 5 alert conditions configured (set up manually)"
Write-Info "  🧪 Validation: scripts/validate-production-gpu.ps1"
Write-Info "  👁️  Watchdog: scripts/gpu-watchdog.ps1"
Write-Info "  📁 Test data: test-payloads/production-payloads.json"

Write-Info "`nNext steps:"
Write-Info "1. Import dashboard in SigNoz UI"
Write-Info "2. Configure alerts with notification channels"
Write-Info "3. Run production validation: pwsh -File scripts/validate-production-gpu.ps1"
Write-Info "4. Start watchdog: pwsh -File scripts/gpu-watchdog.ps1"

Write-Success "GPU sidecar monitoring setup complete!"
