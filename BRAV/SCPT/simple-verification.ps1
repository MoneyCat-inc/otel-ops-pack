# Simple Verification Script - Fixed Version
# ECRR Framework Implementation

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "local-signoz-jwt-secret-rotate",
    [string]$AppUrl = "http://localhost:3000"
)

Write-Host "🔍 Simple Observability Verification" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

$Results = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    tests = @{}
    summary = @{
        total = 0
        passed = 0
        failed = 0
    }
}

# Test 1: SigNoz Health
Write-Host "🏥 Test 1: SigNoz Health Check" -ForegroundColor Yellow
$Results.summary.total++

try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -Headers $Headers -TimeoutSec 10
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

# Test 4: Check Logs
Write-Host "`n📝 Test 4: Log Verification" -ForegroundColor Yellow
$Results.summary.total++

try {
    $LogsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method GET -Headers $Headers -Body @{query="service_name='resonai-backend'"} -TimeoutSec 10
    
    if ($LogsResponse.logs -and $LogsResponse.logs.Count -gt 0) {
        Write-Host "  ✅ Logs found: $($LogsResponse.logs.Count) entries" -ForegroundColor Green
        $Results.tests["log_verification"] = @{
            status = "PASS"
            message = "Logs successfully found in SigNoz"
            log_count = $LogsResponse.logs.Count
        }
        $Results.summary.passed++
    } else {
        Write-Host "  ❌ No logs found" -ForegroundColor Red
        $Results.tests["log_verification"] = @{
            status = "FAIL"
            message = "No logs found in SigNoz"
        }
        $Results.summary.failed++
    }
} catch {
    Write-Host "  ❌ Log verification failed: $($_.Exception.Message)" -ForegroundColor Red
    $Results.tests["log_verification"] = @{
        status = "FAIL"
        message = "Log verification failed"
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
$ResultsPath = "artifacts/simple-verification-results.json"
$Results | ConvertTo-Json -Depth 5 | Set-Content -Path $ResultsPath
Write-Host "`n📝 Results saved to: $ResultsPath" -ForegroundColor Green

# Final status
if ($SuccessRate -ge 75) {
    Write-Host "`n🎉 Verification PASSED!" -ForegroundColor Green
    Write-Host "✅ Observability stack is working" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Verification needs attention" -ForegroundColor Yellow
    Write-Host "❌ Review failed tests" -ForegroundColor Red
}

Write-Host "`n✅ Verification completed!" -ForegroundColor Green
