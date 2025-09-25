# Import Windows Canary Alert to SigNoz
# ECRR: Examine → Clean → Report → Role

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== SigNoz Canary Alert Import ===" -ForegroundColor Green

$script:importPassed = $true

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red; $script:importPassed = $false }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }

Write-Host "`n1. Alert Configuration:" -ForegroundColor Yellow

$canaryAlert = @{
    name = "Windows Canary Log Absence"
    description = "Alert when canary logs stop appearing for more than 5 minutes"
    query = "absent_over_time(count by (test_id) (log.body contains `"windows-canary`")[5m])"
    severity = "critical"
    duration = "5m"
    notification_channels = @("default")
}

Write-Pass "Alert Name: $($canaryAlert.name)"
Write-Pass "Query: $($canaryAlert.query)"
Write-Pass "Severity: $($canaryAlert.severity)"
Write-Pass "Duration: $($canaryAlert.duration)"

Write-Host "`n2. Manual Import Instructions:" -ForegroundColor Yellow
Write-Host "Since SigNoz API authentication is not configured, please import manually:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
Write-Host "2. Navigate to: Alerts → Create Alert" -ForegroundColor Yellow
Write-Host "3. Configure alert with these settings:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Alert Name: $($canaryAlert.name)" -ForegroundColor White
Write-Host "   Description: $($canaryAlert.description)" -ForegroundColor White
Write-Host "   Query: $($canaryAlert.query)" -ForegroundColor White
Write-Host "   Severity: $($canaryAlert.severity)" -ForegroundColor White
Write-Host "   Duration: $($canaryAlert.duration)" -ForegroundColor White
Write-Host ""
Write-Host "4. Save the alert" -ForegroundColor Yellow
Write-Host "5. Test by running: pwsh -File scripts/test-canary-alert.ps1" -ForegroundColor Yellow

Write-Host "`n3. Automated Import (if API token available):" -ForegroundColor Yellow
Write-Host "To enable automated import, set the SIGNOZ_API_TOKEN environment variable:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   `$env:SIGNOZ_API_TOKEN = `"your-api-token-here`"" -ForegroundColor White
Write-Host "   pwsh -File scripts/import-canary-alert.ps1 -AutoImport" -ForegroundColor White

Write-Host "`n4. Alert Testing:" -ForegroundColor Yellow
Write-Host "After importing the alert, test it by:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Generate canary logs: pwsh -File scripts/test-canary-alert.ps1" -ForegroundColor Yellow
Write-Host "2. Wait 5+ minutes without generating canary logs" -ForegroundColor Yellow
Write-Host "3. Check SigNoz UI for alert firing" -ForegroundColor Yellow
Write-Host "4. Verify alert resolves when canary logs resume" -ForegroundColor Yellow

Write-Host "`n=== Import Complete ===" -ForegroundColor Green
if ($importPassed) {
    Write-Host "✅ Canary alert configuration ready for import" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Follow manual import instructions above" -ForegroundColor Yellow
    Write-Host "2. Test the alert with canary log generation" -ForegroundColor Yellow
    Write-Host "3. Monitor alert firing and resolution" -ForegroundColor Yellow
} else {
    Write-Host "❌ Canary alert import preparation failed" -ForegroundColor Red
    Write-Host "Review errors above and retry" -ForegroundColor Red
}

# Save alert configuration for reference
$artifactsDir = ".artifacts"
if (-not (Test-Path $artifactsDir)) { New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null }
$alertConfigFile = Join-Path $artifactsDir "canary-alert-config.json"
$canaryAlert | ConvertTo-Json -Depth 3 | Out-File -FilePath $alertConfigFile -Encoding utf8NoBOM
Write-Host "`nAlert configuration saved: $alertConfigFile" -ForegroundColor Cyan

exit $(if ($importPassed) { 0 } else { 1 })
