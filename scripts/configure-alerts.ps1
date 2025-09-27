# Configure Alert Thresholds and Notification Channels Script
# Creates alert rules and notification channels in SigNoz

param(
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [string]$BaseUrl = "http://localhost:8080",
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Configure Alert Thresholds and Notification Channels - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check prerequisites
Write-Host "`nExamine: Checking prerequisites..." -ForegroundColor Green

if (-not $ApiToken) {
    Write-Host "ERROR: SIGNOZ_API_TOKEN environment variable not set" -ForegroundColor Red
    Write-Host "Please set: `$env:SIGNOZ_API_TOKEN = 'your-api-token-here'" -ForegroundColor Yellow
    exit 1
}

if (-not $WebhookUrl) {
    Write-Host "ERROR: ALERT_WEBHOOK_URL environment variable not set" -ForegroundColor Red
    Write-Host "Please set: `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Yellow
    exit 1
}

Write-Host "API Token: Set" -ForegroundColor Green
Write-Host "Webhook URL: $WebhookUrl" -ForegroundColor Green

# Clean: Configure alert rules and notification channels
Write-Host "`nClean: Configuring alert rules and notification channels..." -ForegroundColor Green

$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

$ConfigurationStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    base_url = $BaseUrl
    webhook_url = $WebhookUrl
    notification_channel_created = $false
    alert_rules_created = @()
    errors = @()
    recommendations = @()
}

# Step 1: Create Notification Channel
Write-Host "`nStep 1: Creating notification channel..." -ForegroundColor Yellow

try {
    $NotificationChannel = @{
        name = "OTel Monitoring Webhook"
        type = "webhook"
        webhook = @{
            url = $WebhookUrl
            httpMethod = "POST"
            headers = @{
                "Content-Type" = "application/json"
            }
            title = "OTel Alert: {{ .GroupLabels.alertname }}"
            text = "Alert: {{ .GroupLabels.alertname }}{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
        }
        sendResolved = $true
        enabled = $true
    }
    
    $ChannelResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/notificationChannels" -Method POST -Headers $Headers -Body ($NotificationChannel | ConvertTo-Json -Depth 3) -TimeoutSec 10
    
    Write-Host "  OK Notification channel created" -ForegroundColor Green
    $ConfigurationStatus.notification_channel_created = $true
    $ChannelId = $ChannelResponse.id
    
} catch {
    Write-Host "  ERROR Failed to create notification channel: $($_.Exception.Message)" -ForegroundColor Red
    $ConfigurationStatus.errors += "Notification channel creation failed: $($_.Exception.Message)"
    $ConfigurationStatus.recommendations += "Check webhook URL and API permissions"
}

# Step 2: Create Alert Rules
Write-Host "`nStep 2: Creating alert rules..." -ForegroundColor Yellow

$AlertRules = @(
    @{
        name = "Queue Utilization High"
        description = "Alert when queue utilization exceeds 80%"
        query = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100"
        condition = "> 80"
        duration = "5m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "queue"
        }
        annotations = @{
            summary = "Queue utilization is high"
            description = "Queue utilization has exceeded 80% for 5 minutes"
        }
    },
    @{
        name = "Send Failure Rate High"
        description = "Alert when send failure rate exceeds 10%"
        query = "rate(otelcol_exporter_send_failed_log_records[5m])"
        condition = "> 10"
        duration = "2m"
        severity = "critical"
        labels = @{
            severity = "critical"
            service = "otel-collector"
            component = "exporter"
        }
        annotations = @{
            summary = "Send failure rate is high"
            description = "Send failure rate has exceeded 10% for 2 minutes"
        }
    },
    @{
        name = "Batch Timeout Triggers"
        description = "Alert when batch timeout triggers exceed 1/sec"
        query = "rate(otelcol_processor_batch_timeout_trigger_send[5m])"
        condition = "> 1"
        duration = "1m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "processor"
        }
        annotations = @{
            summary = "Batch timeout triggers are high"
            description = "Batch timeout triggers have exceeded 1/sec for 1 minute"
        }
    },
    @{
        name = "Log Processing Rate Low"
        description = "Alert when log processing rate drops below 10/sec"
        query = "rate(otelcol_receiver_accepted_log_records[5m])"
        condition = "< 10"
        duration = "3m"
        severity = "warning"
        labels = @{
            severity = "warning"
            service = "otel-collector"
            component = "receiver"
        }
        annotations = @{
            summary = "Log processing rate is low"
            description = "Log processing rate has dropped below 10/sec for 3 minutes"
        }
    }
)

