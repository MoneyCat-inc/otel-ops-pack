#Requires -Version 7.0

<#
.SYNOPSIS
    Check SteamVR status and show detected devices

.DESCRIPTION
    Checks SteamVR runtime state and shows what devices it has detected,
    including base stations, controllers, and HMDs.

.EXAMPLE
    .\vive-check-steamvr-status.ps1
    Show current SteamVR device status
#>

[CmdletBinding()]
param()

function Write-Status {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $Message -ForegroundColor $colors[$Level]
}

Write-Host "SteamVR Device Status Check" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Check if SteamVR is running
$vrProcess = Get-Process -Name "vrserver" -ErrorAction SilentlyContinue
if ($vrProcess) {
    Write-Status "✅ SteamVR is running (PID: $($vrProcess.Id))" -Level SUCCESS
    Write-Status "   Started: $($vrProcess.StartTime)" -Level INFO
} else {
    Write-Status "❌ SteamVR is not running" -Level ERROR
    Write-Status "   Start SteamVR first: pwsh -File BRAV\SCPT\vive-start-and-extract.ps1" -Level INFO
    exit 1
}

# Check SteamVR logs for device information
Write-Host "`nChecking SteamVR logs..." -ForegroundColor Yellow

$logPaths = @(
    "$env:LOCALAPPDATA\OpenVR\logs",
    "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR\logs"
)

$deviceInfo = @{
    base_stations = @()
    controllers = @()
    hmd = $null
    errors = @()
}

foreach ($logPath in $logPaths) {
    if (Test-Path $logPath) {
        Write-Status "Found logs at: $logPath" -Level INFO
        
        $logFiles = Get-ChildItem $logPath -Filter "*.txt" -ErrorAction SilentlyContinue | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 5
        
        foreach ($logFile in $logFiles) {
            $content = Get-Content $logFile.FullName -ErrorAction SilentlyContinue
            
            # Look for base station references
            $lighthouseLines = $content | Select-String -Pattern "(LHB|lighthouse|base station)" -CaseSensitive:$false
            if ($lighthouseLines) {
                Write-Status "  Found base station references in: $($logFile.Name)" -Level SUCCESS
                foreach ($line in $lighthouseLines | Select-Object -First 5) {
                    Write-Host "    - $($line.Line.Trim())" -ForegroundColor White
                    $deviceInfo.base_stations += $line.Line.Trim()
                }
            }
            
            # Look for device detection
            $deviceLines = $content | Select-String -Pattern "(device detected|tracking|connected)" -CaseSensitive:$false
            if ($deviceLines) {
                Write-Status "  Found device references in: $($logFile.Name)" -Level INFO
                foreach ($line in $deviceLines | Select-Object -First 3) {
                    Write-Host "    - $($line.Line.Trim())" -ForegroundColor Gray
                }
            }
            
            # Look for errors
            $errorLines = $content | Select-String -Pattern "(error|failed|not found)" -CaseSensitive:$false
            if ($errorLines) {
                Write-Status "  Found errors in: $($logFile.Name)" -Level WARN
                foreach ($line in $errorLines | Select-Object -First 3) {
                    Write-Host "    - $($line.Line.Trim())" -ForegroundColor Yellow
                    $deviceInfo.errors += $line.Line.Trim()
                }
            }
        }
    }
}

# Check SteamVR config for device settings
Write-Host "`nChecking SteamVR configuration..." -ForegroundColor Yellow

$configPaths = @(
    "$env:LOCALAPPDATA\OpenVR\steamvr.vrsettings",
    "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR\config\steamvr.vrsettings"
)

foreach ($configPath in $configPaths) {
    if (Test-Path $configPath) {
        Write-Status "Found config: $configPath" -Level SUCCESS
        try {
            $configContent = Get-Content $configPath -Raw
            if ($configContent -match "lighthouse" -or $configContent -match "baseStation") {
                Write-Status "  Config contains base station settings" -Level INFO
            }
        } catch {
            Write-Status "  Could not read config: $($_.Exception.Message)" -Level WARN
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Status "Base Stations Found: $($deviceInfo.base_stations.Count)" -Level $(if ($deviceInfo.base_stations.Count -gt 0) { 'SUCCESS' } else { 'WARN' })
Write-Status "Errors Found: $($deviceInfo.errors.Count)" -Level $(if ($deviceInfo.errors.Count -eq 0) { 'SUCCESS' } else { 'WARN' })

if ($deviceInfo.base_stations.Count -eq 0) {
    Write-Host "`n⚠️  No base stations detected" -ForegroundColor Yellow
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure base stations are powered on (check LED indicators)" -ForegroundColor White
    Write-Host "2. Check SteamVR dashboard - do you see base station icons?" -ForegroundColor White
    Write-Host "3. Base stations should show green icons when detected" -ForegroundColor White
    Write-Host "4. Try restarting SteamVR" -ForegroundColor White
    Write-Host "5. Check base station channels (A/B/C) - ensure they're set correctly" -ForegroundColor White
    Write-Host "6. For wireless base stations, ensure Bluetooth pairing is complete" -ForegroundColor White
}

Write-Host "`nTo extract data:" -ForegroundColor Cyan
Write-Host "  pwsh -File BRAV\SCPT\extract-vive-base-station-data.ps1" -ForegroundColor White
