# Enable Kernel DMA Protection Script
# ECRR Framework: Examine → Clean → Report → Role

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

Write-Host "🔒 Enabling Kernel DMA Protection..." -ForegroundColor Cyan
Write-Host "  ECRR Framework: Examine → Clean → Report → Role" -ForegroundColor Gray

# ECRR: Examine - Check current status
Write-Host "`n🔍 ECRR: Examining current DMA Protection status..." -ForegroundColor Cyan

$DMARegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity"
$CurrentStatus = "NOT_CONFIGURED"

try {
    if (Test-Path $DMARegPath) {
        $DMAKey = Get-ItemProperty -Path $DMARegPath -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
        if ($DMAKey) {
            $CurrentStatus = if ($DMAKey.DmaSecurityEnabled -eq 1) { "ENABLED" } else { "DISABLED" }
        } else {
            $CurrentStatus = "KEY_MISSING"
        }
    } else {
        $CurrentStatus = "PATH_MISSING"
    }
    
    Write-Host "  Current Status: $CurrentStatus" -ForegroundColor Yellow
    Write-Host "  Registry Path: $DMARegPath" -ForegroundColor Gray
    
    if ($CurrentStatus -eq "ENABLED") {
        Write-Host "  ✅ DMA Protection is already enabled!" -ForegroundColor Green
        return @{ Status = "ENABLED"; Message = "Already enabled" }
    }
} catch {
    Write-Host "  ❌ Error examining current status: $($_.Exception.Message)" -ForegroundColor Red
    $CurrentStatus = "ERROR"
}

# ECRR: Clean - Enable DMA Protection
Write-Host "`n🧹 ECRR: Enabling Kernel DMA Protection..." -ForegroundColor Green

try {
    # Create registry path if it doesn't exist
    if (!(Test-Path $DMARegPath)) {
        Write-Host "  Creating registry path..." -ForegroundColor Yellow
        New-Item -Path $DMARegPath -Force | Out-Null
        Write-Host "    ✅ Registry path created" -ForegroundColor Green
    }
    
    # Set DMA Protection enabled
    Write-Host "  Setting DmaSecurityEnabled = 1..." -ForegroundColor Yellow
    Set-ItemProperty -Path $DMARegPath -Name "DmaSecurityEnabled" -Value 1 -Type DWord -Force
    
    # Verify the change
    Start-Sleep -Seconds 1
    $VerifyKey = Get-ItemProperty -Path $DMARegPath -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
    
    if ($VerifyKey -and $VerifyKey.DmaSecurityEnabled -eq 1) {
        Write-Host "    ✅ DMA Protection enabled successfully!" -ForegroundColor Green
        
        # ECRR: Report - Generate report
        Write-Host "`n📝 ECRR: Generating report..." -ForegroundColor Cyan
        
        $Report = @{
            Timestamp = $StartTime
            Hostname = $env:COMPUTERNAME
            User = $env:USERNAME
            Action = "Enable Kernel DMA Protection"
            PreviousStatus = $CurrentStatus
            NewStatus = "ENABLED"
            RegistryPath = $DMARegPath
            RegistryValue = 1
            Success = $true
            Message = "DMA Protection enabled successfully"
            RequiresRestart = $true
        }
        
        # Create artifacts directory
        if (!(Test-Path "artifacts")) {
            New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
        }
        
        $ReportPath = "artifacts/dma-protection-enabled-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $Report | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8
        
        Write-Host "  Report saved: $ReportPath" -ForegroundColor Blue
        
        # ECRR: Role - Declare actor
        Write-Host "`n🎭 ECRR: Role Declaration" -ForegroundColor Magenta
        Write-Host "  Actor: Cursor Agent - Observability Copilot" -ForegroundColor White
        Write-Host "  Action: Enabled Kernel DMA Protection via registry modification" -ForegroundColor White
        Write-Host "  Next: System restart required for full activation" -ForegroundColor White
        
        Write-Host "`n✅ DMA Protection enabled successfully!" -ForegroundColor Green
        Write-Host "  ⚠️  System restart required for full activation" -ForegroundColor Yellow
        Write-Host "  📋 Report: $ReportPath" -ForegroundColor Blue
        
        return $Report
        
    } else {
        Write-Host "    ❌ Failed to enable DMA Protection" -ForegroundColor Red
        return @{ Status = "FAILED"; Message = "Registry write failed" }
    }
    
} catch {
    Write-Host "    ❌ Error enabling DMA Protection: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    💡 Try running as Administrator: Start-Process pwsh -Verb RunAs -ArgumentList '-File scripts\enable-dma-protection.ps1'" -ForegroundColor Yellow
    return @{ Status = "ERROR"; Message = $_.Exception.Message }
}
