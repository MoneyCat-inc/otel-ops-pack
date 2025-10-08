<#
.SYNOPSIS
  BossCat SigNoz Alert Creation Script (WyzWoz style)

.DESCRIPTION
  Exports BossCat metric/log/trace alert specs to JSON artifacts and, if -Apply is provided,
  attempts to create/update them in SigNoz using API key or session cookie auth.
  Safe default is export-only.

.USAGE
  pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080
  pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080 -Apply -ApiKey $env:SIGNOZ_API_KEY
  pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080 -Apply -SessionCookie $env:SIGNOZ_SESSION_COOKIE
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [switch]$Apply,
  [string]$ApiKey,
  [string]$SessionCookie
)

# ---------- helpers ----------
function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function Invoke-SigNoz {
  param(
    [Parameter(Mandatory=$true)][string]$Method,
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter()][hashtable]$Headers,
    [Parameter()][object]$Body
  )
  $uri = ($SigNozUrl.TrimEnd('/')) + $Path
  $commonHeaders = @{"Content-Type"="application/json"}
  if ($Headers) { $Headers.GetEnumerator() | ForEach-Object { $commonHeaders[$_.Key] = $_.Value } }

  if ($PSBoundParameters.ContainsKey('Body')) {
    $json = if ($Body -is [string]) { $Body } else { ($Body | ConvertTo-Json -Depth 20) }
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $commonHeaders -Body $json
  } else {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $commonHeaders
  }
}

function Get-AuthHeaders {
  $h = @{}
  if ($ApiKey)       { $h["SIGNOZ-API-KEY"]  = $ApiKey }
  if ($SessionCookie){ $h["Cookie"]          = "signoz-session=$SessionCookie" }
  return $h
}

# ---------- banner ----------
Write-Host "🐾 BossCat Alert Creation — WyzWoz Style" -ForegroundColor Green
Write-Host "Authority: BossCat OEM (Executive Overseer Manager)" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($Apply) { "APPLY (POST to SigNoz)" } else { "EXPORT-ONLY" }))) -ForegroundColor Yellow

# ---------- preflight ----------
$docsDir = "docs/BossCat"
Ensure-Dir $docsDir

Write-Host "🔍 Checking SigNoz health at $SigNozUrl ..." -ForegroundColor Yellow
try {
  $health = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing
  if ($health.StatusCode -eq 200) {
    Write-Host "✅ SigNoz is healthy and accessible" -ForegroundColor Green
  } else {
    Write-Warning "SigNoz health endpoint returned $($health.StatusCode). Continuing (export-only safe)."
  }
} catch {
  Write-Warning "SigNoz not reachable (health). Continuing (export-only safe)."
}

