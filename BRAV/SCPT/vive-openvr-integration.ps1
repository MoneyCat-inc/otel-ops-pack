#Requires -Version 7.0

<#
.SYNOPSIS
    Integration guide and helper for OpenVR SDK to extract HTC Vive base station data

.DESCRIPTION
    Provides functions to interact with HTC Vive base stations via OpenVR SDK.
    Requires SteamVR to be installed and running.

.PARAMETER CheckSteamVR
    Check if SteamVR is installed and running

.PARAMETER InstallInstructions
    Show installation instructions for OpenVR SDK

.EXAMPLE
    .\vive-openvr-integration.ps1 -CheckSteamVR
    Check SteamVR installation status
#>

[CmdletBinding()]
param(
    [switch]$CheckSteamVR,
    [switch]$InstallInstructions
)

function Test-SteamVRInstalled {
    $steamVRPaths = @(
        "$env:ProgramFiles\Steam\steamapps\common\SteamVR",
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR",
        "$env:LOCALAPPDATA\Programs\Steam\steamapps\common\SteamVR"
    )
    
    foreach ($path in $steamVRPaths) {
        if (Test-Path $path) {
            return @{
                Installed = $true
                Path = $path
            }
        }
    }
    
    return @{
        Installed = $false
        Path = $null
    }
}

function Get-SteamVRProcess {
    $process = Get-Process -Name "vrserver" -ErrorAction SilentlyContinue
    if ($process) {
        return @{
            Running = $true
            PID = $process.Id
            Path = $process.Path
        }
    }
    return @{ Running = $false }
}

function Get-OpenVRBaseStationData {
    # This function would use OpenVR API calls
    # Requires OpenVR SDK DLL or C# wrapper
    
    Write-Host "OpenVR Base Station Data Extraction" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    # Check SteamVR
    $steamVR = Test-SteamVRInstalled
    if (-not $steamVR.Installed) {
        Write-Host "SteamVR not found. Please install SteamVR first." -ForegroundColor Yellow
        Write-Host "Download from: https://store.steampowered.com/app/250820/SteamVR/" -ForegroundColor Cyan
        return
    }
    
    Write-Host "SteamVR found at: $($steamVR.Path)" -ForegroundColor Green
    
    # Check if running
    $vrProcess = Get-SteamVRProcess
    if (-not $vrProcess.Running) {
        Write-Host "SteamVR is not running. Start SteamVR to access base stations." -ForegroundColor Yellow
        return
    }
    
    Write-Host "SteamVR is running (PID: $($vrProcess.PID))" -ForegroundColor Green
    
    # OpenVR API integration would go here
    # Example structure:
    $baseStationData = @{
        count = 0
        stations = @()
        tracking_system = "unknown"
    }
    
    Write-Host "`nTo extract full base station data:" -ForegroundColor Cyan
    Write-Host "1. Install OpenVR SDK from: https://github.com/ValveSoftware/openvr" -ForegroundColor White
    Write-Host "2. Use OpenVR API: vr::VRSystem()->GetTrackedDeviceCount()" -ForegroundColor White
    Write-Host "3. Query device properties: GetStringTrackedDeviceProperty()" -ForegroundColor White
    Write-Host "4. Access tracking data: GetDeviceToAbsoluteTrackingPose()" -ForegroundColor White
    
    return $baseStationData
}

if ($CheckSteamVR) {
    $steamVR = Test-SteamVRInstalled
    $vrProcess = Get-SteamVRProcess
    
    Write-Host "SteamVR Status Check" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Installed: $($steamVR.Installed)" -ForegroundColor $(if ($steamVR.Installed) { "Green" } else { "Red" })
    if ($steamVR.Installed) {
        Write-Host "Path: $($steamVR.Path)" -ForegroundColor White
    }
    Write-Host "Running: $($vrProcess.Running)" -ForegroundColor $(if ($vrProcess.Running) { "Green" } else { "Yellow" })
    if ($vrProcess.Running) {
        Write-Host "PID: $($vrProcess.PID)" -ForegroundColor White
    }
}

if ($InstallInstructions) {
    Write-Host "OpenVR SDK Installation Instructions" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Install SteamVR:" -ForegroundColor Yellow
    Write-Host "   - Download from Steam Store" -ForegroundColor White
    Write-Host "   - URL: https://store.steampowered.com/app/250820/SteamVR/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Download OpenVR SDK:" -ForegroundColor Yellow
    Write-Host "   - GitHub: https://github.com/ValveSoftware/openvr" -ForegroundColor Cyan
    Write-Host "   - Extract headers and libraries" -ForegroundColor White
    Write-Host ""
    Write-Host "3. For PowerShell/.NET integration:" -ForegroundColor Yellow
    Write-Host "   - Use OpenVR.NET wrapper: https://github.com/ValveSoftware/openvr" -ForegroundColor Cyan
    Write-Host "   - Or use P/Invoke to call OpenVR DLL directly" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Base Station Data Available:" -ForegroundColor Yellow
    Write-Host "   - Device serial numbers" -ForegroundColor White
    Write-Host "   - Firmware versions" -ForegroundColor White
    Write-Host "   - Power state (A/B/C channels)" -ForegroundColor White
    Write-Host "   - Tracking pose data" -ForegroundColor White
    Write-Host "   - Error diagnostics" -ForegroundColor White
}

if (-not $CheckSteamVR -and -not $InstallInstructions) {
    Get-OpenVRBaseStationData
}
