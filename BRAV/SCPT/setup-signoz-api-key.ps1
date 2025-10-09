# Quick helper to set up SigNoz API key for enterprise views
# Run this after copying your API key from SigNoz UI

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey
)

Write-Host ""
Write-Host "🐾 BossCat · SigNoz API Key Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

if (-not $ApiKey) {
    Write-Host "Please enter your SigNoz API key:" -ForegroundColor Yellow
    Write-Host "(Paste it here - it won't be displayed)" -ForegroundColor Gray
    $secureKey = Read-Host -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

if (-not $ApiKey -or $ApiKey -eq "") {
    Write-Host "✗ No API key provided" -ForegroundColor Red
    exit 1
}

# Set in current session
$env:SIGNOZ_API_KEY = $ApiKey
Write-Host "✓ API key set in current session" -ForegroundColor Green

# Update secrets file for persistence
$secretsPath = "scripts\secrets\signoz.secrets.ps1"
if (Test-Path $secretsPath) {
    $content = Get-Content $secretsPath -Raw
    $content = $content -replace '\$env:SIGNOZ_API_TOKEN = ".*"', "`$env:SIGNOZ_API_TOKEN = `"$ApiKey`""
    $content | Set-Content $secretsPath -Encoding UTF8
    Write-Host "✓ Updated secrets file: $secretsPath" -ForegroundColor Green
} else {
    Write-Host "⚠ Secrets file not found - created new one" -ForegroundColor Yellow
    $newContent = @"
# Set your local SigNoz details here. This file is git-ignored.
`$env:SIGNOZ_BASE_URL = "http://localhost:8080"

# API Token for SigNoz
`$env:SIGNOZ_API_TOKEN = "$ApiKey"

# Set SIGNOZ_API_KEY for compatibility with enterprise view scripts
`$env:SIGNOZ_API_KEY = `$env:SIGNOZ_API_TOKEN
"@
    $newContent | Set-Content $secretsPath -Encoding UTF8
    Write-Host "✓ Created secrets file: $secretsPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "✓ Setup Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run integration test:" -ForegroundColor Gray
Write-Host "     pwsh -File scripts\integration-test-enterprise-views.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  2. Or provision directly:" -ForegroundColor Gray
Write-Host "     pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1" -ForegroundColor White
Write-Host ""

# Test the API key
Write-Host "Testing API key..." -ForegroundColor Yellow
try {
    $headers = @{
        "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY
        "Content-Type" = "application/json"
    }
    $result = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Headers $headers -Method GET -TimeoutSec 5
    Write-Host "✓ API key verified - SigNoz is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not verify API key (SigNoz might not require auth for health endpoint)" -ForegroundColor Yellow
    Write-Host "  Proceed with integration test to confirm" -ForegroundColor Gray
}

Write-Host ""