# ---------- alert definitions (as in your draft) ----------
$BossCatAlerts = @{
  metric_alerts = @(
    @{
      alert = "BossCat Pipeline Health Alert"
      description = "Critical alert when OTel pipeline stops receiving spans"
      alertType = "METRIC_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "critical"
      evalWindow = "2m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          promQueries = @{
            A = @{
              query = "rate(otelcol_*_spans_received_total[5m]) == 0"
              disabled = $false
            }
          }
          queryType = "promql"
        }
        target = 0
        op = "=="
        matchType = "equal"
      }
      disabled = $false
    },
    @{
      alert = "BossCat High Error Rate Alert"
      description = "Warning when pipeline error rate exceeds 5%"
      alertType = "METRIC_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "warning"
      evalWindow = "5m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          promQueries = @{
            A = @{
              query = "rate(otelcol_*_errors_total[5m]) > 0.05"
              disabled = $false
            }
          }
          queryType = "promql"
        }
        target = 0.05
        op = ">"
        matchType = "greater_than"
      }
      disabled = $false
    },
    @{
      alert = "BossCat Latency Spike Alert"
      description = "Warning when P95 latency exceeds 1 second"
      alertType = "METRIC_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "warning"
      evalWindow = "3m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          promQueries = @{
            A = @{
              query = "histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m])) > 1.0"
              disabled = $false
            }
          }
          queryType = "promql"
        }
        target = 1.0
        op = ">"
        matchType = "greater_than"
      }
      disabled = $false
    },
    @{
      alert = "BossCat Throughput Drop Alert"
      description = "Warning when throughput drops below 10 spans/second"
      alertType = "METRIC_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "warning"
      evalWindow = "5m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          promQueries = @{
            A = @{
              query = "rate(otelcol_*_spans_processed_total[5m]) < 10"
              disabled = $false
            }
          }
          queryType = "promql"
        }
        target = 10
        op = "<"
        matchType = "less_than"
      }
      disabled = $false
    }
  )
  log_alerts = @(
    @{
      alert = "BossCat Canary Missing Alert"
      description = "Critical alert when canary logs are missing for 10+ minutes"
      alertType = "LOG_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "critical"
      evalWindow = "10m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          logsAggregate = @{
            A = @{
              query = "(log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')"
              disabled = $false
            }
          }
          queryType = "logs"
        }
        target = 0
        op = "<"
        matchType = "less_than"
      }
      disabled = $false
    },
    @{
      alert = "BossCat Error Log Alert"
      description = "Warning when error logs exceed threshold"
      alertType = "LOG_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "warning"
      evalWindow = "5m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          logsAggregate = @{
            A = @{
              query = "severity = 'ERROR' OR level = 'error'"
              disabled = $false
            }
          }
          queryType = "logs"
        }
        target = 10
        op = ">"
        matchType = "greater_than"
      }
      disabled = $false
    }
  )
  trace_alerts = @(
    @{
      alert = "BossCat High Latency Trace Alert"
      description = "Warning when trace latency exceeds 500ms"
      alertType = "TRACE_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "warning"
      evalWindow = "5m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          tracesAggregate = @{
            A = @{
              query = "duration > 500ms"
              disabled = $false
            }
          }
          queryType = "traces"
        }
        target = 5
        op = ">"
        matchType = "greater_than"
      }
      disabled = $false
    },
    @{
      alert = "BossCat Error Trace Alert"
      description = "Critical alert for error traces"
      alertType = "TRACE_BASED_ALERT"
      ruleType = "threshold_rule"
      severity = "critical"
      evalWindow = "1m"
      frequency = "1m"
      condition = @{
        compositeQuery = @{
          tracesAggregate = @{
            A = @{
              query = "status.code = 'ERROR' OR error = true"
              disabled = $false
            }
          }
          queryType = "traces"
        }
        target = 0
        op = ">"
        matchType = "greater_than"
      }
      disabled = $false
    }
  )
}

$NotificationChannels = @{
  bosscat_executive = @{
    name = "BossCat Executive Channel"
    type = "webhook"
    url = "http://localhost:8080/api/v1/bosscat/notifications"
    description = "Direct notifications to BossCat OEM authority"
  }
  bosscat_log = @{
    name = "BossCat Log Channel"
    type = "file"
    path = "C:\logs\bosscat-alerts.log"
    description = "Alert notifications logged for ECRR compliance"
  }
}

# ---------- export artifacts ----------
$metricAlertsPath = Join-Path $docsDir "bosscat-metric-alerts.json"
$logAlertsPath   = Join-Path $docsDir "bosscat-log-alerts.json"
$traceAlertsPath = Join-Path $docsDir "bosscat-trace-alerts.json"
$notifyPath      = Join-Path $docsDir "bosscat-notification-channels.json"
$summaryPath     = Join-Path $docsDir "bosscat-alert-summary.json"

$BossCatAlerts.metric_alerts | ConvertTo-Json -Depth 20 | Out-File -FilePath $metricAlertsPath -Encoding UTF8
$BossCatAlerts.log_alerts    | ConvertTo-Json -Depth 20 | Out-File -FilePath $logAlertsPath   -Encoding UTF8
$BossCatAlerts.trace_alerts  | ConvertTo-Json -Depth 20 | Out-File -FilePath $traceAlertsPath -Encoding UTF8
$NotificationChannels        | ConvertTo-Json -Depth 20 | Out-File -FilePath $notifyPath      -Encoding UTF8

