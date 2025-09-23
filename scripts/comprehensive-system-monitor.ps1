# Comprehensive System Monitor for SigNoz Integration
# Monitors Memory, CPU, and Disk usage with configurable thresholds

param(
    [int]$MemoryThresholdPercent = 80,
    [int]$CpuThresholdPercent = 85,
    [int]$DiskThresholdPercent = 90,
    [int]$CheckIntervalSeconds = 30,
    [string]$OtlpEndpoint = "http://localhost:5318/v1/logs"
)

function Send-SystemAlert {
    param(
        [string]$MetricType,
        [double]$CurrentValue,
        [string]$AlertType,
        [array]$AdditionalAttributes = @()
    )
    
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
    $severity = if ($AlertType -eq "critical") { "ERROR" } else { "WARN" }
    $severityNumber = if ($AlertType -eq "critical") { 17 } else { 13 }
    
    $body = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = "system-monitor"
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
                                severityNumber = $severityNumber
                                severityText = $severity
                                body = @{
                                    stringValue = "$MetricType usage alert: $([math]::Round($CurrentValue, 1))% - $AlertType threshold reached"
                                }
                                attributes = @(
                                    @{
                                        key = "alert.type"
                                        value = @{
                                            stringValue = $AlertType
                                        }
                                    },
                                    @{
                                        key = "metric.type"
                                        value = @{
                                            stringValue = $MetricType.ToLower()
                                        }
                                    },
                                    @{
                                        key = "metric.value.percent"
                                        value = @{
                                            doubleValue = $CurrentValue
                                        }
                                    },
                                    @{
                                        key = "dataset"
                                        value = @{
                                            stringValue = "system-monitoring"
                                        }
                                    }
                                ) + $AdditionalAttributes
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
        Write-Host "$(Get-Date): $MetricType alert sent - $([math]::Round($CurrentValue, 1))% ($AlertType)" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Error "Failed to send $MetricType alert: $($_.Exception.Message)"
        return $false
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

function Get-CpuUsage {
    # Get CPU usage over a 2-second period for more accurate reading
    $cpu1 = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
    Start-Sleep -Seconds 2
    $cpu2 = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
    
    $avgCpu = ($cpu1.Average + $cpu2.Average) / 2
    
    return @{
        UsagePercent = $avgCpu
        Cores = (Get-WmiObject -Class Win32_Processor).Count
    }
}

function Get-DiskUsage {
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.Size -gt 0 }
    $diskInfo = @()
    
    foreach ($drive in $drives) {
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $usagePercent = ($usedGB / $totalGB) * 100
        
        $diskInfo += @{
            Drive = $drive.DeviceID
            Total = $totalGB
            Free = $freeGB
            Used = $usedGB
            UsagePercent = $usagePercent
        }
    }
    
    return $diskInfo
}

