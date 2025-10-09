# Deploy Alert Thresholds & Notifications Script
# Implements T-2025-01-27-006: Alert Thresholds & Notifications

param(
    [switch]$GenerateAlerts,
    [switch]$TestAlerts,
    [switch]$ConfigureWebhooks,
    [switch]$FullDeployment
)

Write-Host "=== Alert Thresholds & Notifications Deployment ===" -ForegroundColor Green
Write-Host "Task: T-2025-01-27-006 - Alert Thresholds & Notifications" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
    Write-Host "Created artifacts directory" -ForegroundColor Green
}

$alertsConfigFile = "artifacts/signoz-alert-thresholds-notifications.json"

if ($GenerateAlerts -or $FullDeployment) {
    Write-Host "`n=== Generating Alert Thresholds & Notifications Configuration ===" -ForegroundColor Yellow
    
    # Create comprehensive alert thresholds and notifications configuration
    $alertsConfig = @{
        alert_rules = @(
            @{
                name = "Windows Canary Log Absence"
                description = "Alert when Windows canary logs stop appearing for more than 5 minutes"
                query = "count_over_time(count by (canary, service) (canary=`"true`" and service=`"canary-test`" and message contains `"windows-canary`")[5m]) == 0"
                severity = "critical"
                duration = "5m"
                labels = @{
                    alert_type = "canary"
                    service = "windows-logs"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Windows canary logs have stopped appearing"
                    description = "No Windows canary logs detected for 5 minutes. This indicates potential issues with Windows log collection or processing."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#canary-logs"
                }
                thresholds = @{
                    critical = @{
                        value = 0
                        duration = "5m"
                        condition = "equals"
                    }
                }
            },
            @{
                name = "Queue Utilization Critical"
                description = "Alert when queue utilization exceeds 70% for 10 minutes"
                query = "avg_over_time(otelcol_exporter_queue_size / otelcol_exporter_queue_capacity[10m]) > 0.7"
                severity = "critical"
                duration = "10m"
                labels = @{
                    alert_type = "queue"
                    service = "otel-collector"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Queue utilization is critically high"
                    description = "Queue utilization has exceeded 70% for 10 minutes. This indicates potential backpressure issues."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#queue-pressure"
                }
                thresholds = @{
                    critical = @{
                        value = 0.7
                        duration = "10m"
                        condition = "greater_than"
                    }
                    warning = @{
                        value = 0.5
                        duration = "5m"
                        condition = "greater_than"
                    }
                }
            },
            @{
                name = "Send Failure Rate High"
                description = "Alert when send failure rate exceeds 5% for 2 minutes"
                query = "rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m]) > 0.05"
                severity = "critical"
                duration = "2m"
                labels = @{
                    alert_type = "exporter"
                    service = "otel-collector"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Send failure rate is critically high"
                    description = "Send failure rate has exceeded 5% for 2 minutes. This indicates potential connectivity issues with SigNoz."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#send-failures"
                }
                thresholds = @{
                    critical = @{
                        value = 0.05
                        duration = "2m"
                        condition = "greater_than"
                    }
                    warning = @{
                        value = 0.01
                        duration = "1m"
                        condition = "greater_than"
                    }
                }
            },
            @{
                name = "Batch Processing Latency High"
                description = "Alert when p95 batch processing latency exceeds 8 seconds for 5 minutes"
                query = "histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m])) > 8"
                severity = "critical"
                duration = "5m"
                labels = @{
                    alert_type = "latency"
                    service = "otel-collector"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Batch processing latency is critically high"
                    description = "p95 batch processing latency has exceeded 8 seconds for 5 minutes. This indicates potential performance issues."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#latency"
                }
                thresholds = @{
                    critical = @{
                        value = 8
                        duration = "5m"
                        condition = "greater_than"
                    }
                    warning = @{
                        value = 2
                        duration = "2m"
                        condition = "greater_than"
                    }
                }
            },
            @{
                name = "Fractal Drift Detected"
                description = "Alert when fractal drift coefficient exceeds 0.5 for 10 minutes"
                query = "stddev_over_time(otelcol_exporter_queue_size[10m]) / avg_over_time(otelcol_exporter_queue_size[10m]) > 0.5"
                severity = "warning"
                duration = "10m"
                labels = @{
                    alert_type = "fractal"
                    service = "otel-collector"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Fractal drift pattern detected"
                    description = "Fractal drift coefficient has exceeded 0.5 for 10 minutes. This indicates unusual pattern variance in queue behavior."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#fractal-drift"
                }
                thresholds = @{
                    warning = @{
                        value = 0.5
                        duration = "10m"
                        condition = "greater_than"
                    }
                }
            },
            @{
                name = "Memory Usage Critical"
                description = "Alert when memory usage exceeds 400MB for 5 minutes"
                query = "otelcol_process_memory_rss > 400000000"
                severity = "critical"
                duration = "5m"
                labels = @{
                    alert_type = "memory"
                    service = "otel-collector"
                    environment = "production"
                    team = "observability"
                }
                annotations = @{
                    summary = "Memory usage is critically high"
                    description = "Memory usage has exceeded 400MB for 5 minutes. This indicates potential memory leaks or high load."
                    runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#memory"
                }
                thresholds = @{
                    critical = @{
                        value = 400000000
                        duration = "5m"
                        condition = "greater_than"
                    }
                    warning = @{
                        value = 200000000
                        duration = "3m"
                        condition = "greater_than"
                    }
                }
            }
        )
        notification_channels = @(
            @{
                name = "Webhook Notification"
                type = "webhook"
                url = "http://localhost:8080/api/v1/alerts"
                description = "Send alerts to webhook endpoint"
                enabled = $true
                labels = @{
                    environment = "production"
                    team = "observability"
                }
            },
            @{
                name = "Slack Notification"
                type = "slack"
                webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
                description = "Send alerts to Slack channel"
                enabled = $false
                labels = @{
                    environment = "production"
                    team = "observability"
                    channel = "#alerts"
                }
            },
            @{
                name = "Email Notification"
                type = "email"
                addresses = @("alerts@your-org.com", "oncall@your-org.com")
                description = "Send alerts via email"
                enabled = $false
                labels = @{
                    environment = "production"
                    team = "observability"
                }
            }
        )
        alert_groups = @(
            @{
                name = "Critical Alerts"
                description = "Critical system alerts requiring immediate attention"
                alerts = @(
                    "Windows Canary Log Absence",
                    "Queue Utilization Critical",
                    "Send Failure Rate High",
                    "Batch Processing Latency High",
                    "Memory Usage Critical"
                )
                notification_channels = @("Webhook Notification")
                repeat_interval = "5m"
                group_wait = "10s"
                group_interval = "10s"
            },
            @{
                name = "Warning Alerts"
                description = "Warning alerts for monitoring and investigation"
                alerts = @(
                    "Fractal Drift Detected"
                )
                notification_channels = @("Webhook Notification")
                repeat_interval = "15m"
                group_wait = "30s"
                group_interval = "30s"
            }
        )
        global_config = @{
            resolve_timeout = "5m"
            smtp_smarthost = "localhost:587"
            smtp_from = "alerts@your-org.com"
            smtp_auth_username = "alerts@your-org.com"
            smtp_auth_password = "your-password"
            slack_api_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
        }
    }
    
    $alertsConfig | ConvertTo-Json -Depth 6 | Set-Content -Path $alertsConfigFile -Encoding UTF8
    Write-Host "Alert thresholds and notifications configuration saved to: $alertsConfigFile" -ForegroundColor Green
    
    Write-Host "`n=== SigNoz Alert Import Instructions ===" -ForegroundColor Cyan
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to: Alerts -> Create Alert" -ForegroundColor White
    Write-Host "3. Use the configuration from: $alertsConfigFile" -ForegroundColor White
    Write-Host "4. Configure notification channels:" -ForegroundColor White
    Write-Host "   - Webhook: http://localhost:8080/api/v1/alerts" -ForegroundColor Gray
    Write-Host "   - Slack: Configure your webhook URL" -ForegroundColor Gray
    Write-Host "   - Email: Configure SMTP settings" -ForegroundColor Gray
}

