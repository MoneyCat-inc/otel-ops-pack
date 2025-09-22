# See C:\otel\docs\comfort cat
# SigNoz Authentication Setup Helper
# Helps configure authentication for future /api/v5/* queries

param(
    [switch]$TestAuth = $false,
    [string]$AuthToken = ""
)

Write-Host "🔐 SigNoz Authentication Setup Helper" -ForegroundColor Cyan
Write-Host "Configure authentication for future API queries" -ForegroundColor Gray
Write-Host ""

# Check if SigNoz is accessible
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3
    Write-Host "✅ SigNoz accessible at http://localhost:8080" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz not accessible at http://localhost:8080" -ForegroundColor Red
    exit 1
}

# Check current version and setup status
try {
    $version = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/version" -Method Get -TimeoutSec 3
    Write-Host "📊 SigNoz Version: $($version.version)" -ForegroundColor White
    Write-Host "📊 Setup Completed: $($version.setupCompleted)" -ForegroundColor White
} catch {
    Write-Host "⚠️  Could not retrieve version info" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Authentication Methods for /api/v5/* endpoints:" -ForegroundColor Cyan
Write-Host ""

# Method 1: JWT Token (from docker-compose.yml)
Write-Host "1. JWT Token Authentication:" -ForegroundColor Yellow
Write-Host "   - Token: YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong" -ForegroundColor Gray
Write-Host "   - Header: Authorization: Bearer <token>" -ForegroundColor Gray
Write-Host "   - Example: curl -H 'Authorization: Bearer YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong' http://localhost:8080/api/v5/query_range" -ForegroundColor Gray
Write-Host ""

# Method 2: Session-based (login via UI)
Write-Host "2. Session-based Authentication:" -ForegroundColor Yellow
Write-Host "   - Login via UI: http://localhost:8080" -ForegroundColor Gray
Write-Host "   - Extract session cookie from browser" -ForegroundColor Gray
Write-Host "   - Use cookie in subsequent requests" -ForegroundColor Gray
Write-Host ""

# Method 3: API Key (if configured)
Write-Host "3. API Key Authentication:" -ForegroundColor Yellow
Write-Host "   - Check if API keys are enabled in SigNoz settings" -ForegroundColor Gray
Write-Host "   - Generate API key in SigNoz UI" -ForegroundColor Gray
Write-Host "   - Header: X-API-Key: <api-key>" -ForegroundColor Gray
Write-Host ""

# Test authentication if token provided
if ($TestAuth -and $AuthToken) {
    Write-Host "🧪 Testing Authentication:" -ForegroundColor Cyan
    
    $headers = @{
        'Authorization' = "Bearer $AuthToken"
        'Content-Type' = 'application/json'
    }
    
    try {
        # Test with a simple query
        $testQuery = @{
            start = [long]([DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds())
            end = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
            requestType = "raw"
            compositeQuery = @{
                queries = @(@{
                    type = "builder_query"
                    spec = @{
                        name = "test_auth"
                        signal = "logs"
                        filter = @{ expression = "timestamp >= $([long]([DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds()))" }
                        limit = 1
                    }
                })
            }
        } | ConvertTo-Json -Depth 8
        
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v5/query_range" -Method Post -Body $testQuery -Headers $headers -TimeoutSec 5
        Write-Host "✅ Authentication successful!" -ForegroundColor Green
        Write-Host "   Response received from /api/v5/query_range" -ForegroundColor White
    } catch {
        Write-Host "❌ Authentication failed!" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create helper functions for authenticated requests
Write-Host ""
Write-Host "📝 Helper Functions for Authenticated Requests:" -ForegroundColor Cyan
Write-Host ""

$helperScript = @'
# SigNoz Authenticated Request Helper Functions
# Add these to your PowerShell profile or scripts

function Invoke-SigNozQuery {
    param(
        [string]$Query,
        [string]$AuthToken = "YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong",
        [string]$BaseUrl = "http://localhost:8080"
    )
    
    $headers = @{
        'Authorization' = "Bearer $AuthToken"
        'Content-Type' = 'application/json'
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v5/query_range" -Method Post -Body $Query -Headers $headers -TimeoutSec 10
        return $response
    } catch {
        Write-Error "SigNoz query failed: $($_.Exception.Message)"
        return $null
    }
}

function Get-SigNozLogs {
    param(
        [string]$Filter = "*",
        [int]$Limit = 100,
        [int]$MinutesBack = 5
    )
    
    $start = [long]([DateTimeOffset]::UtcNow.AddMinutes(-$MinutesBack).ToUnixTimeMilliseconds())
    $end = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    
    $query = @{
        start = $start
        end = $end
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "logs"
                    signal = "logs"
                    filter = @{ expression = $Filter }
                    limit = $Limit
                }
            })
        }
    } | ConvertTo-Json -Depth 8
    
    return Invoke-SigNozQuery -Query $query
}

# Usage examples:
# Get-SigNozLogs -Filter "message contains 'canary test'" -Limit 10
# Get-SigNozLogs -Filter "severity_text = 'ERROR'" -MinutesBack 60
'@

$helperScript | Out-File -FilePath "scripts/signoz-auth-helpers.ps1" -Encoding UTF8
Write-Host "✅ Created scripts/signoz-auth-helpers.ps1 with helper functions" -ForegroundColor Green

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Blue
Write-Host "   1. Test authentication: pwsh -File scripts\setup-signoz-auth.ps1 -TestAuth -AuthToken 'YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong'" -ForegroundColor Gray
Write-Host "   2. Use helper functions: . scripts\signoz-auth-helpers.ps1" -ForegroundColor Gray
Write-Host "   3. Import in scripts: . scripts\signoz-auth-helpers.ps1; Get-SigNozLogs -Filter 'canary test'" -ForegroundColor Gray
Write-Host "   4. Manual UI login: Visit http://localhost:8080 and check browser cookies for session" -ForegroundColor Gray