foreach ($AlertRule in $AlertRules) {
    Write-Host "  Creating alert: $($AlertRule.name)" -ForegroundColor Yellow
    
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
            notificationChannels = if ($ConfigurationStatus.notification_channel_created) { @($ChannelId) } else { @() }
        }
        
        $AlertResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/alerts" -Method POST -Headers $Headers -Body ($AlertConfig | ConvertTo-Json -Depth 3) -TimeoutSec 10
        
        Write-Host "    OK Alert rule created: $($AlertRule.name)" -ForegroundColor Green
        $ConfigurationStatus.alert_rules_created += $AlertRule.name
        
    } catch {
        Write-Host "    ERROR Failed to create alert rule: $($_.Exception.Message)" -ForegroundColor Red
        $ConfigurationStatus.errors += "Alert rule creation failed for $($AlertRule.name): $($_.Exception.Message)"
    }
}

# Step 3: Test Notification Channel
Write-Host "`nStep 3: Testing notification channel..." -ForegroundColor Yellow

if ($ConfigurationStatus.notification_channel_created) {
    try {
        $TestNotification = @{
            channelId = $ChannelId
            message = "Test notification from OTel monitoring setup"
            severity = "info"
        }
        
        $TestResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/notificationChannels/$ChannelId/test" -Method POST -Headers $Headers -Body ($TestNotification | ConvertTo-Json) -TimeoutSec 10
        
        Write-Host "  OK Test notification sent" -ForegroundColor Green
        
    } catch {
        Write-Host "  ERROR Failed to send test notification: $($_.Exception.Message)" -ForegroundColor Red
        $ConfigurationStatus.errors += "Test notification failed: $($_.Exception.Message)"
    }
}

# Report: Generate configuration status
Write-Host "`nReport: Configuration status summary" -ForegroundColor Green

Write-Host "`nConfiguration Status:" -ForegroundColor Cyan
Write-Host "  Notification Channel: $(if ($ConfigurationStatus.notification_channel_created) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($ConfigurationStatus.notification_channel_created) { 'Green' } else { 'Red' })
Write-Host "  Alert Rules Created: $($ConfigurationStatus.alert_rules_created.Count)/$($AlertRules.Count)" -ForegroundColor $(if ($ConfigurationStatus.alert_rules_created.Count -eq $AlertRules.Count) { 'Green' } else { 'Yellow' })

if ($ConfigurationStatus.alert_rules_created.Count -gt 0) {
    Write-Host "`nCreated Alert Rules:" -ForegroundColor Yellow
    $ConfigurationStatus.alert_rules_created | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
}

if ($ConfigurationStatus.errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $ConfigurationStatus.errors | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
}

if ($ConfigurationStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $ConfigurationStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save configuration status
$ConfigurationStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/alert-configuration-status.json" -Encoding UTF8

Write-Host "`nConfiguration status saved to: artifacts/alert-configuration-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

$AllConfigured = $ConfigurationStatus.notification_channel_created -and $ConfigurationStatus.alert_rules_created.Count -eq $AlertRules.Count

if ($AllConfigured) {
    Write-Host "Next: Alert configuration complete - test alert delivery" -ForegroundColor Green
    Write-Host "Then: Monitor alert thresholds and adjust as needed" -ForegroundColor Green
} else {
    Write-Host "Next: Fix configuration errors and re-run setup" -ForegroundColor Yellow
    Write-Host "Then: Complete alert configuration and test delivery" -ForegroundColor Yellow
}
