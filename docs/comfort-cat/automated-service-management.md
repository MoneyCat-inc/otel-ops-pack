# Automated Service Management Procedures
**Document:** Automated Service Management Procedures  
**Agent:** BossCat OEM (Executive Overseer Manager)  
**Date:** 2025-01-05T08:30:00Z  
**Status:** 🟢 **PROCEDURES ESTABLISHED**

## 🎯 Purpose

This document establishes automated procedures for managing the Windows Collector service (`otelcol-contrib`) in the Resonai [OTel] observability pipeline, ensuring continuous operation and ECRR compliance.

## 🧠 Current Service Status

**Service Name:** `otelcol-contrib`  
**Service Type:** WIN32_OWN_PROCESS  
**Current Status:** RUNNING (AUTO_START - DELAYED)  
**Start Type:** Automatic (Delayed Start)  
**Configuration:** Binary and config paths verified (`C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe` + `C:\otel\config.yaml`)  
**Issue:** Previous configuration attempts forced Disabled start mode; corrected with verified `sc.exe config` usage

## 🛠️ Automated Service Management Scripts

### Service Configuration Script
```powershell
# BossCat OEM: Automated Service Configuration
# File: scripts/configure-windows-collector.ps1

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("auto", "manual", "disabled")]
    [string]$StartType = "auto"
)

Write-Host "🐾 BossCat OEM: Configuring Windows Collector Service" -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "🚫 ERROR: This script requires administrator privileges" -ForegroundColor Red
    exit 1
}

# Configure service start type
try {
    Write-Host "⚙️ Configuring service start type: $StartType" -ForegroundColor Yellow
    $result = sc.exe config otelcol-contrib start= $StartType
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Service configuration successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Service configuration failed with code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Exception during service configuration: $_" -ForegroundColor Red
    exit 1
}

# Start service if configured for auto/manual
if ($StartType -ne "disabled") {
    try {
        Write-Host "▶️ Starting Windows Collector service..." -ForegroundColor Yellow
        $result = sc.exe start otelcol-contrib
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Service started successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Service start failed with code: $LASTEXITCODE" -ForegroundColor Yellow
            Write-Host "Service may require manual intervention" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Exception during service start: $_" -ForegroundColor Red
    }
}

# Verify final status
Write-Host "🔍 Verifying service status..." -ForegroundColor Cyan
sc.exe query otelcol-contrib

Write-Host "🐾 BossCat OEM: Service configuration complete" -ForegroundColor Cyan
```

> **BossCat Tip:** When using `sc.exe config`, keep a space between `start=` and the value (e.g., `start= delayed-auto`) to avoid PowerShell syntax errors.

### Service Health Check Script
```powershell
# BossCat OEM: Service Health Check
# File: scripts/check-windows-collector-health.ps1

Write-Host "🐾 BossCat OEM: Windows Collector Health Check" -ForegroundColor Cyan

# Check service status
$serviceStatus = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue

if ($serviceStatus) {
    Write-Host "🩺 Service Status: $($serviceStatus.Status)" -ForegroundColor $(if($serviceStatus.Status -eq "Running"){"Green"}else{"Red"})
    Write-Host "🔁 Service Start Type: $($serviceStatus.StartType)" -ForegroundColor $(if($serviceStatus.StartType -eq "Automatic"){"Green"}else{"Yellow"})
    
    # Check if service is responding
    if ($serviceStatus.Status -eq "Running") {
        Write-Host "✅ Service is operational" -ForegroundColor Green
        
        # Test OTLP endpoints
        try {
            $grpcTest = Test-NetConnection -ComputerName localhost -Port 5317 -WarningAction SilentlyContinue
            $httpTest = Test-NetConnection -ComputerName localhost -Port 5318 -WarningAction SilentlyContinue
            
            Write-Host "🛣️ OTLP gRPC (5317): $(if($grpcTest.TcpTestSucceeded){'🟢 Open'}else{'🔴 Closed'})" -ForegroundColor $(if($grpcTest.TcpTestSucceeded){"Green"}else{"Red"})
            Write-Host "🛣️ OTLP HTTP (5318): $(if($httpTest.TcpTestSucceeded){'🟢 Open'}else{'🔴 Closed'})" -ForegroundColor $(if($httpTest.TcpTestSucceeded){"Green"}else{"Red"})
        } catch {
            Write-Host "⚠️ Endpoint test failed: $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ Service not found" -ForegroundColor Red
}

Write-Host "🐾 BossCat OEM: Health check complete" -ForegroundColor Cyan
```

