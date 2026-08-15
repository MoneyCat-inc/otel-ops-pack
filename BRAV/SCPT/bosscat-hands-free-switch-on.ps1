<#
.SYNOPSIS
  BossCat Hands-Free Switch-On - Complete 4-Step Process

.DESCRIPTION
  Executes the complete hands-free switch-on process:
  1. Smoke-check API (find working path + header)
  2. Create sentinel alert (flip BLUE → GREEN)
  3. Apply full BossCat alert set (8 alerts)
  3.5. Send trace canary (light up showtime views)
  4. Verify 6/6 completion

.USAGE
  pwsh -File scripts/bosscat-hands-free-switch-on.ps1 -SigNozUrl http://localhost:8080 -ApiKey $env:WYZWOZ_SIGNOZ
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey
)

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$otelPorts = Get-OtelPorts

Write-Host "🐾 BossCat Hands-Free Switch-On - Complete Process" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "Mission: Flip Setup Alerts tile BLUE → GREEN + Apply full alert set" -ForegroundColor Yellow

if (-not $ApiKey) {
  Write-Host "❌ ERROR: -ApiKey parameter required" -ForegroundColor Red
  Write-Host "   Example: pwsh -File scripts/bosscat-hands-free-switch-on.ps1 -ApiKey `$env:WYZWOZ_SIGNOZ" -ForegroundColor Yellow
  exit 1
}

# Set environment variable for sub-scripts
$env:SIGNOZ_API_KEY = $ApiKey

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STEP 1: SMOKE-CHECK API (FIND WORKING PATH + HEADER)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$paths = @("/api/v1/rules", "/api/v1/alerts")
$headers = @(
  @{ name = "SIGNOZ-API-KEY"; value = $ApiKey },
  @{ name = "Authorization"; value = ("Bearer " + $ApiKey) }
)

$workingPath = $null
$workingHeader = $null

foreach ($p in $paths) {
  foreach ($h in $headers) {
    try {
      $resp = Invoke-WebRequest -Method GET -Uri ($SigNozUrl + $p) -Headers @{$h.name = $h.value} -UseBasicParsing -TimeoutSec 10
      Write-Host ("✅ GET {0} with {1}: {2}" -f $p, $h.name, $resp.StatusCode) -ForegroundColor Green
      
      if ($resp.StatusCode -eq 200 -and -not $workingPath) {
        $workingPath = $p
        $workingHeader = $h.name
        Write-Host ("   → SELECTED: {0} with {1}" -f $p, $h.name) -ForegroundColor Cyan
      }
    } catch {
      Write-Host ("❌ GET {0} with {1}: FAIL ({2})" -f $p, $h.name, $_.Exception.Message) -ForegroundColor Red
    }
  }
}

if (-not $workingPath) {
  Write-Host "⚠️ No working API path found, continuing with default..." -ForegroundColor Yellow
  $workingPath = "/api/v1/rules"
  $workingHeader = "SIGNOZ-API-KEY"
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STEP 2: CREATE SENTINEL ALERT (FLIP BLUE → GREEN)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

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

Write-Host "🚨 Creating BossCat Sentinel Alert..." -ForegroundColor White

try {
  $response = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + $workingPath) -Headers $headers -Body ($payload | ConvertTo-Json -Depth 20)
  Write-Host "✅ Sentinel alert created successfully" -ForegroundColor Green
  if ($response.id) {
    Write-Host ("   Alert ID: {0}" -f $response.id) -ForegroundColor DarkGray
  }
} catch {
  Write-Host "❌ Failed to create sentinel alert" -ForegroundColor Red
  Write-Host ("   Error: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
  Write-Host "   Continuing with full alert set..." -ForegroundColor Yellow
}

Write-Host "`n🔍 Verifying sentinel alert exists..." -ForegroundColor White

try {
  $alerts = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + $workingPath) -Headers @{"SIGNOZ-API-KEY" = $ApiKey}
  $count = if ($alerts -is [array]) { $alerts.Count } else { 1 }
  Write-Host ("✅ Found {0} alert rule(s)" -f $count) -ForegroundColor Green
} catch {
  Write-Host "⚠️ Could not verify alert count" -ForegroundColor Yellow
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STEP 3: APPLY FULL BOSSCAT ALERT SET (8 ALERTS)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "🚨 Applying 8 BossCat alerts..." -ForegroundColor White

try {
  $exitCode = & pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl $SigNozUrl -Apply -ApiKey $ApiKey
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ BossCat alert set applied successfully" -ForegroundColor Green
  } else {
    Write-Host "⚠️ BossCat alert application returned exit code $LASTEXITCODE" -ForegroundColor Yellow
  }
} catch {
  Write-Host "❌ Failed to apply BossCat alert set" -ForegroundColor Red
  Write-Host ("   Error: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STEP 3.5: SEND TRACE CANARY (LIGHT UP SHOWTIME VIEWS)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "🎯 Sending trace canary to populate Frontend Canary Spans view..." -ForegroundColor White

try {
  $exitCode = & pwsh -File scripts/iona-trace-canary.ps1 -CollectorHost localhost -OtlpHttpPort $otelPorts.IngestHttp -ZipkinPort 9411 -ServiceName frontend -DurationMs 1200 -Force 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Trace canary sent successfully" -ForegroundColor Green
    Write-Host "   → Check SigNoz Traces: service=frontend, span=iona-canary-span" -ForegroundColor DarkGray
  } else {
    Write-Host "⚠️ Trace canary returned exit code $LASTEXITCODE (non-blocking)" -ForegroundColor Yellow
  }
} catch {
  Write-Host "⚠️ Trace canary failed (non-blocking): $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3  # Allow ingestion time

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STEP 4: VERIFY 6/6 COMPLETION" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "🔍 Verifying SigNoz completion (6/6)..." -ForegroundColor White

try {
  $exitCode = & pwsh -File scripts/bosscat-verify-signoz-completion.ps1 -SigNozUrl $SigNozUrl -ApiKey $ApiKey
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SigNoz completion verification passed (6/6)" -ForegroundColor Green
  } else {
    Write-Host "⚠️ Verification returned exit code $LASTEXITCODE" -ForegroundColor Yellow
  }
} catch {
  Write-Host "❌ Failed to verify completion" -ForegroundColor Red
  Write-Host ("   Error: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  HANDS-FREE SWITCH-ON COMPLETE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n🎯 Expected Results:" -ForegroundColor Yellow
Write-Host "   • SigNoz Home → 'Setup Alerts' tile should be GREEN ✅" -ForegroundColor White
Write-Host "   • All 8 BossCat alerts created (3 critical + 5 warning)" -ForegroundColor White
Write-Host "   • 6/6 verification should pass" -ForegroundColor White
Write-Host "   • Gate status should progress toward 100/100" -ForegroundColor White

Write-Host "`n🐾 BossCat Hands-Free Switch-On Complete" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "WyzWoz Style: Cat Nap Control Room - Feline Silence Maintained" -ForegroundColor Magenta
