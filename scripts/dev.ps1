# Resonai Development Script
# Starts Resonai dev server with proper environment

Write-Host "🎤 Starting Resonai Development Server..." -ForegroundColor Cyan

# Navigate to Resonai directory
$resonaiDir = "third_party\resonai"
if (-not (Test-Path $resonaiDir)) {
    Write-Error "Resonai directory not found: $resonaiDir"
    exit 1
}

Set-Location $resonaiDir

# Check if pnpm is available
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Warning "pnpm not found. Installing globally..."
    npm install -g pnpm
}

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    pnpm install
}

# Set environment variables for OTel integration
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/json"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:14318"
$env:OTEL_SERVICE_NAME = "resonai-local"
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=dev"

Write-Host "✅ Environment variables set for OTel integration" -ForegroundColor Green

# Start development server
Write-Host "🚀 Starting Next.js dev server..." -ForegroundColor Cyan
Write-Host "📍 URL: http://localhost:3003" -ForegroundColor White
Write-Host "🔧 OTel integration: Enabled" -ForegroundColor White
Write-Host "`nPress Ctrl+C to stop the server" -ForegroundColor Yellow

pnpm dev



