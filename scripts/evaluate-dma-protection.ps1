# DMA Protection Evaluation Script
# Usage: pwsh -File scripts/evaluate-dma-protection.ps1

Write-Host "🛡️  DMA Protection Evaluation" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Gray
Write-Host ""

# Check current DMA protection status
Write-Host "📋 Current Status:" -ForegroundColor Yellow
try {
    $dmaKey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
    
    if ($dmaKey) {
        Write-Host "✅ DMA Protection: ENABLED (Value: $($dmaKey.DmaSecurityEnabled))" -ForegroundColor Green
    } else {
        Write-Host "⚠️  DMA Protection: NOT CONFIGURED (Registry key missing)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ DMA Protection: UNKNOWN (Error checking registry)" -ForegroundColor Red
}

Write-Host ""

# Check system capabilities
Write-Host "🔍 System Capabilities:" -ForegroundColor Yellow
try {
    $secureBoot = Get-ComputerInfo -Property "SecureBoot" -ErrorAction SilentlyContinue
    if ($secureBoot) {
        Write-Host "Secure Boot: $($secureBoot.SecureBoot)" -ForegroundColor Gray
    }
    
    $tpm = Get-Tpm -ErrorAction SilentlyContinue
    if ($tpm) {
        Write-Host "TPM Status: $($tpm.TpmPresent)" -ForegroundColor Gray
        Write-Host "TPM Ready: $($tpm.TpmReady)" -ForegroundColor Gray
    }
} catch {
    Write-Host "System capability check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Provide recommendations
Write-Host "💡 Recommendations:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Enable DMA Protection (Recommended for enhanced security)" -ForegroundColor Green
Write-Host "  • Requires: Windows 10/11 Pro/Enterprise, Secure Boot, TPM 2.0" -ForegroundColor Gray
Write-Host "  • Command: Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config' -Name 'DmaSecurityEnabled' -Value 1" -ForegroundColor Gray
Write-Host "  • Restart required: Yes" -ForegroundColor Gray
Write-Host "  • Impact: Prevents DMA attacks, may affect some hardware" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 2: Document Exception (Current approach)" -ForegroundColor Blue
Write-Host "  • Document in hardening tracker as 'Low Priority'" -ForegroundColor Gray
Write-Host "  • Monitor for future Windows updates that may enable by default" -ForegroundColor Gray
Write-Host "  • Accept risk for development environment" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 3: Conditional Enablement" -ForegroundColor Cyan
Write-Host "  • Enable only on production systems" -ForegroundColor Gray
Write-Host "  • Keep disabled on development machines" -ForegroundColor Gray
Write-Host "  • Use Group Policy for enterprise deployment" -ForegroundColor Gray
Write-Host ""

# Check if this is a development environment
$isDev = $env:COMPUTERNAME -like "*DEV*" -or $env:COMPUTERNAME -like "*TEST*" -or $env:USERNAME -like "*dev*"
if ($isDev) {
    Write-Host "🏗️  Development Environment Detected" -ForegroundColor Magenta
    Write-Host "Recommendation: Document exception (Option 2)" -ForegroundColor Magenta
    Write-Host "Rationale: Development environments prioritize functionality over security hardening" -ForegroundColor Gray
} else {
    Write-Host "🏢 Production Environment Detected" -ForegroundColor Magenta
    Write-Host "Recommendation: Enable DMA Protection (Option 1)" -ForegroundColor Magenta
    Write-Host "Rationale: Production environments should maximize security hardening" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review system requirements and hardware compatibility" -ForegroundColor Gray
Write-Host "2. Test DMA protection in non-production environment first" -ForegroundColor Gray
Write-Host "3. Document decision in hardening tracker" -ForegroundColor Gray
Write-Host "4. Schedule maintenance window if enabling protection" -ForegroundColor Gray
