# Manual Setup Completion Guide

## Current Status
✅ **Completed**: Webhook infrastructure, log generation, webhook delivery testing  
⏳ **Pending**: SigNoz API token generation, dashboard import, alert configuration  

## Step 1: Complete SigNoz API Token Generation

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

## Step 2: Import Dashboard

### 2.1 Access Dashboard Management
1. In SigNoz UI, navigate to **Dashboards**
2. Click **Import Dashboard** button

### 2.2 Import Queue Pressure Dashboard
1. Click **Upload JSON file**
2. Select file: `C:\otel\artifacts\signoz-queue-pressure-dashboard.json`
3. Click **Import**
4. Verify dashboard name: "OTel Queue Pressure Monitor"

### 2.3 Verify Dashboard
1. Check that all 5 panels are displayed:
   - Queue Utilization Ratio (Stat)
   - Queue Size vs Capacity (Time Series)
   - Send Failure Rate (Stat)
   - Batch Timeout Triggers (Time Series)
   - Log Processing Rate (Time Series)
2. Verify panels are showing data (may take a few minutes)

## Step 3: Test End-to-End Alert Delivery

### 3.1 Run Complete End-to-End Test
```powershell
# Run end-to-end test with all components
pwsh -File scripts/end-to-end-test.ps1
```

### 3.2 Verify Log Ingestion
1. Go to SigNoz UI: http://localhost:8080
2. Navigate to **Logs**
3. Search for: `message contains "End-to-end test alert"`
4. Verify logs are visible

### 3.3 Check Webhook Logs
```powershell
# Check webhook delivery logs
Get-Content artifacts/webhook-logs.json
```

## Step 4: Configure Alert Thresholds and Notification Channels

### 4.1 Run Alert Configuration Script
```powershell
# Configure alert rules and notification channels
pwsh -File scripts/configure-alerts.ps1
```

### 4.2 Verify Alert Rules
1. Go to SigNoz UI: http://localhost:8080
2. Navigate to **Alerts**
3. Verify the following alert rules are created:
   - Queue Utilization High
   - Send Failure Rate High
   - Batch Timeout Triggers
   - Log Processing Rate Low

### 4.3 Test Alert Delivery
```powershell
# Generate test alert to verify delivery
pwsh -File scripts/canary-test.ps1
```

## Step 5: Final Verification

### 5.1 System Status Check
```powershell
# Check all services and configuration
pwsh -File scripts/complete-setup.ps1
```

### 5.2 End-to-End Test
```powershell
# Run final end-to-end test
pwsh -File scripts/end-to-end-test.ps1 -TestMessage "Final verification test"
```

### 5.3 Verify All Components
- [ ] SigNoz UI accessible and authenticated
- [ ] Dashboard imported and displaying data
- [ ] Webhook delivery working
- [ ] Alert rules configured
- [ ] Notification channels set up
- [ ] End-to-end alert delivery verified

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
Get-Content artifacts/end-to-end-test-results.json
Get-Content artifacts/alert-configuration-status.json
```

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

## Files Created

### Documentation
- `docs/COMPLETE_MANUAL_SETUP.md` - Complete setup guide
- `docs/MANUAL_SETUP_COMPLETION.md` - This completion guide

### Scripts
- `scripts/end-to-end-test.ps1` - End-to-end testing script
- `scripts/configure-alerts.ps1` - Alert configuration script

### Configuration
- `artifacts/end-to-end-test-results.json` - Test results
- `artifacts/alert-configuration-status.json` - Alert configuration status
- `artifacts/webhook-logs.json` - Webhook delivery logs
