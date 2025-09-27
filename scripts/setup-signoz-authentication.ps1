# SigNoz Authentication Setup Script
# Guides user through complete SigNoz API authentication setup

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$SkipBrowser = $false,
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "SigNoz Authentication Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check current authentication status
Write-Host "`nExamine: Checking current SigNoz authentication status..." -ForegroundColor Green

$AuthStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    signoz_url = $SigNozUrl
    ui_accessible = $false
    api_token_set = $false
    authentication_working = $false
    recommendations = @()
}

# Check if SigNoz UI is accessible
Write-Host "Checking SigNoz UI accessibility..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri $SigNozUrl -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI accessible at $SigNozUrl" -ForegroundColor Green
        $AuthStatus.ui_accessible = $true
    }
} catch {
    Write-Host "  ❌ SigNoz UI not accessible at $SigNozUrl" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    $AuthStatus.recommendations += "Start SigNoz stack (docker-compose up -d)"
}

# Check if API token is set
Write-Host "Checking API token..." -ForegroundColor Yellow
if ($env:SIGNOZ_API_TOKEN) {
    Write-Host "  ✅ API token is set" -ForegroundColor Green
    $AuthStatus.api_token_set = $true
} else {
    Write-Host "  ❌ API token not set" -ForegroundColor Red
    $AuthStatus.recommendations += "Generate API token in SigNoz UI and set environment variable"
}

# Test authentication if token is set
if ($env:SIGNOZ_API_TOKEN -and $AuthStatus.ui_accessible) {
    Write-Host "Testing API authentication..." -ForegroundColor Yellow
    try {
        $Headers = @{
            "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN"
            "Content-Type" = "application/json"
        }
        
        $TestQuery = @{
            query = "*"
            start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            limit = 1
        }
        
        $LogsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Headers $Headers -Body ($TestQuery | ConvertTo-Json) -TimeoutSec 10
        
        Write-Host "  ✅ API authentication working" -ForegroundColor Green
        $AuthStatus.authentication_working = $true
    } catch {
        Write-Host "  ❌ API authentication failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $AuthStatus.recommendations += "Check API token validity and permissions"
    }
}

# Clean: Provide setup guidance
if (-not $AuthStatus.authentication_working) {
    Write-Host "`nClean: Setting up SigNoz authentication..." -ForegroundColor Green
    
    if (-not $AuthStatus.ui_accessible) {
        Write-Host "`n=== SIGNOZ UI SETUP ===" -ForegroundColor Cyan
        Write-Host "1. Start SigNoz stack:" -ForegroundColor White
        Write-Host "   docker-compose up -d" -ForegroundColor Yellow
        Write-Host "2. Wait for services to start (30-60 seconds)" -ForegroundColor White
        Write-Host "3. Open browser: $SigNozUrl" -ForegroundColor White
        Write-Host "4. Complete initial setup if prompted" -ForegroundColor White
        Write-Host ""
        Read-Host "Press Enter when SigNoz UI is accessible"
    }
    
    if (-not $AuthStatus.api_token_set) {
        Write-Host "`n=== API TOKEN GENERATION ===" -ForegroundColor Cyan
        Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
        Write-Host "2. Navigate to Settings → API Keys" -ForegroundColor White
        Write-Host "3. Click 'Generate New API Key'" -ForegroundColor White
        Write-Host "4. Fill in details:" -ForegroundColor White
        Write-Host "   - Name: OTel Pipeline Monitoring" -ForegroundColor Yellow
        Write-Host "   - Description: API key for OpenTelemetry pipeline monitoring" -ForegroundColor Yellow
        Write-Host "   - Permissions: Read (minimum required)" -ForegroundColor Yellow
        Write-Host "   - Expiration: 1 year (recommended)" -ForegroundColor Yellow
        Write-Host "5. Click 'Generate' and COPY the token" -ForegroundColor White
        Write-Host "6. Set environment variable:" -ForegroundColor White
        Write-Host "   `$env:SIGNOZ_API_TOKEN = 'your-actual-api-token-here'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter when API token is generated and set"
    }
    
    # Re-test authentication
    if ($env:SIGNOZ_API_TOKEN -and $AuthStatus.ui_accessible) {
        Write-Host "`nRe-testing authentication..." -ForegroundColor Yellow
        try {
            $Headers = @{
                "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN"
                "Content-Type" = "application/json"
            }
            
            $TestQuery = @{
                query = "*"
                start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
                end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
                limit = 1
            }
            
            $LogsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Headers $Headers -Body ($TestQuery | ConvertTo-Json) -TimeoutSec 10
            
            Write-Host "  ✅ API authentication now working" -ForegroundColor Green
            $AuthStatus.authentication_working = $true
        } catch {
            Write-Host "  ❌ API authentication still failing" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Report: Generate authentication status report
Write-Host "`nReport: Authentication status summary" -ForegroundColor Green

Write-Host "`nAuthentication Status:" -ForegroundColor Cyan
Write-Host "  SigNoz UI: $(if ($AuthStatus.ui_accessible) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($AuthStatus.ui_accessible) { 'Green' } else { 'Red' })
Write-Host "  API Token: $(if ($AuthStatus.api_token_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($AuthStatus.api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Authentication: $(if ($AuthStatus.authentication_working) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($AuthStatus.authentication_working) { 'Green' } else { 'Red' })

if ($AuthStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $AuthStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save authentication status report
$AuthStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/signoz-auth-setup.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/signoz-auth-setup.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($AuthStatus.authentication_working) {
    Write-Host "Next: Authentication setup complete - proceed with dashboard import" -ForegroundColor Green
    Write-Host "Then: Configure webhook notifications and test end-to-end pipeline" -ForegroundColor Green
} else {
    Write-Host "Next: Complete manual authentication setup in SigNoz UI" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify authentication" -ForegroundColor Yellow
}

# Additional setup guidance
if ($AuthStatus.authentication_working) {
    Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
    Write-Host "1. Import queue pressure dashboard:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/import-dashboard.ps1" -ForegroundColor Yellow
    Write-Host "2. Configure webhook notifications:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/setup-webhooks.ps1" -ForegroundColor Yellow
    Write-Host "3. Test end-to-end pipeline:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/test-e2e-pipeline.ps1" -ForegroundColor Yellow
}
