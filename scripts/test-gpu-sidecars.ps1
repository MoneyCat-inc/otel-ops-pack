# GPU Sidecar Integration Test Script
# Tests compression and aggregation sidecars end-to-end

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== GPU Sidecar Integration Test ===" -ForegroundColor Green

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail { param([string]$Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red }

# Test compression sidecar
Write-Host "`n1. Testing Compression Sidecar:" -ForegroundColor Yellow

try {
    $compressionHealth = Invoke-WebRequest -Uri "http://localhost:8001/health" -UseBasicParsing
    if ($compressionHealth.StatusCode -eq 200) {
        $healthData = $compressionHealth.Content | ConvertFrom-Json
        Write-Pass "Compression sidecar is healthy"
        Write-Detail "GPU available: $($healthData.gpu_available)"
    } else {
        Write-Fail "Compression sidecar health check failed: HTTP $($compressionHealth.StatusCode)"
    }
} catch {
    Write-Fail "Compression sidecar not reachable: $($_.Exception.Message)"
}

# Test compression API
try {
    $testData = @{
        data = @(
            "2024-01-01T10:00:00Z INFO Service started successfully",
            "2024-01-01T10:00:01Z INFO Processing request 12345",
            "2024-01-01T10:00:02Z WARN High memory usage detected",
            "2024-01-01T10:00:03Z ERROR Database connection failed",
            "2024-01-01T10:00:04Z INFO Retrying database connection"
        )
        metadata = @{
            source = "test-integration"
            service = "test-service"
        }
    } | ConvertTo-Json -Depth 3

    $compressionResponse = Invoke-WebRequest -Uri "http://localhost:8001/compress" -Method POST -Body $testData -ContentType "application/json" -UseBasicParsing
    if ($compressionResponse.StatusCode -eq 200) {
        $compressionResult = $compressionResponse.Content | ConvertFrom-Json
        Write-Pass "Compression API working"
        Write-Detail "Original size: $($compressionResult.original_size) bytes"
        Write-Detail "Compressed size: $($compressionResult.compressed_size) bytes"
        Write-Detail "Compression ratio: $($compressionResult.compression_ratio)"
        Write-Detail "Processing time: $($compressionResult.processing_time_ms) ms"
    } else {
        Write-Fail "Compression API failed: HTTP $($compressionResponse.StatusCode)"
    }
} catch {
    Write-Fail "Compression API test failed: $($_.Exception.Message)"
}

# Test aggregation sidecar
Write-Host "`n2. Testing Aggregation Sidecar:" -ForegroundColor Yellow

try {
    $aggregationHealth = Invoke-WebRequest -Uri "http://localhost:8002/health" -UseBasicParsing
    if ($aggregationHealth.StatusCode -eq 200) {
        $healthData = $aggregationHealth.Content | ConvertFrom-Json
        Write-Pass "Aggregation sidecar is healthy"
        Write-Detail "GPU available: $($healthData.gpu_available)"
        Write-Detail "Buffer size: $($healthData.buffer_size)"
    } else {
        Write-Fail "Aggregation sidecar health check failed: HTTP $($aggregationHealth.StatusCode)"
    }
} catch {
    Write-Fail "Aggregation sidecar not reachable: $($_.Exception.Message)"
}

# Test aggregation API
try {
    $testMetrics = @{
        data = @(
            @{ service_name = "web-server"; response_time = 150; status_code = 200; timestamp = "2024-01-01T10:00:00Z" },
            @{ service_name = "web-server"; response_time = 200; status_code = 200; timestamp = "2024-01-01T10:00:01Z" },
            @{ service_name = "web-server"; response_time = 300; status_code = 500; timestamp = "2024-01-01T10:00:02Z" },
            @{ service_name = "api-server"; response_time = 100; status_code = 200; timestamp = "2024-01-01T10:00:03Z" },
            @{ service_name = "api-server"; response_time = 250; status_code = 200; timestamp = "2024-01-01T10:00:04Z" }
        )
        aggregation_type = "summary"
        group_by = @("service_name")
    } | ConvertTo-Json -Depth 3

    $aggregationResponse = Invoke-WebRequest -Uri "http://localhost:8002/aggregate" -Method POST -Body $testMetrics -ContentType "application/json" -UseBasicParsing
    if ($aggregationResponse.StatusCode -eq 200) {
        $aggregationResult = $aggregationResponse.Content | ConvertFrom-Json
        Write-Pass "Aggregation API working"
        Write-Detail "Original count: $($aggregationResult.original_count)"
        Write-Detail "Aggregated count: $($aggregationResult.aggregated_count)"
        Write-Detail "Processing time: $($aggregationResult.processing_time_ms) ms"
    } else {
        Write-Fail "Aggregation API failed: HTTP $($aggregationResponse.StatusCode)"
    }
} catch {
    Write-Fail "Aggregation API test failed: $($_.Exception.Message)"
}

# Test inference sidecar
Write-Host "`n3. Testing Inference Sidecar:" -ForegroundColor Yellow

try {
    $inferenceHealth = Invoke-WebRequest -Uri "http://localhost:8003/health" -UseBasicParsing
    if ($inferenceHealth.StatusCode -eq 200) {
        $healthData = $inferenceHealth.Content | ConvertFrom-Json
        Write-Pass "Inference sidecar is healthy"
        Write-Detail "Triton available: $($healthData.triton_available)"
        Write-Detail "Available models: $($healthData.available_models -join ', ')"
    } else {
        Write-Fail "Inference sidecar health check failed: HTTP $($inferenceHealth.StatusCode)"
    }
} catch {
    Write-Fail "Inference sidecar not reachable: $($_.Exception.Message)"
}

# Test inference API
try {
    $testLogs = @{
        data = @(
            @{ body = "Application started successfully"; level = "INFO"; timestamp = "2024-01-01T10:00:00Z" },
            @{ body = "Database connection established"; level = "INFO"; timestamp = "2024-01-01T10:00:01Z" },
            @{ body = "ERROR: Failed to connect to external service"; level = "ERROR"; timestamp = "2024-01-01T10:00:02Z" },
            @{ body = "WARNING: High memory usage detected"; level = "WARN"; timestamp = "2024-01-01T10:00:03Z" },
            @{ body = "User authentication completed"; level = "INFO"; timestamp = "2024-01-01T10:00:04Z" }
        )
        model_name = "log_anomaly_detector"
    } | ConvertTo-Json -Depth 3

    $inferenceResponse = Invoke-WebRequest -Uri "http://localhost:8003/infer" -Method POST -Body $testLogs -ContentType "application/json" -UseBasicParsing
    if ($inferenceResponse.StatusCode -eq 200) {
        $inferenceResult = $inferenceResponse.Content | ConvertFrom-Json
        Write-Pass "Inference API working"
        Write-Detail "Original count: $($inferenceResult.original_count)"
        Write-Detail "Processed count: $($inferenceResult.processed_count)"
        Write-Detail "Anomaly count: $($inferenceResult.anomaly_count)"
        Write-Detail "Processing time: $($inferenceResult.processing_time_ms) ms"
    } else {
        Write-Fail "Inference API failed: HTTP $($inferenceResponse.StatusCode)"
    }
} catch {
    Write-Fail "Inference API test failed: $($_.Exception.Message)"
}

# Test GPU buffer files
Write-Host "`n4. Testing GPU Buffer Files:" -ForegroundColor Yellow

$bufferDirs = @("gpu-buffers/logs", "gpu-buffers/traces", "gpu-buffers/analytics", "gpu-buffers/inference")
foreach ($dir in $bufferDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem $dir -File
        $fileCount = if ($files) { $files.Count } else { 0 }
        Write-Pass "Buffer directory exists: $dir ($fileCount files)"
    } else {
        Write-Fail "Buffer directory missing: $dir"
    }
}

