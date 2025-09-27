# SigNoz GPU Monitoring Guide
# This script provides step-by-step instructions for monitoring GPU metrics in SigNoz

Write-Host "=== SigNoz GPU Monitoring Guide ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. MONITOR SIGNOZ UI FOR GPU METRICS VISIBILITY" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Step 1: Open SigNoz UI" -ForegroundColor White
Write-Host "   URL: http://localhost:8080" -ForegroundColor Green
Write-Host ""
Write-Host "Step 2: Navigate to Metrics" -ForegroundColor White
Write-Host "   Click on 'Metrics' in the left sidebar" -ForegroundColor Green
Write-Host ""
Write-Host "Step 3: Look for GPU Metrics" -ForegroundColor White
Write-Host "   Search for these metric names:" -ForegroundColor Green
Write-Host "   - gpu.utilization.percent" -ForegroundColor Cyan
Write-Host "   - gpu.memory.used.bytes" -ForegroundColor Cyan
Write-Host "   - gpu.memory.total.bytes" -ForegroundColor Cyan
Write-Host "   - gpu.memory.utilization.percent" -ForegroundColor Cyan
Write-Host "   - gpu.temperature.celsius" -ForegroundColor Cyan
Write-Host "   - gpu.sidecar.health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 4: Filter by Service" -ForegroundColor White
Write-Host "   Filter by service name:" -ForegroundColor Green
Write-Host "   - gpu-compression-sidecar" -ForegroundColor Cyan
Write-Host "   - gpu-aggregation-sidecar" -ForegroundColor Cyan
Write-Host "   - gpu-inference-sidecar" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. SET UP GPU UTILIZATION ALERTS" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Step 1: Go to Alerts" -ForegroundColor White
Write-Host "   Click on 'Alerts' in the left sidebar" -ForegroundColor Green
Write-Host ""
Write-Host "Step 2: Create New Alert" -ForegroundColor White
Write-Host "   Click 'New Alert' button" -ForegroundColor Green
Write-Host ""
Write-Host "Step 3: Configure Alert" -ForegroundColor White
Write-Host "   Metric: gpu.utilization.percent" -ForegroundColor Green
Write-Host "   Condition: > 80%" -ForegroundColor Green
Write-Host "   Duration: 5 minutes" -ForegroundColor Green
Write-Host "   Severity: Warning" -ForegroundColor Green
Write-Host ""
Write-Host "Step 4: Add More Alerts" -ForegroundColor White
Write-Host "   GPU Memory: gpu.memory.utilization.percent > 90%" -ForegroundColor Green
Write-Host "   GPU Temperature: gpu.temperature.celsius > 85°C" -ForegroundColor Green
Write-Host "   Sidecar Health: gpu.sidecar.health == 0" -ForegroundColor Green
Write-Host ""

Write-Host "3. CREATE GPU MONITORING DASHBOARDS" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Step 1: Go to Dashboards" -ForegroundColor White
Write-Host "   Click on 'Dashboards' in the left sidebar" -ForegroundColor Green
Write-Host ""
Write-Host "Step 2: Create New Dashboard" -ForegroundColor White
Write-Host "   Click 'New Dashboard' button" -ForegroundColor Green
Write-Host "   Name: 'GPU Monitoring Dashboard'" -ForegroundColor Green
Write-Host ""
Write-Host "Step 3: Add Panels" -ForegroundColor White
Write-Host "   Panel 1: GPU Utilization %" -ForegroundColor Green
Write-Host "     Query: rate(gpu.utilization.percent[5m])" -ForegroundColor Cyan
Write-Host "     Visualization: Time Series" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Panel 2: GPU Memory Usage" -ForegroundColor Green
Write-Host "     Query: gpu.memory.used.bytes" -ForegroundColor Cyan
Write-Host "     Visualization: Time Series" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Panel 3: GPU Temperature" -ForegroundColor Green
Write-Host "     Query: gpu.temperature.celsius" -ForegroundColor Cyan
Write-Host "     Visualization: Time Series" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Panel 4: Sidecar Health Status" -ForegroundColor Green
Write-Host "     Query: gpu.sidecar.health" -ForegroundColor Cyan
Write-Host "     Visualization: Stat" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. VERIFY CONTINUOUS METRICS EMISSION" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Step 1: Check Monitoring Logs" -ForegroundColor White
Write-Host "   Command: Get-Content artifacts\gpu-monitoring-simple.log -Tail 20" -ForegroundColor Green
Write-Host ""
Write-Host "Step 2: Manual Metrics Emission" -ForegroundColor White
Write-Host "   Command: python scripts\gpu-metrics-emitter.py" -ForegroundColor Green
Write-Host ""
Write-Host "Step 3: Check GPU Sidecar Health" -ForegroundColor White
Write-Host "   Command: python scripts\check-gpu-sidecars.py" -ForegroundColor Green
Write-Host ""

Write-Host "5. TROUBLESHOOTING" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host ""
Write-Host "If no GPU metrics appear in SigNoz:" -ForegroundColor White
Write-Host "   1. Check OTel collector logs: docker logs signoz-otel-collector" -ForegroundColor Green
Write-Host "   2. Verify OTLP endpoint: curl http://localhost:4318/v1/health" -ForegroundColor Green
Write-Host "   3. Check ClickHouse: docker exec -it signoz-clickhouse clickhouse-client --query 'SELECT COUNT(*) FROM signoz_metrics.samples_v2'" -ForegroundColor Green
Write-Host ""
Write-Host "If GPU sidecars are unhealthy:" -ForegroundColor White
Write-Host "   1. Restart sidecars: python scripts\start-gpu-sidecars.py" -ForegroundColor Green
Write-Host "   2. Check Docker: docker ps | findstr gpu" -ForegroundColor Green
Write-Host ""

Write-Host "=== Monitoring Setup Complete ===" -ForegroundColor Green
Write-Host "Next: Follow the steps above to set up GPU monitoring in SigNoz UI" -ForegroundColor Green
