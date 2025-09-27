# Setup Webhook Notifications for Alerts
# Configure webhook endpoints for SigNoz alert notifications
# Cursor-Local: Observability Copilot

param(
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [string]$Channel = $env:ALERT_CHANNEL,
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$TestWebhook = $false
)

Write-Host "🔔 Setting up Webhook Notifications for Alerts" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ECRR: Examine → Clean → Report → Role
Write-Host "🔍 ECRR Framework: Webhook Notification Setup" -ForegroundColor Yellow

$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

# Check if webhook URL is provided
if (-not $WebhookUrl) {
    Write-Host "⚠️ No webhook URL provided. Setting up example configurations..." -ForegroundColor Yellow
    
    # Create example webhook configurations
    $ExampleConfigs = @{
        slack = @{
            name = "Slack Webhook"
            url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
            description = "Slack channel notifications for OTel alerts"
            headers = @{
                "Content-Type" = "application/json"
            }
            payload_template = @{
                text = "🚨 OTel Alert: {alert_name}"
                attachments = @(
                    @{
                        color = "danger"
                        fields = @(
                            @{
                                title = "Alert"
                                value = "{alert_name}"
                                short = $true
                            },
                            @{
                                title = "Severity"
                                value = "{severity}"
                                short = $true
                            },
                            @{
                                title = "Description"
                                value = "{description}"
                                short = $false
                            }
                        )
                    }
                )
            }
        }
        teams = @{
            name = "Microsoft Teams Webhook"
            url = "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"
            description = "Teams channel notifications for OTel alerts"
            headers = @{
                "Content-Type" = "application/json"
            }
            payload_template = @{
                "@type" = "MessageCard"
                "@context" = "http://schema.org/extensions"
                themeColor = "FF0000"
                summary = "OTel Alert: {alert_name}"
                sections = @(
                    @{
                        activityTitle = "🚨 OTel Alert"
                        activitySubtitle = "{alert_name}"
                        facts = @(
                            @{
                                name = "Severity"
                                value = "{severity}"
                            },
                            @{
                                name = "Description"
                                value = "{description}"
                            }
                        )
                    }
                )
            }
        }
        discord = @{
            name = "Discord Webhook"
            url = "https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
            description = "Discord channel notifications for OTel alerts"
            headers = @{
                "Content-Type" = "application/json"
            }
            payload_template = @{
                content = "🚨 **OTel Alert: {alert_name}**"
                embeds = @(
                    @{
                        title = "Alert Details"
                        color = 15158332
                        fields = @(
                            @{
                                name = "Severity"
                                value = "{severity}"
                                inline = $true
                            },
                            @{
                                name = "Description"
                                value = "{description}"
                                inline = $false
                            }
                        )
                        timestamp = "{timestamp}"
                    }
                )
            }
        }
    }
    
    # Save example configurations
    $ExampleConfigs | ConvertTo-Json -Depth 5 | Set-Content -Path "$ArtifactsDir/webhook-examples.json"
    Write-Host "📁 Example webhook configurations saved to: $ArtifactsDir/webhook-examples.json" -ForegroundColor Yellow
    
    # Display setup instructions
    Write-Host "`n📋 Webhook Setup Instructions:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "1. Choose your notification platform (Slack, Teams, Discord, etc.)" -ForegroundColor White
    Write-Host "2. Create a webhook URL in your platform" -ForegroundColor White
    Write-Host "3. Set environment variables:" -ForegroundColor White
    Write-Host "   `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Gray
    Write-Host "   `$env:ALERT_CHANNEL = 'your-channel-name'" -ForegroundColor Gray
    Write-Host "4. Re-run this script with the webhook URL" -ForegroundColor White
    
    # Create webhook test script
    $WebhookTestScript = @"
# Webhook Test Script
# Test webhook notifications for OTel alerts

param(
    [string]`$WebhookUrl = `$env:ALERT_WEBHOOK_URL,
    [string]`$Channel = `$env:ALERT_CHANNEL
)

if (-not `$WebhookUrl) {
    Write-Host "❌ No webhook URL provided. Set ALERT_WEBHOOK_URL environment variable." -ForegroundColor Red
    exit 1
}

Write-Host "🧪 Testing webhook notification..." -ForegroundColor Yellow

# Test payload
`$TestPayload = @{
    text = "🧪 Test notification from OTel Observability Pipeline"
    attachments = @(
        @{
            color = "good"
            fields = @(
                @{
                    title = "Test"
                    value = "Webhook notification test"
                    short = `$true
                },
                @{
                    title = "Timestamp"
                    value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    short = `$true
                }
            )
        }
    )
} | ConvertTo-Json -Depth 3

try {
    `$Response = Invoke-RestMethod -Uri `$WebhookUrl -Method Post -Body `$TestPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Webhook test successful!" -ForegroundColor Green
    Write-Host "   Response: `$Response" -ForegroundColor Gray
} catch {
    Write-Host "❌ Webhook test failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    $WebhookTestScript | Set-Content -Path "scripts/test-webhook.ps1"
    Write-Host "📝 Webhook test script created: scripts/test-webhook.ps1" -ForegroundColor Yellow
    
    exit 0
}

# Check SigNoz connectivity
Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz is healthy: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test webhook if requested
if ($TestWebhook) {
    Write-Host "`n🧪 Testing webhook notification..." -ForegroundColor Yellow
    
    $TestPayload = @{
        text = "🧪 Test notification from OTel Observability Pipeline"
        attachments = @(
            @{
                color = "good"
                fields = @(
                    @{
                        title = "Test"
                        value = "Webhook notification test"
                        short = $true
                    },
                    @{
                        title = "Timestamp"
                        value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        short = $true
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        $Response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $TestPayload -ContentType "application/json" -TimeoutSec 10
        Write-Host "✅ Webhook test successful!" -ForegroundColor Green
        Write-Host "   Response: $Response" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Create webhook notification configuration
Write-Host "`n🔧 Creating webhook notification configuration..." -ForegroundColor Yellow

$WebhookConfig = @{
    name = "OTel Alert Webhook"
    url = $WebhookUrl
    channel = $Channel
    description = "Webhook notifications for OTel observability alerts"
    headers = @{
        "Content-Type" = "application/json"
    }
    payload_template = @{
        text = "🚨 OTel Alert: {alert_name}"
        attachments = @(
            @{
                color = "danger"
                fields = @(
                    @{
                        title = "Alert"
                        value = "{alert_name}"
                        short = $true
                    },
                    @{
                        title = "Severity"
                        value = "{severity}"
                        short = $true
                    },
                    @{
                        title = "Description"
                        value = "{description}"
                        short = $false
                    },
                    @{
                        title = "Timestamp"
                        value = "{timestamp}"
                        short = $true
                    }
                )
            }
        )
    }
    alerts = @(
        @{
            name = "Queue Utilization High"
            severity = "critical"
            description = "Queue utilization above 70% for 10 minutes"
        },
        @{
            name = "Send Failure Rate High"
            severity = "critical"
            description = "Send failure rate above 5%"
        },
        @{
            name = "Trace Time-to-Use High"
            severity = "critical"
            description = "p95 trace time-to-use above 8 seconds"
        },
        @{
            name = "Canary Log Absence"
            severity = "warning"
            description = "No canary logs for 5 minutes"
        },
        @{
            name = "Collector Memory High"
            severity = "warning"
            description = "Collector memory usage above 80%"
        }
    )
}

# Save webhook configuration
$WebhookConfig | ConvertTo-Json -Depth 5 | Set-Content -Path "$ArtifactsDir/webhook-config.json"
Write-Host "📁 Webhook configuration saved to: $ArtifactsDir/webhook-config.json" -ForegroundColor Yellow

# Create notification script
Write-Host "`n📝 Creating notification script..." -ForegroundColor Yellow

$NotificationScript = @"
# OTel Alert Notification Script
# Send webhook notifications for OTel alerts

param(
    [string]`$AlertName,
    [string]`$Severity,
    [string]`$Description,
    [string]`$WebhookUrl = `$env:ALERT_WEBHOOK_URL,
    [string]`$Channel = `$env:ALERT_CHANNEL
)

if (-not `$WebhookUrl) {
    Write-Host "❌ No webhook URL configured. Set ALERT_WEBHOOK_URL environment variable." -ForegroundColor Red
    exit 1
}

# Determine color based on severity
`$Color = switch (`$Severity.ToLower()) {
    "critical" { "danger" }
    "warning" { "warning" }
    default { "good" }
}

# Create notification payload
`$Payload = @{
    text = "🚨 OTel Alert: `$AlertName"
    attachments = @(
        @{
            color = `$Color
            fields = @(
                @{
                    title = "Alert"
                    value = `$AlertName
                    short = `$true
                },
                @{
                    title = "Severity"
                    value = `$Severity
                    short = `$true
                },
                @{
                    title = "Description"
                    value = `$Description
                    short = `$false
                },
                @{
                    title = "Timestamp"
                    value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    short = `$true
                }
            )
        }
    )
} | ConvertTo-Json -Depth 3

try {
    `$Response = Invoke-RestMethod -Uri `$WebhookUrl -Method Post -Body `$Payload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Alert notification sent successfully!" -ForegroundColor Green
    Write-Host "   Alert: `$AlertName" -ForegroundColor Gray
    Write-Host "   Severity: `$Severity" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to send alert notification: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}
"@

$NotificationScript | Set-Content -Path "scripts/send-alert-notification.ps1"
Write-Host "📝 Notification script created: scripts/send-alert-notification.ps1" -ForegroundColor Yellow

# Create alert integration script
Write-Host "`n🔗 Creating alert integration script..." -ForegroundColor Yellow

$AlertIntegrationScript = @"
# OTel Alert Integration Script
# Integrate webhook notifications with SigNoz alerts

param(
    [string]`$SigNozUrl = "http://localhost:8080",
    [string]`$WebhookUrl = `$env:ALERT_WEBHOOK_URL
)

if (-not `$WebhookUrl) {
    Write-Host "❌ No webhook URL configured. Set ALERT_WEBHOOK_URL environment variable." -ForegroundColor Red
    exit 1
}

Write-Host "🔗 Integrating webhook notifications with SigNoz alerts..." -ForegroundColor Yellow

# Alert configurations with webhook integration
`$AlertConfigs = @(
    @{
        alert = "Queue Utilization High"
        expr = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity > 0.7"
        for = "10m"
        labels = @{
            severity = "critical"
            service = "otel-collector"
            webhook_url = `$WebhookUrl
        }
        annotations = @{
            summary = "Queue utilization above 70%"
            description = "Queue utilization is above 70% for 10 minutes. Check collector performance and batch processing."
        }
    },
    @{
        alert = "Send Failure Rate High"
        expr = "rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m]) > 0.05"
        for = "5m"
        labels = @{
            severity = "critical"
            service = "otel-collector"
            webhook_url = `$WebhookUrl
        }
        annotations = @{
            summary = "Send failure rate above 5%"
            description = "Send failure rate is above 5%. Check exporter connectivity and SigNoz health."
        }
    },
    @{
        alert = "Trace Time-to-Use High"
        expr = "histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m])) > 8"
        for = "5m"
        labels = @{
            severity = "critical"
            service = "otel-collector"
            webhook_url = `$WebhookUrl
        }
        annotations = @{
            summary = "p95 trace time-to-use above 8 seconds"
            description = "p95 trace time-to-use is above 8 seconds. Check batch processor configuration and network latency."
        }
    }
)

# Deploy alerts with webhook integration
foreach (`$Alert in `$AlertConfigs) {
    Write-Host "📋 Deploying alert: `$(`$Alert.alert)" -ForegroundColor Yellow
    
    try {
        `$AlertResponse = Invoke-RestMethod -Uri "`$SigNozUrl/api/v1/rules" -Method Post -Body (`$Alert | ConvertTo-Json -Depth 5) -ContentType "application/json" -TimeoutSec 30
        Write-Host "  ✅ Alert deployed successfully" -ForegroundColor Green
        Write-Host "     Rule ID: `$(`$AlertResponse.rule_id)" -ForegroundColor Gray
    } catch {
        Write-Host "  ❌ Alert deployment failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Webhook notification integration complete!" -ForegroundColor Green
Write-Host "🔔 Alerts will now send notifications to: `$WebhookUrl" -ForegroundColor Blue
"@

$AlertIntegrationScript | Set-Content -Path "scripts/integrate-webhook-alerts.ps1"
Write-Host "📝 Alert integration script created: scripts/integrate-webhook-alerts.ps1" -ForegroundColor Yellow

# ECRR Report
$ECRRReport = @"
# Webhook Notification Setup - ECRR Report
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Webhook URL: $(if ($WebhookUrl) { "Configured" } else { "Not configured" })
- Channel: $(if ($Channel) { $Channel } else { "Default" })
- SigNoz connectivity: ✅ Healthy
- Test webhook: $(if ($TestWebhook) { "Completed" } else { "Skipped" })

## Clean
- Created webhook notification configuration
- Generated notification and integration scripts
- Set up alert templates for OTel monitoring

## Report
- Configuration: $ArtifactsDir/webhook-config.json
- Notification script: scripts/send-alert-notification.ps1
- Integration script: scripts/integrate-webhook-alerts.ps1
- Test script: scripts/test-webhook.ps1
- Example configs: $ArtifactsDir/webhook-examples.json

## Role
Cursor-Local: Observability Copilot - Webhook notification setup and alert integration
"@

$ECRRReport | Set-Content -Path "$ArtifactsDir/webhook-setup-ecrr.md"

Write-Host "`n📁 ECRR Report saved to: $ArtifactsDir/webhook-setup-ecrr.md" -ForegroundColor Magenta

Write-Host "`n🎉 Webhook Notification Setup Complete!" -ForegroundColor Green
Write-Host "🔔 Webhook URL: $WebhookUrl" -ForegroundColor Blue
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Test webhook: pwsh -File scripts/test-webhook.ps1" -ForegroundColor White
Write-Host "   2. Integrate alerts: pwsh -File scripts/integrate-webhook-alerts.ps1" -ForegroundColor White
Write-Host "   3. Send test alert: pwsh -File scripts/send-alert-notification.ps1 -AlertName 'Test Alert' -Severity 'warning' -Description 'Test notification'" -ForegroundColor White
