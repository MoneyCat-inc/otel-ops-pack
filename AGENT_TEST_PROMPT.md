# 🤖 Agent Test Prompt - Optimized OTel Pipeline

## Your Mission
You are a **Pipeline Testing Agent** tasked with verifying the optimized OpenTelemetry pipeline is functioning correctly. Your job is to run comprehensive tests, validate monitoring, and ensure the system is production-ready.

## Environment Context
- **Host**: Windows 11 with PowerShell admin access
- **Pipeline**: Windows Event Logs → OTel Collector → SigNoz → ClickHouse
- **Optimizations**: 200ms batches, 50% volume reduction, sub-second latency
- **Monitoring**: Unified Logs → Metrics → Traces dashboard + alerts

## Test Objectives

### 1. **Pipeline Health Verification**
```powershell
# Run these commands to verify core functionality
pwsh -File quick-status.ps1
pwsh -File canary-test.ps1
pwsh -File verify-pipeline.ps1
```

**Expected Results:**
- All services running (Docker, Windows Collector, SigNoz)
- All ports accessible (5317/5318, 14317/14318, 8080)
- Canary test generates logs and traces successfully

### 2. **Monitoring Dashboard Test**
1. **Open SigNoz UI**: http://localhost:8080
2. **Import Dashboard**: Dashboards → Import → `artifacts/optimized-pipeline-dashboard.json`
3. **Verify Panels**: All 9 panels should load without errors
4. **Check Data Flow**: Recent logs should show Windows events and canary entries

**Key Queries to Test:**
- **Logs**: `message contains "canary test"`
- **Metrics**: `otelcol_receiver_accepted_log_records`
- **Traces**: Look for canary test traces

### 3. **Alert Configuration Test**
1. **Import Alerts**: Alerts → Import → `artifacts/noise-pattern-alerts.json`
2. **Verify Rules**: All 5 alert rules should be active
3. **Test Thresholds**: Ensure alerts are properly configured

### 4. **Performance Validation**
```powershell
# Run the live monitor to check performance
pwsh -File scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 5
```

**Expected Metrics:**
- Batch processing: ~200ms windows
- Noise filtering: Active and effective
- Export errors: <5%
- Latency: p95 < 1 second

### 5. **Noise Filtering Test**
1. **Check Filtered Logs**: Look for Windows Event IDs 6005, 6006, 7036
2. **Verify Filter Rate**: Should be filtering ~50% of noise
3. **Monitor New Patterns**: Watch for unexpected noise sources

### 6. **End-to-End Data Flow Test**
1. **Generate Test Data**: Run canary test multiple times
2. **Verify Ingestion**: Check logs appear in SigNoz within 30 seconds
3. **Check ClickHouse**: Verify data is being stored correctly
4. **Validate Traces**: Ensure trace data is complete

## Success Criteria

### ✅ **Pipeline Health**
- [ ] All services running without errors
- [ ] All ports accessible and responding
- [ ] Canary test generates expected logs and traces
- [ ] No collector warnings or retries in logs

### ✅ **Monitoring Dashboard**
- [ ] Dashboard imports successfully
- [ ] All 9 panels render without errors
- [ ] Recent logs show expected data
- [ ] Metrics display real-time values
- [ ] Traces show latency quantiles

### ✅ **Alert System**
- [ ] All 5 alert rules imported successfully
- [ ] Alerts are active and monitoring
- [ ] Thresholds are appropriate for current load

### ✅ **Performance**
- [ ] Batch processing ~200ms windows
- [ ] Noise filtering effective (~50% reduction)
- [ ] Export error rate <5%
- [ ] Processing latency p95 < 1 second

### ✅ **Data Integrity**
- [ ] Windows Event Logs flowing to ClickHouse
- [ ] Canary test data visible in SigNoz
- [ ] Trace data complete and accurate
- [ ] No data loss or corruption

## Troubleshooting Guide

### **If Services Not Running:**
```powershell
# Restart Windows Collector
sc stop otelcol-contrib
sc start otelcol-contrib

# Restart SigNoz
docker-compose down
docker-compose up -d
```

### **If Dashboard Import Fails:**
- Check SigNoz UI is accessible
- Verify JSON file is valid
- Try importing panels individually

### **If Alerts Not Working:**
- Check alert configuration syntax
- Verify metric names are correct
- Test with manual threshold changes

### **If Performance Issues:**
- Check collector logs for errors
- Verify batch size settings
- Monitor ClickHouse performance

## Test Report Template

After completing tests, provide:

1. **Overall Status**: ✅ PASS / ❌ FAIL
2. **Issues Found**: List any problems discovered
3. **Performance Metrics**: Actual vs expected values
4. **Recommendations**: Any improvements needed
5. **Next Steps**: Follow-up actions required

## Files to Reference

- **Config**: `config.yaml` - OTel collector configuration
- **Dashboard**: `artifacts/optimized-pipeline-dashboard.json`
- **Alerts**: `artifacts/noise-pattern-alerts.json`
- **Monitor**: `scripts/monitor-optimized-pipeline.ps1`
- **Status**: `quick-status.ps1`, `canary-test.ps1`

## Remember

- The pipeline is optimized for **low latency** and **high efficiency**
- **Noise filtering** should reduce volume by ~50%
- **Sub-second processing** is expected
- **Real-time monitoring** is available via dashboard and CLI

Good luck testing! The system should be running smoothly with all optimizations active. 🚀
