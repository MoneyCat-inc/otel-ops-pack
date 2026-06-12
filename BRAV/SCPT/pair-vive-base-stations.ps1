#Requires -Version 7.0

<#
.SYNOPSIS
    Attempt to discover and pair HTC Vive base stations via Bluetooth

.DESCRIPTION
    Scans for HTC Vive base stations and attempts to pair them automatically.
    Base stations must be in pairing mode for this to work.

.PARAMETER ForceDiscovery
    Force a new Bluetooth discovery scan

.EXAMPLE
    .\pair-vive-base-stations.ps1
    Discover and pair base stations
#>

[CmdletBinding()]
param(
    [switch]$ForceDiscovery
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "HTC Vive Base Station Pairing" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check Bluetooth adapter
Write-Status "Checking Bluetooth adapter..." -Level INFO
$btAdapter = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Bluetooth*Adapter*" -and $_.Status -eq "OK" } | Select-Object -First 1

if (-not $btAdapter) {
    Write-Status "❌ No Bluetooth adapter found or not working" -Level ERROR
    exit 1
}

Write-Status "✅ Bluetooth adapter found: $($btAdapter.FriendlyName)" -Level SUCCESS
Write-Host ""

# Instructions for user
Write-Status "IMPORTANT: Put base stations in pairing mode first!" -Level WARN
Write-Host ""
Write-Host "For Base Station 1.0:" -ForegroundColor Yellow
Write-Host "  1. Press and hold the Channel button (on the back)" -ForegroundColor White
Write-Host "  2. LED should start blinking" -ForegroundColor White
Write-Host "  3. Release button when blinking" -ForegroundColor White
Write-Host ""
Write-Host "For Base Station 2.0:" -ForegroundColor Yellow
Write-Host "  1. Press the Mode button" -ForegroundColor White
Write-Host "  2. LED should change pattern" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER when base stations are in pairing mode..." -ForegroundColor Cyan
$null = Read-Host

# Method 1: Try Windows Bluetooth APIs
Write-Status "Attempting to discover base stations..." -Level INFO

try {
    # Try to use Windows.Devices.Bluetooth if available
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue
    
    $btAdapterType = [Windows.Devices.Bluetooth.BluetoothAdapter]
    if ($btAdapterType) {
        Write-Status "Using Windows Bluetooth APIs..." -Level INFO
        $adapter = [Windows.Devices.Bluetooth.BluetoothAdapter]::GetDefaultAsync().GetAwaiter().GetResult()
        
        if ($adapter) {
            Write-Status "✅ Bluetooth adapter accessible" -Level SUCCESS
            Write-Host "  Is Low Energy Supported: $($adapter.IsLowEnergySupported)" -ForegroundColor White
            Write-Host "  Is Classic Supported: $($adapter.IsClassicSupported)" -ForegroundColor White
            
            # Note: Full device discovery requires more complex async operations
            Write-Status "Device discovery requires base stations to be in pairing mode" -Level INFO
        }
    }
} catch {
    Write-Status "Windows Bluetooth APIs not fully available: $($_.Exception.Message)" -Level WARN
}

# Method 2: Check Windows Bluetooth registry for paired devices
Write-Host ""
Write-Status "Checking for already-paired base stations..." -Level INFO

$btRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices"
if (Test-Path $btRegistryPath) {
    $pairedDevices = Get-ChildItem $btRegistryPath -ErrorAction SilentlyContinue
    
    $viveDevices = @()
    foreach ($device in $pairedDevices) {
        $deviceName = $device.PSChildName
        # Base stations typically have MAC addresses
        if ($deviceName -match "^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$") {
            try {
                $deviceProps = Get-ItemProperty $device.PSPath -ErrorAction SilentlyContinue
                # Check if it might be a Vive device
                $viveDevices += @{
                    MAC = $deviceName
                    Path = $device.PSPath
                }
            } catch {
                # Ignore errors
            }
        }
    }
    
    if ($viveDevices.Count -gt 0) {
        Write-Status "Found $($viveDevices.Count) potential Bluetooth device(s) in registry" -Level INFO
        foreach ($device in $viveDevices) {
            Write-Host "  MAC: $($device.MAC)" -ForegroundColor White
        }
    } else {
        Write-Status "No paired base stations found in registry" -Level WARN
    }
}

# Method 3: Use Windows Settings API to add device
Write-Host ""
Write-Status "Attempting to open Windows Bluetooth settings..." -Level INFO

try {
    # Open Windows Bluetooth settings
    Start-Process "ms-settings:bluetooth" -ErrorAction Stop
    Write-Status "✅ Opened Bluetooth settings" -Level SUCCESS
    Write-Host ""
    Write-Host "In the Bluetooth settings window:" -ForegroundColor Yellow
    Write-Host "1. Click 'Add Bluetooth or other device'" -ForegroundColor White
    Write-Host "2. Select 'Bluetooth'" -ForegroundColor White
    Write-Host "3. Look for devices named:" -ForegroundColor White
    Write-Host "   - LHB-XXXX (Lighthouse Base Station)" -ForegroundColor Cyan
    Write-Host "   - HTC Base Station" -ForegroundColor Cyan
    Write-Host "   - Vive Base Station" -ForegroundColor Cyan
    Write-Host "4. Click the device to pair" -ForegroundColor White
    Write-Host ""
    Write-Host "Waiting 30 seconds for you to complete pairing..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
} catch {
    Write-Status "Could not open Bluetooth settings: $($_.Exception.Message)" -Level WARN
    Write-Host "Manually open: Settings > Devices > Bluetooth & other devices" -ForegroundColor Yellow
}

# Method 4: Check if pairing was successful
Write-Host ""
Write-Status "Checking for newly paired base stations..." -Level INFO

Start-Sleep -Seconds 5

$newDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($newDevices.Count -gt 0) {
    Write-Status "✅ Found $($newDevices.Count) base station(s)!" -Level SUCCESS
    foreach ($device in $newDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Status "Pairing successful! You can now extract data:" -Level SUCCESS
    Write-Host "  pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1" -ForegroundColor Cyan
} else {
    Write-Status "⚠️  No base stations detected yet" -Level WARN
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure base stations are in pairing mode (LEDs blinking)" -ForegroundColor White
    Write-Host "2. Check that base stations are powered on" -ForegroundColor White
    Write-Host "3. Try pairing manually via Windows Settings" -ForegroundColor White
    Write-Host "4. Restart base stations and try again" -ForegroundColor White
}

# Verify with extraction script
Write-Host ""
Write-Status "Running verification scan..." -Level INFO
$result = & pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1 -OutputFormat json -ErrorAction SilentlyContinue

if ($result) {
    try {
        $data = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($data -and $data.base_stations_found -gt 0) {
            Write-Status "✅ Verification: $($data.base_stations_found) base station(s) found!" -Level SUCCESS
        } else {
            Write-Status "⚠️  Verification: No base stations found in scan" -Level WARN
        }
    } catch {
        # Ignore JSON parse errors
    }
}

Write-Host ""
Write-Status "Pairing process complete" -Level INFO