# Test collector configuration
Write-Host "`n5. Testing Collector Configuration:" -ForegroundColor Yellow

try {
    $configContent = Get-Content -Path "config.yaml" -Raw
    if ($configContent -match "file/gpu_logs") {
        Write-Pass "GPU buffer exporters configured"
    } else {
        Write-Fail "GPU buffer exporters not found in config"
    }
    
    if ($configContent -match "routing/gpu_logs") {
        Write-Pass "GPU routing processors configured"
    } else {
        Write-Fail "GPU routing processors not found in config"
    }
} catch {
    Write-Fail "Failed to read collector configuration: $($_.Exception.Message)"
}

# Test SigNoz integration
Write-Host "`n6. Testing SigNoz Integration:" -ForegroundColor Yellow

try {
    $sigNozHealth = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
    if ($sigNozHealth.StatusCode -eq 200) {
        Write-Pass "SigNoz UI reachable"
    } else {
        Write-Fail "SigNoz UI not reachable: HTTP $($sigNozHealth.StatusCode)"
    }
} catch {
    Write-Fail "SigNoz UI test failed: $($_.Exception.Message)"
}

Write-Host "`n=== GPU Sidecar Integration Test Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. View SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
Write-Host "2. Check GPU sidecar logs: docker-compose -f docker-compose.gpu.yml logs" -ForegroundColor Yellow
Write-Host "3. Monitor GPU buffer files: Get-ChildItem gpu-buffers -Recurse" -ForegroundColor Yellow
Write-Host "4. Import dashboard: Import artifacts/signoz-gpu-sidecar-dashboard.json" -ForegroundColor Yellow
