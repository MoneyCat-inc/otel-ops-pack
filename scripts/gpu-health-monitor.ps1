# GPU Health Monitor for SigNoz Integration
# ECRR Compliant: Examine → Clean → Report → Role

param(
    [int]$DurationMinutes = 5,
    [int]$IntervalSeconds = 15,
    [string]$ReportPath = "artifacts/gpu-health-report.json"
)

# ECRR: Examine - Capture GPU state
$examineStart = Get-Date
$healthReport = @{
    timestamp = $examineStart.ToString("yyyy-MM-dd HH:mm:ss")
    duration_minutes = $DurationMinutes
    interval_seconds = $IntervalSeconds
    examine = @{}
    clean = @{}
    report = @{}
    role = "GPU Health Monitor"
}

Write-Host "🔍 ECRR Examine: Checking GPU health..." -ForegroundColor Cyan

# Check if GPU metrics emitter is available
$gpuEmitterPath = Join-Path $PSScriptRoot "..\gpu-metrics-emitter.py"
$gpuEmitterRunning = $false

try {
    # Check if Python GPU emitter can run
    $pythonTest = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python available: $pythonTest" -ForegroundColor Green
        $healthReport.examine.python_available = $true
    } else {
        Write-Host "❌ Python not available" -ForegroundColor Red
        $healthReport.examine.python_available = $false
    }
} catch {
    Write-Host "❌ Python check failed: $($_.Exception.Message)" -ForegroundColor Red
    $healthReport.examine.python_available = $false
}

# Check GPU services
$gpuServices = @("localhost:8001", "localhost:8002", "localhost:8003")
$healthyServices = @()

foreach ($service in $gpuServices) {
    try {
        $response = Invoke-WebRequest "http://$service/metrics" -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ GPU service $service is healthy" -ForegroundColor Green
            $healthyServices += $service
        }
    } catch {
        Write-Host "❌ GPU service $service is unhealthy: $($_.Exception.Message)" -ForegroundColor Red
    }
}

$healthReport.examine = @{
    python_available = $healthReport.examine.python_available
    gpu_services_total = $gpuServices.Count
    gpu_services_healthy = $healthyServices.Count
    healthy_services = $healthyServices
}

# ECRR: Clean - Start monitoring if services are healthy
if ($healthyServices.Count -eq 0) {
    Write-Host "⚠️  No healthy GPU services found - monitoring skipped" -ForegroundColor Yellow
    $healthReport.clean.monitoring_started = $false
    $healthReport.clean.reason = "No healthy GPU services"
} else {
    Write-Host "🧹 ECRR Clean: Starting GPU health monitoring..." -ForegroundColor Cyan
    
    $monitoringData = @()
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    
    while ((Get-Date) -lt $endTime) {
        $currentTime = Get-Date
        $sample = @{
            timestamp = $currentTime.ToString("yyyy-MM-dd HH:mm:ss")
            services = @{}
        }
        
        foreach ($service in $healthyServices) {
            try {
                $response = Invoke-WebRequest "http://$service/metrics" -UseBasicParsing -TimeoutSec 3
                $sample.services[$service] = @{
                    status = "healthy"
                    response_time_ms = $response.Headers["X-Response-Time"] ?? "unknown"
                    content_length = $response.Content.Length
                }
            } catch {
                $sample.services[$service] = @{
                    status = "unhealthy"
                    error = $_.Exception.Message
                }
            }
        }
        
        $monitoringData += $sample
        
        # Progress indicator
        $elapsed = [math]::Round(($currentTime - $examineStart).TotalSeconds, 0)
        $remaining = [math]::Round(($endTime - $currentTime).TotalSeconds, 0)
        Write-Host "⠋ Monitoring... $elapsed/$($DurationMinutes * 60)s (${remaining}s remaining)" -NoNewline -ForegroundColor Cyan
        
        Start-Sleep -Seconds $IntervalSeconds
    }
    
    Write-Host "`r✅ Monitoring completed" -ForegroundColor Green
    
    $healthReport.clean = @{
        monitoring_started = $true
        samples_collected = $monitoringData.Count
        monitoring_data = $monitoringData
    }
}

# ECRR: Report - Generate health report
$healthReport.report = @{
    report_path = $ReportPath
    execution_time_seconds = [math]::Round(((Get-Date) - $examineStart).TotalSeconds, 2)
    success = $true
}

# Ensure artifacts directory exists
$reportDir = Split-Path $ReportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$healthReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "📝 ECRR Report: Health report saved to $ReportPath" -ForegroundColor Green
Write-Host "🎭 ECRR Role: $($healthReport.role)" -ForegroundColor Magenta

# Summary
Write-Host "`n=== GPU HEALTH SUMMARY ===" -ForegroundColor Cyan
Write-Host "Healthy services: $($healthyServices.Count)/$($gpuServices.Count)" -ForegroundColor White
Write-Host "Monitoring duration: $DurationMinutes minutes" -ForegroundColor White
Write-Host "Samples collected: $($healthReport.clean.samples_collected)" -ForegroundColor White
Write-Host "Execution time: $($healthReport.report.execution_time_seconds) seconds" -ForegroundColor White
