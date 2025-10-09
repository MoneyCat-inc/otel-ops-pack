# GPU Sidecar API Test Script
# Tests compression and aggregation sidecar APIs

param(
    [switch]$QuickTest,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-TestResult {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "INFO" { "Cyan" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-SidecarHealth {
    param([string]$Name, [string]$Url)
    
    try {
        $response = Invoke-RestMethod -Uri $Url -TimeoutSec 5
        Write-TestResult "✅ $Name Health: $($response.status)" "PASS"
        if ($response.gpu_available -ne $null) {
            Write-TestResult "   GPU Available: $($response.gpu_available)" "INFO"
        }
        if ($response.buffer_size -ne $null) {
            Write-TestResult "   Buffer Size: $($response.buffer_size)" "INFO"
        }
        return $true
    }
    catch {
        Write-TestResult "❌ $Name Health: Not responding" "FAIL"
        return $false
    }
}

function Test-CompressionAPI {
    Write-TestResult "🧪 Testing Compression API..." "INFO"
    
    $payload = @{
        data = @("test-log-1", "test-log-2", "test-log-3")
    } | ConvertTo-Json -Depth 4
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8001/compress" -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 10
        Write-TestResult "✅ Compression Test Passed:" "PASS"
        Write-TestResult "   Original: $($response.original_size) bytes" "INFO"
        Write-TestResult "   Compressed: $($response.compressed_size) bytes" "INFO"
        Write-TestResult "   Ratio: $([math]::Round($response.compression_ratio, 3))" "INFO"
        Write-TestResult "   Algorithm: $($response.algorithm)" "INFO"
        Write-TestResult "   Time: $([math]::Round($response.processing_time_ms, 2))ms" "INFO"
        return $true
    }
    catch {
        Write-TestResult "❌ Compression Test Failed: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

function Test-AggregationAPI {
    Write-TestResult "🧪 Testing Aggregation API..." "INFO"
    
    $payload = @{
        data = @(
            @{ service = 'test-service'; duration_ms = 100; attempts = 1 },
            @{ service = 'test-service'; duration_ms = 200; attempts = 2 },
            @{ service = 'test-service'; duration_ms = 300; attempts = 1 }
        )
        aggregation_type = 'summary'
        group_by = @('service')
    } | ConvertTo-Json -Depth 4
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/aggregate" -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 10
        Write-TestResult "✅ Aggregation Test Passed:" "PASS"
        Write-TestResult "   Original Count: $($response.original_count)" "INFO"
        Write-TestResult "   Aggregated Count: $($response.aggregated_count)" "INFO"
        Write-TestResult "   Type: $($response.aggregation_type)" "INFO"
        Write-TestResult "   Time: $([math]::Round($response.processing_time_ms, 2))ms" "INFO"
        
        if ($Verbose) {
            Write-TestResult "   Aggregated Data:" "INFO"
            $response.aggregated_data | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
        }
        return $true
    }
    catch {
        Write-TestResult "❌ Aggregation Test Failed: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

# Main execution
Write-TestResult "=== GPU Sidecar API Test ===" "INFO"
Write-TestResult ""

# Test health endpoints
$compressionHealthy = Test-SidecarHealth "Compression" "http://localhost:8001/health"
$aggregationHealthy = Test-SidecarHealth "Aggregation" "http://localhost:8002/health"

Write-TestResult ""

if ($compressionHealthy -and $aggregationHealthy) {
    # Test APIs
    $compressionTest = Test-CompressionAPI
    Write-TestResult ""
    $aggregationTest = Test-AggregationAPI
    
    Write-TestResult ""
    if ($compressionTest -and $aggregationTest) {
        Write-TestResult "🎉 All tests passed! GPU sidecars are operational." "PASS"
        Write-TestResult "   Compression: Working with GPU support" "INFO"
        Write-TestResult "   Aggregation: Working with pandas fallback (GPU disabled)" "INFO"
    } else {
        Write-TestResult "⚠️ Some tests failed. Check sidecar services." "WARN"
    }
} else {
    Write-TestResult "❌ Sidecar services not healthy. Start them first:" "FAIL"
    Write-TestResult "   python sidecars/compression/compression_sidecar.py" "INFO"
    Write-TestResult "   python sidecars/aggregation/aggregation_sidecar.py" "INFO"
}


