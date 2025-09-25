# run-collector.ps1 - Deploy SigNoz OTel Collector without Windows bind mount issues
param(
    [string]$NetworkName = "otel_default",
    [string]$ConfigPath = "config/collector-config.yaml"
)

Write-Host "🚀 Deploying SigNoz OTel Collector..." -ForegroundColor Cyan

# Clean up any existing collector
Write-Host "🧹 Cleaning up existing collector..." -ForegroundColor Yellow
docker rm -f signoz-otel-collector 2>$null

# Verify network exists
Write-Host "🔍 Checking Docker network: $NetworkName" -ForegroundColor Yellow
$networkExists = docker network ls --format "{{.Name}}" | Select-String -Pattern "^$NetworkName$"
if (-not $networkExists) {
    Write-Host "❌ Network '$NetworkName' not found. Available networks:" -ForegroundColor Red
    docker network ls --format "table {{.Name}}\t{{.Driver}}"
    exit 1
}

# Verify config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "❌ Config file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Network and config verified" -ForegroundColor Green

# Deploy collector with config file
Write-Host "🚀 Starting collector container..." -ForegroundColor Cyan
$containerId = docker run -d --name signoz-otel-collector `
    --network $NetworkName `
    -p 4317:4317 -p 4318:4318 `
    -v "${PWD}/${ConfigPath}:/etc/otelcol/config.yaml:ro" `
    signoz/signoz-otel-collector:v0.129.5

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Collector deployed successfully!" -ForegroundColor Green
    Write-Host "   Container ID: $containerId" -ForegroundColor Gray
    Write-Host "   Network: $NetworkName" -ForegroundColor Gray
    Write-Host "   OTLP gRPC: localhost:4317" -ForegroundColor Gray
    Write-Host "   OTLP HTTP: localhost:4318" -ForegroundColor Gray
    
    # Wait a moment for startup
    Start-Sleep -Seconds 3
    
    # Test connectivity
    Write-Host "🔍 Testing OTLP endpoints..." -ForegroundColor Yellow
    $grpcTest = Test-NetConnection -ComputerName localhost -Port 4317 -WarningAction SilentlyContinue
    $httpTest = Test-NetConnection -ComputerName localhost -Port 4318 -WarningAction SilentlyContinue
    
    if ($grpcTest.TcpTestSucceeded) {
        Write-Host "✅ gRPC endpoint (4317) is ready" -ForegroundColor Green
    } else {
        Write-Host "❌ gRPC endpoint (4317) not responding" -ForegroundColor Red
    }
    
    if ($httpTest.TcpTestSucceeded) {
        Write-Host "✅ HTTP endpoint (4318) is ready" -ForegroundColor Green
    } else {
        Write-Host "❌ HTTP endpoint (4318) not responding" -ForegroundColor Red
    }
    
    # Show recent logs
    Write-Host "📋 Recent collector logs:" -ForegroundColor Yellow
    docker logs --since 30s signoz-otel-collector | Select-Object -Last 10
    
} else {
    Write-Host "❌ Failed to deploy collector" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Collector deployment complete!" -ForegroundColor Green
Write-Host "   Next: Run 'python gpu-metrics-emitter.py' to test metrics flow" -ForegroundColor Cyan
