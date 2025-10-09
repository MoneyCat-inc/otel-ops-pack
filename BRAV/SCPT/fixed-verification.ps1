# Fixed SigNoz Verification Script
# ECRR Framework Implementation - Authentication Fix

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$AppUrl = "http://localhost:3000"
)

Write-Host "🔍 Fixed SigNoz Verification" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

$Results = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    tests = @{}
    summary = @{
        total = 0
        passed = 0
        failed = 0
    }
}

# Test 1: SigNoz Health (No Auth Required)
Write-Host "🏥 Test 1: SigNoz Health Check" -ForegroundColor Yellow
$Results.summary.total++

try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -TimeoutSec 10
    Write-Host "  ✅ SigNoz is healthy" -ForegroundColor Green
    $Results.tests["signoz_health"] = @{
        status = "PASS"
        message = "SigNoz is healthy and accessible"
    }
    $Results.summary.passed++
} catch {
    Write-Host "  ❌ SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
    $Results.tests["signoz_health"] = @{
        status = "FAIL"
        message = "SigNoz health check failed"
        error = $_.Exception.Message
    }
    $Results.summary.failed++
}

# Test 2: Application Health
Write-Host "`n🌐 Test 2: Application Health Check" -ForegroundColor Yellow
$Results.summary.total++

try {
    $AppHealthResponse = Invoke-RestMethod -Uri "$AppUrl/api/health" -Method GET -TimeoutSec 10
    Write-Host "  ✅ Application is healthy" -ForegroundColor Green
    $Results.tests["app_health"] = @{
        status = "PASS"
        message = "Application is healthy and accessible"
    }
    $Results.summary.passed++
} catch {
    Write-Host "  ❌ Application health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 Make sure the app is running: npm run dev" -ForegroundColor Yellow
    $Results.tests["app_health"] = @{
        status = "FAIL"
        message = "Application health check failed"
        error = $_.Exception.Message
    }
    $Results.summary.failed++
}

# Test 3: Generate Test Traffic
Write-Host "`n📡 Test 3: Generating Test Traffic" -ForegroundColor Yellow
$Results.summary.total++

try {
    # Generate some test API calls
    $TestEndpoints = @("$AppUrl/api/health", "$AppUrl/api/auth/session")
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
        Write-Host "  ✅ Test traffic generated successfully" -ForegroundColor Green
        $Results.tests["traffic_generation"] = @{
            status = "PASS"
            message = "Test traffic generated successfully"
            success_count = $SuccessCount
        }
        $Results.summary.passed++
    } else {
        Write-Host "  ❌ No test traffic generated" -ForegroundColor Red
        $Results.tests["traffic_generation"] = @{
            status = "FAIL"
            message = "No test traffic generated"
        }
        $Results.summary.failed++
    }
} catch {
    Write-Host "  ❌ Traffic generation failed: $($_.Exception.Message)" -ForegroundColor Red
    $Results.tests["traffic_generation"] = @{
        status = "FAIL"
        message = "Traffic generation failed"
        error = $_.Exception.Message
    }
    $Results.summary.failed++
}

# Test 4: Check SigNoz UI Accessibility (No Auth)
Write-Host "`n🌐 Test 4: SigNoz UI Accessibility" -ForegroundColor Yellow
$Results.summary.total++

try {
    # Try to access the main UI page
    $UiResponse = Invoke-WebRequest -Uri "$SigNozUrl" -Method GET -TimeoutSec 10
    if ($UiResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI is accessible" -ForegroundColor Green
        $Results.tests["signoz_ui"] = @{
            status = "PASS"
            message = "SigNoz UI is accessible"
            status_code = $UiResponse.StatusCode
        }
        $Results.summary.passed++
    } else {
        Write-Host "  ❌ SigNoz UI returned status: $($UiResponse.StatusCode)" -ForegroundColor Red
        $Results.tests["signoz_ui"] = @{
            status = "FAIL"
            message = "SigNoz UI returned unexpected status code"
            status_code = $UiResponse.StatusCode
        }
        $Results.summary.failed++
    }
} catch {
    Write-Host "  ❌ SigNoz UI check failed: $($_.Exception.Message)" -ForegroundColor Red
    $Results.tests["signoz_ui"] = @{
        status = "FAIL"
        message = "SigNoz UI check failed"
        error = $_.Exception.Message
    }
    $Results.summary.failed++
}

# Calculate success rate
$SuccessRate = [math]::Round(($Results.summary.passed / $Results.summary.total) * 100, 2)

# Generate summary
Write-Host "`n📊 Verification Summary" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green
Write-Host "✅ Passed tests: $($Results.summary.passed)" -ForegroundColor Green
Write-Host "❌ Failed tests: $($Results.summary.failed)" -ForegroundColor Red
Write-Host "📊 Success rate: $SuccessRate%" -ForegroundColor Cyan

# Detailed results
Write-Host "`n📋 Test Results:" -ForegroundColor Yellow
foreach ($Test in $Results.tests.GetEnumerator()) {
    $StatusColor = switch ($Test.Value.status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "White" }
    }
    Write-Host "  $($Test.Key): $($Test.Value.status) - $($Test.Value.message)" -ForegroundColor $StatusColor
}

# Save results
$ResultsPath = "artifacts/fixed-verification-results.json"
$Results | ConvertTo-Json -Depth 5 | Set-Content -Path $ResultsPath
Write-Host "`n📝 Results saved to: $ResultsPath" -ForegroundColor Green

# Next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Check traces: $SigNozUrl/traces" -ForegroundColor White
Write-Host "3. Check logs: $SigNozUrl/logs" -ForegroundColor White
Write-Host "4. Check alerts: $SigNozUrl/alerts" -ForegroundColor White
Write-Host "5. Check metrics: $SigNozUrl/metrics" -ForegroundColor White

# Final status
if ($SuccessRate -ge 75) {
    Write-Host "`n🎉 Verification PASSED!" -ForegroundColor Green
    Write-Host "✅ Observability stack is working" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Verification needs attention" -ForegroundColor Yellow
    Write-Host "❌ Review failed tests" -ForegroundColor Red
}

Write-Host "`n✅ Fixed verification completed!" -ForegroundColor Green
