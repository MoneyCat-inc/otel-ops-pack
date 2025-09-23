# Simple Memory Alert Script for SigNoz
# Sends memory usage data via OTLP HTTP when threshold is exceeded

param(
    [int]$ThresholdPercent = 80,
    [string]$OtlpEndpoint = "http://localhost:5318/v1/logs"
)

$mem = Get-WmiObject -Class Win32_OperatingSystem
$total = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
$free = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
$used = $total - $free
$percent = ($used / $total) * 100

Write-Host "Memory Usage: $([math]::Round($used, 1))GB used of $total GB ($([math]::Round($percent, 1))% used)" -ForegroundColor Yellow

if ($percent -ge $ThresholdPercent) {
    $alertType = if ($percent -ge 95) { "CRITICAL" } else { "WARNING" }
    $severity = if ($percent -ge 95) { "ERROR" } else { "WARN" }
    
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
    
    $alertPayload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = "memory-monitor"
                            }
                        }
                    )
                }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = $timestamp
                                severityNumber = if ($percent -ge 95) { 17 } else { 13 }
                                severityText = $severity
                                body = @{
                                    stringValue = "Memory usage alert: $([math]::Round($percent, 1))% - $alertType threshold reached"
                                }
                                attributes = @(
                                    @{
                                        key = "alert.type"
                                        value = @{
                                            stringValue = $alertType.ToLower()
                                        }
                                    },
                                    @{
                                        key = "memory.usage.percent"
                                        value = @{
                                            doubleValue = $percent
                                        }
                                    },
                                    @{
                                        key = "memory.used.gb"
                                        value = @{
                                            doubleValue = [math]::Round($used, 2)
                                        }
                                    },
                                    @{
                                        key = "memory.total.gb"
                                        value = @{
                                            doubleValue = $total
                                        }
                                    },
                                    @{
                                        key = "dataset"
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
        $jsonPayload = $alertPayload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $OtlpEndpoint -Method Post -Body $jsonPayload -ContentType "application/json" -ErrorAction Stop
        Write-Host "Memory alert sent to SigNoz: $alertType ($([math]::Round($percent, 1))%)" -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to send memory alert: $($_.Exception.Message)"
    }
} else {
    Write-Host "Memory usage is within normal range ($([math]::Round($percent, 1))% < $ThresholdPercent%)" -ForegroundColor Green
}
