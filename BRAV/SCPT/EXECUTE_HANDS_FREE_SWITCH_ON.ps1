<#
.SYNOPSIS
    BossCat Hands-Free Switch-On - Quick Execution Script
.DESCRIPTION
    Quick wrapper to execute the hands-free switch-on with minimal configuration.
    This script sets up the environment and runs the full 4-step sequence.
.USAGE
    # Set your API key first:
    $env:WYZWOZ_SIGNOZ = "<your-api-key>"
    
    # Then run this script:
    pwsh -File scripts\EXECUTE_HANDS_FREE_SWITCH_ON.ps1
#>

# Set SigNoz URL
$env:SIGNOZ_URL = "http://localhost:8080"

# Check if API key is set
if (-not $env:WYZWOZ_SIGNOZ) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ⚠️  API KEY NOT SET" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please set your SigNoz API key first:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  $env:WYZWOZ_SIGNOZ = "<your-api-key>"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then run this script again:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  pwsh -File scripts\EXECUTE_HANDS_FREE_SWITCH_ON.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Set API key for execution
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🐾 BOSSCAT HANDS-FREE SWITCH-ON - EXECUTING" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Environment:" -ForegroundColor Green
Write-Host "   • SigNoz URL: $env:SIGNOZ_URL" -ForegroundColor White
Write-Host "   • API Key: Set (masked)" -ForegroundColor White
Write-Host ""
Write-Host "📋 Execution Sequence:" -ForegroundColor Yellow
Write-Host "   1. Smoke-check API" -ForegroundColor White
Write-Host "   2. Create sentinel alert (BLUE → GREEN)" -ForegroundColor White
Write-Host "   3. Upsert 8 BossCat alerts" -ForegroundColor White
Write-Host "   4. Verify completion" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Starting execution..." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Execute the hands-free switch-on
try {
    & pwsh -File "$PSScriptRoot\bosscat-hands-free-switch-on.ps1" `
        -SigNozUrl $env:SIGNOZ_URL `
        -ApiKey $env:SIGNOZ_API_KEY
    
    $exitCode = $LASTEXITCODE
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    if ($exitCode -eq 0) {
        Write-Host "  ✅ HANDS-FREE SWITCH-ON COMPLETED SUCCESSFULLY" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ Next Steps:" -ForegroundColor Green
        Write-Host "   1. Refresh SigNoz: http://localhost:8080" -ForegroundColor White
        Write-Host "   2. Verify 'Setup Alerts' tile is GREEN" -ForegroundColor White
        Write-Host "   3. Check Alerts page for 8 BossCat alerts" -ForegroundColor White
        Write-Host ""
        Write-Host "📁 Artifacts:" -ForegroundColor Cyan
        Write-Host "   • docs/BossCat/signoz-completion-verification.json" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  ⚠️  EXECUTION COMPLETED WITH WARNINGS" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  Please review logs above for details" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "🐾 Authority: BossCat OEM" -ForegroundColor Magenta
    Write-Host ""
    
    exit $exitCode
    
} catch {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ❌ EXECUTION FAILED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🧯 Troubleshooting:" -ForegroundColor Cyan
    Write-Host "   • Verify SigNoz is running: docker ps | grep signoz" -ForegroundColor White
    Write-Host "   • Check SigNoz health: curl http://localhost:8080/api/v1/health" -ForegroundColor White
    Write-Host "   • Verify API key is correct" -ForegroundColor White
    Write-Host ""
    exit 1
}

