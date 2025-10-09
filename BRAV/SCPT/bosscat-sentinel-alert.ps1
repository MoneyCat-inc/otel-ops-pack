<#
.SYNOPSIS
  BossCat Sentinel Alert - Flip Setup Alerts Tile GREEN

.DESCRIPTION
  Creates a minimal enabled alert via /api/v1/rules to flip the SigNoz
  "Setup Alerts" tile from BLUE to GREEN. This is a hands-free switch-on
  that works with the WYZWOZ_SIGNOZ API key.

.USAGE
  pwsh -File scripts/bosscat-sentinel-alert.ps1 -SigNozUrl http://localhost:8080 -ApiKey $env:WYZWOZ_SIGNOZ
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey
)

Write-Host "🐾 BossCat Sentinel Alert Creation" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "Mission: Flip Setup Alerts tile BLUE → GREEN" -ForegroundColor Yellow

if (-not $ApiKey) {
  Write-Host "❌ ERROR: -ApiKey parameter required" -ForegroundColor Red
  Write-Host "   Example: pwsh -File scripts/bosscat-sentinel-alert.ps1 -ApiKey `$env:WYZWOZ_SIGNOZ" -ForegroundColor Yellow
  exit 1
}

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

$payload = @{
  alert = "BossCat Sentinel Alert (API)"
  description = "Minimal rule to flip Setup Alerts to GREEN"
  alertType = "METRIC_BASED_ALERT"
  ruleType = "threshold_rule"
  severity = "warning"
  evalWindow = "5m"
  frequency = "1m"
  condition = @{
    compositeQuery = @{
      promQueries = @{
        A = @{
          query = "rate(otelcol_*_spans_received_total[5m]) > 0"
          disabled = $false
        }
      }
      queryType = "promql"
    }
    target = 0
    op = ">"
    matchType = "greater_than"
  }
  disabled = $false  # <-- enabled
}

Write-Host "`n🚨 Creating BossCat Sentinel Alert..." -ForegroundColor White

try {
  $response = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers -Body ($payload | ConvertTo-Json -Depth 20)
  Write-Host "✅ Sentinel alert created successfully" -ForegroundColor Green
  Write-Host ("   Alert ID: {0}" -f $response.id) -ForegroundColor DarkGray
} catch {
  Write-Host "❌ Failed to create sentinel alert" -ForegroundColor Red
  Write-Host ("   Error: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
  exit 1
}

Write-Host "`n🔍 Verifying alert exists..." -ForegroundColor White

try {
  $alerts = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + "/api/v1/rules") -Headers @{"SIGNOZ-API-KEY" = $ApiKey}
  $count = if ($alerts -is [array]) { $alerts.Count } else { 1 }
  Write-Host ("✅ Found {0} alert rule(s)" -f $count) -ForegroundColor Green
} catch {
  Write-Host "⚠️ Could not verify alert count" -ForegroundColor Yellow
  Write-Host ("   Error: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`n🎯 Expected Result:" -ForegroundColor Cyan
Write-Host "   • Reload SigNoz Home page" -ForegroundColor White
Write-Host "   • 'Setup Alerts' step should now show GREEN ✅" -ForegroundColor White
Write-Host "   • Sentinel alert will keep tile green on future runs" -ForegroundColor White

Write-Host "`n🐾 BossCat Sentinel Alert Complete" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
