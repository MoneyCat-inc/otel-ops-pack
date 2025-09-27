# Manual Setup Guide - Complete Configuration

## Overview
This guide provides step-by-step instructions for completing the manual setup of SigNoz authentication, webhook configuration, dashboard import, and Resonai startup.

## Step 1: SigNoz Authentication Setup

### 1.1 Access SigNoz UI
1. Open browser: http://localhost:8080
2. Complete initial setup if prompted
3. Create admin account or use default credentials

### 1.2 Generate API Token
1. Navigate to **Settings** → **API Keys** (or **User Settings** → **API Keys`)
2. Click **Generate New Key** or **Create API Key**
3. **Name**: `otel-monitoring`
4. **Permissions**: Select `read:logs`, `read:metrics`, `read:traces`
5. **Expiration**: Set to 1 year or no expiration
6. Click **Generate** or **Create**
7. **Copy the generated token** (you won't see it again)

### 1.3 Set Environment Variable
```powershell
# Set the API token
$env:SIGNOZ_API_TOKEN = "your-copied-api-token-here"

# Verify it's set
echo $env:SIGNOZ_API_TOKEN
```

### 1.4 Test Authentication
```powershell
# Test the authentication
pwsh -File scripts/test-signoz-auth.ps1
```

## Step 2: Webhook Configuration

### 2.1 Choose Webhook Service
Select one of the following options:

#### Option A: Slack Webhook
1. Go to https://api.slack.com/apps
2. Create new app or use existing
3. Go to **Incoming Webhooks** → **Activate Incoming Webhooks**
4. Click **Add New Webhook to Workspace**
5. Select channel and authorize
6. Copy the webhook URL

#### Option B: Discord Webhook
1. Go to Discord server settings
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Configure name and channel
5. Copy the webhook URL

#### Option C: Local Resonai Webhook
1. Start Resonai application (see Step 4)
2. Use: `http://localhost:3003/api/webhooks/alerts`

### 2.2 Set Webhook URL
```powershell
# Set the webhook URL (replace with your actual URL)
$env:ALERT_WEBHOOK_URL = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
# OR
$env:ALERT_WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
# OR
$env:ALERT_WEBHOOK_URL = "http://localhost:3003/api/webhooks/alerts"

# Verify it's set
echo $env:ALERT_WEBHOOK_URL
```

### 2.3 Test Webhook
```powershell
# Test webhook delivery
pwsh -File scripts/test-webhook.ps1
```

## Step 3: Dashboard Import

### 3.1 Access Dashboard Management
1. In SigNoz UI, navigate to **Dashboards**
2. Click **Import Dashboard** button

### 3.2 Import Queue Pressure Dashboard
1. Click **Upload JSON file**
2. Select file: `C:\otel\artifacts\signoz-queue-pressure-dashboard.json`
3. Click **Import**
4. Verify dashboard name: "OTel Queue Pressure Monitor"

### 3.3 Configure Dashboard Settings
1. **Title**: OTel Queue Pressure Monitor
2. **Description**: Monitor OpenTelemetry collector queue utilization and pressure indicators
3. **Tags**: otel, queue, pressure, monitoring
4. **Timezone**: Browser
5. **Refresh**: 30s (recommended)

### 3.4 Verify Panels
The dashboard should contain 5 panels:
- Queue Utilization Ratio (Stat)
- Queue Size vs Capacity (Time Series)
- Send Failure Rate (Stat)
- Batch Timeout Triggers (Time Series)
- Log Processing Rate (Time Series)

## Step 4: Resonai Startup

### 4.1 Locate Resonai Project
```powershell
# Check if Resonai project exists
Get-ChildItem -Path "C:\" -Recurse -Directory -Name "*resonai*" -ErrorAction SilentlyContinue
```

### 4.2 Navigate to Project Directory
```powershell
# Navigate to Resonai project (adjust path as needed)
cd "C:\path\to\resonai\project"
```

### 4.3 Install Dependencies
```powershell
# Install Node.js dependencies
npm install
```

### 4.4 Start Development Server
```powershell
# Start development server
npm run dev
# OR
npm start
# OR
node server.js
```

### 4.5 Verify Startup
```powershell
# In another terminal, verify startup
cd C:\otel
pwsh -File scripts/verify-resonai.ps1
```

## Step 5: Test Webhook Notifications

### 5.1 Test Webhook Delivery
```powershell
# Test webhook with test message
pwsh -File scripts/test-webhook.ps1 -TestMessage "OTel monitoring test alert"
```

### 5.2 Test Alert Delivery
```powershell
# Generate test alert
pwsh -File scripts/canary-test.ps1
```

### 5.3 Verify in SigNoz
1. Go to SigNoz UI: http://localhost:8080
2. Navigate to **Logs**
3. Search for: `message contains "canary test"`
4. Verify logs are visible

## Troubleshooting

### Common Issues

#### SigNoz Authentication
- **HTML instead of JSON**: Authentication required
- **403 Forbidden**: Invalid or expired API token
- **Connection refused**: SigNoz not running or wrong port

#### Webhook Delivery
- **404 Not Found**: Wrong webhook URL
- **401/403**: Invalid webhook token
- **Timeout**: Network connectivity issues

#### Dashboard Import
- **Import fails**: Invalid JSON file
- **No data**: OTel collector metrics not available
- **Queries fail**: Metric names not found

#### Resonai Startup
- **Port 3003 in use**: Kill existing process or use different port
- **Dependencies missing**: Run `npm install`
- **Permission denied**: Run as administrator

### Verification Commands
```powershell
# Check SigNoz health
curl http://localhost:8080/api/v1/health

# Check OTel collector metrics
curl http://localhost:8888/metrics | Select-String "otelcol_exporter_queue_size"

# Check port 3003
netstat -an | findstr "3003"

# Test webhook endpoint
curl -X POST $env:ALERT_WEBHOOK_URL -H "Content-Type: application/json" -d '{"test": true}'
```

## Next Steps
1. Complete all manual setup steps
2. Verify all components are working
3. Configure alert thresholds
4. Set up monitoring schedules
5. Test end-to-end alert delivery
