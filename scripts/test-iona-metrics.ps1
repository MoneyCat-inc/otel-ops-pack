# Quick IONA Metrics Test Script
# Generates test data and verifies metrics are visible in SigNoz
# Use this to quickly test the integration after deployment

param(
    [int]$JobCount = 5,
    [switch]$EnableTracing = $true,
    [int]$WaitSeconds = 10
)

Write-Host "🧪 IONA Metrics Test - Quick Verification" -ForegroundColor Cyan
Write-Host "   Jobs: $JobCount" -ForegroundColor Gray
Write-Host "   Tracing: $EnableTracing" -ForegroundColor Gray
Write-Host "   Wait: ${WaitSeconds}s for SigNoz ingest" -ForegroundColor Gray
Write-Host ""

# Load metrics helper
. "$PSScriptRoot\metrics.ps1"

# Test 1: Check endpoints
Write-Host "🔍 [1/4] Testing OTLP endpoints..." -ForegroundColor Yellow
$metricsOk = Test-IonaMetricsEndpoint
$tracesOk = Test-IonaTracesEndpoint

if (-not $metricsOk) {
    Write-Host "❌ Metrics endpoint test failed" -ForegroundColor Red
    exit 1
}

if ($EnableTracing -and -not $tracesOk) {
    Write-Host "❌ Traces endpoint test failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ OTLP endpoints are reachable" -ForegroundColor Green

# Test 2: Generate test data
Write-Host "🔍 [2/4] Generating test data..." -ForegroundColor Yellow
try {
    $demoScript = "$PSScriptRoot\iona-supervisor-runner.ps1"
    $tracingFlag = if ($EnableTracing) { "-EnableTracing" } else { "" }
    
    & pwsh -NoLogo -NoProfile -File $demoScript -JobCount $JobCount $tracingFlag
    
    Write-Host "✅ Test data generated successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to generate test data: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Wait for ingestion
Write-Host "🔍 [3/4] Waiting for SigNoz ingestion..." -ForegroundColor Yellow
Write-Host "   Waiting $WaitSeconds seconds for metrics to propagate..." -ForegroundColor Gray

$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
for ($i = 0; $i -lt $WaitSeconds; $i++) {
    $spinnerIndex = $i % $spinner.Count
    Write-Host "`r$($spinner[$spinnerIndex]) Waiting... $($i + 1)/$WaitSeconds" -NoNewline -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}
Write-Host "`r✅ Ingestion wait complete" -ForegroundColor Green

# Test 4: Verify SigNoz API
Write-Host "🔍 [4/4] Checking SigNoz API..." -ForegroundColor Yellow
try {
    $query = "iona_jobs_completed_total"
    $apiUrl = "http://localhost:8080/api/v1/query"
    $body = @{
        query = $query
        time = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    
    if ($response.data.result -and $response.data.result.Count -gt 0) {
        Write-Host "✅ Metrics found in SigNoz: $($response.data.result.Count) results" -ForegroundColor Green
        
        # Show sample results
        Write-Host "📊 Sample metrics:" -ForegroundColor Cyan
        foreach ($result in $response.data.result | Select-Object -First 3) {
            $labels = if ($result.metric) { ($result.metric.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", " } else { "no labels" }
            Write-Host "   $query{$labels} = $($result.value[1])" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "⚠️  No metrics found in SigNoz yet (may need more time)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ SigNoz API check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Open SigNoz UI: http://localhost:8080" -ForegroundColor Gray
Write-Host "   2. Go to Metrics → Explorer" -ForegroundColor Gray
Write-Host "   3. Query: sum(rate(iona_jobs_completed_total{mode!=\"\"}[5m])) by (mode)" -ForegroundColor Gray
Write-Host "   4. Import dashboard: artifacts/iona-supervisor-dashboard.json" -ForegroundColor Gray
if ($EnableTracing) {
    Write-Host "   5. Check Traces → Search → Filter: service.name = \"iona-supervisor\"" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ IONA metrics test completed!" -ForegroundColor Green
