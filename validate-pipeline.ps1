# Comprehensive pipeline validation script

Write-Host "=== OTel Windows -> SigNoz Pipeline Validation ===" -ForegroundColor Green

# Test 1: Check Docker status
Write-Host "`n[1] Checking Docker status..." -ForegroundColor Yellow
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

# Test 2: Start Docker stack
Write-Host "`n[2] Starting Docker stack..." -ForegroundColor Yellow
docker compose -f .\docker-compose.yml up -d
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK Docker stack started" -ForegroundColor Green
} else {
    Write-Host "ERROR Failed to start Docker stack" -ForegroundColor Red
    exit 1
}

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Test 3: Check container status
Write-Host "`n[3] Checking container status..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host $containers

# Test 4: Check specific ports
Write-Host "`n[4] Checking critical ports..." -ForegroundColor Yellow
$ports = @(
    @{Port=4317; Label="SigNoz OTLP gRPC"},
    @{Port=4318; Label="SigNoz OTLP HTTP"},
    @{Port=5317; Label="Windows OTLP gRPC"},
    @{Port=5318; Label="Windows OTLP HTTP"},
    @{Port=8080; Label="SigNoz UI"},
    @{Port=8888; Label="Collector Metrics"},
    @{Port=13134; Label="Collector Health"}
)

foreach ($portInfo in $ports) {
    $result = Test-NetConnection -ComputerName localhost -Port $portInfo.Port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($result) {
        Write-Host "OK $($portInfo.Label) port $($portInfo.Port) is listening" -ForegroundColor Green
    } else {
        Write-Host "ERROR $($portInfo.Label) port $($portInfo.Port) is not listening" -ForegroundColor Red
    }
}

# Test 5: Check SigNoz UI
Write-Host "`n[5] Checking SigNoz UI..." -ForegroundColor Yellow
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

# Test 6: Check Windows OTel Collector service
Write-Host "`n[6] Checking Windows OTel Collector service..." -ForegroundColor Yellow
try {
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
    Write-Host "OK Service status: $($service.Status)" -ForegroundColor Green
} catch {
    Write-Host "ERROR Service not found or not accessible" -ForegroundColor Red
}

# Test 7: Send test log
Write-Host "`n[7] Sending test log..." -ForegroundColor Yellow
$timestamp = (Get-Date).ToString("o")
$canaryMessage = "windows-canary-$timestamp"

$logRecord = [pscustomobject]@{
    timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
    severityNumber = 9
    severityText = "INFO"
    body = [pscustomobject]@{ stringValue = $canaryMessage }
    attributes = @(
        [pscustomobject]@{
            key = "canary"
            value = [pscustomobject]@{ stringValue = "true" }
        }
    )
}

$resourceLog = [pscustomobject]@{
    resource = [pscustomobject]@{
        attributes = @(
            [pscustomobject]@{
                key = "service.name"
                value = [pscustomobject]@{ stringValue = "windows-collector" }
            }
        )
    }
    scopeLogs = @(
        [pscustomobject]@{
            logRecords = @($logRecord)
        }
    )
}

$logPayload = [pscustomobject]@{
    resourceLogs = @($resourceLog)
} | ConvertTo-Json -Depth 10

$otlpEndpoints = @("http://localhost:5318/v1/logs", "http://localhost:4318/v1/logs")
$sent = $false
foreach ($endpoint in $otlpEndpoints) {
    try {
        $response = Invoke-WebRequest -Method Post -Uri $endpoint -ContentType "application/json" -Body $logPayload -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "OK Test log sent to $endpoint" -ForegroundColor Green
            $sent = $true
            break
        }
    } catch {
        # Continue to next endpoint
    }
}

if (-not $sent) {
    Write-Host "ERROR Failed to send test log to any endpoint" -ForegroundColor Red
}

Write-Host "`n=== Validation Complete ===" -ForegroundColor Green
Write-Host "Check SigNoz UI at http://localhost:8080" -ForegroundColor Cyan
Write-Host "Filter logs by: log.body contains `"windows-canary`"" -ForegroundColor Cyan
