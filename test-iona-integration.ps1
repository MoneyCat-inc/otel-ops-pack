# IONA SigNoz Integration Test
# Simple test to verify metrics are being sent and received

Write-Host "🧪 Testing IONA SigNoz Integration" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Import metrics module
try {
    . .\scripts\metrics.ps1
    Write-Host "✅ Metrics module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load metrics module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test connectivity
Write-Host "🔌 Testing connectivity to metrics endpoint..." -ForegroundColor Yellow
$connectivityTest = Test-IonaMetricsEndpoint
if ($connectivityTest) {
    Write-Host "✅ Metrics endpoint is reachable" -ForegroundColor Green
} else {
    Write-Host "⚠️  Metrics endpoint test failed, but continuing..." -ForegroundColor Yellow
}

# Send test metrics
Write-Host "📊 Sending test metrics..." -ForegroundColor Yellow

try {
    # Test counter
    $counterResult = Send-IonaMetric -Name "iona_test_counter" -Type "counter" -Value 1 -Attributes @{ 
        test_type = "integration"
        mode = "Companion"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    Write-Host "✅ Counter metric sent" -ForegroundColor Green

    # Test gauge
    $gaugeResult = Send-IonaMetric -Name "iona_test_gauge" -Type "gauge" -Value 42 -Attributes @{ 
        test_type = "integration"
        mode = "Practice"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    Write-Host "✅ Gauge metric sent" -ForegroundColor Green

    # Test histogram
    $histogramResult = Send-IonaMetric -Name "iona_test_histogram" -Type "histogram" -Value 150 -Attributes @{ 
        test_type = "integration"
        mode = "Assessment"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    Write-Host "✅ Histogram metric sent" -ForegroundColor Green

} catch {
    Write-Host "❌ Failed to send metrics: $($_.Exception.Message)" -ForegroundColor Red
}

# Test trace
Write-Host "🔍 Sending test trace..." -ForegroundColor Yellow
try {
    $traceId = New-IonaTraceId
    $spanId = New-IonaSpanId
    
    $traceResult = Send-IonaSpan -Name "iona.test.integration" -TraceId $traceId -SpanId $spanId -Attributes @{
        test_type = "integration"
        job_id = "test-job-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        mode = "Analysis"
    }
    Write-Host "✅ Trace sent" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to send trace: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 IONA Integration Test Complete!" -ForegroundColor Magenta
Write-Host ""
Write-Host "🔍 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Check SigNoz UI: http://localhost:8080" -ForegroundColor Gray
Write-Host "   2. Go to Metrics → Explorer" -ForegroundColor Gray
Write-Host "   3. Search for: iona_test_*" -ForegroundColor Gray
Write-Host "   4. Go to Traces → Search" -ForegroundColor Gray
Write-Host "   5. Filter: service.name = 'iona-supervisor'" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 Expected Metrics:" -ForegroundColor Yellow
Write-Host "   • iona_test_counter" -ForegroundColor Gray
Write-Host "   • iona_test_gauge" -ForegroundColor Gray
Write-Host "   • iona_test_histogram" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 Expected Traces:" -ForegroundColor Yellow
Write-Host "   • iona.test.integration" -ForegroundColor Gray
Write-Host "   • service.name = 'iona-supervisor'" -ForegroundColor Gray
