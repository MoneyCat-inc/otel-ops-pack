# Manual Setup Step-by-Step Guide
**Actor**: Cursor-Local (Observability Copilot)  
**Date**: 2025-09-27  
**Purpose**: Complete manual configuration for OTel observability pipeline  

## 🎯 Overview

This guide walks you through the remaining manual steps to complete the OTel observability pipeline setup. All automated components are ready - you just need to complete the manual configuration in the SigNoz UI.

## 📋 Prerequisites

- ✅ SigNoz UI accessible at http://localhost:8080
- ✅ OTel Collector running and processing logs
- ✅ Resonai application running on port 3000
- ✅ Webhook server running on port 3003
- ✅ Dashboard configuration file ready
- ✅ All verification scripts available

## 🔑 Step 1: Generate SigNoz API Token

### 1.1 Access SigNoz UI
1. Open your web browser
2. Navigate to: **http://localhost:8080**
3. Log in to SigNoz (if required)

### 1.2 Create API Token
1. Click on **Settings** in the left sidebar
2. Select **API Tokens** from the settings menu
3. Click **Create New Token**
4. Configure the token:
   - **Name**: `OTel Monitoring Token`
   - **Permissions**: Select **Read** permissions
   - **Expiration**: Set to your preference (or leave blank for no expiration)
5. Click **Create Token**
6. **Copy the generated token** - you'll need it for the next steps

### 1.3 Set Environment Variable
Open PowerShell and run:
```powershell
$env:SIGNOZ_API_TOKEN = 'your-copied-token-here'
```

**Verify the token is set:**
```powershell
echo $env:SIGNOZ_API_TOKEN
```

## 📊 Step 2: Import Dashboard

### 2.1 Access Dashboard Import
1. In SigNoz UI, click **Dashboards** in the left sidebar
2. Click **Import** button (usually at the top right)

### 2.2 Upload Dashboard Configuration
1. Click **Upload JSON file**
2. Navigate to: `C:\otel\artifacts\signoz-queue-pressure-dashboard.json`
3. Select the file and click **Open**

### 2.3 Configure Dashboard
1. **Dashboard Name**: `OTel Queue Pressure Monitoring`
2. **Folder**: Leave as default or create new folder
3. **Tags**: Add `otel`, `monitoring`, `queue-pressure`
4. Click **Import**

### 2.4 Verify Dashboard
1. The dashboard should appear in your dashboard list
2. Click on it to open
3. Verify all 5 panels are visible:
   - Queue Utilization Ratio
   - Queue Size vs Capacity
   - Send Failure Rate
   - Batch Timeout Triggers
   - Log Processing Rate

## 🚨 Step 3: Configure Alerts

### 3.1 Create Alert Rules
1. In SigNoz UI, click **Alerts** in the left sidebar
2. Select **Alert Rules**
3. Click **Create Alert Rule**

### 3.2 Queue Utilization Alert
1. **Alert Name**: `Queue Utilization High`
2. **Query**: 
   ```
   otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100
   ```
3. **Condition**: `> 80`
4. **Duration**: `5m`
5. **Severity**: `Warning`
6. **Description**: `Queue utilization exceeds 80% for 5 minutes`

### 3.3 Send Failure Rate Alert
1. **Alert Name**: `Send Failure Rate High`
2. **Query**: 
   ```
   rate(otelcol_exporter_send_failed_log_records_total[5m])
   ```
3. **Condition**: `> 0.05` (5% failure rate)
4. **Duration**: `2m`
5. **Severity**: `Critical`
6. **Description**: `Send failure rate exceeds 5% for 2 minutes`

### 3.4 Batch Timeout Alert
1. **Alert Name**: `Batch Timeout Triggers`
2. **Query**: 
   ```
   rate(otelcol_processor_batch_timeout_trigger_send_total[5m])
   ```
3. **Condition**: `> 0.1` (10 per minute)
4. **Duration**: `3m`
5. **Severity**: `Warning`
6. **Description**: `Batch timeout triggers exceed 10/min for 3 minutes`

### 3.5 Log Processing Rate Alert
1. **Alert Name**: `Log Processing Rate Low`
2. **Query**: 
   ```
   rate(otelcol_receiver_accepted_log_records_total[5m])
   ```
3. **Condition**: `< 1.67` (100 per minute)
4. **Duration**: `5m`
5. **Severity**: `Warning`
6. **Description**: `Log processing rate below 100/min for 5 minutes`