Write-Host "✅ Metric alerts saved: $metricAlertsPath" -ForegroundColor Green
Write-Host "✅ Log alerts saved:    $logAlertsPath"   -ForegroundColor Green
Write-Host "✅ Trace alerts saved:  $traceAlertsPath" -ForegroundColor Green
Write-Host "✅ Channels saved:      $notifyPath"      -ForegroundColor Green

# ---------- optional apply to SigNoz ----------
$created = 0; $failed = 0
if ($Apply) {
  $auth = Get-AuthHeaders
  if (-not $auth.Keys.Count) {
    Write-Warning "No API key or session cookie provided. Skipping apply; artifacts are exported."
  } else {
    Write-Host "🚨 Applying BossCat alert rules to SigNoz..." -ForegroundColor Yellow

    # NOTE:
    # SigNoz alert APIs evolve; we attempt a generic create path.
    # If SigNoz rejects a rule, we record the failure but do not crash the run.

    $all = @()
    $all += $BossCatAlerts.metric_alerts
    $all += $BossCatAlerts.log_alerts
    $all += $BossCatAlerts.trace_alerts

    foreach ($rule in $all) {
      try {
        # Use the rule directly - it's already in the correct SigNoz v0.96+ schema
        # with alert, alertType, ruleType, evalWindow, frequency, condition.compositeQuery, etc.
        $payload = $rule

        $null = Invoke-SigNoz -Method Post -Path "/api/v1/rules" -Headers $auth -Body $payload
        $created++
        Write-Host "✅ Created: $($rule.alert)" -ForegroundColor Green
      } catch {
        $failed++
        Write-Warning "Failed to apply alert: $($rule.alert) - $($_.Exception.Message)"
      }
    }

    Write-Host ("✅ Applied: {0}   ❌ Failed: {1}" -f $created, $failed) -ForegroundColor Cyan
  }
}

# ---------- summary & ECRR note ----------
$alertSummary = @{
  timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  authority = "BossCat OEM"
  operation = "Alert Rules Creation"
  mode      = if ($Apply) { "apply" } else { "export" }
  status    = if ($failed -gt 0) { "partial" } else { "completed" }
  alert_counts = @{
    metric_alerts        = $BossCatAlerts.metric_alerts.Count
    log_alerts           = $BossCatAlerts.log_alerts.Count
    trace_alerts         = $BossCatAlerts.trace_alerts.Count
    notification_channels= $NotificationChannels.Count
    applied_ok           = $created
    applied_failed       = $failed
  }
  wyzwoz_style = @{
    aesthetic         = "cat_nap_control_room"
    monitoring_style  = "feline_silence"
    alert_philosophy  = "peaceful_vigilance"
  }
}

$alertSummary | ConvertTo-Json -Depth 20 | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Host "✅ Alert summary saved: $summaryPath" -ForegroundColor Green

Write-Host "`n🎭 BossCat Alert Rules — WyzWoz Recap" -ForegroundColor Magenta
Write-Host ("   • Metric Alerts:      {0}" -f $BossCatAlerts.metric_alerts.Count)
Write-Host ("   • Log Alerts:         {0}" -f $BossCatAlerts.log_alerts.Count)
Write-Host ("   • Trace Alerts:       {0}" -f $BossCatAlerts.trace_alerts.Count)
Write-Host ("   • Notification Chans: {0}" -f $NotificationChannels.Count)
if ($Apply) { Write-Host ("   • Applied: {0} (ok) / {1} (failed)" -f $created,$failed) }

Write-Host "`n🌐 SigNoz Alert Management Shortcuts:" -ForegroundColor Cyan
Write-Host ("   • Alert Rules:        {0}/alerts"            -f $SigNozUrl)
Write-Host ("   • Triggered Alerts:   {0}/alerts/triggered"  -f $SigNozUrl)
Write-Host ("   • Notification Chans: {0}/alerts/channels"   -f $SigNozUrl)

Write-Host "`n📁 Generated Artifacts:" -ForegroundColor Cyan
Write-Host "   • Metric: $metricAlertsPath"
Write-Host "   • Logs:   $logAlertsPath"
Write-Host "   • Traces: $traceAlertsPath"
Write-Host "   • Chans:  $notifyPath"
Write-Host "   • Summary:$summaryPath"

Write-Host "`n🐾 Done." -ForegroundColor Green
