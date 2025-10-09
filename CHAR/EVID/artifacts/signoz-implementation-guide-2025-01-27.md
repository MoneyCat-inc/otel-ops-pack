# SigNoz Dashboard & Alert Implementation Guide
**Date**: 2025-01-27  
**Time**: 16:45 UTC  
**Purpose**: Complete guide for importing dashboards and configuring alerts

## 🎯 **Implementation Overview**

### **Current Status**
- **SigNoz UI**: ✅ **ACCESSIBLE** - http://localhost:8080
- **SigNoz API**: ✅ **HEALTHY** - {"status":"ok"}
- **Log Ingestion**: ✅ **VERIFIED** - SigNoz-Canary events confirmed
- **Scripts Created**: ✅ **READY** - Dashboard import and alert configuration scripts

## 📊 **Dashboard Implementation**

### **Available Dashboards**
1. **System Health Dashboard** - Core observability monitoring
2. **Performance Metrics Dashboard** - System performance tracking
3. **Application Metrics Dashboard** - Application-specific monitoring

### **Dashboard Features**

#### **System Health Dashboard**
- **Windows Collector Status**: Service health monitoring
- **SigNoz Container Health**: Container status tracking
- **Log Ingestion Rate**: Real-time log processing metrics
- **Canary Generation Success**: Canary event frequency
- **Error Rate**: Log processing error tracking
- **Refresh Rate**: 30 seconds

#### **Performance Metrics Dashboard**
- **CPU Usage**: System CPU utilization
- **Memory Usage**: Memory consumption tracking
- **Network I/O**: Network traffic monitoring
- **Disk I/O**: Disk usage and processing rates
- **Refresh Rate**: 30 seconds

#### **Application Metrics Dashboard**
- **Service Worker Status**: SW support and registration
- **Cross-Origin Isolation**: COI compliance monitoring
- **Audio Latency**: P50, P90, P99 latency tracking
- **WASM Heap Usage**: Memory usage monitoring
- **SharedArrayBuffer Usage**: SAB availability tracking
- **Refresh Rate**: 5 seconds

### **Dashboard Import Commands**

#### **Import All Dashboards**
`powershell
pwsh -File scripts/import-signoz-dashboards.ps1 -All
`

#### **Import Specific Dashboards**
`powershell
# System Health only
pwsh -File scripts/import-signoz-dashboards.ps1 -SystemHealth

# Performance only
pwsh -File scripts/import-signoz-dashboards.ps1 -Performance

# Application only
pwsh -File scripts/import-signoz-dashboards.ps1 -Application
`

#### **Dry Run (Test Mode)**
`powershell
pwsh -File scripts/import-signoz-dashboards.ps1 -All -DryRun
`

## 🚨 **Alert Configuration**

### **Available Alerts**

#### **Critical Alerts (Immediate Response)**
1. **Windows Collector Down**
   - **Condition**: up{job="otelcol-contrib"} == 0
   - **Duration**: 0m (immediate)
   - **Severity**: Critical
   - **Notifications**: Email, Slack

2. **SigNoz Container Unhealthy**
   - **Condition**: up{job="signoz"} == 0
   - **Duration**: 0m (immediate)
   - **Severity**: Critical
   - **Notifications**: Email, Slack

3. **OTLP Pipeline Failure**
   - **Condition**: rate(otelcol_receiver_accepted_log_records[5m]) == 0
   - **Duration**: 5m
   - **Severity**: Critical
   - **Notifications**: Email, Slack

#### **Warning Alerts (Monitor & Investigate)**
1. **High CPU Usage**
   - **Condition**: rate(process_cpu_seconds_total[5m]) * 100 > 80
   - **Duration**: 5m
   - **Severity**: Warning
   - **Notifications**: Slack

2. **Memory Leak Detection**
   - **Condition**: increase(process_resident_memory_bytes[1h]) > 0.1
   - **Duration**: 1h
   - **Severity**: Warning
   - **Notifications**: Slack

3. **Service Worker Registration Failed**
   - **Condition**: service_worker_registration_success_rate < 0.95
   - **Duration**: 10m
   - **Severity**: Warning
   - **Notifications**: Slack

4. **Cross-Origin Isolation Lost**
   - **Condition**: cross_origin_isolated == 0
   - **Duration**: 0m (immediate)
   - **Severity**: Warning
   - **Notifications**: Slack

5. **Audio Latency Degradation**
   - **Condition**: audio_latency_p90 > 200
   - **Duration**: 2m
   - **Severity**: Warning
   - **Notifications**: Slack

6. **Canary Test Failure**
   - **Condition**: rate(otelcol_receiver_accepted_log_records{source="canary"}[5m]) == 0
   - **Duration**: 5m
   - **Severity**: Warning
   - **Notifications**: Slack

7. **Log Parsing Errors**
   - **Condition**: rate(otelcol_receiver_refused_log_records[5m]) > 0.01
   - **Duration**: 10m
   - **Severity**: Warning
   - **Notifications**: Slack

### **Alert Configuration Commands**

#### **Configure All Alerts**
`powershell
pwsh -File scripts/configure-signoz-alerts.ps1 -All
`

#### **Configure Specific Alert Types**
`powershell
# Critical alerts only
pwsh -File scripts/configure-signoz-alerts.ps1 -Critical

# Warning alerts only
pwsh -File scripts/configure-signoz-alerts.ps1 -Warning
`

