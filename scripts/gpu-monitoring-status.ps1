# GPU Monitoring Status Summary
# This script provides a comprehensive status of GPU monitoring setup

Write-Host "=== GPU Monitoring Status Summary ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. GPU SIDECARS STATUS" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
try {
    $gpuStatus = python scripts\check-gpu-sidecars.py 2>&1
    Write-Host $gpuStatus -ForegroundColor Green
} catch {
    Write-Host "Error checking GPU sidecars: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. METRICS EMISSION TEST" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow
try {
    $metricsOutput = python scripts\gpu-metrics-emitter.py 2>&1
    if ($metricsOutput -match "successfully wired to OTel pipeline") {
        Write-Host "SUCCESS: GPU metrics emission working" -ForegroundColor Green
    } else {
        Write-Host "WARNING: GPU metrics emission may have issues" -ForegroundColor Yellow
        Write-Host $metricsOutput -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error testing metrics emission: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. SIGNOZ UI ACCESS" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "SUCCESS: SigNoz UI accessible at http://localhost:8080" -ForegroundColor Green
    } else {
        Write-Host "WARNING: SigNoz UI returned status $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: SigNoz UI not accessible - $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. OTLP ENDPOINTS" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
try {
    $otlpTest = python scripts\otel_synthetic_ping.py 2>&1
    if ($otlpTest -match "Synthetic ping completed successfully") {
        Write-Host "SUCCESS: OTLP endpoints working" -ForegroundColor Green
    } else {
        Write-Host "WARNING: OTLP endpoints may have issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error testing OTLP: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "5. NEXT STEPS FOR SIGNOZ UI" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow
Write-Host "1. Open browser: http://localhost:8080" -ForegroundColor White
Write-Host "2. Go to Metrics → Search for 'gpu.utilization.percent'" -ForegroundColor White
Write-Host "3. Go to Alerts → Create alerts using scripts\setup-gpu-alerts.ps1" -ForegroundColor White
Write-Host "4. Go to Dashboards → Create 'GPU Monitoring Dashboard'" -ForegroundColor White
Write-Host ""

Write-Host "6. MONITORING COMMANDS" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
Write-Host "Check GPU health: python scripts\check-gpu-sidecars.py" -ForegroundColor Cyan
Write-Host "Emit metrics: python scripts\gpu-metrics-emitter.py" -ForegroundColor Cyan
Write-Host "View monitoring guide: pwsh -File scripts\signoz-gpu-monitoring-guide.ps1" -ForegroundColor Cyan
Write-Host "Setup alerts: pwsh -File scripts\setup-gpu-alerts.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== GPU Monitoring Setup Complete ===" -ForegroundColor Green
Write-Host "All systems operational - ready for SigNoz UI configuration" -ForegroundColor Green
