# SigNoz UI Implementation Walkthrough
**Date**: 2025-01-27  
**Time**: 17:05 UTC  
**Purpose**: Live walkthrough of implementing dashboards and alerts in SigNoz UI

## 🎯 **Implementation Walkthrough Overview**

### **Current Status**
- **SigNoz UI**: ✅ **ACCESSIBLE** - http://localhost:8080
- **Test Canary**: ✅ **GENERATED** - Token: 7767040b96d24c1f9ec7eb90038bd635
- **Implementation Guide**: ✅ **READY** - Step-by-step guide available
- **Ready for Walkthrough**: ✅ **CONFIRMED**

## 📊 **Walkthrough Step 1: Access SigNoz UI**

### **1.1 Browser Access**
1. **Open Web Browser**: Chrome, Firefox, or Edge
2. **Navigate to**: http://localhost:8080
3. **Verify Access**: Confirm SigNoz UI loads successfully
4. **Check Login**: If login required, use default credentials

### **1.2 UI Navigation**
- **Left Sidebar**: Should show navigation menu
- **Dashboards**: Should be visible in sidebar
- **Alerts**: Should be visible in sidebar
- **Logs**: Should be visible in sidebar

## 📊 **Walkthrough Step 2: Create System Health Dashboard**

### **2.1 Navigate to Dashboards**
1. **Click "Dashboards"** in left sidebar
2. **Click "New Dashboard"** or "+" button
3. **Set Dashboard Title**: "Observability Pipeline Health"
4. **Set Description**: "Core system health monitoring"

### **2.2 Add Panel 1: Windows Collector Status**
1. **Click "Add Panel"** or "+" button
2. **Select Panel Type**: "Stat" or "Single Stat"
3. **Configure Query**:
   - **Query**: up{job="otelcol-contrib"}
   - **Legend**: "Collector Status"
4. **Configure Thresholds**:
   - **Red**: 0
   - **Green**: 1
5. **Set Position**: Top-left (0,0)
6. **Save Panel**

### **2.3 Add Panel 2: SigNoz Container Health**
1. **Click "Add Panel"**
2. **Select Panel Type**: "Stat"
3. **Configure Query**:
   - **Query**: up{job="signoz"}
   - **Legend**: "SigNoz Status"
4. **Configure Thresholds**:
   - **Red**: 0
   - **Green**: 1
5. **Set Position**: Top-center (6,0)
6. **Save Panel**

### **2.4 Add Panel 3: Log Ingestion Rate**
1. **Click "Add Panel"**
2. **Select Panel Type**: "Graph" or "Time Series"
3. **Configure Query**:
   - **Query**: rate(otelcol_receiver_accepted_log_records[5m])
   - **Legend**: "Logs/sec"
4. **Set Position**: Top-right (12,0)
5. **Save Panel**

### **2.5 Add Panel 4: Canary Generation Success**
1. **Click "Add Panel"**
2. **Select Panel Type**: "Stat"
3. **Configure Query**:
   - **Query**: rate(otelcol_receiver_accepted_log_records{source="canary"}[5m])
   - **Legend**: "Canary Events/sec"
4. **Set Position**: Bottom-left (0,8)
5. **Save Panel**

### **2.6 Add Panel 5: Error Rate**
1. **Click "Add Panel"**
2. **Select Panel Type**: "Graph"
3. **Configure Query**:
   - **Query**: rate(otelcol_receiver_refused_log_records[5m])
   - **Legend**: "Errors/sec"
4. **Set Position**: Bottom-right (6,8)
5. **Save Panel**

### **2.7 Configure Dashboard Settings**
1. **Set Refresh Rate**: 30 seconds
2. **Set Time Range**: Last 1 hour
3. **Save Dashboard**

## 📊 **Walkthrough Step 3: Create Performance Metrics Dashboard**

### **3.1 Create New Dashboard**
1. **Click "New Dashboard"**
2. **Set Title**: "Performance Metrics"
3. **Set Description**: "System performance monitoring"

### **3.2 Add Panel 1: CPU Usage**
1. **Add Panel**: "Graph"
2. **Configure Query**:
   - **Query**: rate(process_cpu_seconds_total[5m]) * 100
   - **Legend**: "CPU %"
3. **Configure Y-Axis**: 0-100 (percent)
4. **Set Position**: Top-left (0,0)
5. **Save Panel**

### **3.3 Add Panel 2: Memory Usage**
1. **Add Panel**: "Graph"
2. **Configure Query**:
   - **Query**: process_resident_memory_bytes / 1024 / 1024
   - **Legend**: "Memory MB"
3. **Configure Y-Axis**: MB
4. **Set Position**: Top-right (12,0)
5. **Save Panel**

### **3.4 Add Panel 3: Network I/O**
1. **Add Panel**: "Graph"
2. **Configure Query**:
   - **Query**: rate(otelcol_exporter_sent_log_records[5m])
   - **Legend**: "Sent Logs/sec"
3. **Set Position**: Bottom-left (0,8)
4. **Save Panel**

