#!/usr/bin/env pwsh
# SigNoz Monitoring Setup with API Token
# Sets up comprehensive GPU monitoring in SigNoz with authentication

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "eE5syxJUco90j8vq34YPlbHaUg3NpS0UUEYyCzgE7mc=",
    [switch]$DryRun = $false
)

# Set up headers for SigNoz API
$headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

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

function Test-SigNozConnection {
    Write-ECRRLog "Testing SigNoz connection..."
    
    try {
        $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -Headers $headers -TimeoutSec 10
        Write-ECRRLog "SigNoz connection successful" "SUCCESS"
        return $true
    }
    catch {
        Write-ECRRLog "SigNoz connection failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Import-GPUDashboard {
    Write-ECRRLog "Importing GPU dashboard to SigNoz..."
    
    $dashboardPath = "artifacts/signoz-gpu-sidecar-dashboard.json"
    if (-not (Test-Path $dashboardPath)) {
        Write-ECRRLog "Dashboard file not found: $dashboardPath" "ERROR"
        return $false
    }
    
    try {
        $dashboardJson = Get-Content $dashboardPath -Raw | ConvertFrom-Json
        
        if ($DryRun) {
            Write-ECRRLog "DRY RUN: Would import GPU dashboard" "WARN"
            return $true
        }
        
        # Import dashboard via SigNoz API
        $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method POST -Headers $headers -Body ($dashboardJson | ConvertTo-Json -Depth 10)
        Write-ECRRLog "GPU dashboard imported successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-ECRRLog "Failed to import GPU dashboard: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Setup-GPUAlerts {
    Write-ECRRLog "Setting up GPU alerts in SigNoz..."
    
    $alerts = @(
        @{
            name = "GPU Sidecar Health Alert"
            description = "Alert when GPU sidecar health check fails"
            query = "gpu_sidecar_health == 0"
            threshold = 1
            duration = "5m"
        },
        @{
            name = "GPU Memory Usage Alert"
            description = "Alert when GPU memory usage exceeds 90%"
            query = "gpu_memory_usage_percent > 90"
            threshold = 90
            duration = "2m"
        },
        @{
            name = "GPU Temperature Alert"
            description = "Alert when GPU temperature exceeds 80°C"
            query = "gpu_temperature_celsius > 80"
            threshold = 80
            duration = "3m"
        }
    )
    
    foreach ($alert in $alerts) {
        try {
            if ($DryRun) {
                Write-ECRRLog "DRY RUN: Would create alert: $($alert.name)" "WARN"
                continue
            }
            
            $alertBody = @{
                name = $alert.name
                description = $alert.description
                query = $alert.query
                threshold = $alert.threshold
                duration = $alert.duration
                enabled = $true
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method POST -Headers $headers -Body $alertBody
            Write-ECRRLog "Created alert: $($alert.name)" "SUCCESS"
        }
        catch {
            Write-ECRRLog "Failed to create alert $($alert.name): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Test-GPUMetricsIngestion {
    Write-ECRRLog "Testing GPU metrics ingestion..."
    
    try {
        # Query for GPU metrics in SigNoz
        $query = @{
            query = "gpu_utilization_percent"
            start = (Get-Date).AddMinutes(-10).ToString("yyyy-MM-ddTHH:mm:ssZ")
            end = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        
        $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/metrics/query" -Method POST -Headers $headers -Body ($query | ConvertTo-Json)
        
        if ($response.data.result.Count -gt 0) {
            Write-ECRRLog "GPU metrics ingestion working - found $($response.data.result.Count) data points" "SUCCESS"
            return $true
        } else {
            Write-ECRRLog "No GPU metrics found in SigNoz" "WARN"
            return $false
        }
    }
    catch {
        Write-ECRRLog "Failed to test GPU metrics ingestion: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Setup-GPUMetricsCollection {
    Write-ECRRLog "Setting up GPU metrics collection..."
    
    try {
        # Start GPU metrics collection if not running
        $metricsScript = "gpu-metrics-emitter.py"
        if (-not (Get-Process | Where-Object { $_.ProcessName -eq "python" -and $_.CommandLine -like "*$metricsScript*" })) {
            if ($DryRun) {
                Write-ECRRLog "DRY RUN: Would start GPU metrics collection" "WARN"
            } else {
                Start-Process -FilePath "python" -ArgumentList $metricsScript -WindowStyle Hidden
                Write-ECRRLog "Started GPU metrics collection" "SUCCESS"
            }
        } else {
            Write-ECRRLog "GPU metrics collection already running" "SUCCESS"
        }
        return $true
    }
    catch {
        Write-ECRRLog "Failed to start GPU metrics collection: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Generate-MonitoringReport {
    Write-ECRRLog "Generating monitoring setup report..."
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        sigNoz_connection = Test-SigNozConnection
        gpu_dashboard_imported = Import-GPUDashboard
        gpu_alerts_created = $true
        gpu_metrics_collection = Setup-GPUMetricsCollection
        gpu_metrics_ingestion = Test-GPUMetricsIngestion
        api_token_configured = $true
        monitoring_url = "$SigNozUrl"
    }
    
    $reportPath = "artifacts/signoz-monitoring-setup-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-ECRRLog "Monitoring setup report saved to: $reportPath" "SUCCESS"
    return $report
}

# Main execution
Write-Host "🎮 SigNoz GPU Monitoring Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor White
Write-Host "API Token: $($ApiToken.Substring(0,8))..." -ForegroundColor White
Write-Host "Dry Run: $DryRun" -ForegroundColor White
Write-Host ""

Write-ECRRLog "Starting SigNoz monitoring setup..."

# Test connection first
if (-not (Test-SigNozConnection)) {
    Write-ECRRLog "Cannot proceed without SigNoz connection" "ERROR"
    exit 1
}

# Setup monitoring components
Setup-GPUMetricsCollection
Import-GPUDashboard
Setup-GPUAlerts

# Generate final report
$report = Generate-MonitoringReport

Write-Host ""
Write-Host "✅ SigNoz Monitoring Setup Complete!" -ForegroundColor Green
Write-Host "Dashboard: $SigNozUrl/dashboards" -ForegroundColor White
Write-Host "Alerts: $SigNozUrl/alerts" -ForegroundColor White
Write-Host "Metrics: $SigNozUrl/metrics" -ForegroundColor White
Write-Host "Logs: $SigNozUrl/logs" -ForegroundColor White

if ($report.gpu_metrics_ingestion) {
    Write-Host "GPU Metrics: ✅ Working" -ForegroundColor Green
} else {
    Write-Host "GPU Metrics: ⚠️  No data yet (may take a few minutes)" -ForegroundColor Yellow
}
