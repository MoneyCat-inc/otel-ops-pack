#Requires -Version 5.1
<#
.SYNOPSIS
  Enumerate likely nRF52840 USB dongles (e.g. EBYTE E104-BT5040U) for SlimeVR.

.DESCRIPTION
  Lists USB devices that may be nRF52840 dongles: PnP names, Hardware IDs,
  and any COM/serial association. No admin, no external modules.
  Use when the Web Flasher doesn't see dongles or Windows stops recognising them.

.EXAMPLE
  .\slimevr-usb-dongles.ps1
#>

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'SlimeVR USB Dongles (nRF52840)'

# Common patterns for nRF52840 USB dongles (Nordic, J-Link, EBYTE, etc.)
$nrfPatterns = @(
    'nRF52', 'nRF52840', 'Nordic', 'J-Link', 'CMSIS-DAP', 'EBYTE', 'E104-BT5040',
    'VID_1915', 'VID_1366', 'VID_2FE3', 'VID_239A'
)

function Test-MatchesNrf {
    param([string] $Name, [string[]] $HardwareIDs)
    $combined = ($Name + ' ' + ($HardwareIDs -join ' '))
    foreach ($p in $nrfPatterns) {
        if ($combined -like "*$p*") { return $true }
    }
    return $false
}

function Get-ComPort {
    param([string] $DeviceID)
    try {
        $port =
            Get-CimInstance -ClassName Win32_SerialPort -ErrorAction SilentlyContinue |
            Where-Object { $_.PnPDeviceID -and $DeviceID -like "*$($_.PnPDeviceID)*" } |
            Select-Object -First 1
        if ($port) { return $port.DeviceID }
    }
    catch {
        return $null
    }
    return $null
}

# ----- main -----
Write-Host ""
Write-Host "SlimeVR nRF52840 USB dongles (e.g. EBYTE E104-BT5040U)" -ForegroundColor Cyan
Write-Host "Enumerating likely devices (no admin, no extra modules)..." -ForegroundColor Gray
Write-Host ""

$found = @()
try {
    $all = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop
}
catch {
    Write-Host "Could not enumerate PnP devices: $_" -ForegroundColor Red
    exit 1
}

foreach ($dev in $all) {
    $name = $dev.Name
    $hwids = @($dev.HardwareID)
    if (-not $hwids) { $hwids = @($dev.DeviceID) }
    if (-not (Test-MatchesNrf -Name $name -HardwareIDs $hwids)) { continue }

    $com = Get-ComPort -DeviceID $dev.DeviceID
    $found += [PSCustomObject]@{
        Name       = $name
        DeviceID   = $dev.DeviceID
        HardwareID = ($hwids -join '; ')
        COM        = $com
    }
}

if (-not $found.Count) {
    Write-Host "No likely nRF52840 USB dongles found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tips:" -ForegroundColor Gray
    Write-Host "  - Plug dongles directly into PC USB ports (avoid hubs)."
    Write-Host "  - Put dongle in bootloader mode if using Web Flasher."
    Write-Host "  - Try another USB port or cable."
    Write-Host "  - Run as same user that uses the Web Flasher."
    Write-Host ""
    exit 0
}

Write-Host "Found $($found.Count) likely nRF52840-related device(s):" -ForegroundColor Green
Write-Host ""

$i = 1
foreach ($d in $found) {
    Write-Host "[$i] $($d.Name)" -ForegroundColor White
    Write-Host "    DeviceID:   $($d.DeviceID)" -ForegroundColor DarkGray
    Write-Host "    HardwareID: $($d.HardwareID)" -ForegroundColor DarkGray
    if ($d.COM) {
        Write-Host "    COM:        $($d.COM)" -ForegroundColor Cyan
    }
    else {
        Write-Host "    COM:        (none)" -ForegroundColor DarkGray
    }
    Write-Host ""
    $i++
}

Write-Host "Done. Use these to confirm dongles are visible before flashing." -ForegroundColor Gray
Write-Host ""
