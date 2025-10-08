param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey,
  [string]$DashboardFile = "docs/BossCat/bosscat-slo-dashboard.json"
)

# Auto-detect API key from environment or GitHub secret
if (-not $ApiKey) {
  if ($env:SIGNOZ_API_KEY) {
    $ApiKey = $env:SIGNOZ_API_KEY
    Write-Host "🔑 Using API key from `$env:SIGNOZ_API_KEY" -ForegroundColor DarkGray
  } elseif ($env:WYZWOZ_SIGNOZ) {
    $ApiKey = $env:WYZWOZ_SIGNOZ
    Write-Host "🔑 Using API key from `$env:WYZWOZ_SIGNOZ" -ForegroundColor DarkGray
  } else {
    throw "ApiKey is required. Set `$env:SIGNOZ_API_KEY or `$env:WYZWOZ_SIGNOZ or pass -ApiKey parameter"
  }
}

$H = @{ "SIGNOZ-API-KEY" = $ApiKey; "Content-Type"="application/json" }
$U = ($SigNozUrl.TrimEnd('/')) + "/api/v1/dashboards"

# Load dashboard JSON
if (-not (Test-Path $DashboardFile)) {
  throw "Dashboard file not found: $DashboardFile"
}

$dashboardJson = Get-Content $DashboardFile -Raw
$dashboard = $dashboardJson | ConvertFrom-Json

Write-Host "📊 Creating BossCat SLO Dashboard..." -ForegroundColor Cyan
Write-Host "   Title: $($dashboard.title)" -ForegroundColor DarkGray
Write-Host "   Panels: $($dashboard.widgets.Count)" -ForegroundColor DarkGray

try {
  # Check if dashboard already exists
  $existing = Invoke-RestMethod -Method GET -Uri $U -Headers $H
  $existingDash = $existing.data | Where-Object { $_.title -eq $dashboard.title }
  
  if ($existingDash) {
    Write-Host "🔁 Dashboard already exists, updating..." -ForegroundColor Yellow
    $dashboardId = $existingDash.uuid
    $result = Invoke-RestMethod -Method PUT -Uri "$U/$dashboardId" -Headers $H -Body $dashboardJson
    Write-Host "✅ Dashboard updated: $($dashboard.title)" -ForegroundColor Green
  } else {
    Write-Host "➕ Creating new dashboard..." -ForegroundColor Yellow
    $result = Invoke-RestMethod -Method POST -Uri $U -Headers $H -Body $dashboardJson
    Write-Host "✅ Dashboard created: $($dashboard.title)" -ForegroundColor Green
  }
  
  Write-Host "" -ForegroundColor Green
  Write-Host "🌐 Dashboard URL: $SigNozUrl/dashboard/$($result.data.uuid ?? $dashboardId)" -ForegroundColor Cyan
  
} catch {
  Write-Host "❌ Failed to create dashboard: $($_.Exception.Message)" -ForegroundColor Red
  throw
}

