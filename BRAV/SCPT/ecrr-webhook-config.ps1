# ECRR Webhook Configuration Script
# Sets up Slack and Teams notification channels for ECRR compliance monitoring

param(
    [string]$SlackWebhookUrl = "",
    [string]$TeamsWebhookUrl = "",
    [string]$DiscordWebhookUrl = "",
    [string]$ConfigPath = "config/ecrr-monitoring.json",
    [switch]$Test,
    [switch]$List
)

# Webhook Configuration Templates
$WEBHOOK_TEMPLATES = @{
    "Slack" = @{
        "Name" = "Slack"
        "Description" = "Slack channel notifications"
        "Template" = @{
            "text" = "ECRR Compliance Alert"
            "attachments" = @(
                @{
                    "color" = "danger"
                    "fields" = @(
                        @{
                            "title" = "Status"
                            "value" = "{status}"
                            "short" = $true
                        },
                        @{
                            "title" = "Overall Score"
                            "value" = "{score}%"
                            "short" = $true
                        },
                        @{
                            "title" = "Regression"
                            "value" = "{regression}%"
                            "short" = $true
                        },
                        @{
                            "title" = "Branch"
                            "value" = "{branch}"
                            "short" = $true
                        },
                        @{
                            "title" = "Commit"
                            "value" = "{commit}"
                            "short" = $true
                        },
                        @{
                            "title" = "Message"
                            "value" = "{message}"
                            "short" = $false
                        }
                    )
                    "footer" = "ECRR Compliance Monitoring"
                    "ts" = "{timestamp}"
                }
            )
        }
    }
    "Teams" = @{
        "Name" = "Microsoft Teams"
        "Description" = "Teams channel notifications"
        "Template" = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "themeColor" = "FF0000"
            "summary" = "ECRR Compliance Alert"
            "sections" = @(
                @{
                    "activityTitle" = "ECRR Compliance Check"
                    "activitySubtitle" = "Status: {status}"
                    "facts" = @(
                        @{
                            "name" = "Overall Score"
                            "value" = "{score}%"
                        },
                        @{
                            "name" = "Regression"
                            "value" = "{regression}%"
                        },
                        @{
                            "name" = "Branch"
                            "value" = "{branch}"
                        },
                        @{
                            "name" = "Commit"
                            "value" = "{commit}"
                        }
                    )
                    "markdown" = $true
                }
            )
        }
    }
    "Discord" = @{
        "Name" = "Discord"
        "Description" = "Discord channel notifications"
        "Template" = @{
            "content" = "🔍 **ECRR Compliance Alert**"
            "embeds" = @(
                @{
                    "title" = "Compliance Check Results"
                    "color" = 16711680
                    "fields" = @(
                        @{
                            "name" = "Status"
                            "value" = "{status}"
                            "inline" = $true
                        },
                        @{
                            "name" = "Overall Score"
                            "value" = "{score}%"
                            "inline" = $true
                        },
                        @{
                            "name" = "Regression"
                            "value" = "{regression}%"
                            "inline" = $true
                        },
                        @{
                            "name" = "Branch"
                            "value" = "{branch}"
                            "inline" = $true
                        },
                        @{
                            "name" = "Commit"
                            "value" = "{commit}"
                            "inline" = $true
                        }
                    )
                    "footer" = @{
                        "text" = "ECRR Compliance Monitoring"
                    }
                    "timestamp" = "{timestamp}"
                }
            )
        }
    }
}

