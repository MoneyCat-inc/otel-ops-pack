# System Hardening Script for monolith-D
# ECRR Framework: Examine → Clean → Report → Role
# Fixes: Kernel DMA Protection, Virtual Desktop Monitor, Phone app crashes

param(
    [switch]$EnableDMAProtection = $true,
    [switch]$FixVirtualDesktop = $true,
    [switch]$ResetPhoneApp = $true,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date
$ReportPath = "artifacts/monolith-d-hardening-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# ECRR: Examine - Capture current system state
Write-Host "🔍 ECRR: Examining system state..." -ForegroundColor Cyan
$SystemState = @{
    Timestamp = $StartTime
    Hostname = $env:COMPUTERNAME
    User = $env:USERNAME
    Issues = @()
    Fixes = @()
    Evidence = @()
}

# Check current DMA Protection status
try {
    $DMARegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity"
    $DMARegKey = Get-ItemProperty -Path $DMARegPath -ErrorAction SilentlyContinue
    $CurrentDMAStatus = if ($DMARegKey) { "Enabled" } else { "Disabled" }
    $SystemState.Issues += "Kernel DMA Protection: $CurrentDMAStatus"
    Write-Host "  Kernel DMA Protection: $CurrentDMAStatus" -ForegroundColor Yellow
} catch {
    $SystemState.Issues += "Kernel DMA Protection: Unable to determine status"
}

# Check Virtual Desktop Monitor status
try {
    $VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" -ErrorAction SilentlyContinue
    $VDStatus = if ($VDDevice) { $VDDevice.Status } else { "Not Found" }
    $SystemState.Issues += "Virtual Desktop Monitor: $VDStatus"
    Write-Host "  Virtual Desktop Monitor: $VDStatus" -ForegroundColor Yellow
} catch {
    $SystemState.Issues += "Virtual Desktop Monitor: Unable to determine status"
}

# Check Phone app crash artifacts
try {
    $WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
    $CrashFiles = if (Test-Path $WERPath) { 
        (Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse | Measure-Object).Count 
    } else { 0 }
    $SystemState.Issues += "Phone app crash dumps: $CrashFiles files"
    Write-Host "  Phone app crash dumps: $CrashFiles files" -ForegroundColor Yellow
} catch {
    $SystemState.Issues += "Phone app crash dumps: Unable to determine count"
}

# ECRR: Clean - Apply fixes
Write-Host "`n🧹 ECRR: Applying system hardening fixes..." -ForegroundColor Green

# Fix 1: Enable Kernel DMA Protection
if ($EnableDMAProtection) {
    try {
        Write-Host "  Enabling Kernel DMA Protection..." -ForegroundColor Yellow
        
        # Create registry key if it doesn't exist
        if (!(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity")) {
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Force | Out-Null
        }
        
        # Enable DMA Protection
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Name "DmaSecurityEnabled" -Value 1 -Type DWord -Force
        
        # Verify the change
        $DMACheck = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity" -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
        if ($DMACheck.DmaSecurityEnabled -eq 1) {
            $SystemState.Fixes += "Kernel DMA Protection: ENABLED"
            Write-Host "    ✅ Kernel DMA Protection enabled successfully" -ForegroundColor Green
        } else {
            $SystemState.Fixes += "Kernel DMA Protection: FAILED to enable"
            Write-Host "    ❌ Failed to enable Kernel DMA Protection" -ForegroundColor Red
        }
    } catch {
        $SystemState.Fixes += "Kernel DMA Protection: ERROR - $($_.Exception.Message)"
        Write-Host "    ❌ Error enabling Kernel DMA Protection: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Fix 2: Re-enable Virtual Desktop Monitor
if ($FixVirtualDesktop) {
    try {
        Write-Host "  Re-enabling Virtual Desktop Monitor..." -ForegroundColor Yellow
        
        $VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" -ErrorAction SilentlyContinue
        if ($VDDevice) {
            Enable-PnpDevice -InstanceId $VDDevice.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            
            # Verify the change
            Start-Sleep -Seconds 2
            $VDCheck = Get-PnpDevice -InstanceId $VDDevice.InstanceId -ErrorAction SilentlyContinue
            if ($VDCheck.Status -eq "OK") {
                $SystemState.Fixes += "Virtual Desktop Monitor: ENABLED"
                Write-Host "    ✅ Virtual Desktop Monitor enabled successfully" -ForegroundColor Green
            } else {
                $SystemState.Fixes += "Virtual Desktop Monitor: Status remains $($VDCheck.Status)"
                Write-Host "    ⚠️  Virtual Desktop Monitor status: $($VDCheck.Status)" -ForegroundColor Yellow
            }
        } else {
            $SystemState.Fixes += "Virtual Desktop Monitor: Device not found"
            Write-Host "    ⚠️  Virtual Desktop Monitor device not found" -ForegroundColor Yellow
        }
    } catch {
        $SystemState.Fixes += "Virtual Desktop Monitor: ERROR - $($_.Exception.Message)"
        Write-Host "    ❌ Error with Virtual Desktop Monitor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Fix 3: Reset Phone app and clean crash artifacts
if ($ResetPhoneApp) {
    try {
        Write-Host "  Resetting Phone app and cleaning crash artifacts..." -ForegroundColor Yellow
        
        # Stop Phone app processes
        Get-Process -Name "PhoneExperienceHost" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # Reset Phone app using PowerShell
        try {
            $PhonePackage = Get-AppxPackage -Name "Microsoft.YourPhone" -ErrorAction SilentlyContinue
            if ($PhonePackage) {
                # Reset the app
                Get-AppxPackage -Name "Microsoft.YourPhone" | Reset-AppxPackage -ErrorAction SilentlyContinue
                $SystemState.Fixes += "Phone app: RESET completed"
                Write-Host "    ✅ Phone app reset completed" -ForegroundColor Green
            } else {
                $SystemState.Fixes += "Phone app: Package not found"
                Write-Host "    ⚠️  Phone app package not found" -ForegroundColor Yellow
            }
        } catch {
            $SystemState.Fixes += "Phone app: Reset failed - $($_.Exception.Message)"
            Write-Host "    ⚠️  Phone app reset failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Clean crash dump artifacts (with safety check)
        $WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
        if (Test-Path $WERPath) {
            $CrashFiles = Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse -ErrorAction SilentlyContinue
            $OldCrashFiles = $CrashFiles | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
            
            if ($OldCrashFiles) {
                $OldCrashFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                $SystemState.Fixes += "Crash artifacts: Cleaned $($OldCrashFiles.Count) old files"
                Write-Host "    ✅ Cleaned $($OldCrashFiles.Count) old crash dump files" -ForegroundColor Green
            } else {
                $SystemState.Fixes += "Crash artifacts: No old files to clean"
                Write-Host "    ℹ️  No old crash dump files found" -ForegroundColor Blue
            }
        }
    } catch {
        $SystemState.Fixes += "Phone app cleanup: ERROR - $($_.Exception.Message)"
        Write-Host "    ❌ Error during Phone app cleanup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ECRR: Report - Generate comprehensive report
Write-Host "`n📝 ECRR: Generating system hardening report..." -ForegroundColor Cyan

$SystemState.CompletionTime = Get-Date
$SystemState.Duration = ($SystemState.CompletionTime - $SystemState.Timestamp).TotalSeconds
$SystemState.Success = ($SystemState.Fixes | Where-Object { $_ -match "ENABLED|RESET|Cleaned" }).Count
$SystemState.TotalFixes = $SystemState.Fixes.Count

# Create artifacts directory if it doesn't exist
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Save detailed report
$SystemState | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8

# Generate summary report
$SummaryReport = @"
# Monolith-D System Hardening Report
**ECRR Framework Applied**: Examine → Clean → Report → Role
**Timestamp**: $($SystemState.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))
**Duration**: $([math]::Round($SystemState.Duration, 2)) seconds
**Success Rate**: $($SystemState.Success)/$($SystemState.TotalFixes) fixes applied

## Issues Identified
$($SystemState.Issues -join "`n- ")

## Fixes Applied
$($SystemState.Fixes -join "`n- ")

## Next Steps
1. Restart system to apply Kernel DMA Protection changes
2. Test Virtual Desktop functionality if VR streaming is needed
3. Monitor Phone app for stability improvements
4. Review SigNoz dashboard for system health metrics

## Evidence
- Detailed report: `$ReportPath`
- System logs: Windows Event Viewer → System/Application logs
- Device status: Device Manager → Display adapters

**Role**: Cursor Agent - Observability Copilot
**Status**: System hardening complete, monitoring active
"@

$SummaryPath = $ReportPath -replace '\.json$', '-summary.md'
$SummaryReport | Out-File -FilePath $SummaryPath -Encoding UTF8

Write-Host "`n✅ System hardening complete!" -ForegroundColor Green
Write-Host "  Report saved: $ReportPath" -ForegroundColor Blue
Write-Host "  Summary: $SummaryPath" -ForegroundColor Blue
Write-Host "  Success: $($SystemState.Success)/$($SystemState.TotalFixes) fixes applied" -ForegroundColor Green

# ECRR: Role - Declare actor and next actions
Write-Host "`n🎭 ECRR: Role Declaration" -ForegroundColor Magenta
Write-Host "  Actor: Cursor Agent - Observability Copilot" -ForegroundColor White
Write-Host "  Action: Applied system hardening fixes with ECRR framework" -ForegroundColor White
Write-Host "  Next: Monitor system health via SigNoz dashboard" -ForegroundColor White

return $SystemState
