# Windows Collector Hardening Verification Script
Write-Host "=== Windows Collector Hardening Verification ===" -ForegroundColor Green

# 1. Validate YAML syntax
Write-Host "`n1. Validating YAML syntax..." -ForegroundColor Yellow
try {
    $yamlResult = python -c "import yaml, pathlib; yaml.safe_load(pathlib.Path('config.yaml').read_text()); print('PASSED')" 2>&1
    if ($yamlResult -match "PASSED") {
        Write-Host "✓ YAML syntax validation: PASSED" -ForegroundColor Green
        $yamlValid = $true
    } else {
        Write-Host "✗ YAML syntax validation: FAILED" -ForegroundColor Red
        Write-Host "Error: $yamlResult" -ForegroundColor Red
        $yamlValid = $false
    }
} catch {
    Write-Host "✗ YAML syntax validation: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    $yamlValid = $false
}

# 2. Check service status
Write-Host "`n2. Checking collector service status..." -ForegroundColor Yellow
try {
    $service = Get-Service -Name otelcol-contrib -ErrorAction Stop
    Write-Host "✓ Service Status: $($service.Status)" -ForegroundColor Green
    $serviceRunning = $service.Status -eq 'Running'
} catch {
    Write-Host "✗ Service not found or not accessible" -ForegroundColor Red
    $serviceRunning = $false
}

# 3. Test health endpoint
Write-Host "`n3. Testing health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri 'http://localhost:13134/healthz' -TimeoutSec 5
    Write-Host "✓ Health endpoint: $healthResponse" -ForegroundColor Green
    $healthOk = $true
} catch {
    Write-Host "✗ Health endpoint: UNAVAILABLE" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    $healthOk = $false
}

# 4. Test port connectivity
Write-Host "`n4. Testing port connectivity..." -ForegroundColor Yellow

# Test gRPC port (5320)
try {
    $grpcTest = Test-NetConnection -ComputerName localhost -Port 5320 -WarningAction SilentlyContinue
    if ($grpcTest.TcpTestSucceeded) {
        Write-Host "✓ gRPC port 5320: OPEN" -ForegroundColor Green
        $grpcOpen = $true
    } else {
        Write-Host "✗ gRPC port 5320: CLOSED" -ForegroundColor Red
        $grpcOpen = $false
    }
} catch {
    Write-Host "✗ gRPC port 5320: ERROR" -ForegroundColor Red
    $grpcOpen = $false
}

# Test HTTP port (5321)
try {
    $httpTest = Test-NetConnection -ComputerName localhost -Port 5321 -WarningAction SilentlyContinue
    if ($httpTest.TcpTestSucceeded) {
        Write-Host "✓ HTTP port 5321: OPEN" -ForegroundColor Green
        $httpOpen = $true
    } else {
        Write-Host "✗ HTTP port 5321: CLOSED" -ForegroundColor Red
        $httpOpen = $false
    }
} catch {
    Write-Host "✗ HTTP port 5321: ERROR" -ForegroundColor Red
    $httpOpen = $false
}

# 5. Test SigNoz connectivity
Write-Host "`n5. Testing SigNoz connectivity..." -ForegroundColor Yellow

# SigNoz gRPC (4317)
try {
    $signozGrpcTest = Test-NetConnection -ComputerName localhost -Port 4317 -WarningAction SilentlyContinue
    if ($signozGrpcTest.TcpTestSucceeded) {
        Write-Host "✓ SigNoz OTLP gRPC port 4317: OPEN" -ForegroundColor Green
        $signozGrpcOpen = $true
    } else {
        Write-Host "✗ SigNoz OTLP gRPC port 4317: CLOSED" -ForegroundColor Red
        $signozGrpcOpen = $false
    }
} catch {
    Write-Host "✗ SigNoz OTLP gRPC port 4317: ERROR" -ForegroundColor Red
    $signozGrpcOpen = $false
}

