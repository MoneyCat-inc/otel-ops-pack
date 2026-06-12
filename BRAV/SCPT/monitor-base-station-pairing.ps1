#Requires -Version 7.0

<#
.SYNOPSIS
    Monitor for base station pairing and notify when detected

.DESCRIPTION
    Opens Bluetooth settings and monitors for newly paired HTC Vive base stations.
    Provides real-time feedback when pairing is successful.

.EXAMPLE
    .\monitor-base-station-pairing.ps1
    Start monitoring for base station pairing
#>

[CmdletBinding()]
param(
    [int]$MonitorDuration = 120
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "Base Station Pairing Monitor" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Get initial device count
$initialDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($initialDevices.Count -gt 0) {
    Write-Status "✅ Found $($initialDevices.Count) already-paired base station(s)!" -Level SUCCESS
    foreach ($device in $initialDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
    }
    Write-Host ""
    Write-Status "Base stations already paired. Exiting." -Level SUCCESS
    exit 0
}

Write-Status "No base stations currently paired" -Level INFO
Write-Host ""

# Instructions
Write-Status "⚠️  Put base stations in pairing mode:" -Level WARN
Write-Host ""
Write-Host "Base Station 1.0:" -ForegroundColor Yellow
Write-Host "  • Press and HOLD Channel button (on back)" -ForegroundColor White
Write-Host "  • Wait for LED to blink" -ForegroundColor White
Write-Host "  • Release button" -ForegroundColor White
Write-Host ""
Write-Host "Base Station 2.0:" -ForegroundColor Yellow
Write-Host "  • Press Mode button" -ForegroundColor White
Write-Host "  • LED should change pattern" -ForegroundColor White
Write-Host ""

# Open Bluetooth settings
Write-Status "Opening Bluetooth settings..." -Level INFO
try {
    Start-Process "ms-settings:bluetooth" -ErrorAction Stop
    Write-Status "✅ Bluetooth settings opened" -Level SUCCESS
} catch {
    Write-Status "Could not open settings: $($_.Exception.Message)" -Level ERROR
    exit 1
}

Write-Host ""
Write-Host "In the Bluetooth settings window:" -ForegroundColor Yellow
Write-Host "1. Click 'Add Bluetooth or other device'" -ForegroundColor White
Write-Host "2. Select 'Bluetooth'" -ForegroundColor White
Write-Host "3. Look for devices named:" -ForegroundColor White
Write-Host "   • LHB-XXXX (Lighthouse Base Station)" -ForegroundColor Cyan
Write-Host "   • HTC Base Station" -ForegroundColor Cyan
Write-Host "   • Vive Base Station" -ForegroundColor Cyan
Write-Host "4. Click the device to pair" -ForegroundColor White
Write-Host ""
Write-Status "Monitoring for $MonitorDuration seconds..." -Level INFO
Write-Host ""

# Monitor for new devices
$startTime = Get-Date
$endTime = $startTime.AddSeconds($MonitorDuration)
$lastCount = 0

while ((Get-Date) -lt $endTime) {
    $currentDevices = Get-PnpDevice | Where-Object {
        $_.FriendlyName -like "*Vive*" -or
        $_.FriendlyName -like "*LHB*" -or
        $_.FriendlyName -like "*Lighthouse*" -or
        ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
    }
    
    $currentCount = $currentDevices.Count
    
    if ($currentCount -gt $lastCount) {
        Write-Host ""
        Write-Status "🎉 NEW BASE STATION DETECTED!" -Level SUCCESS
        
        $newDevices = $currentDevices | Where-Object {
            $initialDevices -notcontains $_
        }
        
        foreach ($device in $newDevices) {
            Write-Host "  ✅ $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
        }
        
        $lastCount = $currentCount
    }
    
    $remaining = [math]::Round(($endTime - (Get-Date)).TotalSeconds, 0)
    if ($remaining -gt 0) {
        Write-Progress -Activity "Monitoring for base stations" -Status "Time remaining: $remaining seconds | Found: $currentCount" -PercentComplete ((($MonitorDuration - $remaining) / $MonitorDuration) * 100)
    }
    
    Start-Sleep -Seconds 2
}

Write-Progress -Activity "Monitoring for base stations" -Completed

# Final check
Write-Host ""
Write-Status "Final check..." -Level INFO

$finalDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($finalDevices.Count -gt 0) {
    Write-Host ""
    Write-Status "✅ SUCCESS! $($finalDevices.Count) base station(s) paired!" -Level SUCCESS
    foreach ($device in $finalDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Status "You can now extract data:" -Level SUCCESS
    Write-Host "  pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Status "⚠️  No base stations detected after monitoring period" -Level WARN
    Write-Host ""
    Write-Host "If you paired devices, they may need a moment to appear." -ForegroundColor Yellow
    Write-Host "Try running the extraction script:" -ForegroundColor Yellow
    Write-Host "  pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1" -ForegroundColor Cyan
}
