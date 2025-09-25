# verify-gpu-pipeline.ps1 - Verify end-to-end GPU metrics pipeline
param(
    [int]$TestDuration = 30,
    [string]$SigNozUrl = "http://localhost:8080"
)

Write-Host "🔍 Verifying GPU Metrics Pipeline..." -ForegroundColor Cyan
Write-Host "   Test Duration: ${TestDuration}s" -ForegroundColor Gray
Write-Host "   SigNoz URL: $SigNozUrl" -ForegroundColor Gray

$allChecksPassed = $true

# 1. Check GPU availability
Write-Host "`n1️⃣ Checking GPU availability..." -ForegroundColor Yellow
try {
    $gpuTest = python -c "import pynvml; pynvml.nvmlInit(); count = pynvml.nvmlDeviceGetCount(); print(f'Found {count} GPU(s)'); [print(f'GPU {i}: {pynvml.nvmlDeviceGetName(pynvml.nvmlDeviceGetHandleByIndex(i)).decode()}') for i in range(count)]" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU check passed" -ForegroundColor Green
        Write-Host "   $gpuTest" -ForegroundColor Gray
    } else {
        Write-Host "❌ GPU check failed" -ForegroundColor Red
        $allChecksPassed = $false
    }
} catch {
    Write-Host "❌ GPU check failed: $($_.Exception.Message)" -ForegroundColor Red
    $allChecksPassed = $false
}

# 2. Check SigNoz stack
Write-Host "`n2️⃣ Checking SigNoz stack..." -ForegroundColor Yellow
try {
    $signozStatus = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "signoz"
    if ($signozStatus) {
        Write-Host "✅ SigNoz stack running" -ForegroundColor Green
        Write-Host "   $signozStatus" -ForegroundColor Gray
    } else {
        Write-Host "❌ SigNoz stack not running" -ForegroundColor Red
        $allChecksPassed = $false
    }
} catch {
    Write-Host "❌ SigNoz check failed: $($_.Exception.Message)" -ForegroundColor Red
    $allChecksPassed = $false
}

# 3. Check collector
Write-Host "`n3️⃣ Checking OTel collector..." -ForegroundColor Yellow
try {
    $collectorStatus = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "signoz-otel-collector"
    if ($collectorStatus) {
        Write-Host "✅ Collector running" -ForegroundColor Green
        Write-Host "   $collectorStatus" -ForegroundColor Gray
    } else {
        Write-Host "❌ Collector not running" -ForegroundColor Red
        Write-Host "   Run: pwsh -File scripts/run-collector.ps1" -ForegroundColor Yellow
        $allChecksPassed = $false
    }
} catch {
    Write-Host "❌ Collector check failed: $($_.Exception.Message)" -ForegroundColor Red
    $allChecksPassed = $false
}

# 4. Check OTLP endpoints
Write-Host "`n4️⃣ Checking OTLP endpoints..." -ForegroundColor Yellow
$grpcTest = Test-NetConnection -ComputerName localhost -Port 4317 -WarningAction SilentlyContinue
$httpTest = Test-NetConnection -ComputerName localhost -Port 4318 -WarningAction SilentlyContinue

if ($grpcTest.TcpTestSucceeded) {
    Write-Host "✅ gRPC endpoint (4317) is open" -ForegroundColor Green
} else {
    Write-Host "❌ gRPC endpoint (4317) not accessible" -ForegroundColor Red
    $allChecksPassed = $false
}

if ($httpTest.TcpTestSucceeded) {
    Write-Host "✅ HTTP endpoint (4318) is open" -ForegroundColor Green
} else {
    Write-Host "❌ HTTP endpoint (4318) not accessible" -ForegroundColor Red
    $allChecksPassed = $false
}

# 5. Test GPU metrics emission
if ($allChecksPassed) {
    Write-Host "`n5️⃣ Testing GPU metrics emission..." -ForegroundColor Yellow
    Write-Host "   Running GPU emitter for ${TestDuration}s..." -ForegroundColor Gray
    
    try {
        # Start GPU emitter in background
        $job = Start-Job -ScriptBlock {
            param($duration)
            python gpu-metrics-emitter.py --duration $duration --interval 5
        } -ArgumentList $TestDuration
        
        # Wait for completion
        Wait-Job $job -Timeout ($TestDuration + 10)
        $result = Receive-Job $job
        Remove-Job $job
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GPU metrics emission completed" -ForegroundColor Green
            Write-Host "   $result" -ForegroundColor Gray
        } else {
            Write-Host "❌ GPU metrics emission failed" -ForegroundColor Red
            $allChecksPassed = $false
        }
    } catch {
        Write-Host "❌ GPU metrics test failed: $($_.Exception.Message)" -ForegroundColor Red
        $allChecksPassed = $false
    }
} else {
    Write-Host "`n⏭️ Skipping GPU metrics test due to previous failures" -ForegroundColor Yellow
}

# 6. Check collector logs
Write-Host "`n6️⃣ Checking collector logs..." -ForegroundColor Yellow
try {
    $logs = docker logs --since 2m signoz-otel-collector 2>$null | Select-Object -Last 5
    if ($logs) {
        Write-Host "✅ Collector logs available" -ForegroundColor Green
        Write-Host "   Recent logs:" -ForegroundColor Gray
        $logs | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
    } else {
        Write-Host "⚠️ No recent collector logs" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to check collector logs: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Check SigNoz UI accessibility
Write-Host "`n7️⃣ Checking SigNoz UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $SigNozUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ SigNoz UI accessible" -ForegroundColor Green
        Write-Host "   URL: $SigNozUrl" -ForegroundColor Gray
    } else {
        Write-Host "❌ SigNoz UI not accessible (Status: $($response.StatusCode))" -ForegroundColor Red
        $allChecksPassed = $false
    }
} catch {
    Write-Host "❌ SigNoz UI check failed: $($_.Exception.Message)" -ForegroundColor Red
    $allChecksPassed = $false
}

# Summary
Write-Host "`n📊 Pipeline Verification Summary" -ForegroundColor Cyan
if ($allChecksPassed) {
    Write-Host "✅ All checks passed! Pipeline is ready." -ForegroundColor Green
    Write-Host "`n🎯 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Open SigNoz UI: $SigNozUrl" -ForegroundColor Gray
    Write-Host "   2. Navigate to Metrics → Query Builder" -ForegroundColor Gray
    Write-Host "   3. Search for 'gpu.utilization.percent'" -ForegroundColor Gray
    Write-Host "   4. Set up alerts for high GPU usage" -ForegroundColor Gray
} else {
    Write-Host "❌ Some checks failed. Please fix the issues above." -ForegroundColor Red
    Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Cyan
    Write-Host "   1. Ensure Docker Desktop is running" -ForegroundColor Gray
    Write-Host "   2. Start SigNoz stack: docker compose up -d" -ForegroundColor Gray
    Write-Host "   3. Deploy collector: pwsh -File scripts/run-collector.ps1" -ForegroundColor Gray
    Write-Host "   4. Install Python dependencies: pip install pynvml opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http" -ForegroundColor Gray
}

Write-Host "`n🏁 Verification complete!" -ForegroundColor Cyan
