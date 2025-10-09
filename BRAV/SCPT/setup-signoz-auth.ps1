# SigNoz API Authentication Setup Script
# This script configures SigNoz API authentication for automated verification

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$Email = "admin@signoz.io",
    [string]$Password = "admin"
)

Write-Host "🔐 SigNoz API Authentication Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if SigNoz is accessible
Write-Host "`n1. Checking SigNoz accessibility..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -TimeoutSec 10
    Write-Host "   ✅ SigNoz is accessible" -ForegroundColor Green
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Try to get API token
Write-Host "`n2. Attempting to get API token..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email = $Email
        password = $Password
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
    
    if ($loginResponse.accessToken) {
        $token = $loginResponse.accessToken
        Write-Host "   ✅ API token obtained successfully" -ForegroundColor Green
        
        # Save token to environment variable
        [Environment]::SetEnvironmentVariable("SIGNOZ_API_TOKEN", $token, "User")
        Write-Host "   ✅ Token saved to SIGNOZ_API_TOKEN environment variable" -ForegroundColor Green
        
        # Test API with token
        Write-Host "`n3. Testing API with token..." -ForegroundColor Yellow
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $testQuery = @{
            query = "message contains 'canary test'"
            limit = 5
        } | ConvertTo-Json
        
        $apiResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Body $testQuery -Headers $headers -TimeoutSec 10
        Write-Host "   ✅ API test successful" -ForegroundColor Green
        Write-Host "   Found $($apiResponse.data.Count) log entries" -ForegroundColor Gray
        
    } else {
        Write-Host "   ❌ No access token in response" -ForegroundColor Red
        Write-Host "   Response: $($loginResponse | ConvertTo-Json)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "   ⚠️  Authentication may not be enabled or configured" -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    
    # Try without authentication
    Write-Host "`n4. Testing API without authentication..." -ForegroundColor Yellow
    try {
        $testQuery = @{
            query = "message contains 'canary test'"
            limit = 5
        } | ConvertTo-Json
        
        $apiResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Body $testQuery -ContentType "application/json" -TimeoutSec 10
        Write-Host "   ✅ API accessible without authentication" -ForegroundColor Green
        Write-Host "   Found $($apiResponse.data.Count) log entries" -ForegroundColor Gray
        
        # Set empty token for scripts that expect it
        [Environment]::SetEnvironmentVariable("SIGNOZ_API_TOKEN", "", "User")
        Write-Host "   ✅ SIGNOZ_API_TOKEN set to empty (no auth required)" -ForegroundColor Green
        
    } catch {
        Write-Host "   ❌ API not accessible: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run verification scripts to test API access" -ForegroundColor White
Write-Host "2. Check SigNoz UI at $SigNozUrl for manual verification" -ForegroundColor White
Write-Host "3. Use SIGNOZ_API_TOKEN environment variable in scripts" -ForegroundColor White

Write-Host "`n✅ SigNoz API Authentication Setup Complete" -ForegroundColor Green