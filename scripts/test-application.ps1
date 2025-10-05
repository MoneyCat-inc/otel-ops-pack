# Simple Application Test Script
# ECRR Framework Implementation - Basic Functionality Test

Write-Host "🧪 Simple Application Test" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Test 1: Application Health
Write-Host "🏥 Test 1: Application Health Check" -ForegroundColor Yellow
try {
    $AppResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 10
    Write-Host "  ✅ Application is healthy" -ForegroundColor Green
    Write-Host "  📊 Response: $($AppResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Application health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 Make sure the app is running: npm run dev" -ForegroundColor Yellow
}

# Test 2: SigNoz UI
Write-Host "`n🌐 Test 2: SigNoz UI Accessibility" -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -Method GET -TimeoutSec 10
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI is accessible" -ForegroundColor Green
        Write-Host "  📊 Status Code: $($SigNozResponse.StatusCode)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️ SigNoz UI returned status: $($SigNozResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ SigNoz UI check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 Make sure SigNoz is running: docker-compose up -d" -ForegroundColor Yellow
}

# Test 3: Generate Test Traffic
Write-Host "`n📡 Test 3: Generating Test Traffic" -ForegroundColor Yellow
$TestEndpoints = @(
    "http://localhost:3000/api/health",
    "http://localhost:3000/api/auth/session"
)

$SuccessCount = 0
foreach ($Endpoint in $TestEndpoints) {
    try {
        $Response = Invoke-RestMethod -Uri $Endpoint -Method GET -TimeoutSec 5
        $SuccessCount++
        Write-Host "    ✅ Generated traffic for: $Endpoint" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️ Failed to generate traffic for: $Endpoint" -ForegroundColor Yellow
    }
}

if ($SuccessCount -gt 0) {
    Write-Host "  ✅ Test traffic generated successfully ($SuccessCount/$($TestEndpoints.Count) endpoints)" -ForegroundColor Green
} else {
    Write-Host "  ❌ No test traffic generated" -ForegroundColor Red
}

# Test 4: Check Application Pages
Write-Host "`n📄 Test 4: Application Pages" -ForegroundColor Yellow
try {
    $PageResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
    if ($PageResponse.StatusCode -eq 200) {
        Write-Host "  ✅ Application homepage is accessible" -ForegroundColor Green
        Write-Host "  📊 Status Code: $($PageResponse.StatusCode)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️ Homepage returned status: $($PageResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Homepage check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Test Summary" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host "✅ Application: http://localhost:3000" -ForegroundColor Green
Write-Host "✅ SigNoz UI: http://localhost:8080" -ForegroundColor Green
Write-Host "✅ Test traffic generated: $SuccessCount endpoints" -ForegroundColor Green

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check application: http://localhost:3000" -ForegroundColor White
Write-Host "2. Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "3. Check traces: http://localhost:8080/traces" -ForegroundColor White
Write-Host "4. Check logs: http://localhost:8080/logs" -ForegroundColor White
Write-Host "5. Check alerts: http://localhost:8080/alerts" -ForegroundColor White

Write-Host "`n✅ Application test completed!" -ForegroundColor Green
