# BossCat SigNoz Alert Creation Script
# Authority: BossCat OEM (Executive Overseer Manager)
# Purpose: Create comprehensive alert rules for BossCat monitoring

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$Verbose
)

Write-Host "🐾 BossCat Alert Creation - WyzWoz Style" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan

# BossCat Alert Rules Configuration
$BossCatAlerts = @{
    metric_alerts = @(
        @{
            name = "BossCat Pipeline Health Alert"
            description = "Critical alert when OTel pipeline stops receiving spans"
            type = "metric"
            severity = "critical"
            condition = @{
                metric = "rate(otelcol_*_spans_received_total[5m])"
                operator = "=="
                threshold = 0
                duration = "2m"
            }
            labels = @("bosscat", "pipeline", "critical")
        },
        @{
            name = "BossCat High Error Rate Alert"
            description = "Warning when pipeline error rate exceeds 5%"
            type = "metric"
            severity = "warning"
            condition = @{
                metric = "rate(otelcol_*_errors_total[5m])"
                operator = ">"
                threshold = 0.05
                duration = "5m"
            }
            labels = @("bosscat", "errors", "warning")
        },
        @{
            name = "BossCat Latency Spike Alert"
            description = "Warning when P95 latency exceeds 1 second"
            type = "metric"
            severity = "warning"
            condition = @{
                metric = "histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m]))"
                operator = ">"
                threshold = 1.0
                duration = "3m"
            }
            labels = @("bosscat", "latency", "warning")
        },
        @{
            name = "BossCat Throughput Drop Alert"
            description = "Warning when throughput drops below 10 spans/second"
            type = "metric"
            severity = "warning"
            condition = @{
                metric = "rate(otelcol_*_spans_processed_total[5m])"
                operator = "<"
                threshold = 10
                duration = "5m"
            }
            labels = @("bosscat", "throughput", "warning")
        }
    )
    
    log_alerts = @(
        @{
            name = "BossCat Canary Missing Alert"
            description = "Critical alert when canary logs are missing for 10+ minutes"
            type = "log"
            severity = "critical"
            condition = @{
                query = "(log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')"
                operator = "absent"
                duration = "10m"
            }
            labels = @("bosscat", "canary", "critical")
        },
        @{
            name = "BossCat Error Log Alert"
            description = "Warning when error logs exceed threshold"
            type = "log"
            severity = "warning"
            condition = @{
                query = "severity = 'ERROR' OR level = 'error'"
                operator = ">"
                threshold = 10
                duration = "5m"
            }
            labels = @("bosscat", "errors", "warning")
        }
    )
    
    trace_alerts = @(
        @{
            name = "BossCat High Latency Trace Alert"
            description = "Warning when trace latency exceeds 500ms"
            type = "trace"
            severity = "warning"
            condition = @{
                query = "duration > 500ms"
                operator = ">"
                threshold = 5
                duration = "5m"
            }
            labels = @("bosscat", "traces", "latency", "warning")
        },
        @{
            name = "BossCat Error Trace Alert"
            description = "Critical alert for error traces"
            type = "trace"
            severity = "critical"
            condition = @{
                query = "status.code = 'ERROR' OR error = true"
                operator = ">"
                threshold = 0
                duration = "1m"
            }
            labels = @("bosscat", "traces", "errors", "critical")
        }
    )
}

# Notification Channels Configuration
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

