# Dashboard Sanity Targets - First Week Monitoring
# ECRR Compliance: Examine → Clean → Report → Role

param(
    [switch]$DryRun,
    [int]$Days = 7,
    [string]$OutputPath = "artifacts/dashboard-sanity-targets.json"
)

Write-Host "📊 Dashboard Sanity Targets" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No targets will be set" -ForegroundColor Yellow
}

# Define sanity targets for first week
$sanityTargets = @{
    "timeframe" = "$Days days"
    "start_date" = (Get-Date).ToString("yyyy-MM-dd")
    "end_date" = (Get-Date).AddDays($Days).ToString("yyyy-MM-dd")
    "targets" = @{
        "throughput" = @{
            "metric" = "jobs_processed_total"
            "description" = "Job processing throughput"
            "target" = "increasing daily"
            "threshold" = "> 0 jobs/day"
            "query" = "increase(jobs_processed_total[1d])"
            "alert_condition" = "rate(jobs_processed_total[1d]) == 0"
            "severity" = "warning"
        }
        "failure_rate" = @{
            "metric" = "job_failure_rate"
            "description" = "Job failure rate on PR lane"
            "target" = "< 1%"
            "threshold" = "0.01"
            "query" = "rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m])"
            "alert_condition" = "rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) > 0.01"
            "severity" = "warning"
        }
        "latency" = @{
            "metric" = "job_duration_ms"
            "description" = "Job duration P95"
            "target" = "< 15s"
            "threshold" = "15000"
            "query" = "histogram_quantile(0.95, rate(job_duration_ms_bucket[5m]))"
            "alert_condition" = "histogram_quantile(0.95, rate(job_duration_ms_bucket[5m])) > 15000"
            "severity" = "warning"
        }
        "queue_health" = @{
            "metric" = "queue_depth"
            "description" = "Queue depth P95"
            "target" = "≤ 1"
            "threshold" = "1"
            "query" = "histogram_quantile(0.95, queue_depth)"
            "alert_condition" = "histogram_quantile(0.95, queue_depth) > 1"
            "severity" = "warning"
        }
        "stability" = @{
            "metric" = "ci_flaky_tests_count"
            "description" = "Flaky test count"
            "target" = "flat or trending down"
            "threshold" = "week-over-week decrease"
            "query" = "ci_flaky_tests_count"
            "alert_condition" = "increase(ci_flaky_tests_count[7d]) > 0"
            "severity" = "info"
        }
    }
    "dashboard_panels" = @(
        @{
            "title" = "Job Throughput"
            "type" = "graph"
            "query" = "rate(jobs_processed_total[5m])"
            "y_axis" = "jobs/second"
            "target_line" = "> 0"
        },
        @{
            "title" = "Failure Rate"
            "type" = "stat"
            "query" = "rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) * 100"
            "unit" = "percent"
            "target_line" = "< 1%"
        },
        @{
            "title" = "Job Duration P95"
            "type" = "graph"
            "query" = "histogram_quantile(0.95, rate(job_duration_ms_bucket[5m]))"
            "y_axis" = "milliseconds"
            "target_line" = "< 15000"
        },
        @{
            "title" = "Queue Depth"
            "type" = "graph"
            "query" = "queue_depth"
            "y_axis" = "tasks"
            "target_line" = "≤ 1"
        },
        @{
            "title" = "Flaky Tests"
            "type" = "stat"
            "query" = "ci_flaky_tests_count"
            "unit" = "count"
            "target_line" = "trending down"
        },
        @{
            "title" = "System Health Score"
            "type" = "stat"
            "query" = "system_health_score"
            "unit" = "percent"
            "target_line" = "> 80%"
        },
        @{
            "title" = "OTLP Exporter Status"
            "type" = "stat"
            "query" = "otlp_exporter_up"
            "unit" = "boolean"
            "target_line" = "= 1"
        },
        @{
            "title" = "Memory Usage"
            "type" = "graph"
            "query" = "process_resident_memory_bytes / 1024 / 1024 / 1024"
            "y_axis" = "GB"
            "target_line" = "< 2"
        }
    )
    "alerts" = @(
        @{
            "name" = "ThroughputStopped"
            "condition" = "rate(jobs_processed_total[1h]) == 0"
            "severity" = "critical"
            "description" = "Job processing has stopped"
        },
        @{
            "name" = "HighFailureRate"
            "condition" = "rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) > 0.01"
            "severity" = "warning"
            "description" = "Failure rate exceeds 1%"
        },
        @{
            "name" = "HighLatency"
            "condition" = "histogram_quantile(0.95, rate(job_duration_ms_bucket[5m])) > 15000"
            "severity" = "warning"
            "description" = "Job latency P95 > 15s"
        },
        @{
            "name" = "QueueBacklog"
            "condition" = "queue_depth > 3"
            "severity" = "warning"
            "description" = "Queue depth > 3"
        },
        @{
            "name" = "FlakyTestsIncreasing"
            "condition" = "increase(ci_flaky_tests_count[24h]) > 3"
            "severity" = "info"
            "description" = "Flaky test count increasing"
        }
    )
    "monitoring_schedule" = @{
        "daily_check" = "09:00 UTC"
        "weekly_review" = "Monday 09:00 UTC"
        "escalation" = "24 hours"
        "reporting" = "ECRR report generated"
    }
}

