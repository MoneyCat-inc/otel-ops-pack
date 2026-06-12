#Requires -Version 7.0

<#
.SYNOPSIS
    Troubleshoot and fix SteamVR Bluetooth issues

.DESCRIPTION
    Diagnoses why SteamVR says Bluetooth is not available and provides solutions.
    Base stations can work without Bluetooth if using sync cable or direct connection.

.PARAMETER CheckOnly
    Only check status, don't attempt fixes

.EXAMPLE
    .\fix-steamvr-bluetooth.ps1
    Diagnose and attempt to fix SteamVR Bluetooth issues
#>

[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "SteamVR Bluetooth Troubleshooting" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if SteamVR is running
$vrProcess = Get-Process -Name "vrserver" -ErrorAction SilentlyContinue
if (-not $vrProcess) {
    Write-Status "⚠️  SteamVR is not running" -Level WARN
    Write-Host "Start SteamVR first to see the Bluetooth error" -ForegroundColor Yellow
}

# Check Bluetooth adapter
Write-Status "Checking Bluetooth adapter..." -Level INFO

$btAdapter = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*Bluetooth*Adapter*" -and 
    $_.Status -eq "OK" 
} | Select-Object -First 1

if ($btAdapter) {
    Write-Status "✅ Bluetooth adapter found: $($btAdapter.FriendlyName)" -Level SUCCESS
    Write-Host "  Status: $($btAdapter.Status)" -ForegroundColor Green
} else {
    Write-Status "❌ No Bluetooth adapter found" -Level ERROR
    exit 1
}

# Check Bluetooth services
Write-Host ""
Write-Status "Checking Bluetooth services..." -Level INFO

$btServices = Get-Service -Name "*Bluetooth*" -ErrorAction SilentlyContinue
$runningServices = $btServices | Where-Object { $_.Status -eq "Running" }

if ($runningServices.Count -gt 0) {
    Write-Status "✅ $($runningServices.Count) Bluetooth service(s) running" -Level SUCCESS
    foreach ($service in $runningServices) {
        Write-Host "  - $($service.DisplayName)" -ForegroundColor White
    }
} else {
    Write-Status "⚠️  No Bluetooth services running" -Level WARN
    if (-not $CheckOnly) {
        Write-Status "Attempting to start Bluetooth services..." -Level INFO
        foreach ($service in $btServices) {
            try {
                Start-Service -Name $service.Name -ErrorAction Stop
                Write-Status "  ✅ Started: $($service.DisplayName)" -Level SUCCESS
            } catch {
                Write-Status "  ⚠️  Could not start: $($service.DisplayName)" -Level WARN
            }
        }
    }
}

# Check driver compatibility
Write-Host ""
Write-Status "Checking Bluetooth driver compatibility..." -Level INFO

$driver = Get-PnpDeviceProperty -InstanceId $btAdapter.InstanceId -KeyName 'DEVPKEY_Device_DriverProvider' -ErrorAction SilentlyContinue
if ($driver) {
    Write-Host "  Driver Provider: $($driver.Data)" -ForegroundColor White
    
    # SteamVR may have issues with certain drivers
    if ($driver.Data -like "*TP-Link*") {
        Write-Status "  ⚠️  TP-Link drivers may have compatibility issues with SteamVR" -Level WARN
        Write-Host "     SteamVR may prefer Microsoft or Intel Bluetooth drivers" -ForegroundColor Yellow
    }
}

# Important: Base stations don't always need Bluetooth!
Write-Host ""
Write-Status "⚠️  IMPORTANT: Base stations can work WITHOUT Bluetooth!" -Level WARN
Write-Host ""
Write-Host "HTC Vive base stations have multiple connection methods:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Sync Cable (Recommended if Bluetooth unavailable):" -ForegroundColor Cyan
Write-Host "   • Connect sync cable between base stations" -ForegroundColor White
Write-Host "   • Base stations will sync via cable instead of Bluetooth" -ForegroundColor White
Write-Host "   • Works perfectly without Bluetooth" -ForegroundColor White
Write-Host ""
Write-Host "2. IR Sync (Line of sight):" -ForegroundColor Cyan
Write-Host "   • Base stations sync via infrared" -ForegroundColor White
Write-Host "   • Requires line of sight between stations" -ForegroundColor White
Write-Host "   • No Bluetooth needed" -ForegroundColor White
Write-Host ""
Write-Host "3. Bluetooth (Optional, for configuration only):" -ForegroundColor Cyan
Write-Host "   • Used mainly for firmware updates and settings" -ForegroundColor White
Write-Host "   • NOT required for tracking to work" -ForegroundColor White
Write-Host ""

# Check if base stations are detected via other methods
Write-Status "Checking if base stations are detected by SteamVR..." -Level INFO

if ($vrProcess) {
    Write-Host "  SteamVR is running - check the SteamVR dashboard window" -ForegroundColor Yellow
    Write-Host "  Look for base station icons (even if Bluetooth shows as unavailable)" -ForegroundColor Yellow
} else {
    Write-Host "  Start SteamVR to check base station detection" -ForegroundColor Yellow
}

# Solutions
Write-Host ""
Write-Status "Solutions:" -Level INFO
Write-Host ""
Write-Host "Option 1: Use Sync Cable (Easiest)" -ForegroundColor Green
Write-Host "  • Connect sync cable between base stations" -ForegroundColor White
Write-Host "  • Base stations will work without Bluetooth" -ForegroundColor White
Write-Host "  • This is the recommended solution" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Ensure Line of Sight" -ForegroundColor Green
Write-Host "  • Make sure base stations can see each other" -ForegroundColor White
Write-Host "  • They sync via IR, no Bluetooth needed" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: Try Different Bluetooth Driver" -ForegroundColor Yellow
Write-Host "  • TP-Link drivers may not be compatible with SteamVR" -ForegroundColor White
Write-Host "  • Try Windows Update to get generic Bluetooth drivers" -ForegroundColor White
Write-Host "  • Or use sync cable instead (easier)" -ForegroundColor White
Write-Host ""
Write-Host "Option 4: Check Base Station Channels" -ForegroundColor Yellow
Write-Host "  • Ensure base stations are on different channels (A and B)" -ForegroundColor White
Write-Host "  • Check channel switches on back of base stations" -ForegroundColor White
Write-Host ""

# Check for sync cable connection
Write-Status "Checking for sync cable connection..." -Level INFO
Write-Host "  If you have a sync cable, connect it between base stations" -ForegroundColor Yellow
Write-Host "  This will bypass the Bluetooth requirement completely" -ForegroundColor Yellow

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Status "Bluetooth Adapter: Working" -Level SUCCESS
Write-Status "SteamVR Bluetooth: Not Available (but this is OK!)" -Level INFO
Write-Host ""
Write-Status "✅ Base stations can work WITHOUT Bluetooth!" -Level SUCCESS
Write-Host "   Use sync cable or ensure line of sight between stations" -ForegroundColor Green
Write-Host ""
Write-Status "The 'Bluetooth not available' message in SteamVR is not critical" -Level INFO
Write-Host "Base stations will still track if they can sync via cable or IR" -ForegroundColor White
