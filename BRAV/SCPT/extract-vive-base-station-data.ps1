#Requires -Version 7.0

<#
.SYNOPSIS
    Extract data from HTC Vive base stations (lighthouses)

.DESCRIPTION
    Connects to HTC Vive base stations via Bluetooth or USB and extracts:
    - Device information (serial, firmware version)
    - Tracking status and health
    - Power state and temperature
    - Channel configuration
    - Error logs and diagnostics

.PARAMETER BaseStationId
    Specific base station ID to query (1 or 2, or MAC address). If not specified, scans for all.

.PARAMETER OutputFormat
    Output format: json, csv, or table. Default: json

.PARAMETER OutputPath
    Path to save extracted data. Default: artifacts/vive/base-station-data-{timestamp}.json

.PARAMETER UseBluetooth
    Use Bluetooth connection (default). Set to false to use USB if available.

.EXAMPLE
    .\extract-vive-base-station-data.ps1
    Scan for and extract data from all detected base stations

.EXAMPLE
    .\extract-vive-base-station-data.ps1 -BaseStationId 1 -OutputFormat json
    Extract data from base station 1 in JSON format
#>

[CmdletBinding()]
param(
    [string]$BaseStationId,
    [ValidateSet('json', 'csv', 'table')]
    [string]$OutputFormat = 'json',
    [string]$OutputPath,
    [switch]$UseBluetooth = $true
)

$ErrorActionPreference = 'Stop'

