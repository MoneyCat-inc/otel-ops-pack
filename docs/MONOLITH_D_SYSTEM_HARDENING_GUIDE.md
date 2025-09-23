# Monolith-D System Hardening Guide

## Overview

This guide addresses critical system security and stability issues identified on monolith-D:

1. **Kernel DMA Protection Disabled** - Thunderbolt/PCIe peripherals lack DMA guard hardening
2. **Virtual Desktop Monitor Disabled** - VR streaming driver disabled in Problem Devices
3. **Phone App Crashes** - PhoneExperienceHost.exe crashing with Microsoft.UI.Xaml.dll

## Quick Fix Commands

### 1. Apply System Hardening
```powershell
# Run comprehensive system hardening script
pwsh -File scripts\fix-monolith-d-issues.ps1 -Verbose

# Expected output: DMA Protection enabled, devices re-enabled, crash artifacts cleaned
```

### 2. Monitor System Health
```powershell
# Start system health monitoring (5 minutes)
pwsh -File scripts\monitor-system-health.ps1 -DurationMinutes 5

# Expected output: Real-time metrics sent to SigNoz, alerts generated
```

### 3. Verify in SigNoz
- **UI**: http://localhost:8080
- **Query**: `dataset = "system_health"`
- **Dashboard**: Import `docs/system-health-dashboard.json`

## Detailed Fixes

### Kernel DMA Protection

**Issue**: Kernel DMA Protection is disabled, leaving Thunderbolt/PCIe peripherals without DMA guard hardening.

**Fix**:
```powershell
# Enable via registry
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Name "DmaSecurityEnabled" -Value 1 -Type DWord

# Verify
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Name "DmaSecurityEnabled"
```

**Expected Result**: Registry value `DmaSecurityEnabled = 1`

**Note**: Requires system restart to take effect.

### Virtual Desktop Monitor

**Issue**: Virtual Desktop Monitor device is present but explicitly disabled under Problem Devices.

**Fix**:
```powershell
# Find and re-enable the device
$VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*"
Enable-PnpDevice -InstanceId $VDDevice.InstanceId -Confirm:$false

# Verify status
Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" | Select-Object Status
```

**Expected Result**: Device status changes from "Disabled" to "OK"

### Phone App Crashes

**Issue**: PhoneExperienceHost.exe crashing with Microsoft.UI.Xaml.dll (exception 0xc000027b).

**Fix**:
```powershell
# Stop the app
Get-Process -Name "PhoneExperienceHost" -ErrorAction SilentlyContinue | Stop-Process -Force

# Reset the app
Get-AppxPackage -Name "Microsoft.YourPhone" | Reset-AppxPackage

# Clean old crash dumps (older than 7 days)
$WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
    Remove-Item -Force
```

**Expected Result**: App resets successfully, old crash dumps removed

## Monitoring & Verification

### SigNoz Dashboard

1. **Import Dashboard**:
   - Go to SigNoz UI → Dashboards → Import
   - Upload `docs/system-health-dashboard.json`

2. **Key Metrics**:
   - DMA Protection Status (should be green)
   - Virtual Desktop Monitor Status (should be green)
   - Phone App Stability (should be green/yellow)
   - Recent Crashes (should be 0)

3. **Log Queries**:
   ```sql
   -- System health metrics
   dataset = "system_health"
   
   -- DMA Protection status
   dataset = "system_health" AND body contains "DMAProtection"
   
   -- Device status
   dataset = "system_health" AND body contains "Devices"
   
   -- Application stability
   dataset = "system_health" AND body contains "ApplicationStability"
   ```

### Health Check Commands

```powershell
# Quick status check
pwsh -File scripts\quick-monitor.ps1

# Detailed system health
pwsh -File scripts\monitor-system-health.ps1 -DurationMinutes 10

# Verify fixes applied
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" | Select-Object Status
Get-AppxPackage -Name "Microsoft.YourPhone" | Select-Object Status
```

## Troubleshooting

### DMA Protection Not Enabling
- **Cause**: Registry key creation failed or insufficient permissions
- **Fix**: Run PowerShell as Administrator
- **Verify**: Check Event Viewer → System logs for DMA-related errors

### Virtual Desktop Monitor Still Disabled
- **Cause**: Driver issues or hardware conflicts
- **Fix**: Update Virtual Desktop drivers, check Device Manager for conflicts
- **Alternative**: Disable if VR streaming not needed

### Phone App Still Crashing
- **Cause**: Windows App Runtime issues or corrupted app data
- **Fix**: 
  ```powershell
  # Complete app removal and reinstall
  Get-AppxPackage -Name "Microsoft.YourPhone" | Remove-AppxPackage
  # Reinstall from Microsoft Store
  ```

### SigNoz Not Receiving Data
- **Cause**: OTLP endpoint not accessible or collector down
- **Fix**: 
  ```powershell
  # Check collector status
  sc query otelcol-contrib
  
  # Verify SigNoz health
  Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"
  ```

## ECRR Compliance

All fixes follow the ECRR framework:

1. **Examine** - System state captured before changes
2. **Clean** - Drift removed, security hardened
3. **Report** - Artifacts generated in `artifacts/` directory
4. **Role** - Cursor Agent - Observability Copilot declared

## Next Steps

1. **Immediate**: Apply hardening fixes and verify in SigNoz
2. **Short-term**: Monitor system stability for 24-48 hours
3. **Long-term**: Integrate system health monitoring into regular operations
4. **Maintenance**: Run health checks weekly, update dashboard as needed

## Files Created

- `scripts/fix-monolith-d-issues.ps1` - Main hardening script
- `scripts/monitor-system-health.ps1` - Health monitoring script
- `docs/system-health-dashboard.json` - SigNoz dashboard configuration
- `docs/MONOLITH_D_SYSTEM_HARDENING_GUIDE.md` - This guide

## Support

For issues or questions:
1. Check SigNoz dashboard for real-time status
2. Review artifacts in `artifacts/` directory
3. Run health check scripts for diagnostics
4. Consult Windows Event Viewer for detailed error logs
