# Quick Verification Script for Monolith-D System Status
# Generates artifacts for verification

$ErrorActionPreference = "Continue"
$StartTime = Get-Date
$Hostname = $env:COMPUTERNAME

Write-Host "🔍 Quick System Verification - $Hostname" -ForegroundColor Cyan
Write-Host "Timestamp: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Create artifacts directory
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$Results = @{
    Timestamp = $StartTime
    Hostname = $Hostname
    Checks = @{}
}

# Check 1: Kernel DMA Protection
Write-Host "`n🔒 Checking Kernel DMA Protection..." -ForegroundColor Yellow
$DMAPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity"
$DMAStatus = "NOT_CONFIGURED"
$DMADetails = "Registry path not found"

if (Test-Path $DMAPath) {
    Write-Host "   Registry path: EXISTS" -ForegroundColor Green
    $DMAValue = Get-ItemProperty -Path $DMAPath -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
    if ($DMAValue) {
        Write-Host "   DmaSecurityEnabled = $($DMAValue.DmaSecurityEnabled)" -ForegroundColor $(if ($DMAValue.DmaSecurityEnabled -eq 1) { 'Green' } else { 'Red' })
        $DMAStatus = if ($DMAValue.DmaSecurityEnabled -eq 1) { "ENABLED" } else { "DISABLED" }
        $DMADetails = "Registry value: $($DMAValue.DmaSecurityEnabled)"
    } else {
        Write-Host "   DmaSecurityEnabled: KEY_NOT_FOUND" -ForegroundColor Yellow
        $DMAStatus = "KEY_MISSING"
        $DMADetails = "DmaSecurityEnabled key not found"
    }
} else {
    Write-Host "   Registry path: NOT_FOUND" -ForegroundColor Red
    $DMAStatus = "PATH_MISSING"
    $DMADetails = "Registry path not found"
}

$Results.Checks.DMAProtection = @{
    Status = $DMAStatus
    Details = $DMADetails
    Success = $DMAStatus -eq "ENABLED"
}

# Check 2: Virtual Desktop Monitor
Write-Host "`n🖥️  Checking Virtual Desktop Monitor..." -ForegroundColor Yellow
$VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" -ErrorAction SilentlyContinue
if ($VDDevice) {
    Write-Host "   Device found: YES" -ForegroundColor Green
    Write-Host "   Status: $($VDDevice.Status)" -ForegroundColor $(if ($VDDevice.Status -eq "OK") { 'Green' } else { 'Yellow' })
    Write-Host "   InstanceId: $($VDDevice.InstanceId)" -ForegroundColor Gray
    $VDStatus = $VDDevice.Status
    $VDDetails = "InstanceId: $($VDDevice.InstanceId)"
} else {
    Write-Host "   Device: NOT_FOUND" -ForegroundColor Yellow
    $VDStatus = "NOT_FOUND"
    $VDDetails = "Device not found in system"
}

$Results.Checks.VirtualDesktopMonitor = @{
    Status = $VDStatus
    Details = $VDDetails
    Success = $VDStatus -eq "OK"
}

# Check 3: Phone App
Write-Host "`n📱 Checking Phone App..." -ForegroundColor Yellow
$PhonePackage = Get-AppxPackage -Name "Microsoft.YourPhone" -ErrorAction SilentlyContinue
$PhoneProcess = Get-Process -Name "PhoneExperienceHost" -ErrorAction SilentlyContinue

if ($PhonePackage) {
    Write-Host "   Package: INSTALLED" -ForegroundColor Green
    Write-Host "   Version: $($PhonePackage.Version)" -ForegroundColor Gray
    $PhoneStatus = if ($PhoneProcess) { "RUNNING" } else { "INSTALLED_NOT_RUNNING" }
    $PhoneDetails = "Package: $($PhonePackage.Version), Process: $(if ($PhoneProcess) { 'Running' } else { 'Not Running' })"
} else {
    Write-Host "   Package: NOT_FOUND" -ForegroundColor Red
    $PhoneStatus = "NOT_INSTALLED"
    $PhoneDetails = "Package not found"
}

$Results.Checks.PhoneApp = @{
    Status = $PhoneStatus
    Details = $PhoneDetails
    Success = $PhoneStatus -in @("RUNNING", "INSTALLED_NOT_RUNNING")
}

# Check 4: Crash Dumps
Write-Host "`n💥 Checking Crash Dumps..." -ForegroundColor Yellow
$WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
if (Test-Path $WERPath) {
    Write-Host "   WER directory: EXISTS" -ForegroundColor Green
    $CrashFiles = Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Crash dumps: $($CrashFiles.Count)" -ForegroundColor $(if ($CrashFiles.Count -eq 0) { 'Green' } else { 'Yellow' })
    $CrashStatus = if ($CrashFiles.Count -eq 0) { "CLEAN" } else { "HAS_FILES" }
    $CrashDetails = "Total crash files: $($CrashFiles.Count)"
} else {
    Write-Host "   WER directory: NOT_FOUND" -ForegroundColor Yellow
    $CrashStatus = "PATH_MISSING"
    $CrashDetails = "WER directory not found"
}

$Results.Checks.CrashDumps = @{
    Status = $CrashStatus
    Details = $CrashDetails
    Count = if (Test-Path $WERPath) { (Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count } else { 0 }
    Success = $CrashStatus -eq "CLEAN"
}

# Check 5: SigNoz
Write-Host "`n📡 Checking SigNoz..." -ForegroundColor Yellow
try {
    $SigNozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method GET -TimeoutSec 10
    Write-Host "   Health endpoint: $($SigNozHealth.status)" -ForegroundColor $(if ($SigNozHealth.status -eq "ok") { 'Green' } else { 'Red' })
    $SigNozStatus = if ($SigNozHealth.status -eq "ok") { "HEALTHY" } else { "UNHEALTHY" }
    $SigNozDetails = "Health: $($SigNozHealth.status)"
} catch {
    Write-Host "   Health endpoint: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    $SigNozStatus = "ERROR"
    $SigNozDetails = "Error: $($_.Exception.Message)"
}

$Results.Checks.SigNoz = @{
    Status = $SigNozStatus
    Details = $SigNozDetails
    Success = $SigNozStatus -eq "HEALTHY"
}

# Calculate summary
$TotalChecks = $Results.Checks.Count
$SuccessfulChecks = ($Results.Checks.Values | Where-Object { $_.Success }).Count
$SuccessRate = [math]::Round(($SuccessfulChecks / $TotalChecks) * 100, 1)

$Results.Summary = @{
    TotalChecks = $TotalChecks
    SuccessfulChecks = $SuccessfulChecks
    SuccessRate = $SuccessRate
    EndTime = Get-Date
    Duration = (Get-Date - $StartTime).TotalSeconds
}

# Save results
$ReportPath = "artifacts/quick-verify-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Results | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8

# Display summary
Write-Host "`n✅ Verification Complete!" -ForegroundColor Green
Write-Host "   Success Rate: $SuccessRate% ($SuccessfulChecks/$TotalChecks)" -ForegroundColor $(if ($SuccessRate -ge 80) { "Green" } elseif ($SuccessRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "   Report: $ReportPath" -ForegroundColor Blue

return $Results
