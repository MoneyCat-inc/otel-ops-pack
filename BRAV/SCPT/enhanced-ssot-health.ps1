# Enhanced SSOT Health Monitoring with Advanced Features
param(
    [switch]$Prometheus,
    [switch]$Slack,
    [switch]$Email,
    [string]$SlackWebhook = "",
    [string]$EmailRecipients = "",
    [int]$HealthThreshold = 95,
    [int]$AlertCooldown = 300
)

# Load existing health monitoring
. "scripts/monitor-ssot-health.ps1"

# Enhanced health check with additional metrics
function Get-EnhancedSSOTHealth {
    $health = Get-SSOTHealth -Detailed
    
    # Add additional metrics
    $health | Add-Member -NotePropertyName "system_load" -NotePropertyValue (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $health | Add-Member -NotePropertyName "memory_usage" -NotePropertyValue (Get-CimInstance -ClassName Win32_OperatingSystem | ForEach-Object { [math]::Round(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize * 100, 2) })
    $health | Add-Member -NotePropertyName "disk_usage" -NotePropertyValue (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | ForEach-Object { [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 2) })
    
    return $health
}

# Prometheus metrics export
function Export-PrometheusMetrics {
    param([object]$health)
    
    $metrics = @"
# SSOT Health Metrics
ssot_health_score $($health.overall_health)
ssot_freshness_age_minutes $($health.freshness_age)
ssot_accuracy_mismatches $($health.accuracy_mismatches)
ssot_integration_status $($health.integration_status)
ssot_system_load_percent $($health.system_load)
ssot_memory_usage_percent $($health.memory_usage)
ssot_disk_usage_percent $($health.disk_usage)
ssot_jobs_processed $($health.telemetry.jobs_processed)
ssot_jobs_failed $($health.telemetry.jobs_failed)
ssot_queue_depth_max $($health.telemetry.queue_depth_max)
ssot_flaky_active $($health.telemetry.flaky_active)
ssot_rehabilitated_7d $($health.telemetry.rehabilitated_7d)
"@
    
    $metrics | Out-File -FilePath ".artifacts/ssot-prometheus-metrics.txt" -Encoding UTF8
    
    if ($Prometheus) {
        try {
            Invoke-RestMethod -Uri "$PrometheusEndpoint/api/v1/import/prometheus" -Method POST -Body $metrics -ContentType "text/plain"
            Write-Host "✅ Prometheus metrics exported" -ForegroundColor Green
        } catch {
            Write-Host "❌ Prometheus export failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Slack notification
function Send-SlackAlert {
    param([object]$health, [string]$message)
    
    if ($Slack -and $SlackWebhook) {
        $payload = @{
            text = "🚨 SSOT Health Alert"
            attachments = @(
                @{
                    color = if ($health.overall_health -lt $HealthThreshold) { "danger" } else { "good" }
                    fields = @(
                        @{ title = "Health Score"; value = "$($health.overall_health)%"; short = $true }
                        @{ title = "Freshness"; value = "$($health.freshness_status)"; short = $true }
                        @{ title = "Accuracy"; value = "$($health.accuracy_status)"; short = $true }
                        @{ title = "Integration"; value = "$($health.integration_status)"; short = $true }
                        @{ title = "Message"; value = $message; short = $false }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10
        
        try {
            Invoke-RestMethod -Uri $SlackWebhook -Method POST -Body $payload -ContentType "application/json"
            Write-Host "✅ Slack alert sent" -ForegroundColor Green
        } catch {
            Write-Host "❌ Slack alert failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Email notification
function Send-EmailAlert {
    param([object]$health, [string]$message)
    
    if ($Email -and $EmailRecipients) {
        $subject = "SSOT Health Alert - $($health.overall_health)% Health Score"
        $body = @"
SSOT Health Alert

Health Score: $($health.overall_health)%
Freshness: $($health.freshness_status)
Accuracy: $($health.accuracy_status)
Integration: $($health.integration_status)

Message: $message

Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')

Please check the SSOT monitoring dashboard for more details.
"@
        
        try {
            Send-MailMessage -To $EmailRecipients -Subject $subject -Body $body -SmtpServer "localhost"
            Write-Host "✅ Email alert sent" -ForegroundColor Green
        } catch {
            Write-Host "❌ Email alert failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Main enhanced health monitoring
$health = Get-EnhancedSSOTHealth

# Export metrics
Export-PrometheusMetrics -Health $health

# Check for alerts
if ($health.overall_health -lt $HealthThreshold) {
    $message = "SSOT health score dropped below threshold ($HealthThreshold%)"
    Send-SlackAlert -Health $health -Message $message
    Send-EmailAlert -Health $health -Message $message
}

return $health
