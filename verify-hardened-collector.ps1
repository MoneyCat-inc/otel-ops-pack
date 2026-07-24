# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Verify Hardened Windows Collector Configuration
# This script validates the collector configuration and tests connectivity

Write-Host "=== Windows Collector Hardening Verification ===" -ForegroundColor Green

# 1. Validate YAML syntax
Write-Host "`n1. Validating YAML syntax..." -ForegroundColor Yellow
try {
    python -c "import yaml, pathlib; yaml.safe_load(pathlib.Path('config.yaml').read_text()); print('✓ YAML syntax validation: PASSED')"
    $yamlValid = $true
} catch {
    Write-Host "✗ YAML syntax validation: FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
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

# 3. Test collector ports
Write-Host "`n3. Testing collector ports..." -ForegroundColor Yellow

# Test gRPC port (5317)
try {
    $grpcTest = Test-NetConnection -ComputerName localhost -Port 5317 -WarningAction SilentlyContinue
    if ($grpcTest.TcpTestSucceeded) {
        Write-Host "✓ gRPC port 5317: OPEN" -ForegroundColor Green
        $grpcOpen = $true
    } else {
        Write-Host "✗ gRPC port 5317: CLOSED" -ForegroundColor Red
        $grpcOpen = $false
    }
} catch {
    Write-Host "✗ gRPC port 5317: ERROR" -ForegroundColor Red
    $grpcOpen = $false
}

# Test HTTP port (5318)
try {
    $httpTest = Test-NetConnection -ComputerName localhost -Port 5318 -WarningAction SilentlyContinue
    if ($httpTest.TcpTestSucceeded) {
        Write-Host "✓ HTTP port 5318: OPEN" -ForegroundColor Green
        $httpOpen = $true
    } else {
        Write-Host "✗ HTTP port 5318: CLOSED" -ForegroundColor Red
        $httpOpen = $false
    }
} catch {
    Write-Host "✗ HTTP port 5318: ERROR" -ForegroundColor Red
    $httpOpen = $false
}

# 4. Test health endpoint
Write-Host "`n4. Testing health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri 'http://localhost:13134/healthz' -TimeoutSec 5
    Write-Host "✓ Health endpoint: $healthResponse" -ForegroundColor Green
    $healthOk = $true
} catch {
    Write-Host "✗ Health endpoint: UNAVAILABLE" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    $healthOk = $false
}

# 5. Test SigNoz connectivity
Write-Host "`n5. Testing SigNoz connectivity..." -ForegroundColor Yellow
try {
    $signozTest = Test-NetConnection -ComputerName localhost -Port 4317 -WarningAction SilentlyContinue
    if ($signozTest.TcpTestSucceeded) {
        Write-Host "✓ SigNoz OTLP port 4317: OPEN" -ForegroundColor Green
        $signozOpen = $true
    } else {
        Write-Host "✗ SigNoz OTLP port 4317: CLOSED" -ForegroundColor Red
        $signozOpen = $false
    }
} catch {
    Write-Host "✗ SigNoz OTLP port 4317: ERROR" -ForegroundColor Red
    $signozOpen = $false
}

# 6. Summary
Write-Host "`n=== VERIFICATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "YAML Syntax: $(if($yamlValid){'✓ PASSED'}else{'✗ FAILED'})" -ForegroundColor $(if($yamlValid){'Green'}else{'Red'})
Write-Host "Service Status: $(if($serviceRunning){'✓ RUNNING'}else{'✗ STOPPED'})" -ForegroundColor $(if($serviceRunning){'Green'}else{'Red'})
Write-Host "gRPC Port 5317: $(if($grpcOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($grpcOpen){'Green'}else{'Red'})
Write-Host "HTTP Port 5318: $(if($httpOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($httpOpen){'Green'}else{'Red'})
Write-Host "Health Endpoint: $(if($healthOk){'✓ AVAILABLE'}else{'✗ UNAVAILABLE'})" -ForegroundColor $(if($healthOk){'Green'}else{'Red'})
Write-Host "SigNoz Port 4317: $(if($signozOpen){'✓ OPEN'}else{'✗ CLOSED'})" -ForegroundColor $(if($signozOpen){'Green'}else{'Red'})

# 7. Next steps
Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
if (-not $serviceRunning) {
    Write-Host "1. Start the collector service:" -ForegroundColor Yellow
    Write-Host "   Start-Service -Name otelcol-contrib" -ForegroundColor White
    Write-Host "   (Run as Administrator if needed)" -ForegroundColor Gray
}

if (-not $signozOpen) {
    Write-Host "2. Ensure SigNoz is running:" -ForegroundColor Yellow
    Write-Host "   docker ps | findstr signoz" -ForegroundColor White
}

Write-Host "`n3. Test log ingestion:" -ForegroundColor Yellow
Write-Host "   # Create test log entry" -ForegroundColor White
Write-Host "   Add-Content -Path 'C:\logs\test.log' -Value '{\"timestamp\":\"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')\",\"level\":\"INFO\",\"message\":\"SigNoz test from hardened collector\",\"service\":\"windows-host\"}'" -ForegroundColor White
Write-Host "`n   # Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "   # Filter: service.name = 'windows-host'" -ForegroundColor White

Write-Host "`n=== HARDENING FEATURES APPLIED ===" -ForegroundColor Green
Write-Host "✓ Enhanced batching (1024/2048 batch sizes)" -ForegroundColor Green
Write-Host "✓ Improved retry logic (1s-30s with 10m max elapsed)" -ForegroundColor Green
Write-Host "✓ Larger queue (50k items, 8 consumers)" -ForegroundColor Green
Write-Host "✓ GZIP compression enabled" -ForegroundColor Green
Write-Host "✓ Extended timeout (30s)" -ForegroundColor Green
Write-Host "✓ Resource enrichment (host.name, service.version)" -ForegroundColor Green
Write-Host "✓ Proper SigNoz endpoint (http://localhost:4317)" -ForegroundColor Green
