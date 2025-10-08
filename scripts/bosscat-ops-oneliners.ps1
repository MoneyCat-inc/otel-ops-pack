<#
.SYNOPSIS
  BossCat SigNoz Operations One-Liners
.DESCRIPTION
  Useful operational commands for managing SigNoz configuration
.USAGE
  pwsh -File scripts/bosscat-ops-oneliners.ps1 -Operation <operation> -ApiKey $env:WYZWOZ_SIGNOZ
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('ListDashboards', 'ExportDashboards', 'ListAlerts', 'HealthCheck', 'FullStatus')]
  [string]$Operation,
  
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey
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
    Write-Host "❌ ERROR: API key required" -ForegroundColor Red
    Write-Host "   Set one of:" -ForegroundColor Yellow
    Write-Host "     `$env:SIGNOZ_API_KEY = 'your-key'" -ForegroundColor Cyan
    Write-Host "     `$env:WYZWOZ_SIGNOZ = 'your-key'" -ForegroundColor Cyan
    Write-Host "   Or pass: -ApiKey 'your-key'" -ForegroundColor Cyan
    exit 1
  }
}

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

Write-Host "🐾 BossCat Operations - $Operation" -ForegroundColor Cyan

switch ($Operation) {
  'ListDashboards' {
    Write-Host "`n📊 Listing Dashboards..." -ForegroundColor Yellow
    try {
      $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Headers $headers -Method GET
      $dashboards = $response.data
      
      if ($dashboards.Count -eq 0) {
        Write-Host "No dashboards found" -ForegroundColor Yellow
      } else {
        $dashboards | ForEach-Object {
          [PSCustomObject]@{
            Id = $_.id ?? $_.uuid ?? 'N/A'
            Title = $_.title ?? $_.name ?? 'Untitled'
            Panels = ($_.data?.widgets?.Count ?? 0)
          }
        } | Format-Table -AutoSize
      }
    } catch {
      Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  
  'ExportDashboards' {
    Write-Host "`n💾 Exporting Dashboards..." -ForegroundColor Yellow
    try {
      $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Headers $headers -Method GET
      $outputPath = "docs/BossCat/bosscat-executive-dashboard.live.json"
      $response | ConvertTo-Json -Depth 20 | Out-File -FilePath $outputPath -Encoding UTF8
      Write-Host "✅ Dashboards exported to: $outputPath" -ForegroundColor Green
    } catch {
      Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  
  'ListAlerts' {
    Write-Host "`n🚨 Listing Alerts..." -ForegroundColor Yellow
    try {
      $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/rules" -Headers $headers -Method GET
      $rules = $response.data?.rules ?? $response.rules ?? $response
      
      if ($rules.Count -eq 0) {
        Write-Host "No alerts found" -ForegroundColor Yellow
      } else {
        $rules | ForEach-Object {
          [PSCustomObject]@{
            Name = $_.alert ?? $_.name ?? $_.alertName ?? 'Untitled'
            Severity = $_.severity ?? $_.alertSeverity ?? 'N/A'
            Type = $_.alertType ?? $_.type ?? 'N/A'
            Disabled = $_.disabled ?? $false
          }
        } | Sort-Object Name | Format-Table -AutoSize
        
        Write-Host "`n📊 Summary:" -ForegroundColor Cyan
        Write-Host "   Total: $($rules.Count)"
        Write-Host "   Critical: $(($rules | Where-Object { ($_.severity ?? $_.alertSeverity) -eq 'critical' }).Count)"
        Write-Host "   Warning: $(($rules | Where-Object { ($_.severity ?? $_.alertSeverity) -eq 'warning' }).Count)"
        Write-Host "   Enabled: $(($rules | Where-Object { -not $_.disabled }).Count)"
      }
    } catch {
      Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  
  'HealthCheck' {
    Write-Host "`n🏥 SigNoz Health Check..." -ForegroundColor Yellow
    
    # Health endpoint
    try {
      $health = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET
      Write-Host "✅ Health: OK" -ForegroundColor Green
    } catch {
      Write-Host "❌ Health: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Version endpoint
    try {
      $version = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/version" -Method GET
      Write-Host "✅ Version: $($version.version)" -ForegroundColor Green
    } catch {
      Write-Host "⚠️ Version: Unknown" -ForegroundColor Yellow
    }
  }
  
  'FullStatus' {
    Write-Host "`n🎯 BossCat Full Status Report" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Health
    Write-Host "`n🏥 Health Status:" -ForegroundColor Yellow
    try {
      $null = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET
      Write-Host "   • SigNoz: ✅ HEALTHY" -ForegroundColor Green
    } catch {
      Write-Host "   • SigNoz: ❌ DOWN" -ForegroundColor Red
    }
    
    # Alerts
    Write-Host "`n🚨 Alert Status:" -ForegroundColor Yellow
    try {
      $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/rules" -Headers $headers -Method GET
      $rules = $response.data?.rules ?? $response.rules ?? $response
      $critical = ($rules | Where-Object { ($_.severity ?? $_.alertSeverity) -eq 'critical' }).Count
      $warning = ($rules | Where-Object { ($_.severity ?? $_.alertSeverity) -eq 'warning' }).Count
      $enabled = ($rules | Where-Object { -not $_.disabled }).Count
      
      Write-Host "   • Total Rules: $($rules.Count)" -ForegroundColor White
      Write-Host "   • Critical: $critical" -ForegroundColor White
      Write-Host "   • Warning: $warning" -ForegroundColor White
      Write-Host "   • Enabled: $enabled" -ForegroundColor White
      
      if ($rules.Count -eq 8 -and $critical -eq 3 -and $warning -eq 5) {
        Write-Host "   • BossCat Set: ✅ COMPLETE" -ForegroundColor Green
      } else {
        Write-Host "   • BossCat Set: ⚠️ INCOMPLETE (expected 8: 3 critical, 5 warning)" -ForegroundColor Yellow
      }
    } catch {
      Write-Host "   • Alerts: ❌ ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Dashboards
    Write-Host "`n📊 Dashboard Status:" -ForegroundColor Yellow
    try {
      $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Headers $headers -Method GET
      $dashboards = $response.data
      Write-Host "   • Total Dashboards: $($dashboards.Count)" -ForegroundColor White
      
      if ($dashboards.Count -gt 0) {
        $dashboards | ForEach-Object {
          Write-Host "     - $($_.title ?? $_.name ?? 'Untitled')" -ForegroundColor DarkGray
        }
      }
    } catch {
      Write-Host "   • Dashboards: ❌ ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🐾 BossCat Status Check Complete" -ForegroundColor Magenta
  }
}

Write-Host "`n✅ Operation Complete" -ForegroundColor Green

