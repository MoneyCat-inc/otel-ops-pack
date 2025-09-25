# Memory Monitor Script for SigNoz Integration
# Monitors physical memory usage and sends alerts via OTLP HTTP

param(
    [int]$ThresholdPercent = 80,
    [int]$CheckIntervalSeconds = 30,
    [string]$OtlpEndpoint = "http://localhost:5318/v1/logs"
)

# Import shared spinner toolkit
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

function Send-MemoryAlert {
    param(
        [double]$MemoryUsagePercent,
        [string]$AlertType
    )
    
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
    $body = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = "memory-monitor"
                            }
                        },
                        @{
                            key = "deployment.environment"
                            value = @{
                                stringValue = "local"
                            }
                        }
                    )
                }
                scopeLogs = @(
                    @{
                        scope = @{}
                        logRecords = @(
                            @{
                                timeUnixNano = $timestamp
                                severityNumber = if ($AlertType -eq "critical") { 17 } else { 13 }
                                severityText = if ($AlertType -eq "critical") { "ERROR" } else { "WARN" }
                                body = @{
                                    stringValue = "Memory usage alert: $([math]::Round($MemoryUsagePercent, 1))% - $AlertType threshold reached"
                                }
                                attributes = @(
                                    @{
                                        key = "alert.type"
                                        value = @{
                                            stringValue = $AlertType
                                        }
                                    },
                                    @{
                                        key = "memory.usage.percent"
                                        value = @{
                                            doubleValue = $MemoryUsagePercent
                                        }
                                    },
                                    @{
                                        key = "alert.dataset"
                                        value = @{
                                            stringValue = "memory-monitoring"
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    }
    
    try {
        $jsonBody = $body | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $OtlpEndpoint -Method Post -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
        Write-Host "$(Get-Date): Memory alert sent - $([math]::Round($MemoryUsagePercent, 1))% ($AlertType)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to send memory alert: $($_.Exception.Message)"
    }
}

function Get-MemoryUsage {
    $memInfo = Get-WmiObject -Class Win32_OperatingSystem
    $totalMem = [math]::Round($memInfo.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($memInfo.FreePhysicalMemory / 1MB, 2)
    $usedMem = $totalMem - $freeMem
    $usagePercent = ($usedMem / $totalMem) * 100
    
    return @{
        Total = $totalMem
        Free = $freeMem
        Used = $usedMem
        UsagePercent = $usagePercent
    }
}

Write-Host "Memory Monitor Started - Threshold: $ThresholdPercent% - Interval: $CheckIntervalSeconds seconds" -ForegroundColor Green
Write-Host "OTLP Endpoint: $OtlpEndpoint" -ForegroundColor Cyan

$lastAlertTime = [DateTime]::MinValue
$alertCooldown = [TimeSpan]::FromMinutes(5) # 5-minute cooldown between alerts

while ($true) {
    $memInfo = Get-MemoryUsage
    
    Write-Host "$(Get-Date): Memory - Used: $([math]::Round($memInfo.Used, 1))GB / $($memInfo.Total)GB ($([math]::Round($memInfo.UsagePercent, 1))%)" -ForegroundColor White
    
    # Check if we need to send an alert
    $shouldAlert = $false
    $alertType = ""
    
    if ($memInfo.UsagePercent -ge 95) {
        $alertType = "critical"
        $shouldAlert = $true
    }
    elseif ($memInfo.UsagePercent -ge $ThresholdPercent) {
        $alertType = "warning"
        $shouldAlert = $true
    }
    
    # Send alert if needed and cooldown period has passed
    if ($shouldAlert -and ((Get-Date) - $lastAlertTime) -gt $alertCooldown) {
        Send-MemoryAlert -MemoryUsagePercent $memInfo.UsagePercent -AlertType $alertType
        $lastAlertTime = Get-Date
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}
