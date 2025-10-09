# API Token Verification — Evidence Capture Script
# Run this after setting SIGNOZ_API_TOKEN to capture proof for PR

param(
    [string]$Token,
    [switch]$Persistent
)

Write-Host "🔍 API Token Verification — Evidence Capture" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# 1. Set the token
if ($Token) {
    if ($Persistent) {
        Write-Host "Setting persistent token..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("SIGNOZ_API_TOKEN", $Token, "User")
        $env:SIGNOZ_API_TOKEN = $Token
        Write-Host "✅ Token set persistently" -ForegroundColor Green
    } else {
        Write-Host "Setting temporary token..." -ForegroundColor Yellow
        $env:SIGNOZ_API_TOKEN = $Token
        Write-Host "✅ Token set for current session" -ForegroundColor Green
    }
    
    # Verify token is set
    $tokenPreview = if ($env:SIGNOZ_API_TOKEN) { $env:SIGNOZ_API_TOKEN.Substring(0,8) + "..." } else { "NOT SET" }
    Write-Host "Token preview: $tokenPreview" -ForegroundColor Gray
} else {
    if (-not $env:SIGNOZ_API_TOKEN) {
        Write-Host "❌ No token provided and SIGNOZ_API_TOKEN not set" -ForegroundColor Red
        Write-Host "Usage: .\capture-evidence.ps1 -Token 'your-token' [-Persistent]" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Using existing SIGNOZ_API_TOKEN" -ForegroundColor Yellow
}

Write-Host ""

# 2. Run full verifier and save output
Write-Host "Running full verification..." -ForegroundColor Yellow
$verifyOutput = pwsh -File .\scripts\verify-integration.ps1 *>&1 | Tee-Object -FilePath .\artifacts\verify-run.txt

# Check for success
if ($verifyOutput -match "== Verification complete: all checks passed ==") {
    Write-Host "✅ Verification PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Verification FAILED" -ForegroundColor Red
    Write-Host "Check .\artifacts\verify-run.txt for details" -ForegroundColor Yellow
}

Write-Host ""

# 3. API probe for redaction evidence
Write-Host "Running API probe for redaction evidence..." -ForegroundColor Yellow
try {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $start = $now - 900000  # 15 minutes ago
    $payload = @{
        start = $start
        end = $now
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "A"
                    signal = "logs"
                    filter = @{ expression = 'log.body contains "synthetic_id"' }
                    order = @(@{ key = @{name="timestamp"}; direction = "desc"})
                    limit = 1
                    offset = 0
                }
            })
        }
    } | ConvertTo-Json -Depth 6
    
    $apiResponse = Invoke-RestMethod -Method Post `
        -Uri "http://localhost:8080/api/v5/query_range" `
        -ContentType "application/json" `
        -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_TOKEN } `
        -Body $payload
    
    $apiResponse | ConvertTo-Json -Depth 6 | Tee-Object .\artifacts\api-sample.json
    Write-Host "✅ API probe successful" -ForegroundColor Green
    
    # Check for redaction
    $responseText = $apiResponse | ConvertTo-Json -Depth 6
    if ($responseText -match "Bearer \*\*\*" -and $responseText -match "pwd=\*\*\*") {
        Write-Host "✅ Redaction confirmed: Bearer *** and pwd=*** found" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Redaction not confirmed in response" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ API probe failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check .\artifacts\api-sample.json for details" -ForegroundColor Yellow
}

Write-Host ""

# 4. Summary
Write-Host "📋 Evidence Captured:" -ForegroundColor Cyan
Write-Host "- .\artifacts\verify-run.txt — Full verification output" -ForegroundColor Gray
Write-Host "- .\artifacts\api-sample.json — API response with redaction" -ForegroundColor Gray
Write-Host "- .\artifacts\PR_COMMENT_TEMPLATE.md — PR comment template" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 Ready for PR! Copy the template and attach artifacts." -ForegroundColor Green
