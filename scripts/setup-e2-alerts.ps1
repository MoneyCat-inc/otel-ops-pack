# Setup E2 Ratio Sweep Alerts
# Creates SigNoz alerts for E2 performance monitoring

param(
    [string]$AlertsFile = "artifacts/signoz-e2-alerts.json",
    [string]$SigNozUrl = "http://127.0.0.1:8080"
)

Write-Host "=== Setting up E2 Ratio Sweep Alerts ===" -ForegroundColor Green
Write-Host "Alerts file: $AlertsFile" -ForegroundColor Yellow
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
    Write-Host "Created artifacts directory" -ForegroundColor Green
}

# Create E2-specific alerts
$e2Alerts = @{
    version = "1.0"
    alerts = @(
        @{
            id = "e2-p95-latency-high"
            name = "E2 P95 Latency High"
            description = "Alert when E2 P95 latency exceeds 2 seconds for 5 minutes"
            condition = @{
                expr = "JSONExtractFloat(body,'metrics.p95_latency_ms') > 2000"
                duration = "5m"
                severity = "warning"
            }
            labels = @{
                service = "e2-ratio-sweep"
                component = "latency"
                environment = "local"
            }
            annotations = @{
                summary = "E2 P95 latency is high"
                description = "E2 ratio sweep P95 latency has exceeded 2000ms for more than 5 minutes. Check batch timeout configuration."
                runbook_url = "https://github.com/your-org/otel/docs/troubleshooting.md#e2-latency-high"
            }
            notifications = @{
                channels = @("email", "slack")
                message = "⚠️ WARNING: E2 P95 latency is high (>2000ms). Check batch timeout configuration."
            }
        },
        @{
            id = "e2-queue-utilization-high"
            name = "E2 Queue Utilization High"
            description = "Alert when E2 queue utilization exceeds 60% for 10 minutes"
            condition = @{
                expr = "JSONExtractFloat(body,'metrics.queue_utilization_percent') > 60"
                duration = "10m"
                severity = "warning"
            }
            labels = @{
                service = "e2-ratio-sweep"
                component = "queue"
                environment = "local"
            }
            annotations = @{
                summary = "E2 queue utilization is high"
                description = "E2 ratio sweep queue utilization has exceeded 60% for more than 10 minutes. Consider increasing batch sizes or reducing ingestion rate."
                runbook_url = "https://github.com/your-org/otel/docs/troubleshooting.md#e2-queue-high"
            }
            notifications = @{
                channels = @("email")
                message = "⚠️ WARNING: E2 queue utilization is high (>60%). Consider adjusting batch configuration."
            }
        },
        @{
            id = "e2-batch-efficiency-low"
            name = "E2 Batch Efficiency Low"
            description = "Alert when E2 batch efficiency drops below 80% for 5 minutes"
            condition = @{
                expr = "JSONExtractFloat(body,'metrics.batch_efficiency_percent') < 80"
                duration = "5m"
                severity = "warning"
            }
            labels = @{
                service = "e2-ratio-sweep"
                component = "batching"
                environment = "local"
            }
            annotations = @{
                summary = "E2 batch efficiency is low"
                description = "E2 ratio sweep batch efficiency has dropped below 80% for more than 5 minutes. Check batch timeout and size configuration."
                runbook_url = "https://github.com/your-org/otel/docs/troubleshooting.md#e2-batch-efficiency-low"
            }
            notifications = @{
                channels = @("email")
                message = "⚠️ WARNING: E2 batch efficiency is low (<80%). Check batch configuration."
            }
        },
        @{
            id = "e2-optimal-config-changed"
            name = "E2 Optimal Config Changed"
            description = "Alert when E2 optimal configuration changes from E2-005"
            condition = @{
                expr = "JSONExtractString(body,'test_id') != 'E2-005' AND JSONExtractFloat(body,'metrics.p95_latency_ms') < 2000 AND JSONExtractFloat(body,'metrics.batch_efficiency_percent') >= 90"
                duration = "1m"
                severity = "info"
            }
            labels = @{
                service = "e2-ratio-sweep"
                component = "optimization"
                environment = "local"
            }
            annotations = @{
                summary = "E2 optimal configuration has changed"
                description = "A new E2 configuration is performing better than the current optimal (E2-005). Consider updating the baseline configuration."
                runbook_url = "https://github.com/your-org/otel/docs/troubleshooting.md#e2-config-change"
            }
            notifications = @{
                channels = @("slack")
                message = "ℹ️ INFO: E2 optimal configuration has changed. New best config detected."
            }
        }
    )
    notification_channels = @(
        @{
            id = "email"
            type = "email"
            settings = @{
                addresses = @("admin@your-org.com")
                subject = "E2 Alert: {{ .GroupLabels.alertname }}"
            }
        },
        @{
            id = "slack"
            type = "slack"
            settings = @{
                webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
                channel = "#alerts"
                title = "E2 Alert"
                text = "{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.description }}"
            }
        }
    )
}