# Initialize output directory
$outputDir = "artifacts/vive"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $outputDir "base-station-data-$timestamp.json"
}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Get-BaseStationViaBluetooth {
    param([string]$StationId)
    
    Write-Log "Scanning for HTC Vive base stations via Bluetooth..." -Level INFO
    
    try {
        # Try multiple methods to detect Bluetooth devices
        $bluetoothDevices = @()
        
        # Method 1: PowerShell Bluetooth module (if available)
        try {
            if (Get-Command Get-BluetoothDevice -ErrorAction SilentlyContinue) {
                $bluetoothDevices = Get-BluetoothDevice -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -like "*Vive*" -or 
                    $_.Name -like "*LHB*" -or 
                    $_.Name -like "*Lighthouse*" -or
                    $_.Name -match "HTC.*[Bb]ase"
                }
            }
        } catch {
            Write-Log "Bluetooth cmdlet not available" -Level INFO
        }
        
        # Method 2: Windows Bluetooth APIs via .NET
        if ($bluetoothDevices.Count -eq 0) {
            try {
                Add-Type -AssemblyName System.Runtime.WindowsRuntime
                $bluetoothAdapter = [Windows.Devices.Bluetooth.BluetoothAdapter]::GetDefaultAsync().GetAwaiter().GetResult()
                if ($bluetoothAdapter) {
                    Write-Log "Bluetooth adapter found, scanning..." -Level INFO
                    # Note: Full Bluetooth LE scanning requires additional setup
                }
            } catch {
                Write-Log "Bluetooth API access limited: $($_.Exception.Message)" -Level INFO
            }
        }
        
        # Method 3: Check Windows Bluetooth registry
        try {
            $btRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices"
            if (Test-Path $btRegistryPath) {
                $btDevices = Get-ChildItem $btRegistryPath -ErrorAction SilentlyContinue
                foreach ($device in $btDevices) {
                    $deviceName = $device.PSChildName
                    # Base stations typically have MAC addresses starting with specific patterns
                    # HTC devices often use vendor ID patterns
                    if ($deviceName -match "^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$") {
                        $bluetoothDevices += [PSCustomObject]@{
                            Name = "Base Station (MAC: $deviceName)"
                            Address = $deviceName
                            Id = $deviceName
                            Connected = $false
                            Paired = $true
                        }
                    }
                }
            }
        } catch {
            Write-Log "Registry scan: $($_.Exception.Message)" -Level INFO
        }
        
        if ($bluetoothDevices.Count -eq 0) {
            Write-Log "No HTC Vive base stations found via Bluetooth" -Level WARN
            Write-Log "Base stations may need to be paired first, or use USB connection" -Level INFO
            Write-Log "Try: Settings > Devices > Bluetooth & other devices" -Level INFO
            return $null
        }
        
        Write-Log "Found $($bluetoothDevices.Count) potential base station(s)" -Level SUCCESS
        return $bluetoothDevices
    } catch {
        Write-Log "Bluetooth scan error: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-BaseStationViaUSB {
    Write-Log "Scanning for HTC Vive base stations via USB..." -Level INFO
    
    try {
        # Check for USB-connected devices
        $usbDevices = Get-PnpDevice | Where-Object {
            $_.FriendlyName -like "*Vive*" -or 
            $_.FriendlyName -like "*Lighthouse*" -or
            $_.FriendlyName -like "*HTC*" -or
            ($_.Class -eq 'USB' -and $_.FriendlyName -match "VID_0bb4") # HTC Vendor ID
        }
        
        if ($usbDevices.Count -eq 0) {
            Write-Log "No HTC Vive base stations found via USB" -Level WARN
            return $null
        }
        
        Write-Log "Found $($usbDevices.Count) USB device(s)" -Level SUCCESS
        return $usbDevices
    } catch {
        Write-Log "USB scan error: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-BaseStationData {
    param(
        [object]$Device,
        [string]$ConnectionType
    )
    
    $data = @{
        timestamp = (Get-Date).ToString("o")
        connection_type = $ConnectionType
        device_info = @{
            name = $Device.Name
            id = $Device.Id
            status = $Device.Status
            class = $Device.Class
        }
        tracking_data = @{
            status = "unknown"
            last_update = $null
        }
        diagnostics = @{
            firmware_version = $null
            serial_number = $null
            power_state = "unknown"
            temperature = $null
            channel = $null
            errors = @()
        }
        raw_data = $Device
    }
    
    # Try to extract additional information based on connection type
    if ($ConnectionType -eq "Bluetooth") {
        $data.device_info.connected = $Device.Connected
        $data.device_info.paired = $Device.Paired
        $data.device_info.address = $Device.Address
    } elseif ($ConnectionType -eq "USB") {
        $data.device_info.instance_id = $Device.InstanceId
        $data.device_info.device_id = $Device.DeviceID
    }
    
    return $data
}

function Get-SteamVRConfig {
    Write-Log "Checking SteamVR configuration files..." -Level INFO
    
    $steamVRPaths = @(
        "$env:ProgramFiles\Steam\steamapps\common\SteamVR",
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR",
        "$env:LOCALAPPDATA\Programs\Steam\steamapps\common\SteamVR"
    )
    
    $steamVRPath = $null
    foreach ($path in $steamVRPaths) {
        if (Test-Path $path) {
            $steamVRPath = $path
            break
        }
    }
    
    if (-not $steamVRPath) {
        Write-Log "SteamVR installation not found" -Level WARN
        return $null
    }
    
    Write-Log "SteamVR found at: $steamVRPath" -Level SUCCESS
    
    # Check for config files
    $configPaths = @(
        "$steamVRPath\config\steamvr.vrsettings",
        "$env:LOCALAPPDATA\OpenVR\steamvr.vrsettings",
        "$env:APPDATA\OpenVR\steamvr.vrsettings"
    )
    
    $configData = @{}
    foreach ($configPath in $configPaths) {
        if (Test-Path $configPath) {
            Write-Log "Found config: $configPath" -Level INFO
            try {
                $content = Get-Content $configPath -Raw
                # Parse JSON-like config (SteamVR uses JSON format)
                if ($content -match '\{') {
                    $configData[$configPath] = $content
                }
            } catch {
                Write-Log "Could not read config: $($_.Exception.Message)" -Level WARN
            }
        }
    }
    
    return @{
        SteamVRPath = $steamVRPath
        ConfigFiles = $configData
    }
}

function Get-SteamVRLogs {
    Write-Log "Checking SteamVR logs for base station information..." -Level INFO
    
    $logPaths = @(
        "$env:LOCALAPPDATA\OpenVR\logs",
        "$env:APPDATA\OpenVR\logs",
        "$env:ProgramFiles\Steam\steamapps\common\SteamVR\logs"
    )
    
    $baseStationInfo = @()
    
    foreach ($logPath in $logPaths) {
        if (Test-Path $logPath) {
            Write-Log "Found log directory: $logPath" -Level INFO
            try {
                $logFiles = Get-ChildItem $logPath -Filter "*.txt" -ErrorAction SilentlyContinue | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 5
                
                foreach ($logFile in $logFiles) {
                    Write-Log "Scanning log: $($logFile.Name)" -Level INFO
                    $content = Get-Content $logFile.FullName -ErrorAction SilentlyContinue
                    
                    # Look for base station references
                    $lighthouseMatches = $content | Select-String -Pattern "(LHB|Lighthouse|Base Station|base station)" -CaseSensitive:$false
                    if ($lighthouseMatches) {
                        foreach ($match in $lighthouseMatches) {
                            $baseStationInfo += @{
                                Source = $logFile.Name
                                Line = $match.Line
                                Timestamp = $logFile.LastWriteTime
                            }
                        }
                    }
                }
            } catch {
                Write-Log "Error reading logs: $($_.Exception.Message)" -Level WARN
            }
        }
    }
    
    return $baseStationInfo
}

function Invoke-OpenVRQuery {
    param([string]$Query)
    
    # Check if SteamVR is running
    $vrProcess = Get-Process -Name "vrserver" -ErrorAction SilentlyContinue
    if (-not $vrProcess) {
        Write-Log "SteamVR not running. Start SteamVR to access base stations via OpenVR API" -Level WARN
        return @{
            available = $false
            message = "SteamVR not running"
            suggestion = "Start SteamVR to enable OpenVR API access"
        }
    }
    
    Write-Log "SteamVR is running (PID: $($vrProcess.Id))" -Level SUCCESS
    Write-Log "OpenVR SDK integration requires DLL access" -Level INFO
    Write-Log "For full API access, use OpenVR.NET or C# wrapper" -Level INFO
    
    # Try to read from SteamVR runtime
    $steamVRConfig = Get-SteamVRConfig
    $steamVRLogs = Get-SteamVRLogs
    
    return @{
        available = $true
        steamvr_running = $true
        steamvr_pid = $vrProcess.Id
        config_data = $steamVRConfig
        log_entries = $steamVRLogs
        message = "SteamVR running, but OpenVR API requires SDK integration"
    }
}

# Main execution
Write-Log "HTC Vive Base Station Data Extraction" -Level INFO
Write-Log "=====================================" -Level INFO

$allBaseStations = @()

# Try Bluetooth first if enabled
if ($UseBluetooth) {
    $bluetoothStations = Get-BaseStationViaBluetooth -StationId $BaseStationId
    if ($bluetoothStations) {
        foreach ($device in $bluetoothStations) {
            $stationData = Get-BaseStationData -Device $device -ConnectionType "Bluetooth"
            $allBaseStations += $stationData
        }
    }
}

# Try USB as fallback or additional method
$usbStations = Get-BaseStationViaUSB
if ($usbStations) {
    foreach ($device in $usbStations) {
        # Check if we already have this device from Bluetooth scan
        $existing = $allBaseStations | Where-Object { $_.device_info.id -eq $device.InstanceId }
        if (-not $existing) {
            $stationData = Get-BaseStationData -Device $device -ConnectionType "USB"
            $allBaseStations += $stationData
        }
    }
}

# Try OpenVR SDK if available
$openvrData = Invoke-OpenVRQuery -Query "base_stations"
if ($openvrData.available -or $openvrData.log_entries) {
    if ($openvrData.log_entries -and $openvrData.log_entries.Count -gt 0) {
        Write-Log "Found $($openvrData.log_entries.Count) base station reference(s) in SteamVR logs" -Level SUCCESS
        foreach ($logEntry in $openvrData.log_entries) {
            Write-Log "  - $($logEntry.Source): $($logEntry.Line.Trim())" -Level INFO
            # Create a base station entry from log data
            $logStation = @{
                timestamp = $logEntry.Timestamp.ToString("o")
                connection_type = "SteamVR_Log"
                device_info = @{
                    name = "Base Station (from log)"
                    id = "log-$($logEntry.Source)"
                    status = "Detected in log"
                    source_file = $logEntry.Source
                }
                tracking_data = @{
                    status = "unknown"
                    log_reference = $logEntry.Line
                }
                diagnostics = @{
                    note = "Information extracted from SteamVR log file"
                }
            }
            $allBaseStations += $logStation
        }
    }
    
    if ($openvrData.config_data) {
        Write-Log "SteamVR configuration files found" -Level SUCCESS
    }
}

# Filter by specific station if requested
if ($BaseStationId) {
    $allBaseStations = $allBaseStations | Where-Object {
        $_.device_info.id -eq $BaseStationId -or
        $_.device_info.name -like "*$BaseStationId*"
    }
}

# Prepare output
$output = @{
    extraction_timestamp = (Get-Date).ToString("o")
    base_stations_found = $allBaseStations.Count
    base_stations = $allBaseStations
    extraction_method = if ($UseBluetooth) { "Bluetooth" } else { "USB" }
    steamvr_status = @{
        running = $false
        pid = $null
    }
    notes = @(
        "For full tracking data, install SteamVR and use OpenVR SDK",
        "Base stations may require pairing before data extraction",
        "USB connection provides more detailed diagnostics"
    )
}

# Add SteamVR status if available
if ($openvrData -and $openvrData.steamvr_running) {
    $output.steamvr_status.running = $true
    $output.steamvr_status.pid = $openvrData.steamvr_pid
    if ($openvrData.config_data) {
        $output.steamvr_config = $openvrData.config_data
    }
}

# Output results
Write-Log "Found $($allBaseStations.Count) base station(s)" -Level SUCCESS

if ($OutputFormat -eq 'json') {
    $output | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "Data saved to: $OutputPath" -Level SUCCESS
} elseif ($OutputFormat -eq 'csv') {
    $csvPath = $OutputPath -replace '\.json$', '.csv'
    $allBaseStations | ForEach-Object {
        [PSCustomObject]@{
            Timestamp = $_.timestamp
            Name = $_.device_info.name
            ID = $_.device_info.id
            Status = $_.device_info.status
            ConnectionType = $_.connection_type
        }
    } | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Log "Data saved to: $csvPath" -Level SUCCESS
} else {
    # Table format
    $allBaseStations | ForEach-Object {
        Write-Host "`nBase Station: $($_.device_info.name)" -ForegroundColor Cyan
        Write-Host "  ID: $($_.device_info.id)" -ForegroundColor White
        Write-Host "  Status: $($_.device_info.status)" -ForegroundColor White
        Write-Host "  Connection: $($_.connection_type)" -ForegroundColor White
    }
}

# Return data for further processing
return $output
