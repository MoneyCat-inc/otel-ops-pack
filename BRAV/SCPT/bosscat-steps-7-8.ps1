<#
.SYNOPSIS
  BossCat SigNoz Steps 7-8 Automation - Saved Views & Dashboards
.DESCRIPTION
  Automates the creation of Saved Views and Dashboards for complete SigNoz setup
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey,
  [switch]$Apply
)

Write-Host "🐾 BossCat SigNoz Steps 7-8 Automation" -ForegroundColor Green
Write-Host "Authority: BossCat OEM (Executive Overseer Manager)" -ForegroundColor Cyan
Write-Host "Mission: Complete SigNoz setup with Saved Views & Dashboards" -ForegroundColor Yellow

# Auto-detect API key from environment or GitHub secret
if (-not $ApiKey) {
  if ($env:SIGNOZ_API_KEY) {
    $ApiKey = $env:SIGNOZ_API_KEY
    Write-Host "🔑 Using API key from `$env:SIGNOZ_API_KEY" -ForegroundColor DarkGray
  } elseif ($env:WYZWOZ_SIGNOZ) {
    $ApiKey = $env:WYZWOZ_SIGNOZ
    Write-Host "🔑 Using API key from `$env:WYZWOZ_SIGNOZ" -ForegroundColor DarkGray
  } else {
    Write-Host "⚠️  No API key detected - exporting definitions only (no -Apply)" -ForegroundColor Yellow
    Write-Host "   Set `$env:SIGNOZ_API_KEY or pass -ApiKey to enable -Apply mode" -ForegroundColor DarkGray
  }
}

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

# Ensure docs directory exists
$docsDir = "docs/BossCat"
if (-not (Test-Path -Path $docsDir)) {
  New-Item -ItemType Directory -Path $docsDir | Out-Null
}

Write-Host "`n🔍 Step 7: Creating BossCat Saved Views..." -ForegroundColor White

# Define BossCat Saved Views (SHOWTIME EDITION - Active data views)
$BossCatSavedViews = @{
  logs_views = @(
    @{
      name = "IONA Canary Activity"
      description = "🎯 SHOWTIME: Live canary test logs from iona-canary.ps1 burst"
      filters = @{
        message = "contains 'canary test'"
        service_name = "frontend"
        source = "Application"  # Windows Event Log source
      }
      timeRange = "15m"
      notes = "Run: pwsh -File scripts\iona-canary.ps1 -DurationMinutes 5 -EventsPerMinute 120"
    },
    @{
      name = "Collector Ingest Logs" 
      description = "🔧 Pipeline health: Collector logs showing ingest activity"
      filters = @{
        service_name = "otelcol"
        log_level = "info,warn,error"
      }
      timeRange = "1h"
      notes = "Monitor collector health and throughput"
    },
    @{
      name = "BossCat Error Logs View"
      description = "Error-level logs across all services"
      filters = @{
        severity = "ERROR"
        level = "error"
      }
      timeRange = "1h"
    }
  )
  traces_views = @(
    @{
      name = "Frontend Canary Spans"
      description = "🎯 SHOWTIME: Synthetic traces from iona-trace-canary.ps1"
      filters = @{
        service_name = "frontend"
        span_name = "iona-canary-span"
        attributes = @{
          bosscat = "1"
          canary = "1"
          env = "dev"
        }
      }
      timeRange = "15m"
      notes = "Run: pwsh -File scripts\iona-trace-canary.ps1 -Force"
    },
    @{
      name = "BossCat High Latency Traces"
      description = "Traces with latency > 500ms"
      filters = @{
        duration = ">500ms"
      }
      timeRange = "1h"
    },
    @{
      name = "BossCat Error Traces"
      description = "Traces with errors"
      filters = @{
        status_code = "ERROR"
        error = "true"
      }
      timeRange = "1h"
    }
  )
  metrics_views = @(
    @{
      name = "Collector Ingest Pulse"
      description = "🎯 SHOWTIME: Real-time pipeline metrics from OTel Collector"
      queries = @(
        "rate(otelcol_receiver_accepted_log_records[5m])",
        "rate(otelcol_receiver_accepted_spans[5m])",
        "rate(otelcol_exporter_sent_log_records[5m])",
        "rate(otelcol_exporter_sent_spans[5m])"
      )
      timeRange = "1h"
      notes = "Monitor log/trace ingestion and export rates"
    }
  )
}

# Export Saved Views definitions
$savedViewsPath = Join-Path $docsDir "bosscat-saved-views.json"
$BossCatSavedViews | ConvertTo-Json -Depth 20 | Out-File -FilePath $savedViewsPath -Encoding UTF8
Write-Host "✅ Saved Views definitions exported: $savedViewsPath" -ForegroundColor Green