### **3.5 Add Panel 4: Disk I/O**
1. **Add Panel**: "Graph"
2. **Configure Query**:
   - **Query**: rate(otelcol_receiver_accepted_log_records[5m])
   - **Legend**: "Processed Logs/sec"
3. **Set Position**: Bottom-right (12,8)
4. **Save Panel**

### **3.6 Configure Dashboard Settings**
1. **Set Refresh Rate**: 30 seconds
2. **Set Time Range**: Last 1 hour
3. **Save Dashboard**

## 📊 **Walkthrough Step 4: Create Application Metrics Dashboard**

### **4.1 Create New Dashboard**
1. **Click "New Dashboard"**
2. **Set Title**: "Application Metrics"
3. **Set Description**: "Application-specific monitoring"

### **4.2 Add Panel 1: Service Worker Status**
1. **Add Panel**: "Stat"
2. **Configure Query**:
   - **Query**: service_worker_supported
   - **Legend**: "SW Supported"
3. **Set Position**: Top-left (0,0)
4. **Save Panel**

### **4.3 Add Panel 2: Cross-Origin Isolation**
1. **Add Panel**: "Stat"
2. **Configure Query**:
   - **Query**: cross_origin_isolated
   - **Legend**: "COI Status"
3. **Set Position**: Top-center (6,0)
4. **Save Panel**

### **4.4 Add Panel 3: Audio Latency**
1. **Add Panel**: "Graph"
2. **Configure Queries**:
   - **Query 1**: audio_latency_p50 (Legend: "P50 Latency")
   - **Query 2**: audio_latency_p90 (Legend: "P90 Latency")
   - **Query 3**: audio_latency_p99 (Legend: "P99 Latency")
3. **Configure Y-Axis**: ms
4. **Set Position**: Top-right (12,0)
5. **Save Panel**

### **4.5 Add Panel 4: WASM Heap Usage**
1. **Add Panel**: "Graph"
2. **Configure Queries**:
   - **Query 1**: wasm_heap_used_bytes (Legend: "Heap Used")
   - **Query 2**: wasm_heap_total_bytes (Legend: "Heap Total")
3. **Configure Y-Axis**: bytes
4. **Set Position**: Bottom-left (0,8)
5. **Save Panel**

### **4.6 Add Panel 5: SharedArrayBuffer Usage**
1. **Add Panel**: "Stat"
2. **Configure Query**:
   - **Query**: shared_array_buffer_available
   - **Legend**: "SAB Available"
3. **Set Position**: Bottom-right (12,8)
4. **Save Panel**

### **4.7 Configure Dashboard Settings**
1. **Set Refresh Rate**: 5 seconds
2. **Set Time Range**: Last 1 hour
3. **Save Dashboard**

## 🚨 **Walkthrough Step 5: Configure Critical Alerts**

### **5.1 Navigate to Alerts**
1. **Click "Alerts"** in left sidebar
2. **Click "New Alert"** or "+" button

### **5.2 Configure Alert 1: Windows Collector Down**
1. **Set Alert Name**: "Windows Collector Down"
2. **Configure Condition**: up{job="otelcol-contrib"} == 0
3. **Set Duration**: 0m (immediate)
4. **Set Severity**: Critical
5. **Set Message**: "Windows Collector service is down. Immediate action required."
6. **Configure Notifications**: Email, Slack
7. **Save Alert**

### **5.3 Configure Alert 2: SigNoz Container Unhealthy**
1. **Set Alert Name**: "SigNoz Container Unhealthy"
2. **Configure Condition**: up{job="signoz"} == 0
3. **Set Duration**: 0m (immediate)
4. **Set Severity**: Critical
5. **Set Message**: "SigNoz container is unhealthy. Check Docker status."
6. **Configure Notifications**: Email, Slack
7. **Save Alert**

### **5.4 Configure Alert 3: OTLP Pipeline Failure**
1. **Set Alert Name**: "OTLP Pipeline Failure"
2. **Configure Condition**: rate(otelcol_receiver_accepted_log_records[5m]) == 0
3. **Set Duration**: 5m
4. **Set Severity**: Critical
5. **Set Message**: "No logs ingested for 5 minutes. Check OTLP pipeline."
6. **Configure Notifications**: Email, Slack
7. **Save Alert**

## 🚨 **Walkthrough Step 6: Configure Warning Alerts**

