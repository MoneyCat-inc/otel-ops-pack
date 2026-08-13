# SigNoz Stack Startup Script (PowerShell)
# Ensures proper initialization order and schema migration

Write-Host "Starting SigNoz Observability Stack..." -ForegroundColor Green

# Start core services
Write-Host "Starting ZooKeeper and ClickHouse..." -ForegroundColor Yellow
docker-compose -f docker-compose.yml up -d signoz-zookeeper signoz-clickhouse

# Wait for ClickHouse to be ready
Write-Host "Waiting for ClickHouse to be ready..." -ForegroundColor Yellow
do {
    try {
        docker exec signoz-clickhouse clickhouse-client --query "SELECT 1" *> $null
        if ($LASTEXITCODE -eq 0) { break }
    } catch {}
    Write-Host "   ClickHouse not ready yet, waiting..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
} while ($true)

Write-Host "ClickHouse is ready!" -ForegroundColor Green

# Run schema migration
Write-Host "Running SigNoz schema migration (sync)..." -ForegroundColor Yellow
docker-compose -f docker-compose.yml run --rm signoz-schema-migrator-sync
if ($LASTEXITCODE -ne 0) {
    Write-Error "Schema migration failed. Check docker compose output above."
    exit $LASTEXITCODE
}

Write-Host "Schema migration completed!" -ForegroundColor Green

# Start remaining services
Write-Host "Starting SigNoz collector and frontend..." -ForegroundColor Yellow
docker-compose -f docker-compose.yml up -d

# Wait for services to be healthy
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verify services
Write-Host "Verifying services..." -ForegroundColor Yellow
docker-compose -f docker-compose.yml ps

Write-Host "SigNoz stack is ready!" -ForegroundColor Green
Write-Host "   - SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "   - OTLP gRPC: localhost:4317" -ForegroundColor Cyan
Write-Host "   - OTLP HTTP: localhost:4318" -ForegroundColor Cyan
Write-Host "   - ClickHouse: http://localhost:8123" -ForegroundColor Cyan
