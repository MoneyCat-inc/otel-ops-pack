#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive Bluetooth adapter configuration check

.DESCRIPTION
    Checks Bluetooth adapter status, drivers, services, and configuration
    to ensure it's properly configured for HTC Vive base station pairing.

.EXAMPLE
    .\check-bluetooth-config.ps1
    Run full Bluetooth configuration check
#>

[CmdletBinding()]
param()

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "Bluetooth Configuration Check" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check for Bluetooth adapters
Write-Status "Checking Bluetooth Adapters..." -Level INFO

$adapters = Get-PnpDevice | Where-Object { 
    ($_.Class -eq "Bluetooth" -and $_.FriendlyName -like "*Adapter*") -or
    ($_.FriendlyName -like "*Bluetooth*" -and $_.FriendlyName -notlike "*Service*" -and $_.FriendlyName -notlike "*Device*")
} | Where-Object { $_.Status -eq "OK" }

if ($adapters.Count -eq 0) {
    Write-Status "❌ No Bluetooth adapters found" -Level ERROR
    exit 1
}

Write-Status "✅ Found $($adapters.Count) Bluetooth adapter(s)" -Level SUCCESS

foreach ($adapter in $adapters) {
    Write-Host ""
    Write-Status "Adapter: $($adapter.FriendlyName)" -Level INFO
    Write-Host "  Status: $($adapter.Status)" -ForegroundColor $(if ($adapter.Status -eq 'OK') { 'Green' } else { 'Red' })
    Write-Host "  Instance ID: $($adapter.InstanceId)" -ForegroundColor Gray
    
    # Check for problems
    $problem = Get-PnpDeviceProperty -InstanceId $adapter.InstanceId -KeyName 'DEVPKEY_Device_ProblemCode' -ErrorAction SilentlyContinue
    if ($problem -and $problem.Data -ne 0) {
        Write-Status "  ⚠️  Problem Code: $($problem.Data)" -Level WARN
    } else {
        Write-Status "  ✅ No problems detected" -Level SUCCESS
    }
    
    # Get driver info
    $driver = Get-PnpDeviceProperty -InstanceId $adapter.InstanceId -KeyName 'DEVPKEY_Device_Driver' -ErrorAction SilentlyContinue
    if ($driver) {
        Write-Host "  Driver: $($driver.Data)" -ForegroundColor White
    }
}

# Check Bluetooth services
Write-Host ""
Write-Status "Checking Bluetooth Services..." -Level INFO

$services = Get-Service -Name "*Bluetooth*" -ErrorAction SilentlyContinue
if ($services) {
    foreach ($service in $services) {
        $statusColor = if ($service.Status -eq 'Running') { 'Green' } else { 'Yellow' }
        Write-Host "  $($service.DisplayName): $($service.Status)" -ForegroundColor $statusColor
        Write-Host "    Start Type: $($service.StartType)" -ForegroundColor Gray
    }
} else {
    Write-Status "  ⚠️  No Bluetooth services found" -Level WARN
}

# Check connected devices
Write-Host ""
Write-Status "Checking Connected Bluetooth Devices..." -Level INFO

$btDevices = Get-PnpDevice | Where-Object { 
    $_.Class -eq "Bluetooth" -and 
    $_.FriendlyName -notlike "*Service*" -and
    $_.FriendlyName -notlike "*Adapter*" -and
    $_.FriendlyName -notlike "*Enumerator*" -and
    $_.FriendlyName -notlike "*Profile*" -and
    $_.FriendlyName -notlike "*Generic*"
} | Where-Object { $_.Status -eq "OK" }

if ($btDevices.Count -gt 0) {
    Write-Status "✅ Found $($btDevices.Count) connected device(s)" -Level SUCCESS
    foreach ($device in $btDevices) {
        Write-Host "  - $($device.FriendlyName)" -ForegroundColor White
    }
} else {
    Write-Status "  ⚠️  No Bluetooth devices currently connected" -Level WARN
}

# Check for HTC Vive base stations specifically
Write-Host ""
Write-Status "Checking for HTC Vive Base Stations..." -Level INFO

$viveDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Vive*" -or
    $_.FriendlyName -like "*LHB*" -or
    $_.FriendlyName -like "*Lighthouse*" -or
    ($_.FriendlyName -like "*HTC*" -and $_.Class -eq "Bluetooth")
}

if ($viveDevices.Count -gt 0) {
    Write-Status "✅ Found $($viveDevices.Count) potential Vive device(s)" -Level SUCCESS
    foreach ($device in $viveDevices) {
        Write-Host "  - $($device.FriendlyName) ($($device.Status))" -ForegroundColor White
    }
} else {
    Write-Status "  ⚠️  No HTC Vive base stations found in Bluetooth devices" -Level WARN
    Write-Host "     Base stations may need to be paired first" -ForegroundColor Yellow
}

# Check network adapter
Write-Host ""
Write-Status "Checking Bluetooth Network Adapter..." -Level INFO

$btNetwork = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Bluetooth*" }
if ($btNetwork) {
    Write-Host "  Name: $($btNetwork.Name)" -ForegroundColor White
    Write-Host "  Status: $($btNetwork.Status)" -ForegroundColor $(if ($btNetwork.Status -eq 'Up') { 'Green' } else { 'Yellow' })
    Write-Host "  MAC Address: $($btNetwork.MacAddress)" -ForegroundColor White
    Write-Host "  Link Speed: $($btNetwork.LinkSpeed)" -ForegroundColor White
} else {
    Write-Status "  ⚠️  Bluetooth network adapter not found" -Level WARN
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Status "Bluetooth Adapters: $($adapters.Count)" -Level $(if ($adapters.Count -gt 0) { 'SUCCESS' } else { 'ERROR' })
Write-Status "Connected Devices: $($btDevices.Count)" -Level $(if ($btDevices.Count -gt 0) { 'SUCCESS' } else { 'WARN' })
Write-Status "Vive Base Stations: $($viveDevices.Count)" -Level $(if ($viveDevices.Count -gt 0) { 'SUCCESS' } else { 'WARN' })

if ($viveDevices.Count -eq 0) {
    Write-Host ""
    Write-Status "Next Steps:" -Level INFO
    Write-Host "1. Ensure base stations are powered on" -ForegroundColor White
    Write-Host "2. Put base stations in pairing mode" -ForegroundColor White
    Write-Host "3. Pair via Windows Settings > Devices > Bluetooth" -ForegroundColor White
    Write-Host "4. Look for devices named 'LHB-XXXX' or 'HTC Base Station'" -ForegroundColor White
}
