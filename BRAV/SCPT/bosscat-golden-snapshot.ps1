<#
.SYNOPSIS
  BossCat Golden Config Snapshot - Capture live SigNoz configuration
.DESCRIPTION
  Snapshots current alerts and dashboards from SigNoz API as "golden" baseline.
  Use after successful apply/verify to lock evidence parity.
.USAGE
  pwsh -File scripts/bosscat-golden-snapshot.ps1 -ApiKey $env:WYZWOZ_SIGNOZ
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [Parameter(Mandatory=$true)]
  [string]$ApiKey,
  [string]$OutputDir = "docs/BossCat"
)

Write-Host "🐾 BossCat Golden Config Snapshot" -ForegroundColor Cyan
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "Mission: Capture live configuration as golden baseline" -ForegroundColor Yellow
Write-Host ""

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

# Ensure output directory exists
if (-not (Test-Path -Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$success = 0
$failed = 0

# Snapshot Alerts/Rules
Write-Host "📋 Snapshotting alerts..." -ForegroundColor Yellow
try {
  $rules = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers
  $rulesPath = Join-Path $OutputDir "bosscat-alerts.live.json"
  $rules | ConvertTo-Json -Depth 20 | Out-File -FilePath $rulesPath -Encoding UTF8
  Write-Host "✅ Alerts snapshot saved: $rulesPath" -ForegroundColor Green
  $success++
} catch {
  Write-Host "❌ Failed to snapshot alerts: $($_.Exception.Message)" -ForegroundColor Red
  $failed++
}

# Snapshot Dashboards
Write-Host "📊 Snapshotting dashboards..." -ForegroundColor Yellow
try {
  $dashboards = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + "/api/v1/dashboards") -Headers $headers
  $dashPath = Join-Path $OutputDir "bosscat-executive-dashboard.live.json"
  $dashboards | ConvertTo-Json -Depth 20 | Out-File -FilePath $dashPath -Encoding UTF8
  Write-Host "✅ Dashboards snapshot saved: $dashPath" -ForegroundColor Green
  $success++
} catch {
  Write-Host "❌ Failed to snapshot dashboards: $($_.Exception.Message)" -ForegroundColor Red
  $failed++
}

# Create snapshot manifest
$manifest = @{
  timestamp = $timestamp
  authority = "BossCat OEM"
  operation = "Golden Config Snapshot"
  signoz_url = $SigNozUrl
  snapshots = @{
    alerts = if ($success -ge 1) { "bosscat-alerts.live.json" } else { $null }
    dashboards = if ($success -ge 2) { "bosscat-executive-dashboard.live.json" } else { $null }
  }
  status = if ($failed -eq 0) { "complete" } else { "partial" }
  success_count = $success
  failed_count = $failed
}

$manifestPath = Join-Path $OutputDir "golden-snapshot-manifest.json"
$manifest | ConvertTo-Json -Depth 20 | Out-File -FilePath $manifestPath -Encoding UTF8
Write-Host "✅ Snapshot manifest saved: $manifestPath" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "📊 Snapshot Summary:" -ForegroundColor Cyan
Write-Host "   Success: $success" -ForegroundColor Green
Write-Host "   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "   Timestamp: $timestamp" -ForegroundColor White

if ($failed -eq 0) {
  Write-Host ""
  Write-Host "✅ Golden baseline captured successfully" -ForegroundColor Green
  Write-Host ""
  Write-Host "📦 Next Steps:" -ForegroundColor Cyan
  Write-Host "   1. Review snapshot files for correctness" -ForegroundColor White
  Write-Host "   2. Commit to version control:" -ForegroundColor White
  Write-Host "      git add $OutputDir/*.live.json $manifestPath" -ForegroundColor Cyan
  Write-Host "      git commit -m 'docs(ecrr): Golden config snapshot - $timestamp'" -ForegroundColor Cyan
  Write-Host "   3. Tag release (optional):" -ForegroundColor White
  Write-Host "      git tag -a v1.0.0-bosscat-observability -m 'BossCat OEM: SigNoz setup 8/8, HARDENED'" -ForegroundColor Cyan
  Write-Host ""
  exit 0
} else {
  Write-Host ""
  Write-Host "⚠️  Snapshot completed with errors" -ForegroundColor Yellow
  Write-Host "   Review error messages above and retry if needed" -ForegroundColor Yellow
  Write-Host ""
  exit 2
}

