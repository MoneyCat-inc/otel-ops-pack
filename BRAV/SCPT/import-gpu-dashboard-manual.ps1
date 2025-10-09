#!/usr/bin/env pwsh
# Manual GPU Dashboard Import for SigNoz
# Provides step-by-step instructions for importing GPU dashboard

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardPath = "artifacts/signoz-gpu-sidecar-dashboard.json"
)

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Show-DashboardImportInstructions {
    Write-Host "🎮 GPU Dashboard Import Instructions" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. Open SigNoz UI:" -ForegroundColor Yellow
    Write-Host "   $SigNozUrl" -ForegroundColor White
    Write-Host ""
    
    Write-Host "2. Navigate to Dashboards:" -ForegroundColor Yellow
    Write-Host "   Click 'Dashboards' in the left sidebar" -ForegroundColor White
    Write-Host ""
    
    Write-Host "3. Import Dashboard:" -ForegroundColor Yellow
    Write-Host "   Click 'Import Dashboard' button" -ForegroundColor White
    Write-Host "   Select file: $DashboardPath" -ForegroundColor White
    Write-Host "   Click 'Import'" -ForegroundColor White
    Write-Host ""
    
    Write-Host "4. Verify GPU Metrics:" -ForegroundColor Yellow
    Write-Host "   Go to 'Metrics' section" -ForegroundColor White
    Write-Host "   Search for 'gpu_' metrics" -ForegroundColor White
    Write-Host "   Look for metrics like:" -ForegroundColor White
    Write-Host "     - gpu_utilization_percent" -ForegroundColor Gray
    Write-Host "     - gpu_memory_usage_percent" -ForegroundColor Gray
    Write-Host "     - gpu_temperature_celsius" -ForegroundColor Gray
    Write-Host "     - gpu_power_consumption_watts" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "5. Check Alerts:" -ForegroundColor Yellow
    Write-Host "   Go to 'Alerts' section" -ForegroundColor White
    Write-Host "   Verify GPU alerts are active:" -ForegroundColor White
    Write-Host "     - GPU Sidecar Health Alert" -ForegroundColor Gray
    Write-Host "     - GPU Memory Usage Alert" -ForegroundColor Gray
    Write-Host "     - GPU Temperature Alert" -ForegroundColor Gray
    Write-Host ""
}

function Test-GPUMetricsInSigNoz {
    Write-ECRRLog "Testing GPU metrics in SigNoz..."
    
    Write-Host "🔍 GPU Metrics Test Queries:" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    
    $queries = @(
        "gpu_utilization_percent",
        "gpu_memory_usage_percent", 
        "gpu_temperature_celsius",
        "gpu_power_consumption_watts",
        "gpu_sidecar_health",
        "gpu_compression_throughput",
        "gpu_aggregation_latency"
    )
    
    foreach ($query in $queries) {
        Write-Host "Query: $query" -ForegroundColor Yellow
        Write-Host "URL: $SigNozUrl/metrics?query=$query" -ForegroundColor White
        Write-Host ""
    }
}

function Show-MonitoringCommands {
    Write-Host "📊 Monitoring Commands:" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Check GPU Status:" -ForegroundColor Yellow
    Write-Host ".\scripts\gpu-workflow-orchestrator.ps1 -Action status" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Monitor GPU Health:" -ForegroundColor Yellow
    Write-Host ".\scripts\gpu-workflow-orchestrator.ps1 -Action monitor" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Test GPU Integration:" -ForegroundColor Yellow
    Write-Host ".\scripts\gpu-workflow-orchestrator.ps1 -Action test" -ForegroundColor White
    Write-Host ""
    
    Write-Host "View GPU Metrics:" -ForegroundColor Yellow
    Write-Host "python gpu-metrics-emitter.py --duration 300 --interval 5" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Check SigNoz Health:" -ForegroundColor Yellow
    Write-Host "Invoke-WebRequest -Uri '$SigNozUrl/api/v1/health' -UseBasicParsing" -ForegroundColor White
    Write-Host ""
}

# Main execution
Write-ECRRLog "Starting GPU dashboard import guide..."

if (-not (Test-Path $DashboardPath)) {
    Write-ECRRLog "Dashboard file not found: $DashboardPath" "ERROR"
    exit 1
}

Show-DashboardImportInstructions
Test-GPUMetricsInSigNoz
Show-MonitoringCommands

Write-Host ""
Write-Host "✅ Manual Dashboard Import Guide Complete!" -ForegroundColor Green
Write-Host "Dashboard file: $DashboardPath" -ForegroundColor White
Write-Host "SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: GPU metrics may take 2-3 minutes to appear in SigNoz" -ForegroundColor Yellow