# Save alerts configuration
$e2Alerts | ConvertTo-Json -Depth 10 | Set-Content $AlertsFile
Write-Host "✓ E2 alerts configuration saved to: $AlertsFile" -ForegroundColor Green

# Display alert summary
Write-Host "`n=== E2 Alerts Created ===" -ForegroundColor Green
Write-Host "Total alerts: $($e2Alerts.alerts.Count)" -ForegroundColor White

foreach ($alert in $e2Alerts.alerts) {
    Write-Host "`n$($alert.name):" -ForegroundColor Yellow
    Write-Host "  ID: $($alert.id)" -ForegroundColor White
    Write-Host "  Severity: $($alert.condition.severity)" -ForegroundColor White
    Write-Host "  Duration: $($alert.condition.duration)" -ForegroundColor White
    Write-Host "  Description: $($alert.description)" -ForegroundColor White
}

Write-Host "`n=== Alert Details ===" -ForegroundColor Green

Write-Host "`n1. E2 P95 Latency High:" -ForegroundColor Yellow
Write-Host "   Triggers: P95 latency > 2000ms for 5 minutes" -ForegroundColor White
Write-Host "   Severity: Warning" -ForegroundColor White
Write-Host "   Action: Check batch timeout configuration" -ForegroundColor White

Write-Host "`n2. E2 Queue Utilization High:" -ForegroundColor Yellow
Write-Host "   Triggers: Queue utilization > 60% for 10 minutes" -ForegroundColor White
Write-Host "   Severity: Warning" -ForegroundColor White
Write-Host "   Action: Consider increasing batch sizes" -ForegroundColor White

Write-Host "`n3. E2 Batch Efficiency Low:" -ForegroundColor Yellow
Write-Host "   Triggers: Batch efficiency < 80% for 5 minutes" -ForegroundColor White
Write-Host "   Severity: Warning" -ForegroundColor White
Write-Host "   Action: Check batch timeout and size configuration" -ForegroundColor White

Write-Host "`n4. E2 Optimal Config Changed:" -ForegroundColor Yellow
Write-Host "   Triggers: New config outperforms E2-005" -ForegroundColor White
Write-Host "   Severity: Info" -ForegroundColor White
Write-Host "   Action: Consider updating baseline configuration" -ForegroundColor White

Write-Host "`n=== Import Instructions ===" -ForegroundColor Green
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Go to: Alerts → Import" -ForegroundColor White
Write-Host "3. Upload: $AlertsFile" -ForegroundColor White
Write-Host "4. Configure notification channels" -ForegroundColor White
Write-Host "5. Enable alerts" -ForegroundColor White

Write-Host "`n=== Test Alerts ===" -ForegroundColor Green
Write-Host "To test alerts:" -ForegroundColor Yellow
Write-Host "1. Run E2 sweep with suboptimal configuration" -ForegroundColor White
Write-Host "2. Publish results to trigger alerts" -ForegroundColor White
Write-Host "3. Verify alerts fire in SigNoz UI" -ForegroundColor White
Write-Host "4. Check notification channels" -ForegroundColor White

Write-Host "`nE2 alerts setup completed!" -ForegroundColor Green
Write-Host "Alerts file: $AlertsFile" -ForegroundColor Cyan
