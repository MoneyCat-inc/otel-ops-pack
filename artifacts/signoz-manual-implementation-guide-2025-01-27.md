# SigNoz Manual Implementation Guide
**Date**: 2025-01-27  
**Time**: 16:45 UTC  
**Purpose**: Manual implementation guide for SigNoz dashboards and alerts

## 🎯 **Implementation Status**

### **Current Situation**
- **SigNoz UI**: ✅ **ACCESSIBLE** - http://localhost:8080
- **SigNoz API**: ⚠️ **AUTHENTICATION REQUIRED** - 401 Unauthorized
- **Scripts Created**: ✅ **READY** - But require authentication
- **Manual Implementation**: ✅ **REQUIRED** - Use SigNoz UI directly

## 📊 **Manual Dashboard Implementation**

### **Step 1: Access SigNoz UI**
1. **Open Browser**: Navigate to http://localhost:8080
2. **Login**: Use default credentials (if required)
3. **Verify Access**: Confirm SigNoz UI loads successfully

### **Step 2: Create System Health Dashboard**
1. **Navigate to Dashboards**: Click "Dashboards" in left sidebar
2. **Create New Dashboard**: Click "New Dashboard" or "+" button
3. **Set Title**: "Observability Pipeline Health"
4. **Add Panels**:

#### **Panel 1: Windows Collector Status**
- **Panel Type**: Stat
- **Query**: up{job="otelcol-contrib"}
- **Legend**: "Collector Status"
- **Thresholds**: 
  - Red: 0
  - Green: 1
- **Position**: Top-left (0,0)

#### **Panel 2: SigNoz Container Health**
- **Panel Type**: Stat
- **Query**: up{job="signoz"}
- **Legend**: "SigNoz Status"
- **Thresholds**:
  - Red: 0
  - Green: 1
- **Position**: Top-center (6,0)

#### **Panel 3: Log Ingestion Rate**
- **Panel Type**: Graph
- **Query**: rate(otelcol_receiver_accepted_log_records[5m])
- **Legend**: "Logs/sec"
- **Position**: Top-right (12,0)

#### **Panel 4: Canary Generation Success**
- **Panel Type**: Stat
- **Query**: rate(otelcol_receiver_accepted_log_records{source="canary"}[5m])
- **Legend**: "Canary Events/sec"
- **Position**: Bottom-left (0,8)

#### **Panel 5: Error Rate**
- **Panel Type**: Graph
- **Query**: rate(otelcol_receiver_refused_log_records[5m])
- **Legend**: "Errors/sec"
- **Position**: Bottom-right (6,8)

### **Step 3: Create Performance Metrics Dashboard**
1. **Create New Dashboard**: Click "New Dashboard"
2. **Set Title**: "Performance Metrics"
3. **Add Panels**:

#### **Panel 1: CPU Usage**
- **Panel Type**: Graph
- **Query**: rate(process_cpu_seconds_total[5m]) * 100
- **Legend**: "CPU %"
- **Y-Axis**: 0-100 (percent)
- **Position**: Top-left (0,0)

#### **Panel 2: Memory Usage**
- **Panel Type**: Graph
- **Query**: process_resident_memory_bytes / 1024 / 1024
- **Legend**: "Memory MB"
- **Y-Axis**: MB
- **Position**: Top-right (12,0)

#### **Panel 3: Network I/O**
- **Panel Type**: Graph
- **Query**: rate(otelcol_exporter_sent_log_records[5m])
- **Legend**: "Sent Logs/sec"
- **Position**: Bottom-left (0,8)

#### **Panel 4: Disk I/O**
- **Panel Type**: Graph
- **Query**: rate(otelcol_receiver_accepted_log_records[5m])
- **Legend**: "Processed Logs/sec"
- **Position**: Bottom-right (12,8)

### **Step 4: Create Application Metrics Dashboard**
1. **Create New Dashboard**: Click "New Dashboard"
2. **Set Title**: "Application Metrics"
3. **Add Panels**:

#### **Panel 1: Service Worker Status**
- **Panel Type**: Stat
- **Query**: service_worker_supported
- **Legend**: "SW Supported"
- **Position**: Top-left (0,0)

#### **Panel 2: Cross-Origin Isolation**
- **Panel Type**: Stat
- **Query**: cross_origin_isolated
- **Legend**: "COI Status"
- **Position**: Top-center (6,0)

#### **Panel 3: Audio Latency**
- **Panel Type**: Graph
- **Queries**:
  - audio_latency_p50 (P50 Latency)
  - audio_latency_p90 (P90 Latency)
  - audio_latency_p99 (P99 Latency)
- **Y-Axis**: ms
- **Position**: Top-right (12,0)

#### **Panel 4: WASM Heap Usage**
- **Panel Type**: Graph
- **Queries**:
  - wasm_heap_used_bytes (Heap Used)
  - wasm_heap_total_bytes (Heap Total)
- **Y-Axis**: bytes
- **Position**: Bottom-left (0,8)

#### **Panel 5: SharedArrayBuffer Usage**
- **Panel Type**: Stat
- **Query**: shared_array_buffer_available
- **Legend**: "SAB Available"
- **Position**: Bottom-right (12,8)

## 🚨 **Manual Alert Configuration**

### **Step 1: Access Alerts Section**
1. **Navigate to Alerts**: Click "Alerts" in left sidebar
2. **Create New Alert**: Click "New Alert" or "+" button

### **Step 2: Configure Critical Alerts**

