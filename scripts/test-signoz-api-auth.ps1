# SigNoz API Authentication Test Script
# Test different authentication methods for SigNoz API

param(
    [string]$ApiToken = "eE5syxJUco90j8vq34YPlbHaUg3NpS0UUEYYCzgE7mc=",
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$Username = "admin",
    [string]$Password = "admin"
)

Write-Host "=== SigNoz API Authentication Test ===" -ForegroundColor Green

# Test different authentication methods
$authMethods = @(
    @{
        name = "Bearer Token"
        headers = @{
            "Authorization" = "Bearer $ApiToken"
            "Content-Type" = "application/json"
        }
    },
    @{
        name = "API Key Header"
        headers = @{
            "X-API-Key" = $ApiToken
            "Content-Type" = "application/json"
        }
    },
    @{
        name = "Basic Auth"
        headers = @{
            "Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password")))"
            "Content-Type" = "application/json"
        }
    },
    @{
        name = "No Auth"
        headers = @{
            "Content-Type" = "application/json"
        }
    }
)

Write-Host "`n=== Testing Authentication Methods ===" -ForegroundColor Yellow

foreach ($method in $authMethods) {
    Write-Host "`n🔐 Testing: $($method.name)" -ForegroundColor Cyan
    
    try {
        # Test health endpoint
        $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Headers $method.headers -TimeoutSec 10
        Write-Host "  ✅ Health endpoint accessible" -ForegroundColor Green
        
        # Test alerts endpoint
        try {
            $alertsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Headers $method.headers -TimeoutSec 10
            Write-Host "  ✅ Alerts endpoint accessible - Found $($alertsResponse.Count) alerts" -ForegroundColor Green
            
            # Show first few alerts
            if ($alertsResponse.Count -gt 0) {
                Write-Host "  📋 Sample alerts:" -ForegroundColor Gray
                $alertsResponse | Select-Object -First 3 | ForEach-Object {
                    Write-Host "     - $($_.name) (ID: $($_.id))" -ForegroundColor Gray
                }
            }
            
        } catch {
            Write-Host "  ❌ Alerts endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test dashboards endpoint
        try {
            $dashboardsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Headers $method.headers -TimeoutSec 10
            Write-Host "  ✅ Dashboards endpoint accessible - Found $($dashboardsResponse.Count) dashboards" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Dashboards endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "  🎯 RECOMMENDED METHOD: $($method.name)" -ForegroundColor Green
        
    } catch {
        Write-Host "  ❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test specific SigNoz API endpoints
Write-Host "`n=== Testing SigNoz-Specific Endpoints ===" -ForegroundColor Yellow

$signozEndpoints = @(
    @{ path = "/api/v1/health"; name = "Health Check" },
    @{ path = "/api/v1/alerts"; name = "Alerts List" },
    @{ path = "/api/v1/dashboards"; name = "Dashboards List" },
    @{ path = "/api/v1/logs"; name = "Logs Query" },
    @{ path = "/api/v1/metrics"; name = "Metrics Query" },
    @{ path = "/api/v1/traces"; name = "Traces Query" }
)

$workingHeaders = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

foreach ($endpoint in $signozEndpoints) {
    Write-Host "`n🔍 Testing: $($endpoint.name)" -ForegroundColor Cyan
    Write-Host "   URL: $SigNozUrl$($endpoint.path)" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$SigNozUrl$($endpoint.path)" -Headers $workingHeaders -TimeoutSec 10
        Write-Host "   ✅ Accessible" -ForegroundColor Green
        
        if ($response -is [array]) {
            Write-Host "   📊 Found $($response.Count) items" -ForegroundColor Gray
        } elseif ($response -is [hashtable] -or $response -is [PSCustomObject]) {
            $keys = $response.PSObject.Properties.Name
            Write-Host "   📊 Response keys: $($keys -join ', ')" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "   ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test creating a simple alert
Write-Host "`n=== Testing Alert Creation ===" -ForegroundColor Yellow

$testAlert = @{
    name = "API Test Alert"
    description = "Test alert created via API"
    query = @{
        queryType = "logs"
        logsQuery = @{
            query = "level = 'ERROR'"
            groupBy = @('service')
        }
    }
    condition = @{
        threshold = 1
        operator = "above"
        evaluationWindow = "5m"
    }
    severity = "warning"
    labels = @{
        test = "api"
        environment = "local"
    }
}

try {
    Write-Host "🔍 Testing alert creation..." -ForegroundColor Cyan
    $createResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method Post -Body ($testAlert | ConvertTo-Json -Depth 6) -Headers $workingHeaders -TimeoutSec 30
    Write-Host "✅ Alert created successfully!" -ForegroundColor Green
    Write-Host "   Alert ID: $($createResponse.id)" -ForegroundColor Gray
    Write-Host "   Alert Name: $($createResponse.name)" -ForegroundColor Gray
    
    # Clean up - delete the test alert
    Write-Host "`n🧹 Cleaning up test alert..." -ForegroundColor Yellow
    $deleteResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts/$($createResponse.id)" -Method Delete -Headers $workingHeaders -TimeoutSec 30
    Write-Host "✅ Test alert deleted" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Alert creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Authentication Test Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Use the working authentication method for API calls" -ForegroundColor White
Write-Host "2. Update scripts with correct headers" -ForegroundColor White
Write-Host "3. Test alert deployment with working auth" -ForegroundColor White
