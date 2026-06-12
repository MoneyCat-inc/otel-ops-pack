#Requires -Version 7.0

<#
.SYNOPSIS
    Start SteamVR and extract base station data

.DESCRIPTION
    Launches SteamVR, waits for it to initialize, then extracts base station data.
    Useful when base stations are only detectable when SteamVR is running.

.PARAMETER WaitSeconds
    Seconds to wait for SteamVR to initialize. Default: 15

.PARAMETER AutoClose
    Close SteamVR after extraction. Default: false

.EXAMPLE
    .\vive-start-and-extract.ps1
    Start SteamVR, wait, then extract data

.EXAMPLE
    .\vive-start-and-extract.ps1 -WaitSeconds 30 -AutoClose
    Wait 30 seconds, extract, then close SteamVR
#>

[CmdletBinding()]
param(
    [int]$WaitSeconds = 15,
    [switch]$AutoClose
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

Write-Log "HTC Vive Base Station Extraction with SteamVR" -Level INFO
Write-Log "==============================================" -Level INFO

# Check if SteamVR is already running
$vrProcess = Get-Process -Name "vrserver" -ErrorAction SilentlyContinue
if ($vrProcess) {
    Write-Log "SteamVR is already running (PID: $($vrProcess.Id))" -Level SUCCESS
} else {
    Write-Log "Starting SteamVR..." -Level INFO
    
    # Find SteamVR executable
    $steamVRPaths = @(
        "$env:ProgramFiles\Steam\steamapps\common\SteamVR\bin\win64\vrserver.exe",
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR\bin\win64\vrserver.exe",
        "$env:LOCALAPPDATA\Programs\Steam\steamapps\common\SteamVR\bin\win64\vrserver.exe"
    )
    
    $steamVRExe = $null
    foreach ($path in $steamVRPaths) {
        if (Test-Path $path) {
            $steamVRExe = $path
            break
        }
    }
    
    if (-not $steamVRExe) {
        # Try SteamVR launcher instead
        $launcherPaths = @(
            "$env:ProgramFiles\Steam\steamapps\common\SteamVR\bin\win64\vrmonitor.exe",
            "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR\bin\win64\vrmonitor.exe"
        )
        
        foreach ($path in $launcherPaths) {
            if (Test-Path $path) {
                $steamVRExe = $path
                break
            }
        }
    }
    
    if (-not $steamVRExe) {
        Write-Log "SteamVR executable not found. Please start SteamVR manually." -Level ERROR
        Write-Log "Or install SteamVR from: https://store.steampowered.com/app/250820/SteamVR/" -Level INFO
        exit 1
    }
    
    Write-Log "Found SteamVR at: $steamVRExe" -Level SUCCESS
    
    # Start SteamVR
    try {
        $steamVRProcess = Start-Process -FilePath $steamVRExe -PassThru -ErrorAction Stop
        Write-Log "SteamVR started (PID: $($steamVRProcess.Id))" -Level SUCCESS
    } catch {
        Write-Log "Failed to start SteamVR: $($_.Exception.Message)" -Level ERROR
        exit 1
    }
    
    # Wait for SteamVR to initialize
    Write-Log "Waiting $WaitSeconds seconds for SteamVR to initialize and detect base stations..." -Level INFO
    Start-Sleep -Seconds $WaitSeconds
    
    # Verify it's still running
    $vrProcess = Get-Process -Id $steamVRProcess.Id -ErrorAction SilentlyContinue
    if (-not $vrProcess) {
        Write-Log "SteamVR process exited unexpectedly" -Level ERROR
        exit 1
    }
}

# Now extract data
Write-Log "Extracting base station data..." -Level INFO
$extractionScript = Join-Path $PSScriptRoot "extract-vive-base-station-data.ps1"

if (-not (Test-Path $extractionScript)) {
    Write-Log "Extraction script not found: $extractionScript" -Level ERROR
    exit 1
}

try {
    $result = & pwsh -File $extractionScript -OutputFormat json
    Write-Log "Extraction complete" -Level SUCCESS
    
    # Display summary
    if ($result.base_stations_found -gt 0) {
        Write-Log "Found $($result.base_stations_found) base station(s)" -Level SUCCESS
        $result.base_stations | ForEach-Object {
            Write-Host "  - $($_.device_info.name) ($($_.connection_type))" -ForegroundColor Green
        }
    } else {
        Write-Log "No base stations detected" -Level WARN
        Write-Log "Ensure base stations are:" -Level INFO
        Write-Log "  1. Powered on" -Level INFO
        Write-Log "  2. Visible to SteamVR (check SteamVR dashboard)" -Level INFO
        Write-Log "  3. Paired via Bluetooth (if using wireless)" -Level INFO
    }
    
    # Save result
    $outputPath = "artifacts\vive\steamvr-extraction-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Log "Results saved to: $outputPath" -Level SUCCESS
    
} catch {
    Write-Log "Extraction failed: $($_.Exception.Message)" -Level ERROR
}

# Optionally close SteamVR
if ($AutoClose) {
    Write-Log "Closing SteamVR..." -Level INFO
    Stop-Process -Name "vrserver" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "vrmonitor" -Force -ErrorAction SilentlyContinue
    Write-Log "SteamVR closed" -Level SUCCESS
} else {
    Write-Log "SteamVR is still running. Close manually or use -AutoClose flag" -Level INFO
}

Write-Log "Done" -Level SUCCESS