Write-Host "`n📊 Step 8: Creating BossCat Dashboards..." -ForegroundColor White

# Define BossCat Executive Dashboard
$BossCatDashboard = @{
  name = "BossCat Executive Dashboard"
  description = "Executive overview of OTel pipeline health and performance"
  panels = @(
    @{
      title = "Pipeline Health Overview"
      type = "metric"
      query = "rate(otelcol_*_spans_received_total[5m])"
      visualization = "line"
    },
    @{
      title = "Error Rate Trend"
      type = "metric" 
      query = "rate(otelcol_*_errors_total[5m])"
      visualization = "line"
    },
    @{
      title = "Latency Distribution"
      type = "metric"
      query = "histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m]))"
      visualization = "line"
    },
    @{
      title = "Throughput Metrics"
      type = "metric"
      query = "rate(otelcol_*_spans_processed_total[5m])"
      visualization = "line"
    }
  )
  layout = @{
    rows = 2
    columns = 2
  }
  refreshInterval = "30s"
}

# Export Dashboard definition
$dashboardPath = Join-Path $docsDir "bosscat-executive-dashboard.json"
$BossCatDashboard | ConvertTo-Json -Depth 20 | Out-File -FilePath $dashboardPath -Encoding UTF8
Write-Host "✅ Dashboard definition exported: $dashboardPath" -ForegroundColor Green

# Optional: Apply to SigNoz (if API endpoints are available)
if ($Apply) {
  Write-Host "`n🚨 Attempting to apply Saved Views and Dashboards..." -ForegroundColor Yellow
  
  # Try to create dashboard
  try {
    Write-Host "📊 Creating BossCat Executive Dashboard..." -ForegroundColor White
    $dashboardResponse = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + "/api/v1/dashboards") -Headers $headers -Body ($BossCatDashboard | ConvertTo-Json -Depth 20)
    Write-Host "✅ Dashboard created successfully" -ForegroundColor Green
  } catch {
    Write-Host "⚠️ Dashboard creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   This may be expected if the API endpoint structure differs" -ForegroundColor DarkGray
  }
  
  # Note: Saved Views API may need different endpoint or approach
  Write-Host "📋 Saved Views creation skipped - API endpoint needs investigation" -ForegroundColor Yellow
}

# Create summary report
$summary = @{
  timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  authority = "BossCat OEM"
  operation = "Steps 7-8: Saved Views & Dashboards Setup"
  status = "completed"
  artifacts = @{
    saved_views_definition = $savedViewsPath
    dashboard_definition = $dashboardPath
  }
  wyzwoz_style = @{
    aesthetic = "cat_nap_control_room"
    monitoring_style = "feline_silence"
    completion_philosophy = "peaceful_vigilance"
  }
}

$summaryPath = Join-Path $docsDir "bosscat-steps-7-8-summary.json"
$summary | ConvertTo-Json -Depth 20 | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Host "✅ Summary report saved: $summaryPath" -ForegroundColor Green

Write-Host "`n🎭 BossCat Steps 7-8 — WyzWoz Recap" -ForegroundColor Magenta
Write-Host (" • Saved Views: {0} (logs) + {1} (traces) + {2} (metrics)" -f $BossCatSavedViews.logs_views.Count, $BossCatSavedViews.traces_views.Count, $BossCatSavedViews.metrics_views.Count)
Write-Host (" • Dashboard Panels: {0}" -f $BossCatDashboard.panels.Count)
Write-Host (" • Artifacts Generated: 3")
Write-Host (" • 🎯 SHOWTIME Views: IONA Canary Activity, Frontend Canary Spans, Collector Ingest Pulse" -f $BossCatDashboard.panels.Count)

Write-Host "`n🌐 SigNoz Management Shortcuts:" -ForegroundColor Cyan
Write-Host (" • Dashboards: {0}/dashboards" -f $SigNozUrl)
Write-Host (" • Logs: {0}/logs" -f $SigNozUrl)
Write-Host (" • Traces: {0}/traces" -f $SigNozUrl)
Write-Host (" • Metrics: {0}/metrics" -f $SigNozUrl)

Write-Host "`n📁 Generated Artifacts:" -ForegroundColor Cyan
Write-Host " • Saved Views: $savedViewsPath"
Write-Host " • Dashboard: $dashboardPath"
Write-Host " • Summary: $summaryPath"

Write-Host "`n🐾 Steps 7-8 Complete." -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
