<#
.SYNOPSIS
  BossCat SigNoz API Smoke Check - Find Working Path + Header

.DESCRIPTION
  Tests SigNoz API endpoints to find the correct path and header combination
  for reading alert rules. Tests /api/v1/rules and /api/v1/alerts with
  SIGNOZ-API-KEY and Authorization headers.

.USAGE
  pwsh -File scripts/bosscat-signoz-smoke-check.ps1 -SigNozUrl http://localhost:8080 -ApiKey $env:WYZWOZ_SIGNOZ
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey
)

Write-Host "🐾 BossCat SigNoz API Smoke Check" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "Mission: Find working API path + header combination" -ForegroundColor Yellow

if (-not $ApiKey) {
  Write-Host "❌ ERROR: -ApiKey parameter required" -ForegroundColor Red
  Write-Host "   Example: pwsh -File scripts/bosscat-signoz-smoke-check.ps1 -ApiKey `$env:WYZWOZ_SIGNOZ" -ForegroundColor Yellow
  exit 1
}

$paths = @("/api/v1/rules", "/api/v1/alerts")
$headers = @(
  @{ name = "SIGNOZ-API-KEY"; value = $ApiKey },
  @{ name = "Authorization"; value = ("Bearer " + $ApiKey) }
)

Write-Host "`n🔍 Testing API endpoints..." -ForegroundColor White

foreach ($p in $paths) {
  foreach ($h in $headers) {
    try {
      $resp = Invoke-WebRequest -Method GET -Uri ($SigNozUrl + $p) -Headers @{$h.name = $h.value} -UseBasicParsing -TimeoutSec 10
      Write-Host ("✅ GET {0} with {1}: {2}" -f $p, $h.name, $resp.StatusCode) -ForegroundColor Green
      
      if ($resp.StatusCode -eq 200) {
        Write-Host ("   Content-Length: {0}" -f $resp.Headers.'Content-Length') -ForegroundColor DarkGray
      }
    } catch {
      Write-Host ("❌ GET {0} with {1}: FAIL ({2})" -f $p, $h.name, $_.Exception.Message) -ForegroundColor Red
    }
  }
}

Write-Host "`n🎯 Recommended Configuration:" -ForegroundColor Cyan
Write-Host "   • Path: /api/v1/rules" -ForegroundColor White
Write-Host "   • Header: SIGNOZ-API-KEY" -ForegroundColor White
Write-Host "   • Value: [masked for security]" -ForegroundColor DarkGray

Write-Host "`n🐾 BossCat Smoke Check Complete" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
