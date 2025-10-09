# BossCat OEM - Windows Service Recovery Configuration
# Hardens OTel collector service with automatic recovery and delayed start

<#
.SYNOPSIS
  Configures Windows service recovery for OTel collector.

.DESCRIPTION
  Sets up:
  - Automatic (Delayed) startup to avoid boot storms
  - Recovery actions: restart on 1st/2nd/3rd failure (5s delay each)
  - Reset failure count after 1 day

.PARAMETER ServiceName
  Windows service name (default: otelcol-contrib)

.EXAMPLE
  pwsh -File scripts\configure-service-recovery.ps1
  
.EXAMPLE
  pwsh -File scripts\configure-service-recovery.ps1 -ServiceName "my-otel-service"
#>

param(
  [string]$ServiceName = "otelcol-contrib"
)

Write-Host "🐾 BossCat OEM - Service Recovery Configuration" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

# Check if service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
  Write-Error "Service '$ServiceName' not found. Is OTel collector installed?"
  exit 1
}

Write-Host "[config] Configuring recovery for service: $ServiceName" -ForegroundColor Cyan

# --- 1) Set startup type to Automatic (Delayed) ---
Write-Host "`n[config] Step 1/3: Setting startup type..." -ForegroundColor Cyan

try {
  Set-Service -Name $ServiceName -StartupType Automatic
  Write-Host "   ✓ Set to Automatic" -ForegroundColor Green
  
  # Set delayed start (registry key)
  $svcKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
  if (Test-Path $svcKey) {
    Set-ItemProperty -Path $svcKey -Name "DelayedAutostart" -Value 1 -Force
    Write-Host "   ✓ Delayed start enabled (avoids boot storms)" -ForegroundColor Green
  }
} catch {
  Write-Error "Failed to set startup type: $_"
  exit 1
}

# --- 2) Configure recovery actions ---
Write-Host "`n[config] Step 2/3: Configuring recovery actions..." -ForegroundColor Cyan

try {
  # Recovery: restart on 1st/2nd/3rd failure with 5-second delays
  # Reset failure counter after 86400 seconds (1 day)
  $result = sc.exe failure $ServiceName `
    actions= restart/5000/restart/5000/restart/5000 `
    reset= 86400
  
  if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Recovery actions: Restart on failure (x3, 5s delay each)" -ForegroundColor Green
    Write-Host "   ✓ Failure counter reset: 1 day" -ForegroundColor Green
  } else {
    Write-Warning "   sc.exe failure returned code $LASTEXITCODE"
  }
  
  # Enable failure actions flag
  $flagResult = sc.exe failureflag $ServiceName 1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Failure actions enabled" -ForegroundColor Green
  }
  
} catch {
  Write-Error "Failed to configure recovery: $_"
  exit 1
}

# --- 3) Display configuration ---
Write-Host "`n[config] Step 3/3: Verifying configuration..." -ForegroundColor Cyan

$service.Refresh()
$service | Select-Object Name, Status, StartType | Format-List

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "✅ Recovery configuration complete" -ForegroundColor Green
Write-Host ""
Write-Host "Service: $ServiceName" -ForegroundColor White
Write-Host "Startup: Automatic (Delayed)" -ForegroundColor White
Write-Host "Recovery: Restart on failure (3 attempts, 5s delay)" -ForegroundColor White
Write-Host "Reset: After 1 day" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

Write-Host ""
Write-Host "🐾 BossCat OEM - Configuration Complete" -ForegroundColor Cyan