## 🔗 Step 4: Configure Notification Channels

### 4.1 Create Webhook Notification Channel
1. In SigNoz UI, go to **Alerts** → **Notification Channels**
2. Click **Create Notification Channel**
3. Select **Webhook** as the type

### 4.2 Configure Webhook
1. **Name**: `OTel Webhook Alerts`
2. **URL**: `http://localhost:3003/api/webhooks/alerts`
3. **Method**: `POST`
4. **Headers**: 
   ```
   Content-Type: application/json
   ```
5. **Body Template** (optional):
   ```json
   {
     "alert_name": "{{ .AlertName }}",
     "severity": "{{ .Severity }}",
     "message": "{{ .Message }}",
     "timestamp": "{{ .Timestamp }}",
     "source": "signoz-alerts"
   }
   ```
6. Click **Save**

### 4.3 Link Alerts to Notification Channel
1. Go back to **Alert Rules**
2. For each alert rule created above:
   - Click **Edit** on the alert
   - Scroll to **Notification Channels**
   - Select **OTel Webhook Alerts**
   - Click **Save**

## ✅ Step 5: Final Verification

### 5.1 Run Component Verification
```powershell
cd C:\otel
pwsh -File scripts/verify-all-components.ps1
```

### 5.2 Run End-to-End Test
```powershell
pwsh -File scripts/end-to-end-test.ps1
```

### 5.3 Test Alert Delivery
1. Generate test logs to trigger alerts:
   ```powershell
   pwsh -File scripts/canary-test.ps1
   ```
2. Check webhook server logs:
   ```powershell
   Get-Content artifacts/webhook-logs.json | Select-Object -Last 10
   ```
3. Verify alerts in SigNoz UI:
   - Go to **Alerts** → **Alert History**
   - Check for recent alert triggers

### 5.4 Verify Dashboard
1. Open the imported dashboard
2. Verify all panels show data
3. Check that metrics are updating in real-time
4. Test different time ranges (1h, 6h, 24h)

## 🔍 Troubleshooting

### API Token Issues
- **Problem**: API calls return 401 Unauthorized
- **Solution**: Verify token is set correctly and has proper permissions
- **Test**: `echo $env:SIGNOZ_API_TOKEN`

### Dashboard Import Issues
- **Problem**: Dashboard import fails
- **Solution**: Check JSON file format and SigNoz version compatibility
- **Test**: Validate JSON at https://jsonlint.com/

### Alert Issues
- **Problem**: Alerts not triggering
- **Solution**: Check query syntax and threshold values
- **Test**: Use SigNoz query builder to test queries

### Webhook Issues
- **Problem**: Webhook not receiving alerts
- **Solution**: Verify webhook server is running and URL is correct
- **Test**: Send test webhook manually

## 📊 Expected Results

After completing all steps, you should have:

- ✅ **API Token**: Set and validated
- ✅ **Dashboard**: Imported with 5 working panels
- ✅ **Alerts**: 4 alert rules configured and active
- ✅ **Webhooks**: Notification channel working
- ✅ **Verification**: All tests passing
- ✅ **Monitoring**: Real-time metrics and alerts

## 🎯 Success Criteria

1. **Component Verification**: All 9 components show "OK" status
2. **Dashboard**: All 5 panels display data
3. **Alerts**: Alert rules are active and not in error state
4. **Webhooks**: Test alerts are delivered successfully
5. **End-to-End**: Complete pipeline test passes

## 📁 Files Created/Modified

- `scripts/complete-manual-setup.ps1` - Automated setup guide
- `docs/MANUAL_SETUP_STEP_BY_STEP.md` - This detailed guide
- `artifacts/signoz-queue-pressure-dashboard.json` - Dashboard configuration
- `artifacts/webhook-logs.json` - Webhook delivery logs
- `artifacts/component-verification-report.json` - Component status

## 🔄 Next Steps

After completing manual setup:

1. **Monitor**: Watch dashboard for 24 hours
2. **Tune**: Adjust alert thresholds based on actual usage
3. **Scale**: Add more metrics and alerts as needed
4. **Optimize**: Fine-tune OTel collector configuration
5. **Document**: Update runbooks and procedures

---

**Actor**: Cursor-Local (Observability Copilot)  
**Status**: Manual setup guide completed  
**Next**: Execute manual steps in SigNoz UI  
**System**: Ready for production after manual configuration
