# Setup Resonai OTel Environment Variables
Write-Host "🔧 Setting up Resonai OTel environment..." -ForegroundColor Cyan

$envContent = @"
# Local OTel Integration
OTEL_EXPORTER_OTLP_PROTOCOL=http/json
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_SERVICE_NAME=resonai-local
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev,service.version=1.0.0,service.instance.id=resonai-dev-001
"@

$envFile = "third_party\resonai\.env.local"
$envContent | Out-File -FilePath $envFile -Encoding UTF8

Write-Host "✅ Created $envFile" -ForegroundColor Green
Write-Host "📝 Environment variables set for OTel integration" -ForegroundColor Yellow

# Also set them in current session for immediate use
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/json"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
$env:OTEL_SERVICE_NAME = "resonai-local"
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=dev,service.version=1.0.0,service.instance.id=resonai-dev-001"

Write-Host "✅ Environment variables set in current session" -ForegroundColor Green
Write-Host "`n🚀 You can now run: cd third_party\resonai && pnpm dev" -ForegroundColor Cyan