function Test-WebhookConnection {
    param(
        [string]$WebhookUrl,
        [string]$ServiceName
    )
    
    if ($WebhookUrl -eq "") {
        Write-Host "⚠️ No $ServiceName webhook URL provided" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $testPayload = @{
            "text" = "🔍 ECRR Compliance Monitoring - Test Connection"
            "attachments" = @(
                @{
                    "color" = "good"
                    "fields" = @(
                        @{
                            "title" = "Service"
                            "value" = $ServiceName
                            "short" = $true
                        },
                        @{
                            "title" = "Status"
                            "value" = "Connection Test Successful"
                            "short" = $true
                        },
                        @{
                            "title" = "Timestamp"
                            "value" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                            "short" = $false
                        }
                    )
                    "footer" = "ECRR Compliance Monitoring"
                }
            )
        }
        
        $jsonPayload = $testPayload | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        
        Write-Host "✅ $ServiceName webhook connection test successful" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ $ServiceName webhook connection test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Update-MonitoringConfig {
    param(
        [string]$ConfigPath,
        [hashtable]$WebhookConfigs
    )
    
    Write-Host "🔧 Updating ECRR monitoring configuration..." -ForegroundColor Cyan
    
    # Load existing configuration
    $config = if (Test-Path $ConfigPath) {
        Get-Content $ConfigPath | ConvertFrom-Json
    } else {
        @{
            "Thresholds" = @{
                "Critical" = 50
                "Warning" = 70
                "Target" = 80
                "Excellent" = 90
            }
            "Alerts" = @{
                "Regression_Threshold" = 5
                "Critical_Threshold" = 50
                "Notification_Channels" = @("console", "file")
            }
        }
    }
    
    # Add webhook configurations
    $config.Webhooks = $WebhookConfigs
    
    # Update notification channels
    $channels = @("console", "file")
    foreach ($webhook in $WebhookConfigs.Keys) {
        if ($WebhookConfigs[$webhook].Url -ne "") {
            $channels += $webhook.ToLower()
        }
    }
    $config.Alerts.Notification_Channels = $channels
    
    # Save updated configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    Write-Host "✅ Configuration updated: $ConfigPath" -ForegroundColor Green
    
    return $config
}

function Send-TestNotification {
    param(
        [hashtable]$WebhookConfigs
    )
    
    Write-Host "📤 Sending test notifications..." -ForegroundColor Cyan
    
    $testData = @{
        "status" = "TEST"
        "score" = "85.5"
        "regression" = "2.1"
        "branch" = "main"
        "commit" = "abc1234"
        "message" = "This is a test notification from ECRR Compliance Monitoring"
        "timestamp" = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }
    
    foreach ($webhookName in $WebhookConfigs.Keys) {
        $webhook = $WebhookConfigs[$webhookName]
        if ($webhook.Url -eq "") {
            continue
        }
        
        Write-Host "📤 Testing $webhookName notification..." -ForegroundColor Cyan
        
        try {
            $template = $WEBHOOK_TEMPLATES[$webhookName].Template
            $payload = $template | ConvertTo-Json -Depth 10
            
            # Replace placeholders
            foreach ($key in $testData.Keys) {
                $payload = $payload -replace "\{$key\}", $testData[$key]
            }
            
            $response = Invoke-RestMethod -Uri $webhook.Url -Method Post -Body $payload -ContentType "application/json"
            Write-Host "✅ $webhookName test notification sent successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ $webhookName test notification failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Show-WebhookInstructions {
    Write-Host "📋 Webhook Setup Instructions" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🔵 Slack Setup:" -ForegroundColor Blue
    Write-Host "1. Go to your Slack workspace"
    Write-Host "2. Navigate to Apps > Incoming Webhooks"
    Write-Host "3. Click 'Add to Slack'"
    Write-Host "4. Choose the channel for notifications"
    Write-Host "5. Copy the webhook URL"
    Write-Host "6. Run: pwsh -File scripts/ecrr-webhook-config.ps1 -SlackWebhookUrl 'YOUR_WEBHOOK_URL'"
    Write-Host ""
    
    Write-Host "🔵 Microsoft Teams Setup:" -ForegroundColor Blue
    Write-Host "1. Go to your Teams channel"
    Write-Host "2. Click the '...' menu > Connectors"
    Write-Host "3. Find 'Incoming Webhook' and click Configure"
    Write-Host "4. Enter a name and upload an image (optional)"
    Write-Host "5. Click Create and copy the webhook URL"
    Write-Host "6. Run: pwsh -File scripts/ecrr-webhook-config.ps1 -TeamsWebhookUrl 'YOUR_WEBHOOK_URL'"
    Write-Host ""
    
    Write-Host "🔵 Discord Setup:" -ForegroundColor Blue
    Write-Host "1. Go to your Discord server"
    Write-Host "2. Right-click on the channel > Edit Channel"
    Write-Host "3. Go to Integrations > Webhooks"
    Write-Host "4. Click 'Create Webhook'"
    Write-Host "5. Copy the webhook URL"
    Write-Host "6. Run: pwsh -File scripts/ecrr-webhook-config.ps1 -DiscordWebhookUrl 'YOUR_WEBHOOK_URL'"
    Write-Host ""
    
    Write-Host "🔵 GitHub Secrets Setup:" -ForegroundColor Blue
    Write-Host "1. Go to your GitHub repository"
    Write-Host "2. Navigate to Settings > Secrets and variables > Actions"
    Write-Host "3. Click 'New repository secret'"
    Write-Host "4. Name: SLACK_WEBHOOK_URL"
    Write-Host "5. Value: Your Slack webhook URL"
    Write-Host "6. Repeat for TEAMS_WEBHOOK_URL and DISCORD_WEBHOOK_URL if needed"
    Write-Host ""
}

# Main execution
Write-Host "🔧 ECRR Webhook Configuration Tool" -ForegroundColor Cyan
Write-Host ""

if ($List) {
    Show-WebhookInstructions
    exit 0
}

# Collect webhook configurations
$webhookConfigs = @{}

if ($SlackWebhookUrl -ne "") {
    $webhookConfigs["Slack"] = @{
        "Url" = $SlackWebhookUrl
        "Enabled" = $true
        "Template" = "Slack"
    }
}

if ($TeamsWebhookUrl -ne "") {
    $webhookConfigs["Teams"] = @{
        "Url" = $TeamsWebhookUrl
        "Enabled" = $true
        "Template" = "Teams"
    }
}

if ($DiscordWebhookUrl -ne "") {
    $webhookConfigs["Discord"] = @{
        "Url" = $DiscordWebhookUrl
        "Enabled" = $true
        "Template" = "Discord"
    }
}

if ($webhookConfigs.Count -eq 0) {
    Write-Host "⚠️ No webhook URLs provided. Use -List to see setup instructions." -ForegroundColor Yellow
    Show-WebhookInstructions
    exit 1
}

# Test webhook connections
Write-Host "🔍 Testing webhook connections..." -ForegroundColor Cyan
foreach ($webhookName in $webhookConfigs.Keys) {
    $webhook = $webhookConfigs[$webhookName]
    Test-WebhookConnection -WebhookUrl $webhook.Url -ServiceName $webhookName
}

# Update configuration
$config = Update-MonitoringConfig -ConfigPath $ConfigPath -WebhookConfigs $webhookConfigs

# Send test notifications if requested
if ($Test) {
    Send-TestNotification -WebhookConfigs $webhookConfigs
}

Write-Host ""
Write-Host "✅ ECRR Webhook Configuration Complete" -ForegroundColor Green
Write-Host "📋 Configured webhooks:" -ForegroundColor Cyan
foreach ($webhookName in $webhookConfigs.Keys) {
    Write-Host "   - $webhookName`: $($webhookConfigs[$webhookName].Url)" -ForegroundColor Green
}

Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Add webhook URLs to GitHub repository secrets"
Write-Host "2. Test the CI/CD pipeline with a pull request"
Write-Host "3. Verify notifications are received in your channels"
Write-Host "4. Run: pwsh -File scripts/ecrr-webhook-config.ps1 -Test to send test notifications"
