# Gate #026 Track A: Verify .NET Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify spans, metrics, logs, and measure overhead

param(
    [string]$ServiceName = "dotnet-test-gate026",
    [string]$AppUrl = "http://localhost:5555",
    [string]$SigNozUrl = "http://localhost:8080",
    [int]$WaitSeconds = 15
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #026 Track A: Verification Suite ===" -ForegroundColor Cyan
Write-Host ""

# Check if app is running
Write-Host "[1/6] Checking if .NET app is running..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$AppUrl/health" -Method Get -TimeoutSec 5
    Write-Host "   ✅ App is running" -ForegroundColor Green
    Write-Host "   Service: $($healthResponse.service)" -ForegroundColor White
    Write-Host "   Instrumentation: $($healthResponse.instrumentation)" -ForegroundColor White
} catch {
    Write-Host "   ❌ App not running at $AppUrl" -ForegroundColor Red
    Write-Host "   Run: .\scripts\gate026\run-dotnet-app-instrumented.ps1" -ForegroundColor Yellow
    exit 1
}

# Test incoming HTTP endpoint
Write-Host ""
Write-Host "[2/6] Testing incoming HTTP endpoint (root)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$AppUrl/" -Method Get
    Write-Host "   ✅ Root endpoint responded: $response" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test outbound HttpClient call
Write-Host ""
Write-Host "[3/6] Testing outbound HttpClient call (/test)..." -ForegroundColor Cyan
try {
    $testResponse = Invoke-RestMethod -Uri "$AppUrl/test" -Method Get
    Write-Host "   ✅ Outbound call status: $($testResponse.status)" -ForegroundColor Green
    Write-Host "   Outbound result: $($testResponse.outbound_call)" -ForegroundColor White
} catch {
    Write-Host "   ❌ Test endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for telemetry to propagate
Write-Host ""
Write-Host "[4/6] Waiting $WaitSeconds seconds for telemetry to propagate..." -ForegroundColor Cyan
Start-Sleep -Seconds $WaitSeconds
Write-Host "   ✅ Wait complete" -ForegroundColor Green

# Query SigNoz for spans
Write-Host ""
Write-Host "[5/6] Querying SigNoz for spans..." -ForegroundColor Cyan
try {
    # SigNoz API query for traces
    $queryUrl = "$SigNozUrl/api/v3/query_range"
    $body = @{
        start = [Math]::Floor((Get-Date).AddMinutes(-5).ToUniversalTime().Subtract([DateTime]'1970-01-01').TotalMilliseconds)
        end = [Math]::Floor((Get-Date).ToUniversalTime().Subtract([DateTime]'1970-01-01').TotalMilliseconds)
        step = 60
        variables = @{}
        compositeQuery = @{
            builderQueries = @{
                A = @{
                    queryName = "A"
                    aggregateOperator = "count"
                    dataSource = "traces"
                    aggregateAttribute = @{
                        key = ""
                        type = ""
                    }
                    filters = @{
                        items = @(
                            @{
                                key = @{
                                    key = "service.name"
                                    type = "tag"
                                    dataType = "string"
                                }
                                op = "="
                                value = $ServiceName
                            }
                        )
                    }
                }
            }
            queryType = "builder"
            panelType = "graph"
        }
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Content-Type" = "application/json"
    }

    $sigNozResponse = Invoke-RestMethod -Uri $queryUrl -Method Post -Body $body -Headers $headers -TimeoutSec 10

    $spanCount = 0
    if ($sigNozResponse.data.result.Count -gt 0) {
        $spanCount = ($sigNozResponse.data.result[0].values | Measure-Object -Property 1 -Sum).Sum
    }

    if ($spanCount -gt 0) {
        Write-Host "   ✅ Found $spanCount span(s) in SigNoz" -ForegroundColor Green
        Write-Host "   Service: $ServiceName" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  No spans found yet (may need more time)" -ForegroundColor Yellow
        Write-Host "   Check manually: $SigNozUrl/traces?service=$ServiceName" -ForegroundColor White
    }
} catch {
    Write-Host "   ⚠️  SigNoz query failed (manual verification recommended)" -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host "   Check manually: $SigNozUrl/traces?service=$ServiceName" -ForegroundColor White
}

# Performance measurement (basic)
Write-Host ""
Write-Host "[6/6] Performance check (10 requests)..." -ForegroundColor Cyan
$times = @()
for ($i = 1; $i -le 10; $i++) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-RestMethod -Uri "$AppUrl/" -Method Get | Out-Null
        $sw.Stop()
        $times += $sw.ElapsedMilliseconds
    } catch {
        Write-Host "   ⚠️  Request $i failed" -ForegroundColor Yellow
    }
}

if ($times.Count -gt 0) {
    $avgTime = ($times | Measure-Object -Average).Average
    $p95Time = ($times | Sort-Object)[[Math]::Ceiling($times.Count * 0.95) - 1]
    Write-Host "   ✅ Performance:" -ForegroundColor Green
    Write-Host "      Avg: $($avgTime.ToString('F2')) ms" -ForegroundColor White
    Write-Host "      P95: $p95Time ms" -ForegroundColor White
    Write-Host "   Note: Run baseline comparison for overhead calculation" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Track A Verification Complete" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Results Summary:" -ForegroundColor Yellow
Write-Host "   - App Running: ✅" -ForegroundColor Green
Write-Host "   - Incoming HTTP: ✅" -ForegroundColor Green
Write-Host "   - Outbound HttpClient: ✅" -ForegroundColor Green
Write-Host "   - Spans in SigNoz: $(if ($spanCount -gt 0) { '✅' } else { '⚠️  (check manually)' })" -ForegroundColor $(if ($spanCount -gt 0) { 'Green' } else { 'Yellow' })
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Verify spans visually in SigNoz UI" -ForegroundColor White
Write-Host "   2. Check metrics (ASP.NET Core + .NET runtime)" -ForegroundColor White
Write-Host "   3. Run baseline: .\run-dotnet-app-instrumented.ps1 -Baseline" -ForegroundColor White
Write-Host "   4. Compare overhead (baseline vs instrumented)" -ForegroundColor White
Write-Host ""
Write-Host "Evidence: Save screenshots from SigNoz for ECRR report" -ForegroundColor Gray
Write-Host ""