function Check-Thresholds {
    param($memInfo, $cpuInfo, $diskInfo, $memThreshold, $cpuThreshold, $diskThreshold)
    
    $alerts = @()
    
    # Memory check
    if ($memInfo.UsagePercent -ge 95) {
        $alerts += @{
            Type = "Memory"
            Value = $memInfo.UsagePercent
            Severity = "critical"
            Attributes = @(
                @{
                    key = "memory.total.gb"
                    value = @{ doubleValue = $memInfo.Total }
                },
                @{
                    key = "memory.used.gb"
                    value = @{ doubleValue = [math]::Round($memInfo.Used, 2) }
                }
            )
        }
    }
    elseif ($memInfo.UsagePercent -ge $memThreshold) {
        $alerts += @{
            Type = "Memory"
            Value = $memInfo.UsagePercent
            Severity = "warning"
            Attributes = @(
                @{
                    key = "memory.total.gb"
                    value = @{ doubleValue = $memInfo.Total }
                },
                @{
                    key = "memory.used.gb"
                    value = @{ doubleValue = [math]::Round($memInfo.Used, 2) }
                }
            )
        }
    }
    
    # CPU check
    if ($cpuInfo.UsagePercent -ge 95) {
        $alerts += @{
            Type = "CPU"
            Value = $cpuInfo.UsagePercent
            Severity = "critical"
            Attributes = @(
                @{
                    key = "cpu.cores"
                    value = @{ intValue = $cpuInfo.Cores }
                }
            )
        }
    }
    elseif ($cpuInfo.UsagePercent -ge $cpuThreshold) {
        $alerts += @{
            Type = "CPU"
            Value = $cpuInfo.UsagePercent
            Severity = "warning"
            Attributes = @(
                @{
                    key = "cpu.cores"
                    value = @{ intValue = $cpuInfo.Cores }
                }
            )
        }
    }
    
    # Disk check (check each drive)
    foreach ($disk in $diskInfo) {
        if ($disk.UsagePercent -ge 95) {
            $alerts += @{
                Type = "Disk"
                Value = $disk.UsagePercent
                Severity = "critical"
                Attributes = @(
                    @{
                        key = "disk.drive"
                        value = @{ stringValue = $disk.Drive }
                    },
                    @{
                        key = "disk.total.gb"
                        value = @{ doubleValue = $disk.Total }
                    },
                    @{
                        key = "disk.used.gb"
                        value = @{ doubleValue = [math]::Round($disk.Used, 2) }
                    }
                )
            }
        }
        elseif ($disk.UsagePercent -ge $diskThreshold) {
            $alerts += @{
                Type = "Disk"
                Value = $disk.UsagePercent
                Severity = "warning"
                Attributes = @(
                    @{
                        key = "disk.drive"
                        value = @{ stringValue = $disk.Drive }
                    },
                    @{
                        key = "disk.total.gb"
                        value = @{ doubleValue = $disk.Total }
                    },
                    @{
                        key = "disk.used.gb"
                        value = @{ doubleValue = [math]::Round($disk.Used, 2) }
                    }
                )
            }
        }
    }
    
    return $alerts
}

# Main execution
Write-Host "Comprehensive System Monitor Started" -ForegroundColor Cyan
Write-Host "Memory Threshold: $MemoryThresholdPercent% | CPU Threshold: $CpuThresholdPercent% | Disk Threshold: $DiskThresholdPercent%" -ForegroundColor White
Write-Host "Check Interval: $CheckIntervalSeconds seconds | OTLP Endpoint: $OtlpEndpoint" -ForegroundColor Gray

$lastAlertTimes = @{
    Memory = [DateTime]::MinValue
    CPU = [DateTime]::MinValue
    Disk = [DateTime]::MinValue
}
$alertCooldown = [TimeSpan]::FromMinutes(5) # 5-minute cooldown between alerts per metric type

while ($true) {
    try {
        # Collect system metrics
        $memInfo = Get-MemoryUsage
        $cpuInfo = Get-CpuUsage
        $diskInfo = Get-DiskUsage
        
        # Display current status
        Write-Host "`n$(Get-Date): System Status" -ForegroundColor White
        Write-Host "  Memory: $([math]::Round($memInfo.Used, 1))GB / $($memInfo.Total)GB ($([math]::Round($memInfo.UsagePercent, 1))%)" -ForegroundColor White
        Write-Host "  CPU: $([math]::Round($cpuInfo.UsagePercent, 1))% (avg across $($cpuInfo.Cores) cores)" -ForegroundColor White
        Write-Host "  Disks:" -ForegroundColor White
        foreach ($disk in $diskInfo) {
            Write-Host "    $($disk.Drive): $([math]::Round($disk.Used, 1))GB / $($disk.Total)GB ($([math]::Round($disk.UsagePercent, 1))%)" -ForegroundColor Gray
        }
        
        # Check thresholds and send alerts
        $alerts = Check-Thresholds -memInfo $memInfo -cpuInfo $cpuInfo -diskInfo $diskInfo -memThreshold $MemoryThresholdPercent -cpuThreshold $CpuThresholdPercent -diskThreshold $DiskThresholdPercent
        
        foreach ($alert in $alerts) {
            $lastAlertTime = $lastAlertTimes[$alert.Type]
            
            # Send alert if cooldown period has passed
            if ((Get-Date) - $lastAlertTime -gt $alertCooldown) {
                $success = Send-SystemAlert -MetricType $alert.Type -CurrentValue $alert.Value -AlertType $alert.Severity -AdditionalAttributes $alert.Attributes
                if ($success) {
                    $lastAlertTimes[$alert.Type] = Get-Date
                }
            }
        }
        
        if ($alerts.Count -eq 0) {
            Write-Host "  All metrics within normal range" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Error during system monitoring: $($_.Exception.Message)"
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}