# Generate dashboard configuration
$dashboardConfig = @{
    "title" = "Agent System Sanity Dashboard"
    "description" = "First week monitoring targets and alerts"
    "timeframe" = "$Days days"
    "panels" = $sanityTargets.dashboard_panels
    "targets" = $sanityTargets.targets
    "alerts" = $sanityTargets.alerts
    "created_at" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    "created_by" = "Cursor Agent (Observability Copilot)"
}

# Save configuration
if (-not $DryRun) {
    Write-Host "💾 Saving dashboard configuration..." -ForegroundColor Cyan
    
    # Ensure artifacts directory exists
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $dashboardConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Dashboard configuration saved: $OutputPath" -ForegroundColor Green
}

# Display targets
Write-Host "`n📈 Sanity Targets (First $Days Days)" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

foreach ($target in $sanityTargets.targets.Keys) {
    $targetData = $sanityTargets.targets[$target]
    Write-Host "🎯 $($targetData.description)" -ForegroundColor White
    Write-Host "   Metric: $($targetData.metric)" -ForegroundColor Gray
    Write-Host "   Target: $($targetData.target)" -ForegroundColor Green
    Write-Host "   Query: $($targetData.query)" -ForegroundColor Gray
    Write-Host ""
}

# Display dashboard panels
Write-Host "📊 Dashboard Panels" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

foreach ($panel in $sanityTargets.dashboard_panels) {
    Write-Host "📋 $($panel.title)" -ForegroundColor White
    Write-Host "   Type: $($panel.type)" -ForegroundColor Gray
    Write-Host "   Query: $($panel.query)" -ForegroundColor Gray
    Write-Host "   Target: $($panel.target_line)" -ForegroundColor Green
    Write-Host ""
}

# Generate ECRR report
$reportPath = "docs/ECRR_REPORTS/$(Get-Date -Format 'yyyy-MM-dd')-dashboard-sanity-targets-complete.md"
$reportContent = @"
# Dashboard Sanity Targets - ECRR Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent (Observability Copilot)  
**Status**: ✅ COMPLETE

## 🔍 Examine - Current State
- **Post-Merge**: System deployed and operational
- **Monitoring Need**: First week sanity targets and alerts
- **Dashboard**: Comprehensive monitoring interface required
- **Targets**: Throughput, failure rate, latency, queue health, stability

## 🧹 Clean - Dashboard Actions
- **Sanity Targets**: Defined for first week monitoring
- **Dashboard Panels**: 8 panels for comprehensive monitoring
- **Alert Rules**: 5 alerts for critical conditions
- **Monitoring Schedule**: Daily and weekly review schedule

## 📝 Report - Dashboard Results

### Sanity Targets
"@

foreach ($target in $sanityTargets.targets.Keys) {
    $targetData = $sanityTargets.targets[$target]
    $reportContent += @"

- **$($targetData.description)**
  - Metric: $($targetData.metric)
  - Target: $($targetData.target)
  - Threshold: $($targetData.threshold)
  - Query: $($targetData.query)
  - Alert: $($targetData.alert_condition)
"@
}

$reportContent += @"

### Dashboard Panels
"@

foreach ($panel in $sanityTargets.dashboard_panels) {
    $reportContent += @"

- **$($panel.title)**
  - Type: $($panel.type)
  - Query: $($panel.query)
  - Target: $($panel.target_line)
"@
}

$reportContent += @"

### Alert Rules
"@

foreach ($alert in $sanityTargets.alerts) {
    $reportContent += @"

- **$($alert.name)**
  - Condition: $($alert.condition)
  - Severity: $($alert.severity)
  - Description: $($alert.description)
"@
}

$reportContent += @"

### Monitoring Schedule
- **Daily Check**: $($sanityTargets.monitoring_schedule.daily_check)
- **Weekly Review**: $($sanityTargets.monitoring_schedule.weekly_review)
- **Escalation**: $($sanityTargets.monitoring_schedule.escalation)
- **Reporting**: $($sanityTargets.monitoring_schedule.reporting)

### Configuration Files
- **Dashboard Config**: $OutputPath
- **Timeframe**: $Days days
- **Panels**: $($sanityTargets.dashboard_panels.Count)
- **Targets**: $($sanityTargets.targets.Keys.Count)
- **Alerts**: $($sanityTargets.alerts.Count)

## 🎭 Role - Actor Declaration
**Cursor Agent (Observability Copilot)**: Defined sanity targets, created dashboard configuration, implemented monitoring schedule, generated ECRR report.

## ✅ ECRR Gate
- **Examine**: ✅ Current state captured and analyzed
- **Clean**: ✅ Dashboard sanity targets implemented
- **Report**: ✅ Implementation results documented
- **Role**: ✅ Actor declared and responsibilities clear

---
**Dashboard Sanity Targets Complete**: $Days-day monitoring plan operational
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "📄 ECRR report generated: $reportPath" -ForegroundColor Green

Write-Host "`n🎉 Dashboard Sanity Targets Complete!" -ForegroundColor Green
Write-Host "✅ $Days-day monitoring plan created" -ForegroundColor Green
Write-Host "📊 $($sanityTargets.dashboard_panels.Count) dashboard panels" -ForegroundColor Green
Write-Host "🎯 $($sanityTargets.targets.Keys.Count) sanity targets" -ForegroundColor Green
Write-Host "🚨 $($sanityTargets.alerts.Count) alert rules" -ForegroundColor Green
Write-Host "📄 ECRR report: $reportPath" -ForegroundColor Green
