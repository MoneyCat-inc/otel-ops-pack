<#
.SYNOPSIS
  BossCat Verification Runner with WYZWOZ_SIGNOZ API Key

.DESCRIPTION
  Loads the WYZWOZ_SIGNOZ API key from environment and runs the BossCat verification script.
#>

Write-Host "🐾 BossCat Authenticated Verification Runner" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan

# Check for API key
if (-not $env:WYZWOZ_SIGNOZ) {
  Write-Host "❌ ERROR: WYZWOZ_SIGNOZ environment variable not found" -ForegroundColor Red
  Write-Host "   Please set the API key: `$env:WYZWOZ_SIGNOZ = '<your_api_key>'" -ForegroundColor Yellow
  exit 1
}

Write-Host "✅ API Key loaded from WYZWOZ_SIGNOZ" -ForegroundColor Green
Write-Host ("   Length: {0} characters" -f $env:WYZWOZ_SIGNOZ.Length) -ForegroundColor DarkGray

# Run verification with API key
$scriptPath = Join-Path $PSScriptRoot "bosscat-verify-signoz-completion.ps1"
Write-Host "🔍 Running verification script..." -ForegroundColor Yellow
Write-Host ("   Script: {0}" -f $scriptPath) -ForegroundColor DarkGray
Write-Host ("   Target: http://localhost:8080") -ForegroundColor DarkGray

& $scriptPath -SigNozUrl "http://localhost:8080" -ApiKey $env:WYZWOZ_SIGNOZ

$exitCode = $LASTEXITCODE
Write-Host ""
Write-Host "🐾 BossCat Verification Complete" -ForegroundColor Green
Write-Host ("   Exit Code: {0}" -f $exitCode) -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Yellow" })

exit $exitCode

