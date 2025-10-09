# scripts/automate-signoz-setup-fresh.ps1
#requires -Version 5.1
param(
    [string]$SignozUrl = $env:SIGNOZ_URL,
    [switch]$SkipHealthCheck,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$host.UI.RawUI.WindowTitle = 'SigNoz Automation (Fresh)'

# Verbose logging
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

Write-Host ''
Write-Host ('=' * 70)
Write-Host '  SigNoz Automation (Fresh) - Enhanced Version'
Write-Host ('=' * 70)
Write-Host ''

if (-not $SignozUrl -or $SignozUrl.Trim() -eq '') {
    $SignozUrl = 'http://localhost:8080'
}
Write-Host " Target: $SignozUrl"

# Validate environment
Write-Host ''
Write-Host ' Validating environment...'

if (-not $env:SIGNOZ_USER -or -not $env:SIGNOZ_PASS) {
    Write-Host ' SigNoz credentials missing. Set SIGNOZ_USER and SIGNOZ_PASS before running.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'To set credentials:'
    Write-Host '  $env:SIGNOZ_USER = "your-email@example.com"'
    Write-Host '  $env:SIGNOZ_PASS = "your-password"'
    Write-Host ''
    Write-Host 'Or add to PowerShell profile:'
    Write-Host '  Add-Content $PROFILE "`$env:SIGNOZ_USER = `"your-email@example.com`""'
    Write-Host '  Add-Content $PROFILE "`$env:SIGNOZ_PASS = `"your-password`""'
    exit 1
}
Write-Host ' SigNoz credentials present'

# Health check function
function Test-HttpOk([string]$Url, [int]$TimeoutSec = 10) {
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
    } catch {
        Write-Verbose "HTTP check failed for $Url : $($_.Exception.Message)"
        return $false
    }
}

# Check SigNoz health
if (-not $SkipHealthCheck) {
    Write-Host ''
    Write-Host ' Checking SigNoz health...'
    
    $signozOk = Test-HttpOk $SignozUrl
    if (-not $signozOk) {
        Write-Host " SigNoz not reachable at $SignozUrl" -ForegroundColor Red
        Write-Host ''
        Write-Host 'Troubleshooting steps:'
        Write-Host '  1. Start SigNoz: docker compose -f docker-compose-signoz.yml up -d'
        Write-Host '  2. Wait for startup: timeout 300 bash -c "until curl -sf $SignozUrl/api/v1/health; do sleep 5; done"'
        Write-Host '  3. Check logs: docker logs signoz'
        Write-Host ''
        exit 1
    }
    Write-Host ' SigNoz is reachable'
    
    # Check API health
    $apiHealth = Test-HttpOk "$SignozUrl/api/v1/health"
    if ($apiHealth) {
        Write-Host ' SigNoz API health check passed'
    } else {
        Write-Host '  SigNoz API health check failed (continuing anyway)'
    }
}

# Check Playwright
Write-Host ''
Write-Host ' Checking Playwright...'
try {
    $playwrightVersion = npx playwright --version 2>$null
    if ($playwrightVersion) {
        Write-Host " Playwright CLI available: $playwrightVersion"
    } else {
        throw "Playwright not found"
    }
} catch {
    Write-Host ' Installing Playwright browsers...'
    npx playwright install
    if ($LASTEXITCODE -ne 0) {
        Write-Host ' Failed to install Playwright browsers' -ForegroundColor Red
        exit 1
    }
    Write-Host ' Playwright browsers installed'
}

# Run tests
Write-Host ''
Write-Host ' Running SigNoz automation tests...'
Write-Host "Command: npx playwright test tests/signoz.final.spec.ts -c playwright.signoz.config.ts --reporter=line"

$env:SIGNOZ_URL = $SignozUrl
$testCmd = 'npx playwright test tests/signoz.final.spec.ts -c playwright.signoz.config.ts --reporter=line'

try {
    cmd /c $testCmd
    $testResult = $LASTEXITCODE
} catch {
    Write-Host " Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResult = 1
}

Write-Host ''
if ($testResult -eq 0) {
    Write-Host ' SigNoz automation completed successfully!' -ForegroundColor Green
    Write-Host ''
    Write-Host ' Available at:'
    Write-Host "   SigNoz UI: $SignozUrl"
    Write-Host "   Dashboards: $SignozUrl/dashboards"
    Write-Host "   Alerts: $SignozUrl/alerts/rules"
    Write-Host "   Logs: $SignozUrl/logs"
    Write-Host ''
    Write-Host ' Test coverage:'
    Write-Host '   Health check API'
    Write-Host '   Authentication flow'
    Write-Host '   Dashboard navigation'
    Write-Host '   Alerts page access'
    Write-Host '   Logs search functionality'
    exit 0
} else {
    Write-Host ' Some tests failed. See details below:' -ForegroundColor Red
    Write-Host ''
    Write-Host ' Troubleshooting:'
    Write-Host '   Check Playwright HTML report: npx playwright show-report'
    Write-Host '   Verify SigNoz is running: curl -sf $SignozUrl/api/v1/health'
    Write-Host '   Check credentials: $env:SIGNOZ_USER and $env:SIGNOZ_PASS'
    Write-Host '   Review browser console for JavaScript errors'
    Write-Host ''
    Write-Host ' Common fixes:'
    Write-Host '   Restart SigNoz: docker compose -f docker-compose-signoz.yml restart'
    Write-Host '   Clear browser cache: npx playwright show-report (then clear browser data)'
    Write-Host '   Check network connectivity to $SignozUrl'
    exit $testResult
}

