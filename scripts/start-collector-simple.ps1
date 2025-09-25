# start-collector-simple.ps1 - Simple collector startup without bind mounts
param(
    [string]$NetworkName = "otel_default"
)

Write-Host "🚀 Starting SigNoz OTel Collector (Simple Mode)..." -ForegroundColor Cyan

# Clean up any existing collector
Write-Host "🧹 Cleaning up existing collector..." -ForegroundColor Yellow
docker rm -f signoz-otel-collector 2>$null

# Check if network exists
Write-Host "🔍 Checking Docker network: $NetworkName" -ForegroundColor Yellow
$networkExists = docker network ls --format "{{.Name}}" | Select-String -Pattern "^$NetworkName$"
if (-not $networkExists) {
    Write-Host "❌ Network '$NetworkName' not found. Available networks:" -ForegroundColor Red
    docker network ls --format "table {{.Name}}\t{{.Driver}}"
    exit 1
}

Write-Host "✅ Network verified" -ForegroundColor Green

# Start collector with default config (no custom config file)
Write-Host "🚀 Starting collector with default config..." -ForegroundColor Cyan
$containerId = docker run -d --name signoz-otel-collector `
    --network $NetworkName `
    -p 4317:4317 -p 4318:4318 `
    signoz/signoz-otel-collector:v0.129.5

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Collector started successfully!" -ForegroundColor Green
    Write-Host "   Container ID: $containerId" -ForegroundColor Gray
    Write-Host "   Network: $NetworkName" -ForegroundColor Gray
    Write-Host "   OTLP gRPC: localhost:4317" -ForegroundColor Gray
    Write-Host "   OTLP HTTP: localhost:4318" -ForegroundColor Gray
    
    # Wait for startup
    Write-Host "⏳ Waiting for collector to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
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
    Write-Host "❌ Failed to start collector" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Collector startup complete!" -ForegroundColor Green
Write-Host "   Next: Run 'python gpu-metrics-emitter.py' to test metrics flow" -ForegroundColor Cyan