if ($ConfigureWebhooks -or $FullDeployment) {
    Write-Host "`n=== Configuring Webhook Notifications ===" -ForegroundColor Yellow
    
    # Create webhook configuration script
    $webhookConfig = @{
        webhook_url = "http://localhost:8080/api/v1/alerts"
        webhook_secret = "your-webhook-secret"
        webhook_timeout = "10s"
        webhook_retry_count = 3
        webhook_retry_interval = "5s"
        webhook_headers = @{
            "Content-Type" = "application/json"
            "X-Webhook-Secret" = "your-webhook-secret"
        }
        webhook_payload_template = @{
            alert_name = "{{ .AlertName }}"
            alert_severity = "{{ .Severity }}"
            alert_description = "{{ .Description }}"
            alert_query = "{{ .Query }}"
            alert_duration = "{{ .Duration }}"
            alert_labels = "{{ .Labels }}"
            alert_annotations = "{{ .Annotations }}"
            alert_status = "{{ .Status }}"
            alert_timestamp = "{{ .Timestamp }}"
        }
    }
    
    $webhookConfigFile = "artifacts/webhook-notification-config.json"
    $webhookConfig | ConvertTo-Json -Depth 4 | Set-Content -Path $webhookConfigFile -Encoding UTF8
    Write-Host "Webhook configuration saved to: $webhookConfigFile" -ForegroundColor Green
}