#### **Dry Run (Test Mode)**
`powershell
pwsh -File scripts/configure-signoz-alerts.ps1 -All -DryRun
`

## 🔧 **Implementation Steps**

### **Step 1: Pre-Implementation Verification**
`powershell
# Verify SigNoz is accessible
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing

# Verify SigNoz API health
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing

# Run health check
pwsh -File scripts/health-check-observability-fixed.ps1
`

### **Step 2: Import Dashboards**
`powershell
# Test with dry run first
pwsh -File scripts/import-signoz-dashboards.ps1 -All -DryRun

# Import all dashboards
pwsh -File scripts/import-signoz-dashboards.ps1 -All
`

### **Step 3: Configure Alerts**
`powershell
# Test with dry run first
pwsh -File scripts/configure-signoz-alerts.ps1 -All -DryRun

# Configure all alerts
pwsh -File scripts/configure-signoz-alerts.ps1 -All
`

### **Step 4: Verify Implementation**
1. **Access SigNoz UI**: Navigate to http://localhost:8080
2. **Check Dashboards**: Go to "Dashboards" section
3. **Verify Panels**: Confirm all panels are loading data
4. **Check Alerts**: Go to "Alerts" section
5. **Verify Alert Rules**: Confirm all alerts are configured

## 📋 **Verification Checklist**

### **Dashboard Verification**
- [ ] All 3 dashboards imported successfully
- [ ] System Health dashboard shows collector status
- [ ] Performance dashboard shows CPU/memory metrics
- [ ] Application dashboard shows Service Worker status
- [ ] All panels refresh at correct intervals
- [ ] No error messages in dashboard panels

### **Alert Verification**
- [ ] All 10 alerts configured successfully
- [ ] 3 critical alerts configured
- [ ] 7 warning alerts configured
- [ ] Alert conditions are correct
- [ ] Alert durations are appropriate
- [ ] Notification channels are configured

### **Integration Verification**
- [ ] Dashboards show real-time data
- [ ] Alerts are monitoring correct metrics
- [ ] Canary events appear in dashboards
- [ ] Error conditions trigger alerts
- [ ] Notification delivery works

## 🚀 **Usage Examples**

### **Daily Operations**
`powershell
# Quick health check
pwsh -File scripts/health-check-observability-fixed.ps1

# Generate canary for testing
canary

# Check dashboard status
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
`

### **Troubleshooting**
`powershell
# Check Windows Event Log
Get-WinEvent -LogName Application | Where-Object { .ProviderName -eq "SigNoz-Canary" } | Select-Object -First 5

# Check collector service
Get-Service -Name "otelcol-contrib"

# Check Docker containers
docker ps --format "table {{.Names}}\t{{.Status}}"
`

### **Maintenance**
`powershell
# Update dashboards
pwsh -File scripts/import-signoz-dashboards.ps1 -All

# Update alerts
pwsh -File scripts/configure-signoz-alerts.ps1 -All

# Test configuration
pwsh -File scripts/import-signoz-dashboards.ps1 -All -DryRun
pwsh -File scripts/configure-signoz-alerts.ps1 -All -DryRun
`

## 📊 **Expected Results**

### **Dashboard Results**
- **System Health**: Real-time status of all components
- **Performance**: CPU, memory, network, disk metrics
- **Application**: Service Worker, COI, audio latency, WASM metrics
- **Refresh**: Dashboards update automatically
- **Data**: Historical trends and current values

### **Alert Results**
- **Critical Alerts**: Immediate notification for system failures
- **Warning Alerts**: Proactive notification for performance issues
- **Monitoring**: Continuous monitoring of all metrics
- **Notifications**: Email/Slack alerts for critical issues
- **Response**: Clear alert messages with actionable information

## 🔧 **Troubleshooting**

### **Common Issues**
- **Dashboard Import Fails**: Check SigNoz API accessibility
- **Alert Configuration Fails**: Verify alert syntax and conditions
- **No Data in Dashboards**: Check metric availability and queries
- **Alerts Not Triggering**: Verify alert conditions and thresholds

### **Resolution Steps**
1. **Check SigNoz Status**: Verify UI and API accessibility
2. **Verify Metrics**: Ensure metrics are being collected
3. **Check Logs**: Review SigNoz logs for errors
4. **Test Queries**: Verify PromQL queries in SigNoz UI
5. **Update Configuration**: Re-run scripts if needed

## 📝 **Next Steps**

### **Immediate Actions**
1. **Import Dashboards**: Use dashboard import script
2. **Configure Alerts**: Use alert configuration script
3. **Verify Implementation**: Check dashboards and alerts
4. **Test Functionality**: Generate canary and verify monitoring

### **Follow-up Actions**
1. **Customize Dashboards**: Adjust queries and thresholds
2. **Configure Notifications**: Set up email/Slack channels
3. **Create Runbooks**: Document alert response procedures
4. **Train Team**: Educate team on monitoring and alerting

### **Future Enhancements**
1. **Custom Metrics**: Add application-specific metrics
2. **Advanced Alerts**: Implement anomaly detection
3. **Historical Analysis**: Add trend analysis and forecasting
4. **Integration**: Connect with external monitoring systems

---
**Guide Generated**: 2025-01-27 16:45 UTC  
**Status**: Ready for implementation  
**Next**: Execute dashboard import and alert configuration scripts
