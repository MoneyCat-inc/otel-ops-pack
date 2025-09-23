# Kernel DMA Protection Enabler for Monolith-D
# ECRR Framework: Examine → Clean → Report → Role
# Based on provided BIOS/firmware requirements and registry configuration

param(
    [switch]$CheckBIOS = $true,
    [switch]$ApplyPolicy = $true,
    [switch]$Verify = $true,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date
$Hostname = $env:COMPUTERNAME

Write-Host "🔒 Kernel DMA Protection Enabler for $Hostname" -ForegroundColor Cyan
Write-Host "  ECRR Framework: Examine → Clean → Report → Role" -ForegroundColor Gray
Write-Host "  Timestamp: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# ECRR: Examine - Check current status
Write-Host "`n🔍 ECRR: Examining current DMA Protection status..." -ForegroundColor Cyan

$CurrentStatus = @{
    RegistryPath = "NOT_FOUND"
    DmaSecurityEnabled = "NOT_SET"
    DmaSecurityBoot = "NOT_SET"
    DmaDiagEnabled = "NOT_SET"
    RequiresReboot = $false
}

$DMAPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity'

try {
    if (Test-Path $DMAPath) {
        $CurrentStatus.RegistryPath = "EXISTS"
        Write-Host "  Registry path: EXISTS" -ForegroundColor Green
        
        # Check existing values
        $DmaEnabled = Get-ItemProperty -Path $DMAPath -Name 'DmaSecurityEnabled' -ErrorAction SilentlyContinue
        $DmaBoot = Get-ItemProperty -Path $DMAPath -Name 'DmaSecurityBoot' -ErrorAction SilentlyContinue
        $DmaDiag = Get-ItemProperty -Path $DMAPath -Name 'DmaDiagEnabled' -ErrorAction SilentlyContinue
        
        if ($DmaEnabled) {
            $CurrentStatus.DmaSecurityEnabled = $DmaEnabled.DmaSecurityEnabled
            Write-Host "  DmaSecurityEnabled: $($DmaEnabled.DmaSecurityEnabled)" -ForegroundColor $(if ($DmaEnabled.DmaSecurityEnabled -eq 1) { 'Green' } else { 'Yellow' })
        } else {
            Write-Host "  DmaSecurityEnabled: NOT_SET" -ForegroundColor Yellow
        }
        
        if ($DmaBoot) {
            $CurrentStatus.DmaSecurityBoot = $DmaBoot.DmaSecurityBoot
            Write-Host "  DmaSecurityBoot: $($DmaBoot.DmaSecurityBoot)" -ForegroundColor Gray
        }
        
        if ($DmaDiag) {
            $CurrentStatus.DmaDiagEnabled = $DmaDiag.DmaDiagEnabled
            Write-Host "  DmaDiagEnabled: $($DmaDiag.DmaDiagEnabled)" -ForegroundColor Gray
        }
        
    } else {
        Write-Host "  Registry path: NOT_FOUND" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Error examining status: $($_.Exception.Message)" -ForegroundColor Red
}

# BIOS/Firmware Requirements Check
if ($CheckBIOS) {
    Write-Host "`n🔧 BIOS/Firmware Requirements Check:" -ForegroundColor Yellow
    Write-Host "  ⚠️  Manual verification required:" -ForegroundColor Yellow
    Write-Host "    • SVM (AMD virtualization) - ENABLED" -ForegroundColor Gray
    Write-Host "    • IOMMU / AMD-Vi / PCIe ARI Support - ENABLED" -ForegroundColor Gray
    Write-Host "    • Secure Boot - ENABLED (already confirmed)" -ForegroundColor Green
    Write-Host "  💡 If any are OFF, enable them in BIOS first, save, and reboot" -ForegroundColor Cyan
}

# ECRR: Clean - Apply DMA Protection Policy
if ($ApplyPolicy) {
    Write-Host "`n🧹 ECRR: Applying Kernel DMA Protection policy..." -ForegroundColor Green
    
    try {
        # Ensure the DMA security registry hive exists
        Write-Host "  Creating registry path..." -ForegroundColor Yellow
        if (-not (Test-Path $DMAPath)) {
            New-Item -Path $DMAPath -Force | Out-Null
            Write-Host "    ✅ Registry path created" -ForegroundColor Green
        } else {
            Write-Host "    ✅ Registry path already exists" -ForegroundColor Green
        }
        
        # Enable DMA protection (1 = enabled, 0 = disabled)
        Write-Host "  Setting DmaSecurityEnabled = 1..." -ForegroundColor Yellow
        Set-ItemProperty -Path $DMAPath -Name 'DmaSecurityEnabled' -Type DWord -Value 1
        Write-Host "    ✅ DmaSecurityEnabled set to 1" -ForegroundColor Green
        
        # Enforce the policy during boot (prevents unprotected devices before Windows loads)
        Write-Host "  Setting DmaSecurityBoot = 1..." -ForegroundColor Yellow
        Set-ItemProperty -Path $DMAPath -Name 'DmaSecurityBoot' -Type DWord -Value 1
        Write-Host "    ✅ DmaSecurityBoot set to 1" -ForegroundColor Green
        
        # Optional: log protected devices for troubleshooting
        Write-Host "  Setting DmaDiagEnabled = 1..." -ForegroundColor Yellow
        Set-ItemProperty -Path $DMAPath -Name 'DmaDiagEnabled' -Type DWord -Value 1
        Write-Host "    ✅ DmaDiagEnabled set to 1" -ForegroundColor Green
        
        $CurrentStatus.RequiresReboot = $true
        
        Write-Host "`n✅ Kernel DMA Protection policy written successfully!" -ForegroundColor Green
        Write-Host "  ⚠️  REBOOT REQUIRED to take effect" -ForegroundColor Yellow
        
    } catch {
        Write-Host "    ❌ Error applying policy: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    💡 Ensure you're running as Administrator" -ForegroundColor Yellow
        return @{ Status = "ERROR"; Message = $_.Exception.Message }
    }
}

# ECRR: Report - Generate comprehensive report
Write-Host "`n📝 ECRR: Generating DMA Protection report..." -ForegroundColor Cyan

$Report = @{
    Timestamp = $StartTime
    Hostname = $Hostname
    User = $env:USERNAME
    Action = "Enable Kernel DMA Protection"
    RegistryPath = $DMAPath
    PolicyApplied = $ApplyPolicy
    RequiresReboot = $CurrentStatus.RequiresReboot
    CurrentStatus = $CurrentStatus
    NextSteps = @(
        "1. Verify BIOS settings (SVM, IOMMU, Secure Boot)",
        "2. Reboot the system",
        "3. Verify DMA Protection is enabled after reboot",
        "4. Run system-health-check.ps1 to confirm in SigNoz"
    )
    VerificationCommands = @{
        SystemInfo = "systeminfo | Select-String 'Kernel DMA Protection'"
        RegistryCheck = "(Get-ItemProperty -Path '$DMAPath').DmaSecurityEnabled"
        HealthCheck = "pwsh -File scripts\system-health-check.ps1"
    }
}

# Create artifacts directory
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$ReportPath = "artifacts/dma-protection-policy-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Report | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8

# Generate summary report
$SummaryReport = @"
# Kernel DMA Protection Policy Applied

**ECRR Framework**: Examine → Clean → Report → Role  
**Hostname**: $Hostname  
**Timestamp**: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))  
**Policy Applied**: $(if ($ApplyPolicy) { 'YES' } else { 'NO' })  
**Requires Reboot**: $(if ($CurrentStatus.RequiresReboot) { 'YES' } else { 'NO' })  