### **6.1 Configure Alert 4: High CPU Usage**
1. **Set Alert Name**: "High CPU Usage"
2. **Configure Condition**: rate(process_cpu_seconds_total[5m]) * 100 > 80
3. **Set Duration**: 5m
4. **Set Severity**: Warning
5. **Set Message**: "CPU usage above 80% for 5 minutes."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.2 Configure Alert 5: Memory Leak Detection**
1. **Set Alert Name**: "Memory Leak Detection"
2. **Configure Condition**: increase(process_resident_memory_bytes[1h]) > 0.1
3. **Set Duration**: 1h
4. **Set Severity**: Warning
5. **Set Message**: "Memory usage increasing significantly."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.3 Configure Alert 6: Service Worker Registration Failed**
1. **Set Alert Name**: "Service Worker Registration Failed"
2. **Configure Condition**: service_worker_registration_success_rate < 0.95
3. **Set Duration**: 10m
4. **Set Severity**: Warning
5. **Set Message**: "Service Worker registration success rate below 95%."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.4 Configure Alert 7: Cross-Origin Isolation Lost**
1. **Set Alert Name**: "Cross-Origin Isolation Lost"
2. **Configure Condition**: cross_origin_isolated == 0
3. **Set Duration**: 0m (immediate)
4. **Set Severity**: Warning
5. **Set Message**: "Cross-origin isolation lost. Check COOP/COEP headers."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.5 Configure Alert 8: Audio Latency Degradation**
1. **Set Alert Name**: "Audio Latency Degradation"
2. **Configure Condition**: audio_latency_p90 > 200
3. **Set Duration**: 2m
4. **Set Severity**: Warning
5. **Set Message**: "Audio latency P90 above 200ms."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.6 Configure Alert 9: Canary Test Failure**
1. **Set Alert Name**: "Canary Test Failure"
2. **Configure Condition**: rate(otelcol_receiver_accepted_log_records{source="canary"}[5m]) == 0
3. **Set Duration**: 5m
4. **Set Severity**: Warning
5. **Set Message**: "Canary test failure detected. Check canary system."
6. **Configure Notifications**: Slack
7. **Save Alert**

### **6.7 Configure Alert 10: Log Parsing Errors**
1. **Set Alert Name**: "Log Parsing Errors"
2. **Configure Condition**: rate(otelcol_receiver_refused_log_records[5m]) > 0.01
3. **Set Duration**: 10m
4. **Set Severity**: Warning
5. **Set Message**: "Log parsing error rate above 1%."
6. **Configure Notifications**: Slack
7. **Save Alert**

## 🔧 **Walkthrough Step 7: Verification and Testing**

### **7.1 Dashboard Verification**
1. **Check All Dashboards**: Verify all 3 dashboards are created
2. **Check Panel Data**: Confirm all panels show data
3. **Check Refresh Rates**: Verify dashboards refresh correctly
4. **Check Time Ranges**: Confirm time ranges are set correctly

### **7.2 Alert Verification**
1. **Check All Alerts**: Verify all 10 alerts are configured
2. **Check Alert Status**: Confirm alerts are enabled
3. **Check Conditions**: Verify alert conditions are correct
4. **Check Notifications**: Confirm notification channels are set

### **7.3 Integration Testing**
1. **Generate Canary**: Run canary command
2. **Check Dashboard**: Verify canary appears in dashboards
3. **Check Logs**: Verify canary events in SigNoz logs
4. **Test Alerts**: Trigger test alerts if possible

## 🚀 **Walkthrough Step 8: Final Verification Commands**

### **8.1 Generate Test Data**
`powershell
# Generate canary for testing
canary

# Check Windows Event Log
Get-WinEvent -LogName Application | Where-Object { .ProviderName -eq "SigNoz-Canary" } | Select-Object -First 5
`

### **8.2 Health Check**
`powershell
# Run health check
pwsh -File scripts/health-check-observability-fixed.ps1

# Check SigNoz status
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
`

## 📋 **Walkthrough Implementation Checklist**

### **Dashboard Checklist**
- [ ] System Health Dashboard created (5 panels)
- [ ] Performance Metrics Dashboard created (4 panels)
- [ ] Application Metrics Dashboard created (5 panels)
- [ ] All panels show data
- [ ] Refresh rates configured correctly
- [ ] Time ranges set appropriately

### **Alert Checklist**
- [ ] 3 Critical alerts configured
- [ ] 7 Warning alerts configured
- [ ] All alerts enabled
- [ ] Notification channels configured
- [ ] Alert conditions correct
- [ ] Alert durations appropriate

### **Integration Checklist**
- [ ] Dashboards show real-time data
- [ ] Canary events appear in dashboards
- [ ] Alerts monitor correct metrics
- [ ] Notification delivery works
- [ ] System health monitoring active

## 📝 **Walkthrough Next Steps**

### **Immediate Actions**
1. **Follow Walkthrough Steps**: Use this guide step-by-step
2. **Create All Dashboards**: Implement all 3 dashboards
3. **Configure All Alerts**: Set up all 10 alerts
4. **Verify Implementation**: Check dashboards and alerts

### **Follow-up Actions**
1. **Test Functionality**: Generate canary and verify monitoring
2. **Customize Dashboards**: Adjust queries and thresholds
3. **Configure Notifications**: Set up email/Slack channels
4. **Create Runbooks**: Document alert response procedures

### **Future Enhancements**
1. **Custom Metrics**: Add application-specific metrics
2. **Advanced Alerts**: Implement anomaly detection
3. **Historical Analysis**: Add trend analysis
4. **Integration**: Connect with external systems

---
**Walkthrough Generated**: 2025-01-27 17:05 UTC  
**Status**: Ready for step-by-step walkthrough  
**Next**: Follow each step in SigNoz UI
