# Test script to verify the OTel Windows -> SigNoz setup

Write-Host "=== OTel Windows -> SigNoz Setup Test ===" -ForegroundColor Green

# Test 1: Check if Docker is running
Write-Host "`n[1] Testing Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "OK Docker found: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "ERROR Docker not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR Docker not accessible" -ForegroundColor Red
    exit 1
}

# Test 2: Check Docker containers
Write-Host "`n[2] Testing Docker containers..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
if ($containers -match "signoz") {
    Write-Host "OK SigNoz containers found" -ForegroundColor Green
    Write-Host $containers
} else {
    Write-Host "ERROR No SigNoz containers running" -ForegroundColor Red
    Write-Host "Starting Docker stack..." -ForegroundColor Yellow
    docker compose -f .\docker-compose.yml up -d
    Start-Sleep -Seconds 10
}

# Test 3: Check ports
Write-Host "`n[3] Testing ports..." -ForegroundColor Yellow
$ports = @(4317, 4318, 8080)
foreach ($port in $ports) {
    $result = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet
    if ($result) {
        Write-Host "OK Port $port is listening" -ForegroundColor Green
    } else {
        Write-Host "ERROR Port $port is not listening" -ForegroundColor Red
    }
}

# Test 4: Check SigNoz UI
Write-Host "`n[4] Testing SigNoz UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "OK SigNoz UI is accessible" -ForegroundColor Green
    } else {
        Write-Host "ERROR SigNoz UI returned status: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR SigNoz UI not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Check Windows OTel Collector service
Write-Host "`n[5] Testing Windows OTel Collector service..." -ForegroundColor Yellow
try {
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
    Write-Host "OK Service status: $($service.Status)" -ForegroundColor Green
} catch {
    Write-Host "ERROR Service not found or not accessible" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