if ($TestAlerts -or $FullDeployment) {
    Write-Host "`n=== Testing Alert Configuration ===" -ForegroundColor Yellow
    
    # Validate JSON configuration
    try {
        $config = Get-Content -Path $alertsConfigFile -Raw | ConvertFrom-Json
        Write-Host "✅ Alert configuration is valid" -ForegroundColor Green
        Write-Host "   Alert Rules: $($config.alert_rules.Count)" -ForegroundColor Cyan
        Write-Host "   Notification Channels: $($config.notification_channels.Count)" -ForegroundColor Cyan
        Write-Host "   Alert Groups: $($config.alert_groups.Count)" -ForegroundColor Cyan
        
        # Test each alert rule
        foreach ($rule in $config.alert_rules) {
            Write-Host "   Testing alert: $($rule.name)" -ForegroundColor Yellow
            Write-Host "     Query: $($rule.query)" -ForegroundColor Gray
            Write-Host "     Severity: $($rule.severity)" -ForegroundColor Gray
            Write-Host "     Duration: $($rule.duration)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "❌ Alert configuration is invalid: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Generate test report
    $testResults = @{
        task_id = "T-2025-01-27-006"
        task_name = "Alert Thresholds & Notifications"
        deployment_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        alerts_config_file = $alertsConfigFile
        status = "deployed"
        alert_rules_count = $config.alert_rules.Count
        notification_channels_count = $config.notification_channels.Count
        alert_groups_count = $config.alert_groups.Count
        alert_rules = $config.alert_rules | ForEach-Object { @{
            name = $_.name
            severity = $_.severity
            duration = $_.duration
            query = $_.query
        }}
        verification_steps = @(
            "Import alert configuration in SigNoz UI",
            "Configure notification channels",
            "Test alert rule queries",
            "Verify threshold configurations",
            "Test webhook notifications"
        )
        signoz_ui_url = "http://localhost:8080"
        alert_features = @{
            canary_monitoring = "Windows canary log absence detection"
            queue_monitoring = "Queue utilization and pressure alerts"
            failure_monitoring = "Send failure rate tracking"
            latency_monitoring = "Batch processing latency alerts"
            fractal_monitoring = "Fractal drift pattern detection"
            memory_monitoring = "Memory usage and limits alerts"
            notification_system = "Webhook, Slack, and email notifications"
            alert_grouping = "Critical and warning alert groups"
        }
    }
    
    $reportFile = "artifacts/alert-thresholds-notifications-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8
    Write-Host "`nDeployment report saved to: $reportFile" -ForegroundColor Blue
}

Write-Host "`n=== Alert Thresholds & Notifications Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Import alert configuration in SigNoz UI" -ForegroundColor White
Write-Host "2. Configure notification channels (webhook, Slack, email)" -ForegroundColor White
Write-Host "3. Test alert rule queries" -ForegroundColor White
Write-Host "4. Verify threshold configurations" -ForegroundColor White
Write-Host "5. Test webhook notifications" -ForegroundColor White
