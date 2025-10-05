# Comprehensive Alert Setup for Resonai Observability Stack
# ECRR Framework Implementation - Alert Configuration

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "local-signoz-jwt-secret-rotate",
    [string]$WebhookUrl = "http://localhost:3003/api/webhooks/alerts",
    [switch]$DryRun = $false,
    [switch]$SkipApplicationAlerts = $false
)

Write-Host "🚨 Comprehensive Alert Setup - Resonai Observability Stack" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

# Test SigNoz connectivity
Write-Host "🔍 Testing SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -Headers $Headers -TimeoutSec 10
    Write-Host "  ✅ SigNoz is accessible" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Cannot connect to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Alert Configuration Array
$AlertRules = @(
    # =============================================================================
    # INFRASTRUCTURE ALERTS (Existing)
    # =============================================================================
    @{
        name = "Queue Utilization High"
        description = "Queue utilization above 80% for 5 minutes"
        query = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100"
        condition = "> 80"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "exporter"
        }
        annotations = @{
            summary = "Queue utilization is high"
            description = "Queue utilization exceeds 80% for 5 minutes. Check collector performance."
        }
    },
    @{
        name = "Send Failure Rate High"
        description = "Send failure rate above 5%"
        query = "rate(otelcol_exporter_send_failed_log_records_total[5m]) / rate(otelcol_exporter_sent_log_records_total[5m]) * 100"
        condition = "> 5"
        duration = "5m"
        severity = "critical"
        labels = @{
            severity = "critical"
            service = "otel-collector"
            component = "exporter"
        }
        annotations = @{
            summary = "Send failure rate is high"
            description = "Send failure rate exceeds 5%. Check exporter connectivity and SigNoz health."
        }
    },
    @{
        name = "Batch Timeout Triggers High"
        description = "High frequency of batch timeout triggers"
        query = "rate(otelcol_processor_batch_timeout_trigger_send[5m])"
        condition = "> 10"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "processor"
        }
        annotations = @{
            summary = "High batch timeout frequency"
            description = "High frequency of batch timeout triggers. Consider optimizing batch configuration."
        }
    },
    @{
        name = "Log Processing Rate Low"
        description = "Log processing rate below 1 log/second"
        query = "rate(otelcol_receiver_accepted_log_records_total[5m])"
        condition = "< 1"
        duration = "10m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "receiver"
        }
        annotations = @{
            summary = "Log processing rate is low"
            description = "Log processing rate below 1 log/second for 10 minutes. Check log ingestion pipeline."
        }
    },

    # =============================================================================
    # APPLICATION ALERTS (New)
    # =============================================================================
    @{
        name = "Resonai Backend High Error Rate"
        description = "Backend error rate above 5%"
        query = 'rate(http_requests_total{service_name="resonai-backend",status_code=~"5.."}[5m]) / rate(http_requests_total{service_name="resonai-backend"}[5m]) * 100'
        condition = "> 5"
        duration = "5m"
        severity = "critical"
        labels = @{
            severity = "critical"
            service = "resonai-backend"
            component = "api"
        }
        annotations = @{
            summary = "Backend error rate is high"
            description = "Backend error rate exceeds 5%. Check application health and logs."
        }
    },
    @{
        name = "Resonai Backend High Latency"
        description = "Backend response time above 2 seconds"
        query = 'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service_name="resonai-backend"}[5m]))'
        condition = "> 2"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "resonai-backend"
            component = "api"
        }
        annotations = @{
            summary = "Backend latency is high"
            description = "95th percentile response time exceeds 2 seconds. Check performance."
        }
    },
    @{
        name = "Resonai Frontend High Error Rate"
        description = "Frontend error rate above 3%"
        query = 'rate(http_requests_total{service_name="resonai-frontend",status_code=~"4..|5.."}[5m]) / rate(http_requests_total{service_name="resonai-frontend"}[5m]) * 100'
        condition = "> 3"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "resonai-frontend"
            component = "ui"
        }
        annotations = @{
            summary = "Frontend error rate is high"
            description = "Frontend error rate exceeds 3%. Check client-side issues."
        }
    },
    @{
        name = "Database Connection Pool Exhausted"
        description = "Database connection pool utilization above 90%"
        query = "prisma_pool_connections_active / prisma_pool_connections_max * 100"
        condition = "> 90"
        duration = "3m"
        severity = "critical"
        labels = @{
            severity = "critical"
            service = "resonai-backend"
            component = "database"
        }
        annotations = @{
            summary = "Database connection pool exhausted"
            description = "Database connection pool utilization exceeds 90%. Check database health."
        }
    },
    @{
        name = "Memory Usage High"
        description = "Memory usage above 85%"
        query = "process_resident_memory_bytes / (1024*1024*1024)"
        condition = "> 1.5"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "resonai-backend"
            component = "system"
        }
        annotations = @{
            summary = "Memory usage is high"
            description = "Memory usage exceeds 1.5GB. Check for memory leaks."
        }
    },

    # =============================================================================
    # LOG-BASED ALERTS
    # =============================================================================
    @{
        name = "Critical Error Logs"
        description = "Critical error logs detected"
        query = "logs{severity=\"error\" OR severity=\"critical\"}"
        condition = "> 0"
        duration = "1m"
        severity = "critical"
        labels = @{
            severity = "critical"
            service = "resonai-backend"
            component = "logs"
        }
        annotations = @{
            summary = "Critical errors detected"
            description = "Critical error logs detected in the system. Immediate attention required."
        }
    },
    @{
        name = "Authentication Failures High"
        description = "High rate of authentication failures"
        query = "rate(logs{message=~\"authentication.*failed\"}[5m])"
        condition = "> 10"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "resonai-backend"
            component = "auth"
        }
        annotations = @{
            summary = "High authentication failure rate"
            description = "High rate of authentication failures detected. Check for security issues."
        }
    }
)