#### **Alert 1: Windows Collector Down**
- **Name**: "Windows Collector Down"
- **Condition**: up{job="otelcol-contrib"} == 0
- **Duration**: 0m (immediate)
- **Severity**: Critical
- **Message**: "Windows Collector service is down. Immediate action required."
- **Notifications**: Email, Slack

#### **Alert 2: SigNoz Container Unhealthy**
- **Name**: "SigNoz Container Unhealthy"
- **Condition**: up{job="signoz"} == 0
- **Duration**: 0m (immediate)
- **Severity**: Critical
- **Message**: "SigNoz container is unhealthy. Check Docker status."
- **Notifications**: Email, Slack

#### **Alert 3: OTLP Pipeline Failure**
- **Name**: "OTLP Pipeline Failure"
- **Condition**: rate(otelcol_receiver_accepted_log_records[5m]) == 0
- **Duration**: 5m
- **Severity**: Critical
- **Message**: "No logs ingested for 5 minutes. Check OTLP pipeline."
- **Notifications**: Email, Slack

### **Step 3: Configure Warning Alerts**

#### **Alert 4: High CPU Usage**
- **Name**: "High CPU Usage"
- **Condition**: rate(process_cpu_seconds_total[5m]) * 100 > 80
- **Duration**: 5m
- **Severity**: Warning
- **Message**: "CPU usage above 80% for 5 minutes."
- **Notifications**: Slack

#### **Alert 5: Memory Leak Detection**
- **Name**: "Memory Leak Detection"
- **Condition**: increase(process_resident_memory_bytes[1h]) > 0.1
- **Duration**: 1h
- **Severity**: Warning
- **Message**: "Memory usage increasing significantly."
- **Notifications**: Slack

#### **Alert 6: Service Worker Registration Failed**
- **Name**: "Service Worker Registration Failed"
- **Condition**: service_worker_registration_success_rate < 0.95
- **Duration**: 10m
- **Severity**: Warning
- **Message**: "Service Worker registration success rate below 95%."
- **Notifications**: Slack

#### **Alert 7: Cross-Origin Isolation Lost**
- **Name**: "Cross-Origin Isolation Lost"
- **Condition**: cross_origin_isolated == 0
- **Duration**: 0m (immediate)
- **Severity**: Warning
- **Message**: "Cross-origin isolation lost. Check COOP/COEP headers."
- **Notifications**: Slack

#### **Alert 8: Audio Latency Degradation**
- **Name**: "Audio Latency Degradation"
- **Condition**: audio_latency_p90 > 200
- **Duration**: 2m
- **Severity**: Warning
- **Message**: "Audio latency P90 above 200ms."
- **Notifications**: Slack

#### **Alert 9: Canary Test Failure**
- **Name**: "Canary Test Failure"
- **Condition**: rate(otelcol_receiver_accepted_log_records{source="canary"}[5m]) == 0
- **Duration**: 5m
- **Severity**: Warning
- **Message**: "Canary test failure detected. Check canary system."
- **Notifications**: Slack

#### **Alert 10: Log Parsing Errors**
- **Name**: "Log Parsing Errors"
- **Condition**: rate(otelcol_receiver_refused_log_records[5m]) > 0.01
- **Duration**: 10m
- **Severity**: Warning
- **Message**: "Log parsing error rate above 1%."
- **Notifications**: Slack

## 🔧 **Implementation Verification**

### **Dashboard Verification Checklist**
- [ ] All 3 dashboards created successfully
- [ ] System Health dashboard shows collector status
- [ ] Performance dashboard shows CPU/memory metrics
- [ ] Application dashboard shows Service Worker status
- [ ] All panels refresh at correct intervals
- [ ] No error messages in dashboard panels
- [ ] Data is visible in all panels

### **Alert Verification Checklist**
- [ ] All 10 alerts configured successfully
- [ ] 3 critical alerts configured
- [ ] 7 warning alerts configured
- [ ] Alert conditions are correct
- [ ] Alert durations are appropriate
- [ ] Notification channels are configured
- [ ] Alerts are enabled and active

### **Integration Verification**
- [ ] Dashboards show real-time data
- [ ] Alerts are monitoring correct metrics
- [ ] Canary events appear in dashboards
- [ ] Error conditions trigger alerts
- [ ] Notification delivery works

## 🚀 **Quick Implementation Commands**

### **Generate Test Data**
`powershell
# Generate canary for testing
canary

# Check Windows Event Log
Get-WinEvent -LogName Application | Where-Object { .ProviderName -eq "SigNoz-Canary" } | Select-Object -First 5
`

### **Health Check**
`powershell
# Run health check
pwsh -File scripts/health-check-observability-fixed.ps1

# Check SigNoz status
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
`

## 📝 **Next Steps**

### **Immediate Actions**
1. **Access SigNoz UI**: Navigate to http://localhost:8080
2. **Create Dashboards**: Follow manual implementation steps
3. **Configure Alerts**: Set up all 10 alerts
4. **Verify Implementation**: Check dashboards and alerts

### **Follow-up Actions**
1. **Test Functionality**: Generate canary and verify monitoring
2. **Customize Dashboards**: Adjust queries and thresholds
3. **Configure Notifications**: Set up email/Slack channels
4. **Create Runbooks**: Document alert response procedures

### **Future Enhancements**
1. **API Authentication**: Set up SigNoz API authentication
2. **Automated Scripts**: Update scripts with authentication
3. **Custom Metrics**: Add application-specific metrics
4. **Advanced Alerts**: Implement anomaly detection

---
**Guide Generated**: 2025-01-27 16:45 UTC  
**Status**: Ready for manual implementation  
**Next**: Follow manual implementation steps in SigNoz UI
