#requires -Version 5.1
[CmdletBinding()]
param(
  [string]$SignozUrl = $env:SIGNOZ_URL,
  [switch]$Headed
)

$ErrorActionPreference = 'Stop'

if (-not $SignozUrl) { $SignozUrl = 'http://localhost:8080' }

Write-Host
Write-Host '[SigNoz Sleekify] Playwright runner starting'
Write-Host "[SigNoz Sleekify] Target: $SignozUrl"
if ($env:SIGNOZ_USER) { Write-Host "[SigNoz Sleekify] User: $($env:SIGNOZ_USER)" }
Write-Host

try {
  Write-Host 'Ensuring Playwright chromium browser binaries are installed...'
  npx --yes playwright install chromium | Out-Host
} catch {
  Write-Error "Failed to install Playwright browsers: $($_.Exception.Message)"
  exit 1
}

$env:SIGNOZ_URL = $SignozUrl
$env:SIGNOZ_USER = $env:SIGNOZ_USER
$env:SIGNOZ_PASS = $env:SIGNOZ_PASS
$env:SIGNOZ_EMAIL = $env:SIGNOZ_EMAIL
$env:SIGNOZ_PASSWORD = $env:SIGNOZ_PASSWORD
$headedSwitch = if ($Headed.IsPresent -or $env:HEADED) { '--headed' } else { '' }
$artifactsDir = Join-Path (Get-Location) 'artifacts'
if (-not (Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir | Out-Null }
$env:PLAYWRIGHT_JUNIT_OUTPUT = Join-Path $artifactsDir 'results.xml'
$env:DEBUG = 'pw:api'

$testPath = 'tests/signoz-sleekify.spec.ts'
$cmd = "npx playwright test `"$testPath`" --reporter=line $headedSwitch"

Write-Host "Running: $cmd"
try {
  Invoke-Expression $cmd
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    if (Test-Path $artifactsDir) {
      Write-Host 'Artifacts in artifacts/'
      Get-ChildItem -Path $artifactsDir | Out-Host
    }
    Write-Error "Playwright run failed with exit code: $exitCode"
    exit $exitCode
  }
} catch {
  if (Test-Path $artifactsDir) {
    Write-Host 'Artifacts in artifacts/'
    Get-ChildItem -Path $artifactsDir | Out-Host
  }
  Write-Error "Playwright run failed: $($_.Exception.Message)"
  exit 2
}

Write-Host 'SigNoz sleekify flow completed successfully.'
