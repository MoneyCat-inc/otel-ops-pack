#Requires -Version 7.0

<#
.SYNOPSIS
    Automated base station pairing using Windows Bluetooth APIs

.DESCRIPTION
    Attempts to discover and pair HTC Vive base stations automatically.
    May still require user confirmation for security.

.PARAMETER ScanDuration
    How long to scan for devices (seconds). Default: 30

.EXAMPLE
    .\auto-pair-vive-base-stations.ps1
    Scan and attempt to pair base stations
#>

[CmdletBinding()]
param(
    [int]$ScanDuration = 30
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "Automated HTC Vive Base Station Pairing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if base stations are already paired
Write-Status "Checking for existing paired base stations..." -Level INFO

$existingDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($existingDevices.Count -gt 0) {
    Write-Status "✅ Found $($existingDevices.Count) already-paired base station(s)!" -Level SUCCESS
    foreach ($device in $existingDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
    }
    Write-Host ""
    Write-Status "Base stations are already paired. No action needed." -Level SUCCESS
    exit 0
}

Write-Status "No base stations currently paired. Starting discovery..." -Level INFO
Write-Host ""

# Instructions
Write-Status "⚠️  IMPORTANT: Put base stations in pairing mode NOW!" -Level WARN
Write-Host ""
Write-Host "Base Station 1.0:" -ForegroundColor Yellow
Write-Host "  • Press and HOLD the Channel button (on back)" -ForegroundColor White
Write-Host "  • Wait for LED to blink" -ForegroundColor White
Write-Host "  • Release button" -ForegroundColor White
Write-Host ""
Write-Host "Base Station 2.0:" -ForegroundColor Yellow
Write-Host "  • Press the Mode button" -ForegroundColor White
Write-Host "  • LED should change pattern" -ForegroundColor White
Write-Host ""
Write-Host "Starting discovery in 5 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Method 1: Use Windows Bluetooth Device Enumeration
Write-Status "Scanning for Bluetooth devices..." -Level INFO

# Try to use bthprops.cpl (Bluetooth Control Panel)
try {
    Write-Status "Opening Bluetooth device management..." -Level INFO
    Start-Process "bthprops.cpl" -ErrorAction Stop
    Write-Status "✅ Bluetooth control panel opened" -Level SUCCESS
    Write-Host "  In the Bluetooth window, click 'Add Device'" -ForegroundColor Yellow
} catch {
    Write-Status "Could not open Bluetooth control panel" -Level WARN
}

# Method 2: Use PowerShell to interact with Windows.Devices.Bluetooth
Write-Host ""
Write-Status "Attempting programmatic device discovery..." -Level INFO

try {
    # Load Windows Runtime assemblies
    [Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher, Windows.Devices.Bluetooth, ContentType = WindowsRuntime] | Out-Null
    
    $watcher = New-Object Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher
    $watcher.ScanningMode = [Windows.Devices.Bluetooth.Advertisement.BluetoothLEScanningMode]::Active
    
    $discoveredDevices = @()
    
    # Event handler for discovered devices
    $watcher.add_Received({
        param($sender, $args)
        $deviceName = $args.Advertisement.LocalName
        $deviceAddress = $args.BluetoothAddress
        
        if ($deviceName -and (
            $deviceName -like "*LHB*" -or
            $deviceName -like "*Lighthouse*" -or
            $deviceName -like "*Vive*" -or
            $deviceName -like "*HTC*Base*"
        )) {
            $discoveredDevices += @{
                Name = $deviceName
                Address = $deviceAddress
                Timestamp = Get-Date
            }
            Write-Host "  🔍 Found: $deviceName (Address: $deviceAddress)" -ForegroundColor Green
        }
    })
    
    Write-Status "Starting Bluetooth LE scan for $ScanDuration seconds..." -Level INFO
    $watcher.Start()
    
    $endTime = (Get-Date).AddSeconds($ScanDuration)
    while ((Get-Date) -lt $endTime) {
        $remaining = [math]::Round(($endTime - (Get-Date)).TotalSeconds, 0)
        Write-Progress -Activity "Scanning for base stations" -Status "Time remaining: $remaining seconds" -PercentComplete ((($ScanDuration - $remaining) / $ScanDuration) * 100)
        Start-Sleep -Seconds 1
    }
    
    Write-Progress -Activity "Scanning for base stations" -Completed
    $watcher.Stop()
    
    if ($discoveredDevices.Count -gt 0) {
        Write-Host ""
        Write-Status "✅ Discovered $($discoveredDevices.Count) potential base station(s)!" -Level SUCCESS
        
        foreach ($device in $discoveredDevices) {
            Write-Host "  - $($device.Name) (Address: $($device.Address))" -ForegroundColor Green
            
            # Attempt to pair
            try {
                Write-Status "  Attempting to pair: $($device.Name)..." -Level INFO
                
                # Get Bluetooth device
                $btDevice = [Windows.Devices.Bluetooth.BluetoothDevice]::FromBluetoothAddressAsync($device.Address).GetAwaiter().GetResult()
                
                if ($btDevice) {
                    # Request pairing
                    $pairingResult = $btDevice.DeviceInformation.Pairing.PairAsync().GetAwaiter().GetResult()
                    
                    if ($pairingResult.Status -eq [Windows.Devices.Enumeration.DevicePairingResultStatus]::Paired) {
                        Write-Status "  ✅ Successfully paired: $($device.Name)" -Level SUCCESS
                    } else {
                        Write-Status "  ⚠️  Pairing result: $($pairingResult.Status)" -Level WARN
                    }
                }
            } catch {
                Write-Status "  ⚠️  Could not pair automatically: $($_.Exception.Message)" -Level WARN
                Write-Host "     Try pairing manually via Windows Settings" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host ""
        Write-Status "⚠️  No base stations discovered during scan" -Level WARN
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "1. Base stations not in pairing mode" -ForegroundColor White
        Write-Host "2. Base stations not powered on" -ForegroundColor White
        Write-Host "3. Base stations out of range" -ForegroundColor White
        Write-Host "4. Base stations already paired (check existing devices)" -ForegroundColor White
    }
    
} catch {
    Write-Status "Bluetooth LE scanning not available: $($_.Exception.Message)" -Level WARN
    Write-Host ""
    Write-Status "Falling back to manual pairing method..." -Level INFO
    
    # Fallback: Open Windows Settings
    Start-Process "ms-settings:bluetooth"
    Write-Host ""
    Write-Host "Please pair manually:" -ForegroundColor Yellow
    Write-Host "1. Click 'Add Bluetooth or other device'" -ForegroundColor White
    Write-Host "2. Select 'Bluetooth'" -ForegroundColor White
    Write-Host "3. Look for 'LHB-XXXX' or 'HTC Base Station'" -ForegroundColor White
    Write-Host "4. Click to pair" -ForegroundColor White
    Write-Host ""
    Write-Host "Press ENTER after pairing..." -ForegroundColor Cyan
    $null = Read-Host
}

# Final verification
Write-Host ""
Write-Status "Verifying pairing..." -Level INFO
Start-Sleep -Seconds 3

$pairedDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($pairedDevices.Count -gt 0) {
    Write-Host ""
    Write-Status "✅ SUCCESS! $($pairedDevices.Count) base station(s) now paired!" -Level SUCCESS
    foreach ($device in $pairedDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Status "You can now extract data:" -Level SUCCESS
    Write-Host "  pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Status "⚠️  No base stations detected after pairing attempt" -Level WARN
    Write-Host ""
    Write-Host "Try:" -ForegroundColor Yellow
    Write-Host "1. Ensure base stations are in pairing mode" -ForegroundColor White
    Write-Host "2. Pair manually via Windows Settings" -ForegroundColor White
    Write-Host "3. Check base station LEDs (should blink when pairing)" -ForegroundColor White
}
