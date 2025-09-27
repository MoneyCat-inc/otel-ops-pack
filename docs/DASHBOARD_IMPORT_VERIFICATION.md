# Dashboard Import Verification
**Actor**: Cursor-Local (Observability Copilot)  
**Date**: 2025-09-27  
**Status**: Dashboard uploaded by user  
**Purpose**: Verify dashboard import and functionality  

## ✅ Dashboard Upload Confirmed

The user has successfully uploaded the dashboard to SigNoz. Now we need to verify the import and ensure all components are working correctly.

## 🔍 Verification Steps

### 1. Manual Verification in SigNoz UI
1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate**: Go to Dashboards
3. **Find Dashboard**: Look for "OTel Queue Pressure Monitoring"
4. **Open Dashboard**: Click on the dashboard name
5. **Verify Panels**: Check that all 5 panels are visible

### 2. Expected Dashboard Panels
The dashboard should contain these 5 panels:

1. **Queue Utilization Ratio**
   - Type: Stat panel
   - Query: `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100`
   - Unit: Percent
   - Thresholds: Green (0-70%), Yellow (70-90%), Red (90-100%)

2. **Queue Size vs Capacity**
   - Type: Time series
   - Queries: 
     - `otelcol_exporter_queue_size`
     - `otelcol_exporter_queue_capacity`
   - Unit: Count
   - Visualization: Line chart

3. **Send Failure Rate**
   - Type: Time series
   - Query: `rate(otelcol_exporter_send_failed_log_records_total[5m])`
   - Unit: Rate
   - Visualization: Line chart

4. **Batch Timeout Triggers**
   - Type: Time series
   - Query: `rate(otelcol_processor_batch_timeout_trigger_send_total[5m])`
   - Unit: Rate
   - Visualization: Line chart

5. **Log Processing Rate**
   - Type: Time series
   - Query: `rate(otelcol_receiver_accepted_log_records_total[5m])`
   - Unit: Rate
   - Visualization: Line chart

### 3. Data Verification
- **Check Time Range**: Verify data is showing for the last 1 hour
- **Check Data Points**: Ensure panels are not empty
- **Check Refresh**: Verify data updates automatically
- **Test Time Ranges**: Try 6h, 24h, 7d ranges

## 🧪 Testing Dashboard Functionality

### Test 1: Queue Utilization
1. **Generate Test Logs**: Create some log activity
2. **Monitor Queue**: Watch queue utilization panel
3. **Expected**: Values should be between 0-100%

### Test 2: Log Processing Rate
1. **Generate Test Logs**: Create log entries
2. **Monitor Rate**: Watch log processing rate panel
3. **Expected**: Rate should increase when logs are generated

### Test 3: Error Conditions
1. **Stop OTel Collector**: Temporarily stop the service
2. **Monitor Panels**: Watch for error indicators
3. **Restart Service**: Restart and verify recovery

## 📊 Dashboard Performance

### Expected Behavior
- **Load Time**: Dashboard should load within 5 seconds
- **Refresh Rate**: Panels should refresh every 30 seconds
- **Data Latency**: Data should be available within 1-2 minutes
- **Query Performance**: Queries should complete within 10 seconds

### Troubleshooting
- **Empty Panels**: Check if OTel metrics are being generated
- **Slow Loading**: Check SigNoz performance and resource usage
- **Query Errors**: Verify metric names and availability
- **No Data**: Ensure OTel Collector is running and processing logs

## 🔧 Configuration Verification

### Dashboard Settings
- **Name**: "OTel Queue Pressure Monitoring"
- **Tags**: `otel`, `monitoring`, `queue-pressure`
- **Refresh**: 30s
- **Time Range**: Last 1 hour (default)
- **Auto Refresh**: Enabled

### Panel Configuration
- **Thresholds**: Properly configured for each panel
- **Units**: Correct units for each metric
- **Visualization**: Appropriate chart types
- **Queries**: Valid PromQL queries

## 📈 Next Steps

### After Dashboard Verification
1. **Set API Token**: Generate and set `SIGNOZ_API_TOKEN`
2. **Configure Alerts**: Set up alert rules for dashboard metrics
3. **Test Alerts**: Verify alert delivery to webhook
4. **Monitor Performance**: Watch dashboard for 24 hours
5. **Tune Thresholds**: Adjust based on actual usage

### Alert Configuration
Once the dashboard is verified, configure these alerts:
- Queue Utilization > 80% for 5 minutes
- Send Failure Rate > 5% for 2 minutes
- Batch Timeout Triggers > 10/min for 3 minutes
- Log Processing Rate < 100/min for 5 minutes

## 🎯 Success Criteria

### Dashboard Import Success
- [x] Dashboard uploaded to SigNoz
- [ ] Dashboard visible in dashboard list
- [ ] All 5 panels visible and functional
- [ ] Data showing in panels
- [ ] Queries executing successfully
- [ ] Auto-refresh working
- [ ] Time range controls working

### System Integration
- [ ] Dashboard queries return data
- [ ] Metrics are being collected
- [ ] OTel Collector is generating metrics
- [ ] SigNoz is processing metrics
- [ ] Dashboard updates in real-time

## 📁 Related Files

- `artifacts/signoz-queue-pressure-dashboard.json` - Dashboard configuration
- `scripts/verify-dashboard-import.ps1` - Verification script
- `docs/MANUAL_SETUP_STEP_BY_STEP.md` - Setup guide
- `docs/COMPONENT_VERIFICATION_SUMMARY.md` - Component status

## 🔄 Verification Commands

### Manual Verification
```powershell
# Check dashboard in SigNoz UI
# Open http://localhost:8080
# Go to Dashboards
# Find "OTel Queue Pressure Monitoring"
# Verify all 5 panels
```

### Automated Verification (requires API token)
```powershell
# Set API token first
$env:SIGNOZ_API_TOKEN = 'your-token-here'

# Run verification
pwsh -File scripts/verify-dashboard-import.ps1
```

### Component Status
```powershell
# Check overall system status
pwsh -File scripts/verify-all-components.ps1
```

---

**Actor**: Cursor-Local (Observability Copilot)  
**Status**: Dashboard uploaded, verification in progress  
**Next**: Complete API token setup and alert configuration  
**System**: Dashboard ready for verification and testing