# Create notification channel
Write-Host "📢 Creating notification channel..." -ForegroundColor Yellow
$NotificationChannel = @{
    name = "Resonai Alert Channel"
    type = "webhook"
    config = @{
        url = $WebhookUrl
        httpMethod = "POST"
        headers = @{
            "Content-Type" = "application/json"
        }
    }
    enabled = $true
}

if (-not $DryRun) {
    try {
        $ChannelResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/notificationChannels" -Method POST -Headers $Headers -Body ($NotificationChannel | ConvertTo-Json -Depth 3) -TimeoutSec 10
        $ChannelId = $ChannelResponse.id
        Write-Host "  ✅ Notification channel created: $ChannelId" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Notification channel creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  📝 Manual setup required for notifications" -ForegroundColor Yellow
        $ChannelId = $null
    }
} else {
    Write-Host "  🔍 Dry run: Notification channel would be created" -ForegroundColor Gray
    $ChannelId = "dry-run-channel-id"
}

# Create alert rules
Write-Host "`n🚨 Creating alert rules..." -ForegroundColor Yellow
$CreatedAlerts = @()
$FailedAlerts = @()

foreach ($AlertRule in $AlertRules) {
    Write-Host "  Creating alert: $($AlertRule.name)" -ForegroundColor Cyan
    
    if (-not $DryRun) {
        try {
            $AlertConfig = @{
                name = $AlertRule.name
                description = $AlertRule.description
                query = $AlertRule.query
                condition = $AlertRule.condition
                duration = $AlertRule.duration
                severity = $AlertRule.severity
                labels = $AlertRule.labels
                annotations = $AlertRule.annotations
                enabled = $true
                notificationChannels = if ($ChannelId) { @($ChannelId) } else { @() }
            }
            
            $AlertResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method POST -Headers $Headers -Body ($AlertConfig | ConvertTo-Json -Depth 3) -TimeoutSec 10
            
            Write-Host "    ✅ Alert rule created: $($AlertRule.name)" -ForegroundColor Green
            $CreatedAlerts += $AlertRule.name
            
        } catch {
            Write-Host "    ❌ Failed to create alert rule: $($_.Exception.Message)" -ForegroundColor Red
            $FailedAlerts += $AlertRule.name
        }
    } else {
        Write-Host "    🔍 Dry run: Alert rule would be created" -ForegroundColor Gray
        $CreatedAlerts += $AlertRule.name
    }
}

# Generate summary report
Write-Host "`n📊 Alert Setup Summary" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host "✅ Created alerts: $($CreatedAlerts.Count)" -ForegroundColor Green
Write-Host "❌ Failed alerts: $($FailedAlerts.Count)" -ForegroundColor Red

if ($CreatedAlerts.Count -gt 0) {
    Write-Host "`n📋 Successfully Created Alerts:" -ForegroundColor Green
    foreach ($Alert in $CreatedAlerts) {
        Write-Host "  • $Alert" -ForegroundColor White
    }
}

if ($FailedAlerts.Count -gt 0) {
    Write-Host "`n❌ Failed Alert Creation:" -ForegroundColor Red
    foreach ($Alert in $FailedAlerts) {
        Write-Host "  • $Alert" -ForegroundColor White
    }
}

# Save configuration to artifacts
$ConfigPath = "artifacts/signoz-alert-configuration.json"
$AlertConfiguration = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    signoz_url = $SigNozUrl
    webhook_url = $WebhookUrl
    notification_channel_id = $ChannelId
    alerts = $AlertRules
    summary = @{
        total_alerts = $AlertRules.Count
        created_alerts = $CreatedAlerts.Count
        failed_alerts = $FailedAlerts.Count
        success_rate = [math]::Round(($CreatedAlerts.Count / $AlertRules.Count) * 100, 2)
    }
}

$AlertConfiguration | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
Write-Host "`n📝 Alert configuration saved to: $ConfigPath" -ForegroundColor Green

# Next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Verify alerts in SigNoz UI: $SigNozUrl/alerts" -ForegroundColor White
Write-Host "2. Test alert notifications by triggering conditions" -ForegroundColor White
Write-Host "3. Configure additional notification channels if needed" -ForegroundColor White
Write-Host "4. Review and adjust thresholds based on baseline metrics" -ForegroundColor White

Write-Host "`n✅ Alert setup completed!" -ForegroundColor Green
