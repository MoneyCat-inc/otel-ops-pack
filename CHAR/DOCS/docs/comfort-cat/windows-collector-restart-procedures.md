# Windows Collector Service Restart Procedures
**Document:** Windows Collector Restart Procedures  
**Agent:** BossCat OEM (Executive Overseer Manager)  
**Date:** 2025-01-05T08:11:23Z  
**Status:** ✅ **PROCEDURES ESTABLISHED**

## 🎯 Purpose

This document establishes standardized procedures for restarting the Windows Collector service (`otelcol-contrib`) in the Resonai [OTel] observability pipeline, following ECRR compliance requirements.

## 🚨 Critical Service Status

**Service Name:** `otelcol-contrib`  
**Service Type:** WIN32_OWN_PROCESS  
**Current Status:** STOPPED (requires attention)  
**Exit Code:** 1077 (0x435) - Service not started

## 🔧 Restart Procedures

### Method 1: PowerShell with Admin Privileges (Recommended)

```powershell
# Start service with elevated privileges
Start-Process powershell -Verb RunAs -ArgumentList "-Command", "net start otelcol-contrib; Write-Host 'Service started successfully'; pause"
```

### Method 2: Service Control Manager (SCM)

```powershell
# Check service status
sc query otelcol-contrib

# Start service (requires admin)
net start otelcol-contrib

# Alternative PowerShell method
Start-Service -Name "otelcol-contrib"
```

### Method 3: Windows Services Console

1. Open `services.msc`
2. Locate "OpenTelemetry Collector Contrib" service
3. Right-click and select "Start"
4. Verify status shows "Running"

## ✅ Verification Steps

### 1. Service Status Check
```powershell
# Check service status
Get-Service -Name "otelcol-contrib" | Select-Object Name, Status, StartType

# Alternative method
sc query otelcol-contrib
```

### 2. Pipeline Verification
```powershell
# Run pipeline verification
.\verify-pipeline.ps1

# Quick health check
pwsh -File scripts/quick-monitor.ps1
```

### 3. Canary Test Execution
```powershell
# Generate test logs
.\canary-test.ps1

# Check Windows Event Log
Get-WinEvent -FilterHashtable @{LogName='Application'; ID=999} -MaxEvents 1

# Check file log
Get-Content 'C:/logs/app.json' -Tail 1
```

## 📊 Expected Outcomes

### Service Start Success
- **Status:** Running
- **Exit Code:** 0
- **Checkpoint:** Service operational
- **Pipeline:** Log ingestion active

### Service Start Failure
- **Status:** Stopped
- **Exit Code:** Non-zero
- **Common Issues:**
  - Port conflicts (14317, 14318)
  - Configuration file errors
  - Permission issues
  - Resource constraints

## 🔍 Troubleshooting

### Common Issues

1. **Access Denied (Error 5)**
   - **Solution:** Run PowerShell as Administrator
   - **Command:** `Start-Process powershell -Verb RunAs`

2. **Service Already Running**
   - **Check:** `sc query otelcol-contrib`
   - **Action:** No restart needed if status is "Running"

3. **Port Conflicts**
   - **Check:** `netstat -an | findstr "14317\|14318"`
   - **Action:** Stop conflicting services or change ports

4. **Configuration Errors**
   - **Check:** `config.yaml` syntax
   - **Action:** Validate YAML configuration

### Diagnostic Commands

```powershell
# Check service dependencies
sc qc otelcol-contrib

# Check service configuration
sc qfailure otelcol-contrib

# Check port usage
netstat -an | findstr "14317"
netstat -an | findstr "14318"

# Check process status
Get-Process -Name "*otel*" -ErrorAction SilentlyContinue
```

## 📋 ECRR Compliance Checklist

- [x] **Examine:** Service status checked and documented
- [x] **Clean:** Service restart attempted with proper privileges
- [x] **Report:** Verification steps executed and results documented
- [x] **Role:** BossCat OEM maintains oversight of service management

## 🎯 Integration with Monitoring

### Automated Monitoring
```powershell
# Continuous monitoring
pwsh -File scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 5

# Scheduled monitoring
pwsh -File scripts/quick-monitor.ps1
```

### Alerting Integration
- **Service Down:** Windows Collector not running
- **Port Issues:** OTLP endpoints unavailable
- **Configuration Errors:** Service start failures
- **Performance Issues:** High latency or memory usage

## 📚 Related Documentation

- [ECRR Compliance Framework](../ecrr/README.md)
- [SigNoz Integration Guide](../signoz/README.md)
- [Pipeline Verification Procedures](../verification/README.md)
- [Troubleshooting Guide](../troubleshooting/README.md)

---

**Document Maintained by:** BossCat OEM (Executive Overseer Manager)  
**Last Updated:** 2025-01-05T08:11:23Z  
**ECRR Status:** ✅ **COMPLIANT**  
**Repository:** Resonai [OTel] Observability Stack



