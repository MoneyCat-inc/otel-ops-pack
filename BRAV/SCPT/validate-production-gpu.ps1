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

# Test compression sidecar with production data (both string lists and structured logs)
Write-Info "Testing compression sidecar with production payloads..."
$compressionResults = @()

for ($i = 1; $i -le $Iterations; $i++) {
    try {
        # Test 1: String list payload (original format)
        $stringPayload = @{
            data = $payloads.logs | Get-Random -Count 3 | ForEach-Object { $_.body }
            compression_algorithm = "zstd"
        } | ConvertTo-Json -Depth 3

        $response1 = Invoke-WebRequest -Uri "http://localhost:8001/compress" -Method POST -Body $stringPayload -ContentType "application/json" -UseBasicParsing
        $result1 = $response1.Content | ConvertFrom-Json
        
        # Test 2: Structured log payload (JSON objects)
        $structuredPayload = @{
            data = $payloads.logs | Get-Random -Count 2 | ConvertTo-Json -Depth 3
            compression_algorithm = "zstd"
        } | ConvertTo-Json -Depth 3

        $response2 = Invoke-WebRequest -Uri "http://localhost:8001/compress" -Method POST -Body $structuredPayload -ContentType "application/json" -UseBasicParsing
        $result2 = $response2.Content | ConvertFrom-Json
        
        $compressionResults += [PSCustomObject]@{
            Iteration = $i
            StringListRatio = $result1.compression_ratio
            StructuredRatio = $result2.compression_ratio
            StringListTime = $result1.processing_time_ms
            StructuredTime = $result2.processing_time_ms
            AvgRatio = ($result1.compression_ratio + $result2.compression_ratio) / 2
            AvgTime = ($result1.processing_time_ms + $result2.processing_time_ms) / 2
        }
        
        Write-Info "  Iteration $i`: String list $($result1.compression_ratio) ratio ($($result1.processing_time_ms)ms), Structured $($result2.compression_ratio) ratio ($($result2.processing_time_ms)ms)"
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
        
        Write-Info "  Iteration $i`: $($result.original_count) → $($result.aggregated_count), $($result.processing_time_ms)ms"
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
        
        Write-Info "  Iteration $i`: $($result.processed_count) processed, $($result.anomaly_count) anomalies, $($result.processing_time_ms)ms"
        Start-Sleep -Milliseconds $DelayMs
    } catch {
        Write-Error "Inference test $i failed: $($_.Exception.Message)"
    }
}

# Calculate statistics
Write-Header "Validation Results Summary"

if ($compressionResults.Count -gt 0) {
    $avgCompressionTime = ($compressionResults | Measure-Object -Property AvgTime -Average).Average
    $avgStringRatio = ($compressionResults | Measure-Object -Property StringListRatio -Average).Average
    $avgStructuredRatio = ($compressionResults | Measure-Object -Property StructuredRatio -Average).Average
    Write-Success "Compression: Avg time $([math]::Round($avgCompressionTime, 2))ms (String list: $([math]::Round($avgStringRatio, 3)) ratio, Structured: $([math]::Round($avgStructuredRatio, 3)) ratio)"
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
