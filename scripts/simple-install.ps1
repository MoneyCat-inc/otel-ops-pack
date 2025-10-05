# Simple Working Installation Script
# ECRR Framework Implementation - No Hanging Issues

Write-Host "🚀 Simple Working Installation" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Step 1: Clean install
Write-Host "🧹 Cleaning dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Remove-Item -Recurse -Force node_modules
}
if (Test-Path "package-lock.json") {
    Remove-Item -Force package-lock.json
}
Write-Host "  ✅ Cleaned" -ForegroundColor Green

# Step 2: Install core dependencies first
Write-Host "`n📦 Installing core dependencies..." -ForegroundColor Yellow
Write-Host "  Installing Next.js..." -ForegroundColor Cyan
npm.cmd install next@^15.5.4 react@^18.2.0 react-dom@^18.2.0 --legacy-peer-deps

Write-Host "  Installing OpenTelemetry..." -ForegroundColor Cyan
npm.cmd install @opentelemetry/api@^1.7.0 @opentelemetry/sdk-node@^0.40.0 --legacy-peer-deps
npm.cmd install @opentelemetry/auto-instrumentations-node@^0.40.0 --legacy-peer-deps
npm.cmd install @opentelemetry/exporter-otlp-http@^0.26.0 --legacy-peer-deps
npm.cmd install @opentelemetry/resources@^1.18.1 @opentelemetry/semantic-conventions@^1.18.1 --legacy-peer-deps

# Step 3: Install remaining dependencies
Write-Host "`n📦 Installing remaining dependencies..." -ForegroundColor Yellow
npm.cmd install --legacy-peer-deps

# Step 4: Verify installation
Write-Host "`n🔍 Verifying installation..." -ForegroundColor Yellow
try {
    $NextVersion = npm.cmd list next --depth=0
    Write-Host "  ✅ Next.js installed" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Next.js installation failed" -ForegroundColor Red
}

# Step 5: Start application
Write-Host "`n🚀 Starting application..." -ForegroundColor Yellow
Write-Host "  💡 Run: npm run dev" -ForegroundColor Cyan
Write-Host "  🌐 Application will be at: http://localhost:3000" -ForegroundColor White
Write-Host "  📊 SigNoz UI at: http://localhost:8080" -ForegroundColor White

Write-Host "`n✅ Installation completed!" -ForegroundColor Green
Write-Host "🎯 Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: npm run dev" -ForegroundColor White
Write-Host "2. Check: http://localhost:3000" -ForegroundColor White
Write-Host "3. Check SigNoz: http://localhost:8080" -ForegroundColor White
