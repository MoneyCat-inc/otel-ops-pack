# SigNoz Authentication Setup Guide

## Overview
SigNoz requires authentication for API access. This guide covers manual setup steps and automated configuration scripts.

## Manual Setup Steps

### 1. Access SigNoz UI
- Open browser: http://localhost:8080
- Complete initial setup if prompted
- Create admin account or use default credentials

### 2. Generate API Token
1. Navigate to **Settings** → **API Keys**
2. Click **Generate New Key**
3. Name: `otel-monitoring`
4. Permissions: `read:logs`, `read:metrics`, `read:traces`
5. Copy the generated token

### 3. Configure Environment Variables
```powershell
# Set API token for SigNoz authentication
$env:SIGNOZ_API_TOKEN = "your-api-token-here"

# Set webhook URL for alerts
$env:ALERT_WEBHOOK_URL = "your-webhook-url"

# Optional: Set SigNoz base URL
$env:SIGNOZ_BASE_URL = "http://localhost:8080"
```

### 4. Test Authentication
```powershell
# Test API access with token
pwsh -File scripts/test-signoz-auth.ps1
```

## Dashboard Import

### 1. Access Dashboard Management
- Navigate to **Dashboards** in SigNoz UI
- Click **Import Dashboard**

### 2. Import Queue Pressure Dashboard
- Use file: `artifacts/signoz-queue-pressure-dashboard.json`
- Click **Import**
- Verify panels are created correctly

### 3. Configure Alerts
- Navigate to **Alerts** → **New Alert**
- Use queries from `docs/QUERY_RECIPES.md`
- Set thresholds and notification channels

## Webhook Configuration

### 1. Set Webhook URL
```powershell
# Example webhook URLs
$env:ALERT_WEBHOOK_URL = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
$env:ALERT_WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
$env:ALERT_WEBHOOK_URL = "http://localhost:3003/api/webhooks/alerts"
```

### 2. Test Webhook
```powershell
# Test webhook delivery
pwsh -File scripts/test-webhook.ps1
```

## Troubleshooting

### Common Issues
1. **HTML instead of JSON**: Authentication required
2. **403 Forbidden**: Invalid or expired API token
3. **Connection refused**: SigNoz not running or wrong port
4. **Dashboard import fails**: Invalid JSON or missing permissions

### Verification Commands
```powershell
# Check SigNoz health
curl http://localhost:8080/api/v1/health

# Test API with token
curl -H "Authorization: Bearer $env:SIGNOZ_API_TOKEN" http://localhost:8080/api/v1/logs

# Check webhook endpoint
curl -X POST $env:ALERT_WEBHOOK_URL -H "Content-Type: application/json" -d '{"test": true}'
```

## Next Steps
1. Complete manual authentication setup
2. Import dashboard configuration
3. Configure alert thresholds
4. Test webhook notifications
5. Verify Resonai startup on port 3003