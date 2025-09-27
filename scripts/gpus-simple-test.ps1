# Simple GPUS Command Test
param(
    [string]$Action = "status"
)

Write-Host "=== GPUS Command Test ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow

switch ($Action.ToLower()) {
    "status" {
        Write-Host "`nChecking GPU Sidecar Status..." -ForegroundColor Yellow
        Write-Host "1. Compression Sidecar (port 8001):" -ForegroundColor White
        $compression = curl -s http://localhost:8001/health 2>$null
        if ($compression) {
            Write-Host "   $compression" -ForegroundColor Green
        } else {
            Write-Host "   [FAIL] Not responding" -ForegroundColor Red
        }
        
        Write-Host "2. Aggregation Sidecar (port 8002):" -ForegroundColor White
        $aggregation = curl -s http://localhost:8002/health 2>$null
        if ($aggregation) {
            Write-Host "   $aggregation" -ForegroundColor Green
        } else {
            Write-Host "   [FAIL] Not responding" -ForegroundColor Red
        }
        
        Write-Host "3. Inference Sidecar (port 8003):" -ForegroundColor White
        $inference = curl -s http://localhost:8003/health 2>$null
        if ($inference) {
            Write-Host "   $inference" -ForegroundColor Green
        } else {
            Write-Host "   [FAIL] Not responding" -ForegroundColor Red
        }
        
        Write-Host "`nDocker Container Status:" -ForegroundColor Yellow
        docker ps --format "table {{.Names}}\t{{.Status}}" | findstr gpu
    }
    
    "metrics" {
        Write-Host "`nTesting GPU Metrics Emission..." -ForegroundColor Yellow
        try {
            $result = python scripts\gpu-metrics-emitter.py 2>&1
            Write-Host "Result: $result" -ForegroundColor White
        } catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
    
    "test" {
        Write-Host "`nRunning Complete GPU Pipeline Test..." -ForegroundColor Yellow
        
        Write-Host "1. Testing OTel Pipeline..." -ForegroundColor White
        try {
            $result = python scripts\otel_synthetic_ping.py 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   [SUCCESS] OTel pipeline working" -ForegroundColor Green
            } else {
                Write-Host "   [FAIL] OTel pipeline issues" -ForegroundColor Red
            }
        } catch {
            Write-Host "   [ERROR] OTel test failed: $_" -ForegroundColor Red
        }
        
        Write-Host "2. Testing GPU Sidecars..." -ForegroundColor White
        $healthy = 0
        $total = 3
        
        $compression = curl -s http://localhost:8001/health 2>$null
        if ($compression) { $healthy++ }
        
        $aggregation = curl -s http://localhost:8002/health 2>$null
        if ($aggregation) { $healthy++ }
        
        $inference = curl -s http://localhost:8003/health 2>$null
        if ($inference) { $healthy++ }
        
        Write-Host "   GPU Sidecars: $healthy/$total healthy" -ForegroundColor $(if($healthy -eq $total){"Green"}else{"Yellow"})
        
        Write-Host "3. Testing SigNoz Connectivity..." -ForegroundColor White
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 2>$null
            if ($response.StatusCode -eq 200) {
                Write-Host "   [SUCCESS] SigNoz UI accessible" -ForegroundColor Green
            } else {
                Write-Host "   [WARNING] SigNoz UI status: $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "   [WARNING] SigNoz UI not accessible" -ForegroundColor Yellow
        }
        
        Write-Host "`n=== GPU Pipeline Test Complete ===" -ForegroundColor Green
    }
    
    "help" {
        Write-Host "`nGPUS Command Test Usage:" -ForegroundColor Yellow
        Write-Host "  gpus-simple-test status   - Check GPU sidecar status" -ForegroundColor White
        Write-Host "  gpus-simple-test metrics  - Test GPU metrics emission" -ForegroundColor White
        Write-Host "  gpus-simple-test test     - Run complete pipeline test" -ForegroundColor White
        Write-Host "  gpus-simple-test help     - Show this help" -ForegroundColor White
    }
    
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Use 'gpus-simple-test help' for usage information" -ForegroundColor Yellow
    }
}