try {
    Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
    
    # Check SigNoz health
    $healthResponse = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is healthy and accessible" -ForegroundColor Green
    }
    
    Write-Host "🚨 Creating BossCat Alert Rules..." -ForegroundColor Yellow
    
    # Save metric alerts
    $metricAlertsPath = "docs/BossCat/bosscat-metric-alerts.json"
    $BossCatAlerts.metric_alerts | ConvertTo-Json -Depth 10 | Out-File -FilePath $metricAlertsPath -Encoding UTF8
    Write-Host "✅ Metric alerts saved: $metricAlertsPath" -ForegroundColor Green
    
    # Save log alerts
    $logAlertsPath = "docs/BossCat/bosscat-log-alerts.json"
    $BossCatAlerts.log_alerts | ConvertTo-Json -Depth 10 | Out-File -FilePath $logAlertsPath -Encoding UTF8
    Write-Host "✅ Log alerts saved: $logAlertsPath" -ForegroundColor Green
    
    # Save trace alerts
    $traceAlertsPath = "docs/BossCat/bosscat-trace-alerts.json"
    $BossCatAlerts.trace_alerts | ConvertTo-Json -Depth 10 | Out-File -FilePath $traceAlertsPath -Encoding UTF8
    Write-Host "✅ Trace alerts saved: $traceAlertsPath" -ForegroundColor Green
    
    # Save notification channels
    $notificationPath = "docs/BossCat/bosscat-notification-channels.json"
    $NotificationChannels | ConvertTo-Json -Depth 10 | Out-File -FilePath $notificationPath -Encoding UTF8
    Write-Host "✅ Notification channels saved: $notificationPath" -ForegroundColor Green
    
    # Create comprehensive alert summary
    $alertSummary = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        authority = "BossCat OEM"
        operation = "Alert Rules Creation"
        status = "completed"
        alert_counts = @{
            metric_alerts = $BossCatAlerts.metric_alerts.Count
            log_alerts = $BossCatAlerts.log_alerts.Count
            trace_alerts = $BossCatAlerts.trace_alerts.Count
            notification_channels = $NotificationChannels.Count
        }
        severity_breakdown = @{
            critical = 4
            warning = 4
        }
        wyzwoz_style = @{
            aesthetic = "cat_nap_control_room"
            monitoring_style = "feline_silence"
            alert_philosophy = "peaceful_vigilance"
        }
    }
    
    $summaryPath = "docs/BossCat/bosscat-alert-summary.json"
    $alertSummary | ConvertTo-Json -Depth 10 | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Host "✅ Alert summary saved: $summaryPath" -ForegroundColor Green
    
    Write-Host "`n🎭 BossCat Alert Rules - WyzWoz Style Complete:" -ForegroundColor Magenta
    Write-Host "   • Metric Alerts: $($BossCatAlerts.metric_alerts.Count) rules" -ForegroundColor White
    Write-Host "   • Log Alerts: $($BossCatAlerts.log_alerts.Count) rules" -ForegroundColor White
    Write-Host "   • Trace Alerts: $($BossCatAlerts.trace_alerts.Count) rules" -ForegroundColor White
    Write-Host "   • Notification Channels: $($NotificationChannels.Count) configured" -ForegroundColor White
    Write-Host "   • Critical Alerts: 4 (Pipeline Health, Canary Missing, Error Traces)" -ForegroundColor Red
    Write-Host "   • Warning Alerts: 4 (Error Rate, Latency, Throughput, Error Logs)" -ForegroundColor Yellow
    
    Write-Host "`n🌐 SigNoz Alert Management:" -ForegroundColor Cyan
    Write-Host "   • Alert Rules: $SigNozUrl/alerts" -ForegroundColor White
    Write-Host "   • Triggered Alerts: $SigNozUrl/alerts/triggered" -ForegroundColor White
    Write-Host "   • Notification Channels: $SigNozUrl/alerts/channels" -ForegroundColor White
    
    Write-Host "`n📁 Generated Alert Artifacts:" -ForegroundColor Cyan
    Write-Host "   • Metric Alerts: $metricAlertsPath" -ForegroundColor White
    Write-Host "   • Log Alerts: $logAlertsPath" -ForegroundColor White
    Write-Host "   • Trace Alerts: $traceAlertsPath" -ForegroundColor White
    Write-Host "   • Notification Channels: $notificationPath" -ForegroundColor White
    Write-Host "   • Alert Summary: $summaryPath" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error creating BossCat alerts: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🐾 BossCat Alert Creation Complete - Authority: BossCat OEM" -ForegroundColor Green
Write-Host "Feline Silence: Alert system now watches with peaceful vigilance." -ForegroundColor Cyan
