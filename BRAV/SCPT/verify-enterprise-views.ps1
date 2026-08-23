# See C:\otel\docs\comfort cat
# BossCat OEM · Enterprise View Verification
# Validates that enterprise views are accessible and functional in SigNoz

<#
.SYNOPSIS
  Verification companion for cursor-startup-signoz-enterprise-views.ps1
  Tests that all enterprise views are properly configured and queryable.

.PARAMETER SigNozUrl
  Base URL to SigNoz (default: http://localhost:8080)

.PARAMETER ApiKey
  SigNoz API key. Optional—auto-detects $env:SIGNOZ_API_KEY if not provided.

.PARAMETER OrgPrefix
  Prefix for view names (default: 'Enterprise •')

.EXAMPLE
  pwsh -File scripts\verify-enterprise-views.ps1
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey,
  [string]$OrgPrefix = "Enterprise •"
)

# Auto-load secrets if available
$secretsPath = "scripts\secrets\signoz.secrets.ps1"
if (Test-Path $secretsPath) {
  . $secretsPath
}

$script:ApiKey = $ApiKey

function Log([string]$msg, [string]$color="Gray") {
  Write-Host "  $msg" -ForegroundColor $color
}

function Hdr([string]$k) {
  $api = if ($script:ApiKey) { $script:ApiKey } else { $env:SIGNOZ_API_KEY }
  if (-not $api) { throw "No API key. Pass -ApiKey or set SIGNOZ_API_KEY." }
  return @{ 
    "SIGNOZ-API-KEY" = $api
    "Content-Type" = "application/json"
    "Accept" = "application/json" 
  }
}

Write-Host ""
Write-Host "🐾 BossCat · Enterprise View Verification" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

$expectedViews = @(
  "$OrgPrefix Logs • Error Triage",
  "$OrgPrefix Logs • Security Signals",
  "$OrgPrefix Traces • Hot Endpoints",
  "$OrgPrefix Traces • Canary Spans",
  "$OrgPrefix Metrics • Collector Ingest Pulse",
  "$OrgPrefix Metrics • P95 Latency"
)

# Try to find Saved Views endpoint
# v2 first (SigNoz >= 0.137); v1 kept as fallback while upstream still serves it. A non-existent
# /api/v2 path on older SigNoz returns index.html with HTTP 200, so a successful call is not
# enough - the response must look like a JSON list or a {data: [...]} envelope.
$candidates = @(
  "/api/v2/saved_views",
  "/api/v1/saved-views",
  "/api/v1/explorer/saved-views",
  "/api/v1/views",
  "/api/v1/explorer/views"
)

$viewsEndpoint = $null
foreach ($p in $candidates) {
  try {
    $resp = Invoke-RestMethod -Method GET -Uri ($SigNozUrl.TrimEnd('/') + $p) -Headers (Hdr "k") -TimeoutSec 10
    $looksJson = ($resp -is [array]) -or ($null -ne $resp.PSObject.Properties['data'])
    if (-not $looksJson) { continue }
    $viewsEndpoint = $p
    break
  } catch { 
    continue 
  }
}

$passCount = 0
$failCount = 0

if ($viewsEndpoint) {
  Log "Using Saved Views endpoint: $viewsEndpoint" "Gray"
  Write-Host ""
  
  try {
    $views = Invoke-RestMethod -Method GET -Uri ($SigNozUrl.TrimEnd('/') + $viewsEndpoint) -Headers (Hdr "k")
    $viewList = if ($views.data) { $views.data } else { $views }
    
    foreach ($expectedName in $expectedViews) {
      $found = $viewList | Where-Object { 
        ($_.name ?? $_.title ?? $_.viewName) -eq $expectedName 
      } | Select-Object -First 1
      
      if ($found) {
        Log "✓ $expectedName" "Green"
        $passCount++
      } else {
        Log "✗ $expectedName (missing)" "Red"
        $failCount++
      }
    }
  } catch {
    Log "Failed to query Saved Views: $($_.Exception.Message)" "Red"
    $failCount = $expectedViews.Count
  }
} else {
  # Check dashboard fallback
  Log "No Saved Views API - checking Dashboard fallback" "Yellow"
  Write-Host ""
  
  try {
    $dashboards = Invoke-RestMethod -Method GET -Uri ($SigNozUrl.TrimEnd('/') + "/api/v1/dashboards") -Headers (Hdr "k")
    $dashList = if ($dashboards.data) { $dashboards.data } else { $dashboards }
    
    $fallbackDash = $dashList | Where-Object { 
      $_.title -eq "$OrgPrefix Saved Views (Dashboard)" 
    } | Select-Object -First 1
    
    if ($fallbackDash) {
      Log "✓ Found fallback dashboard: $($fallbackDash.title)" "Green"
      
      if ($fallbackDash.data -and $fallbackDash.data.widgets) {
        $widgetCount = $fallbackDash.data.widgets.Count
        Log "✓ Dashboard has $widgetCount widgets" "Green"
        
        foreach ($expectedName in $expectedViews) {
          $widget = $fallbackDash.data.widgets | Where-Object { $_.title -eq $expectedName } | Select-Object -First 1
          if ($widget) {
            Log "✓ $expectedName" "Green"
            $passCount++
          } else {
            Log "✗ $expectedName (missing)" "Red"
            $failCount++
          }
        }
      } else {
        Log "✗ Dashboard has no widgets" "Red"
        $failCount = $expectedViews.Count
      }
    } else {
      Log "✗ Fallback dashboard not found" "Red"
      $failCount = $expectedViews.Count
    }
  } catch {
    Log "Failed to query dashboards: $($_.Exception.Message)" "Red"
    $failCount = $expectedViews.Count
  }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "Results: " -NoNewline -ForegroundColor Gray
if ($failCount -eq 0) {
  Write-Host "✓ ALL PASS ($passCount/$($expectedViews.Count))" -ForegroundColor Green
} else {
  Write-Host "⚠ $failCount FAILED ($passCount/$($expectedViews.Count))" -ForegroundColor Yellow
}
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

exit $failCount