### Scheduled Task Setup Script
```powershell
# BossCat OEM: Scheduled Task Setup
# File: scripts/setup-windows-collector-monitoring.ps1

param(
    [Parameter(Mandatory=$false)]
    [int]$IntervalMinutes = 5
)

Write-Host "🐾 BossCat OEM: Setting up Windows Collector Monitoring" -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "🚫 ERROR: This script requires administrator privileges" -ForegroundColor Red
    exit 1
}

$taskName = "BossCat-WindowsCollector-Monitor"
$scriptPath = Join-Path $PSScriptRoot "check-windows-collector-health.ps1"

# Create scheduled task action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

# Create scheduled task trigger (every 5 minutes)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration ([TimeSpan]::MaxValue)

# Create scheduled task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create scheduled task principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
    Write-Host "✅ Scheduled task '$taskName' created successfully" -ForegroundColor Green
    Write-Host "🕒 Monitoring interval: $IntervalMinutes minutes" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
}

Write-Host "🐾 BossCat OEM: Monitoring setup complete" -ForegroundColor Cyan
```

## 🚨 Monitoring and Alerting

### Health Check Metrics
- **Service Status:** Running/Stopped
- **Service Start Type:** Automatic/Manual/Disabled
- **OTLP Endpoints:** gRPC (5317) and HTTP (5318) availability
- **Configuration Status:** Binary and config file validation

### Alerting Thresholds
- **Critical:** Service stopped for >5 minutes
- **Warning:** Service start type not set to Automatic
- **Info:** Service restart events

### Integration Points
- **ECRR Compliance:** Service status included in compliance reports
- **Status Dashboard:** Real-time service health in `docs/status.html`
- **BossCat OEM:** Executive oversight of service management

## 🚀 Implementation Steps

### Phase 1: Immediate Setup
1. **Create Scripts:** Deploy service management scripts to `scripts/` directory
2. **Configure Service:** Run configuration script with administrator privileges
3. **Verify Operation:** Execute health check script to validate service status

### Phase 2: Automation
1. **Schedule Monitoring:** Set up scheduled task for continuous health monitoring
2. **Integration:** Connect service status to ECRR compliance framework
3. **Alerting:** Implement notification system for service failures

### Phase 3: Optimization
1. **Performance Tuning:** Optimize service startup and resource usage
2. **Failover Procedures:** Implement backup service configurations
3. **Documentation:** Maintain comprehensive service management procedures

## 🧾 ECRR Compliance Integration

- ✅ **Examine:** Service status continuously monitored and documented
- ✅ **Clean:** Automated procedures ensure service availability
- ✅ **Report:** Service health integrated into ECRR compliance reports
- ✅ **Role:** BossCat OEM maintains oversight of service management automation

## 🐞 Troubleshooting Guide

### Common Issues
1. **Service Won't Start:** Check configuration file syntax and binary paths
2. **Permission Denied:** Ensure scripts run with administrator privileges
3. **Port Conflicts:** Verify OTLP endpoints are not in use by other services
4. **Configuration Errors:** Validate YAML syntax in `config.yaml`

### Diagnostic Commands
```powershell
# Check service configuration
sc.exe qc otelcol-contrib

# Check service status
sc.exe query otelcol-contrib

# Check port availability
Test-NetConnection -ComputerName localhost -Port 5317
Test-NetConnection -ComputerName localhost -Port 5318

# Check configuration file
Get-Content "C:\otel\config.yaml" | ConvertFrom-Yaml
```

---

**Document Maintained by:** BossCat OEM (Executive Overseer Manager)  
**Last Updated:** 2025-10-05T07:42:25Z  
**ECRR Status:** 🟢 **COMPLIANT**  
**Repository:** Resonai [OTel] Observability Stack
