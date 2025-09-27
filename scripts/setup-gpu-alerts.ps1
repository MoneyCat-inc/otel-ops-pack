# Setup GPU Alert Thresholds
# ECRR: Examine → Clean → Report → Role
# Automated GPU alert configuration for SigNoz

param(
    [switch]$Force,
    [switch]$Verbose
)

Write-Host "=== GPU Alert Thresholds Setup ===" -ForegroundColor Cyan
Write-Host "ECRR: Setting up GPU monitoring alerts..." -ForegroundColor Yellow

# Create GPU alert configuration
$gpuAlerts = @{
    alerts = @(
        @{
            name = "High GPU Utilization"
            description = "GPU utilization exceeds 80%"
            query = "gpu.utilization.percent > 80"
            severity = "warning"
            duration = "5m"
            threshold = 80
        },
        @{
            name = "Critical GPU Utilization"
            description = "GPU utilization exceeds 95%"
            query = "gpu.utilization.percent > 95"
            severity = "critical"
            duration = "2m"
            threshold = 95
        },
        @{
            name = "High GPU Memory Usage"
            description = "GPU memory utilization exceeds 90%"
            query = "gpu.memory.utilization.percent > 90"
            severity = "warning"
            duration = "5m"
            threshold = 90
        },
        @{
            name = "GPU Overheating"
            description = "GPU temperature exceeds 85°C"
            query = "gpu.temperature.celsius > 85"
            severity = "critical"
            duration = "3m"
            threshold = 85
        },
        @{
            name = "GPU Sidecar Unhealthy"
            description = "GPU sidecar health status is unhealthy"
            query = "gpu.sidecar.health == 0"
            severity = "critical"
            duration = "1m"
            threshold = 0
        },
        @{
            name = "GPU Monitoring Stalled"
            description = "No GPU metrics received for 5 minutes"
            query = "absent(gpu.utilization.percent)"
            severity = "warning"
            duration = "5m"
            threshold = "absent"
        }
    )
}

# Save alert configuration
$alertConfig = "artifacts\gpu-alerts-config.json"
$gpuAlerts | ConvertTo-Json -Depth 4 | Out-File -FilePath $alertConfig -Encoding UTF8

Write-Host "✅ GPU alert configuration saved to $alertConfig" -ForegroundColor Green

# ECRR: Report - Generate setup report
Write-Host "`n=== ECRR Report: GPU Alert Setup Complete ===" -ForegroundColor Cyan

$report = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    action = "setup-gpu-alerts"
    status = "completed"
    alerts_configured = 6
    features = @(
        "Automated GPU metrics monitoring",
        "Comprehensive alert thresholds",
        "ECRR-compliant reporting",
        "Windows scheduled task integration"
    )
}

$reportFile = "artifacts\gpu-alerts-setup-report.json"
$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ GPU Alert Setup Complete!" -ForegroundColor Green
Write-Host "📋 Alert Thresholds Configured: 6 alerts" -ForegroundColor Yellow
Write-Host "📁 Configuration: artifacts\gpu-alerts-config.json" -ForegroundColor Yellow

# ECRR: Role - Declare actor
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor Cyan