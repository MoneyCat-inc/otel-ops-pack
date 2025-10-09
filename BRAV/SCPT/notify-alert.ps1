# Alert Notification Script for SSOT Production Monitoring
# Sends webhook notifications to Slack/Teams when health thresholds are breached

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertType,  # "health", "freshness", "error_rate", "integration"
    
    [Parameter(Mandatory=$true)]
    [string]$AlertLevel,  # "critical", "warning", "info"
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [Parameter(Mandatory=$false)]
    [string]$HealthScore,
    
    [Parameter(Mandatory=$false)]
    [string]$FreshnessMinutes,
    
    [Parameter(Mandatory=$false)]
    [string]$ErrorRate,
    
    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$Channel,
    
    [switch]$DryRun
)

# Set UTF-8 encoding
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🚨 SSOT Alert Notification" -ForegroundColor Red
Write-Host "=========================" -ForegroundColor Red

# Get environment variables if not provided
if (-not $WebhookUrl) {
    $WebhookUrl = $env:ALERT_WEBHOOK_URL
}

if (-not $Channel) {
    $Channel = $env:ALERT_CHANNEL
}

# Validate required parameters
if (-not $WebhookUrl) {
    Write-Host "❌ ERROR: Webhook URL not provided and ALERT_WEBHOOK_URL not set" -ForegroundColor Red
    Write-Host "   Set environment variable: `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Yellow
    exit 1
}

if (-not $Channel) {
    $Channel = "#ssot-alerts"  # Default channel
    Write-Host "⚠️  WARNING: Using default channel: $Channel" -ForegroundColor Yellow
}

# Determine alert color and emoji
$alertConfig = switch ($AlertLevel) {
    "critical" { @{ color = "#FF0000"; emoji = "🔴" } }
    "warning"  { @{ color = "#FFA500"; emoji = "🟡" } }
    "info"     { @{ color = "#0000FF"; emoji = "🔵" } }
    default    { @{ color = "#808080"; emoji = "⚪" } }
}

# Build alert payload
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$hostname = $env:COMPUTERNAME ?? "unknown-host"

# Create rich payload based on alert type
$payload = switch ($AlertType) {
    "health" {
        @{
            text = "$($alertConfig.emoji) SSOT Health Alert"
            blocks = @(
                @{
                    type = "header"
                    text = @{
                        type = "plain_text"
                        text = "$($alertConfig.emoji) SSOT Health Alert"
                    }
                },
                @{
                    type = "section"
                    fields = @(
                        @{
                            type = "mrkdwn"
                            text = "*Level:* $AlertLevel"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Health Score:* $HealthScore%"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Host:* $hostname"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Time:* $timestamp"
                        }
                    )
                },
                @{
                    type = "section"
                    text = @{
                        type = "mrkdwn"
                        text = "*Message:* $Message"
                    }
                }
            )
        }
    }
    "freshness" {
        @{
            text = "$($alertConfig.emoji) SSOT Freshness Alert"
            blocks = @(
                @{
                    type = "header"
                    text = @{
                        type = "plain_text"
                        text = "$($alertConfig.emoji) SSOT Freshness Alert"
                    }
                },
                @{
                    type = "section"
                    fields = @(
                        @{
                            type = "mrkdwn"
                            text = "*Level:* $AlertLevel"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Freshness:* $FreshnessMinutes minutes"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Host:* $hostname"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Time:* $timestamp"
                        }
                    )
                },
                @{
                    type = "section"
                    text = @{
                        type = "mrkdwn"
                        text = "*Message:* $Message"
                    }
                }
            )
        }
    }
    "error_rate" {
        @{
            text = "$($alertConfig.emoji) SSOT Error Rate Alert"
            blocks = @(
                @{
                    type = "header"
                    text = @{
                        type = "plain_text"
                        text = "$($alertConfig.emoji) SSOT Error Rate Alert"
                    }
                },
                @{
                    type = "section"
                    fields = @(
                        @{
                            type = "mrkdwn"
                            text = "*Level:* $AlertLevel"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Error Rate:* $ErrorRate%"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Host:* $hostname"
                        },
                        @{
                            type = "mrkdwn"
                            text = "*Time:* $timestamp"
                        }
                    )
                },
                @{
                    type = "section"
                    text = @{
                        type = "mrkdwn"
                        text = "*Message:* $Message"
                    }
                }
            )
        }
    }
    default {
        @{
            text = "$($alertConfig.emoji) SSOT Alert: $Message"
            blocks = @(
                @{
                    type = "section"
                    text = @{
                        type = "mrkdwn"
                        text = "$($alertConfig.emoji) *$AlertType Alert*\n*Level:* $AlertLevel\n*Message:* $Message\n*Host:* $hostname\n*Time:* $timestamp"
                    }
                }
            )
        }
    }
}

# Add channel to payload
$payload.channel = $Channel

# Convert to JSON
$jsonPayload = $payload | ConvertTo-Json -Depth 10

Write-Host "📤 Sending alert notification..." -ForegroundColor Cyan
Write-Host "   Type: $AlertType" -ForegroundColor Cyan
Write-Host "   Level: $AlertLevel" -ForegroundColor Cyan
Write-Host "   Channel: $Channel" -ForegroundColor Cyan
Write-Host "   Webhook: $($WebhookUrl.Substring(0, [Math]::Min(50, $WebhookUrl.Length)))..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🧪 DRY RUN MODE - Would send:" -ForegroundColor Yellow
    Write-Host $jsonPayload -ForegroundColor Gray
    Write-Host "✅ DRY RUN COMPLETED" -ForegroundColor Green
    exit 0
}

# Send webhook notification
try {
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonPayload -Headers $headers -TimeoutSec 30
    
    Write-Host "✅ Alert notification sent successfully" -ForegroundColor Green
    Write-Host "   Response: $response" -ForegroundColor Green
    
    # Log the alert
    $logEntry = @{
        timestamp = $timestamp
        alert_type = $AlertType
        alert_level = $AlertLevel
        message = $Message
        health_score = $HealthScore
        freshness_minutes = $FreshnessMinutes
        error_rate = $ErrorRate
        channel = $Channel
        status = "sent"
        response = $response
    }
    
    $logPath = ".artifacts/alert-notifications.log"
    $logEntry | ConvertTo-Json -Compress | Out-File -FilePath $logPath -Append -Encoding UTF8
    
    Write-Host "📝 Alert logged to: $logPath" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ ERROR: Failed to send alert notification" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Log the failed alert
    $logEntry = @{
        timestamp = $timestamp
        alert_type = $AlertType
        alert_level = $AlertLevel
        message = $Message
        health_score = $HealthScore
        freshness_minutes = $FreshnessMinutes
        error_rate = $ErrorRate
        channel = $Channel
        status = "failed"
        error = $_.Exception.Message
    }
    
    $logPath = ".artifacts/alert-notifications.log"
    $logEntry | ConvertTo-Json -Compress | Out-File -FilePath $logPath -Append -Encoding UTF8
    
    exit 1
}

Write-Host "🎯 Alert notification completed" -ForegroundColor Green