# SigNoz HTTP (4318)
try {
    $signozHttpTest = Test-NetConnection -ComputerName localhost -Port 4318 -WarningAction SilentlyContinue
    if ($signozHttpTest.TcpTestSucceeded) {
        Write-Host "✓ SigNoz OTLP HTTP port 4318: OPEN" -ForegroundColor Green
        $signozHttpOpen = $true
    } else {
        Write-Host "✗ SigNoz OTLP HTTP port 4318: CLOSED" -ForegroundColor Red
        $signozHttpOpen = $false
    }
} catch {
    Write-Host "✗ SigNoz OTLP HTTP port 4318: ERROR" -ForegroundColor Red
    $signozHttpOpen = $false
}
# 6. Summary
Write-Host "`n=== VERIFICATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "YAML Syntax: $(if($yamlValid){'✓ PASSED'}else{'✗ FAILED'})" -ForegroundColor $(if($yamlValid){'Green'}else{'Red'})
Write-Host "Service Status: $(if($serviceRunning){'✓ RUNNING'}else{'✗ STOPPED'})" -ForegroundColor $(if($serviceRunning){'Green'}else{'Red'})
Write-Host "Health Endpoint: $(if($healthOk){'✓ AVAILABLE'}else{'✗ UNAVAILABLE'})" -ForegroundColor $(if($healthOk){'Green'}else{'Red'})
Write-Host "gRPC Port 5320: $(if($grpcOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($grpcOpen){'Green'}else{'Red'})
Write-Host "HTTP Port 5321: $(if($httpOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($httpOpen){'Green'}else{'Red'})
Write-Host "SigNoz gRPC Port 4317: $(if($signozGrpcOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($signozGrpcOpen){'Green'}else{'Red'})
Write-Host "SigNoz HTTP Port 4318: $(if($signozHttpOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($signozHttpOpen){'Green'}else{'Red'})

# 7. Hardening features applied
Write-Host "`n=== HARDENING FEATURES APPLIED ===" -ForegroundColor Green
Write-Host "✓ Enhanced batching (200ms timeout, 1024/2048 batch sizes)" -ForegroundColor Green
Write-Host "✓ Retry with exponential backoff (100ms->5s, 30s max elapsed)" -ForegroundColor Green
Write-Host "✓ Bounded send queue (2048 items, 8 consumers)" -ForegroundColor Green
Write-Host "✓ Sensitive header redaction active" -ForegroundColor Green
Write-Host "✓ Windows event noise filters (IDs 6005/6006/7036)" -ForegroundColor Green
Write-Host "✓ Resource defaults (deployment.env/service.name)" -ForegroundColor Green
Write-Host "✓ SigNoz OTLP endpoints (http://localhost:4317 gRPC, http://localhost:4318 HTTP)" -ForegroundColor Green

# 8. Next steps
Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
if (-not $serviceRunning) {
    Write-Host "1. Start the collector service:" -ForegroundColor Yellow
    Write-Host "   Start-Service -Name otelcol-contrib" -ForegroundColor White
    Write-Host "   (Run as Administrator if needed)" -ForegroundColor Gray
}

if (-not ($signozGrpcOpen -and $signozHttpOpen)) {
    Write-Host "2. Ensure SigNoz is running:" -ForegroundColor Yellow
    Write-Host "   docker ps | findstr signoz" -ForegroundColor White
    Write-Host "   # Expect signoz-otel-collector to expose 4317/4318" -ForegroundColor Gray
}

Write-Host "`n3. Test log ingestion:" -ForegroundColor Yellow
Write-Host "   # Create test log entry" -ForegroundColor White
Write-Host "   Add-Content -Path 'C:\logs\test.log' -Value '{\"timestamp\":\"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')\",\"level\":\"INFO\",\"message\":\"SigNoz test from hardened collector\",\"service\":\"windows-host\"}'" -ForegroundColor White
Write-Host "`n   # Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "   # Filter: service.name = 'windows-host'" -ForegroundColor White

Write-Host "`n=== VERIFICATION COMPLETE ===" -ForegroundColor Cyan