## Registry Configuration
- **Path**: $DMAPath
- **DmaSecurityEnabled**: 1 (enabled)
- **DmaSecurityBoot**: 1 (boot-time enforcement)
- **DmaDiagEnabled**: 1 (diagnostic logging)

## Next Steps
1. **BIOS Verification**: Ensure SVM, IOMMU, and Secure Boot are enabled
2. **System Reboot**: Required for policy to take effect
3. **Post-Reboot Verification**: Run verification commands
4. **SigNoz Monitoring**: Check system-health-check.ps1 output

## Verification Commands (Post-Reboot)
\`\`\`powershell
# Check system info
systeminfo | Select-String 'Kernel DMA Protection'

# Check registry
(Get-ItemProperty -Path '$DMAPath').DmaSecurityEnabled

# Run health check
pwsh -File scripts\system-health-check.ps1
\`\`\`

## Expected Results
- **System Info**: Kernel DMA Protection : On
- **Registry**: DmaSecurityEnabled = 1
- **SigNoz**: dma_protection="enabled"

**Role**: Cursor Agent - Observability Copilot  
**Status**: DMA Protection policy applied, reboot required
"@

$SummaryPath = $ReportPath -replace '\.json$', '-summary.md'
$SummaryReport | Out-File -FilePath $SummaryPath -Encoding UTF8

Write-Host "  Report saved: $ReportPath" -ForegroundColor Blue
Write-Host "  Summary: $SummaryPath" -ForegroundColor Blue

# ECRR: Role - Declare actor and next actions
Write-Host "`n🎭 ECRR: Role Declaration" -ForegroundColor Magenta
Write-Host "  Actor: Cursor Agent - Observability Copilot" -ForegroundColor White
Write-Host "  Action: Applied Kernel DMA Protection policy with comprehensive configuration" -ForegroundColor White
Write-Host "  Next: System reboot required, then verification via SigNoz monitoring" -ForegroundColor White

# Final status
Write-Host "`n🔒 Kernel DMA Protection policy written. Reboot required to take effect." -ForegroundColor Green
Write-Host "  📋 Reports: $ReportPath, $SummaryPath" -ForegroundColor Blue
Write-Host "  🔄 Next: Reboot system, then verify with provided commands" -ForegroundColor Yellow

return $Report
