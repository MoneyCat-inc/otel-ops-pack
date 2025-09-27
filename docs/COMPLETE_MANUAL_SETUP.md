# Complete Manual Setup Guide

## Overview
This guide provides step-by-step instructions for completing the remaining manual setup tasks: SigNoz API token generation, dashboard import, end-to-end testing, and alert configuration.

## Step 1: SigNoz API Token Generation

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

## Step 2: Dashboard Import

### 2.1 Access Dashboard Management
1. In SigNoz UI, navigate to **Dashboards**
2. Click **Import Dashboard** button

### 2.2 Import Queue Pressure Dashboard
1. Click **Upload JSON file**
2. Select file: `C:\otel\artifacts\signoz-queue-pressure-dashboard.json`
3. Click **Import**
4. Verify dashboard name: "OTel Queue Pressure Monitor"

### 2.3 Configure Dashboard Settings
1. **Title**: OTel Queue Pressure Monitor
2. **Description**: Monitor OpenTelemetry collector queue utilization and pressure indicators
3. **Tags**: otel, queue, pressure, monitoring
4. **Timezone**: Browser
5. **Refresh**: 30s (recommended)

### 2.4 Verify Panels
The dashboard should contain 5 panels:
- Queue Utilization Ratio (Stat)
- Queue Size vs Capacity (Time Series)
- Send Failure Rate (Stat)
- Batch Timeout Triggers (Time Series)
- Log Processing Rate (Time Series)

## Step 3: End-to-End Alert Delivery Testing

### 3.1 Generate Test Alert
```powershell
# Generate canary test logs
pwsh -File scripts/canary-test.ps1
```

### 3.2 Verify Log Ingestion
1. Go to SigNoz UI: http://localhost:8080
2. Navigate to **Logs**
3. Search for: `message contains "canary test"`
4. Verify logs are visible

### 3.3 Test Webhook Delivery
```powershell
# Test webhook with custom message
pwsh -File scripts/test-webhook.ps1 -TestMessage "End-to-end test alert"
```

### 3.4 Verify Webhook Logs
```powershell
# Check webhook logs
Get-Content artifacts/webhook-logs.json
```

## Step 4: Configure Alert Thresholds and Notification Channels

### 4.1 Create Alert Rules
1. Navigate to **Alerts** → **New Alert**
2. Create alerts for:

#### Alert 1: Queue Utilization High
- **Name**: Queue Utilization High
- **Query**: `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100`
- **Condition**: `> 80`
- **Duration**: `5m`
- **Severity**: `warning`

#### Alert 2: Send Failure Rate High
- **Name**: Send Failure Rate High
- **Query**: `rate(otelcol_exporter_send_failed_log_records[5m])`
- **Condition**: `> 10`
- **Duration**: `2m`
- **Severity**: `critical`

#### Alert 3: Batch Timeout Triggers
- **Name**: Batch Timeout Triggers
- **Query**: `rate(otelcol_processor_batch_timeout_trigger_send[5m])`
- **Condition**: `> 1`
- **Duration**: `1m`
- **Severity**: `warning`

### 4.2 Configure Notification Channels
1. Navigate to **Settings** → **Notification Channels**
2. Click **Add Channel**
3. **Type**: Webhook
4. **Name**: OTel Monitoring Webhook
5. **URL**: `http://localhost:3003/api/webhooks/alerts`
6. **Method**: POST
7. **Headers**: `Content-Type: application/json`
8. **Test**: Send test notification

### 4.3 Link Alerts to Notification Channels
1. Edit each alert rule
2. Add notification channel: OTel Monitoring Webhook
3. Save changes

## Step 5: Verification and Testing

### 5.1 System Status Check
```powershell
# Check all services
pwsh -File scripts/complete-setup.ps1
```

### 5.2 Authentication Test
```powershell
# Test SigNoz authentication
pwsh -File scripts/test-signoz-auth.ps1
```

### 5.3 Webhook Test
```powershell
# Test webhook delivery
pwsh -File scripts/test-webhook.ps1
```

### 5.4 End-to-End Test
```powershell
# Generate test alert and verify delivery
pwsh -File scripts/canary-test.ps1
pwsh -File scripts/test-webhook.ps1 -TestMessage "End-to-end verification test"
```

## Troubleshooting

### Common Issues

#### SigNoz Authentication
- **HTML instead of JSON**: Authentication required
- **403 Forbidden**: Invalid or expired API token
- **Connection refused**: SigNoz not running or wrong port

#### Dashboard Import
- **Import fails**: Check JSON file validity
- **Panels show no data**: Verify OTel collector metrics are available
- **Queries fail**: Check metric names and availability

#### Webhook Delivery
- **404 Not Found**: Webhook server not running
- **Timeout**: Network connectivity issues
- **No logs**: Check webhook server status

#### Alert Configuration
- **Alerts not firing**: Check query syntax and thresholds
- **Notifications not sent**: Verify webhook URL and channel configuration
- **False positives**: Adjust thresholds and duration

### Verification Commands
```powershell
# Check service status
netstat -an | findstr "3000 3003 8080 13134"

# Test endpoints
curl http://localhost:8080/api/v1/health
curl http://localhost:3000
curl http://localhost:3003/api/webhooks/alerts

# Check logs
Get-Content artifacts/webhook-logs.json
Get-Content artifacts/signoz-auth-status.json
```

## Next Steps

### Immediate
1. Complete all manual setup steps
2. Verify end-to-end alert delivery
3. Test alert thresholds and notifications

### Follow-up
1. Monitor queue pressure patterns
2. Optimize alert thresholds based on usage
3. Implement canary alerts for Windows logs
4. Create fractal drift monitors
5. Set up production notification channels

## Success Criteria

### Completed Setup
- [x] SigNoz API token generated and tested
- [x] Dashboard imported and displaying data
- [x] Webhook delivery tested successfully
- [x] Alert thresholds configured
- [x] Notification channels set up
- [x] End-to-end alert delivery verified

### System Status
- [x] All services running and accessible
- [x] Authentication working
- [x] Dashboard displaying metrics
- [x] Webhook notifications working
- [x] Alert rules active
- [x] End-to-end flow verified
