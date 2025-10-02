#requires -Version 5.1
param(
  [string]$SignozUrl = $env:SIGNOZ_URL
)

$ErrorActionPreference = 'Stop'
$host.UI.RawUI.WindowTitle = 'SigNoz Automation'

Write-Host ''
Write-Host ('=' * 66)
Write-Host '  OTel + SigNoz Automation (Playwright)'
Write-Host ('=' * 66)
Write-Host ''

if (-not $SignozUrl -or $SignozUrl.Trim() -eq '') {
  $SignozUrl = 'http://localhost:8080'
}
Write-Host "Target: $SignozUrl"

function Test-HttpOk([string]$Url) {
  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
    return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
  } catch {
    return $false
  }
}

$collectorHealth = Test-HttpOk 'http://localhost:13134/healthz'
if ($collectorHealth) {
  Write-Host 'Collector health endpoint is up'
} else {
  Write-Host 'Collector /healthz not responding (continuing)'
}

$signozOk = Test-HttpOk $SignozUrl
if (-not $signozOk) {
  Write-Host "SigNoz not reachable at $SignozUrl"
  Write-Host 'Start SigNoz first (docker-compose or service), then rerun.'
  exit 1
}
Write-Host 'SigNoz reachable'

Write-Host 'Checking Playwright...'
try {
  $null = npx playwright --version 2>$null
  Write-Host 'Playwright CLI available'
} catch {
  Write-Host 'Installing Playwright browsers...'
  npx playwright install
}

Write-Host ''
Write-Host 'Running SigNoz automation tests...'
$cmd = 'npx playwright test tests/signoz.final.spec.ts -c playwright.signoz.config.ts --reporter=line'
$env:SIGNOZ_URL = $SignozUrl
Write-Host "Command: $cmd"
cmd /c $cmd
$code = $LASTEXITCODE

if ($code -eq 0) {
  Write-Host ''
  Write-Host 'SigNoz automation complete!'
  Write-Host "Dashboards: $SignozUrl/dashboards"
  Write-Host "Alerts:     $SignozUrl/alerts/rules"
  exit 0
} else {
  Write-Host ''
  Write-Host 'Some tests failed. See Playwright HTML report:'
  Write-Host '  npx playwright show-report'
  exit $code
}