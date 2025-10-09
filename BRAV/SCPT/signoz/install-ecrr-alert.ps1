# scripts/signoz/install-ecrr-alert.ps1
# Copies alerts/ecrr-canary-missing.json to the clipboard and opens the SigNoz Alerts page.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$jsonPath = Join-Path $root 'alerts\ecrr-canary-missing.json'
if (-not (Test-Path $jsonPath)) { throw "Missing: $jsonPath" }

# Copy JSON to clipboard
$json = Get-Content $jsonPath -Raw -Encoding UTF8
Set-Clipboard -Value $json

Write-Host "[ECRR] Alert JSON copied to clipboard:" -ForegroundColor Cyan
Write-Host " - $jsonPath"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host " 1) Open SigNoz: http://localhost:8080/alerts"
Write-Host " 2) Click 'Create Alert Rule' -> switch to JSON mode (if available) OR use the builder matching the fields"
Write-Host " 3) Paste JSON (Ctrl+V) and 'Save & Enable'"
Write-Host ""
Write-Host "Tip: Labels set severity=warning, framework=ecrr; adjust if you want page/critical later."

# Open UI
Start-Process "http://localhost:8080/alerts"