# System Health Monitoring Script for SigNoz Integration
# Tracks DMA Protection, device status, and application stability

param(
    [int]$DurationMinutes = 5,
    [string]$SignozEndpoint = "http://localhost:14318/v1/logs",
    [switch]$ExportToArtifacts = $true
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date
$ArtifactPath = "artifacts/system-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

Write-Host "🔍 Monitoring system health for $DurationMinutes minutes..." -ForegroundColor Cyan
Write-Host "  SigNoz endpoint: $SignozEndpoint" -ForegroundColor Blue

# Create artifacts directory
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$HealthMetrics = @{
    Timestamp = $StartTime
    Hostname = $env:COMPUTERNAME
    Metrics = @()
    Events = @()
}

function Send-ToSigNoz {
    param($LogData)
    
    try {
        $Headers = @{
            "Content-Type" = "application/json"
        }
        
        $Payload = @{
            resourceLogs = @(
                @{
                    resource = @{
                        attributes = @(
                            @{
                                key = "host.name"
                                value = @{
                                    stringValue = $env:COMPUTERNAME
                                }
                            },
                            @{
                                key = "service.name"
                                value = @{
                                    stringValue = "monolith-d-system-health"
                                }
                            },
                            @{
                                key = "dataset"
                                value = @{
                                    stringValue = "system_health"
                                }
                            }
                        )
                    }
                    scopeLogs = @(
                        @{
                            scope = @{
                                name = "system-health-monitor"
                                version = "1.0.0"
                            }
                            logRecords = @(
                                @{
                                    timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                    severityText = "INFO"
                                    body = @{
                                        stringValue = ($LogData | ConvertTo-Json -Compress)
                                    }
                                    attributes = @(
                                        @{
                                            key = "metric_type"
                                            value = @{
                                                stringValue = "system_health"
                                            }
                                        },
                                        @{
                                            key = "hostname"
                                            value = @{
                                                stringValue = $env:COMPUTERNAME
                                            }
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $Response = Invoke-RestMethod -Uri $SignozEndpoint -Method POST -Body $Payload -Headers $Headers -TimeoutSec 10 -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Host "    ⚠️  SigNoz send failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Get-DMAProtectionStatus {
    try {
        $DMARegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity"
        $DMARegKey = Get-ItemProperty -Path $DMARegPath -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
        return if ($DMARegKey) { $DMARegKey.DmaSecurityEnabled -eq 1 } else { $false }
    } catch {
        return $false
    }
}

function Get-DeviceStatus {
    $Devices = @()
    try {
        # Virtual Desktop Monitor
        $VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" -ErrorAction SilentlyContinue
        if ($VDDevice) {
            $Devices += @{
                Name = "Virtual Desktop Monitor"
                Status = $VDDevice.Status
                InstanceId = $VDDevice.InstanceId
            }
        }
        
        # Display adapters
        $DisplayAdapters = Get-PnpDevice -Class "Display" -ErrorAction SilentlyContinue
        foreach ($Adapter in $DisplayAdapters) {
            $Devices += @{
                Name = $Adapter.FriendlyName
                Status = $Adapter.Status
                Class = "Display"
            }
        }
        
        return $Devices
    } catch {
        return @()
    }
}

function Get-ApplicationStability {
    $Stability = @{
        PhoneAppRunning = $false
        RecentCrashes = 0
        MemoryUsage = 0
    }
    
    try {
        # Check if Phone app is running
        $PhoneProcess = Get-Process -Name "PhoneExperienceHost" -ErrorAction SilentlyContinue
        $Stability.PhoneAppRunning = $PhoneProcess -ne $null
        
        # Count recent crash dumps
        $WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
        if (Test-Path $WERPath) {
            $RecentCrashes = Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse | 
                Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) } | 
                Measure-Object
            $Stability.RecentCrashes = $RecentCrashes.Count
        }
        
        # Get system memory usage
        $Memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $Stability.MemoryUsage = [math]::Round((($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory) / $Memory.TotalVisibleMemorySize) * 100, 2)
        
        return $Stability
    } catch {
        return $Stability
    }
}

# Main monitoring loop
$EndTime = $StartTime.AddMinutes($DurationMinutes)
$CheckInterval = 30 # seconds

while ((Get-Date) -lt $EndTime) {
    $CheckTime = Get-Date
    
    Write-Host "`n📊 System health check at $($CheckTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
    
    # Collect metrics
    $DMAActive = Get-DMAProtectionStatus
    $DeviceStatus = Get-DeviceStatus
    $AppStability = Get-ApplicationStability
    
    # Create metric record
    $MetricRecord = @{
        Timestamp = $CheckTime
        DMAProtection = $DMAActive
        Devices = $DeviceStatus
        ApplicationStability = $AppStability
        SystemUptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }
    
    $HealthMetrics.Metrics += $MetricRecord
    
    # Display status
    Write-Host "  🔒 Kernel DMA Protection: $(if ($DMAActive) { 'ENABLED' } else { 'DISABLED' })" -ForegroundColor $(if ($DMAActive) { 'Green' } else { 'Red' })
    Write-Host "  🖥️  Display Devices: $($DeviceStatus.Count) found" -ForegroundColor Blue
    
    $VDStatus = $DeviceStatus | Where-Object { $_.Name -like "*Virtual Desktop*" }
    if ($VDStatus) {
        Write-Host "    Virtual Desktop Monitor: $($VDStatus.Status)" -ForegroundColor $(if ($VDStatus.Status -eq "OK") { 'Green' } else { 'Yellow' })
    }
    
    Write-Host "  📱 Phone App: $(if ($AppStability.PhoneAppRunning) { 'RUNNING' } else { 'NOT RUNNING' })" -ForegroundColor $(if ($AppStability.PhoneAppRunning) { 'Green' } else { 'Yellow' })
    Write-Host "  💥 Recent Crashes (24h): $($AppStability.RecentCrashes)" -ForegroundColor $(if ($AppStability.RecentCrashes -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  💾 Memory Usage: $($AppStability.MemoryUsage)%" -ForegroundColor $(if ($AppStability.MemoryUsage -lt 80) { 'Green' } else { 'Yellow' })
    
    # Send to SigNoz
    $SigNozSuccess = Send-ToSigNoz -LogData $MetricRecord
    Write-Host "  📡 SigNoz: $(if ($SigNozSuccess) { 'SENT' } else { 'FAILED' })" -ForegroundColor $(if ($SigNozSuccess) { 'Green' } else { 'Red' })
    
    # Check for alerts
    if (!$DMAActive) {
        $AlertEvent = @{
            Timestamp = $CheckTime
            Severity = "WARNING"
            Message = "Kernel DMA Protection is disabled"
            Metric = "dma_protection"
            Value = $DMAActive
        }
        $HealthMetrics.Events += $AlertEvent
        Write-Host "  ⚠️  ALERT: Kernel DMA Protection disabled" -ForegroundColor Red
    }
    
    if ($AppStability.RecentCrashes -gt 0) {
        $AlertEvent = @{
            Timestamp = $CheckTime
            Severity = "WARNING"
            Message = "Recent application crashes detected"
            Metric = "recent_crashes"
            Value = $AppStability.RecentCrashes
        }
        $HealthMetrics.Events += $AlertEvent
        Write-Host "  ⚠️  ALERT: $($AppStability.RecentCrashes) recent crashes detected" -ForegroundColor Red
    }
    
    # Wait for next check
    if ((Get-Date) -lt $EndTime) {
        $RemainingTime = [math]::Round(($EndTime - (Get-Date)).TotalSeconds)
        Write-Host "  ⏰ Next check in $RemainingTime seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $CheckInterval
    }
}

# Final report
$HealthMetrics.EndTime = Get-Date
$HealthMetrics.Duration = ($HealthMetrics.EndTime - $HealthMetrics.Timestamp).TotalMinutes
$HealthMetrics.TotalChecks = $HealthMetrics.Metrics.Count
$HealthMetrics.TotalAlerts = $HealthMetrics.Events.Count

# Export to artifacts
if ($ExportToArtifacts) {
    $HealthMetrics | ConvertTo-Json -Depth 4 | Out-File -FilePath $ArtifactPath -Encoding UTF8
    
    # Generate summary
    $Summary = @"
# System Health Monitoring Summary
**Host**: $($env:COMPUTERNAME)
**Duration**: $($HealthMetrics.Duration) minutes
**Checks Performed**: $($HealthMetrics.TotalChecks)
**Alerts Generated**: $($HealthMetrics.TotalAlerts)

## Key Findings
- DMA Protection: $(if ($HealthMetrics.Metrics[-1].DMAProtection) { 'ENABLED' } else { 'DISABLED' })
- Display Devices: $($HealthMetrics.Metrics[-1].Devices.Count) active
- Recent Crashes: $($HealthMetrics.Metrics[-1].ApplicationStability.RecentCrashes)
- Memory Usage: $($HealthMetrics.Metrics[-1].ApplicationStability.MemoryUsage)%

## SigNoz Queries
- System Health: `dataset = "system_health"`
- DMA Protection: `attributes.metric_type = "system_health" AND body contains "DMAProtection"`
- Device Status: `attributes.metric_type = "system_health" AND body contains "Devices"`

**Report**: $ArtifactPath
"@
    
    $SummaryPath = $ArtifactPath -replace '\.json$', '-summary.md'
    $Summary | Out-File -FilePath $SummaryPath -Encoding UTF8
    
    Write-Host "`n📋 Monitoring complete!" -ForegroundColor Green
    Write-Host "  Report: $ArtifactPath" -ForegroundColor Blue
    Write-Host "  Summary: $SummaryPath" -ForegroundColor Blue
    Write-Host "  Checks: $($HealthMetrics.TotalChecks), Alerts: $($HealthMetrics.TotalAlerts)" -ForegroundColor Green
}

return $HealthMetrics
