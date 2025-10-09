# Fix Dependencies and Start Application
# ECRR Framework Implementation - Dependency Resolution

Write-Host "🔧 Fixing Dependencies and Starting Application" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Step 1: Clean install
Write-Host "🧹 Step 1: Cleaning old dependencies..." -ForegroundColor Yellow
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
Write-Host "  ✅ Cleaned old dependencies" -ForegroundColor Green

# Step 2: Install with force to resolve conflicts
Write-Host "`n📦 Step 2: Installing dependencies..." -ForegroundColor Yellow
try {
    npm install --legacy-peer-deps --force
    Write-Host "  ✅ Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 Trying alternative installation method..." -ForegroundColor Yellow
    
    # Try installing core dependencies first
    npm install next@^15.5.4 react@^18.2.0 react-dom@^18.2.0 --legacy-peer-deps
    npm install @opentelemetry/api@^1.7.0 @opentelemetry/sdk-node@^0.40.0 --legacy-peer-deps
    npm install --legacy-peer-deps --force
}

# Step 3: Verify Next.js installation
Write-Host "`n🔍 Step 3: Verifying Next.js installation..." -ForegroundColor Yellow
try {
    $NextVersion = npx next --version
    Write-Host "  ✅ Next.js installed: $NextVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Next.js not found, installing..." -ForegroundColor Red
    npm install next@^15.5.4 --legacy-peer-deps
}

# Step 4: Use simplified instrumentation
Write-Host "`n⚙️ Step 4: Setting up simplified instrumentation..." -ForegroundColor Yellow
if (Test-Path "instrumentation-simple.js") {
    Copy-Item instrumentation-simple.js instrumentation.js -Force
    Write-Host "  ✅ Using simplified instrumentation" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Simplified instrumentation not found, using existing" -ForegroundColor Yellow
}

# Step 5: Start application
Write-Host "`n🚀 Step 5: Starting application..." -ForegroundColor Yellow
Write-Host "  💡 Starting Next.js development server..." -ForegroundColor Cyan
Write-Host "  🌐 Application will be available at: http://localhost:3000" -ForegroundColor White
Write-Host "  📊 SigNoz UI is available at: http://localhost:8080" -ForegroundColor White
Write-Host ""

# Start the application in background
Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow -PassThru

# Wait a moment for the app to start
Start-Sleep -Seconds 5

# Step 6: Verify application is running
Write-Host "`n🔍 Step 6: Verifying application startup..." -ForegroundColor Yellow
try {
    $AppResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 10
    Write-Host "  ✅ Application is running and healthy" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Application may still be starting up..." -ForegroundColor Yellow
    Write-Host "  💡 Check http://localhost:3000 in your browser" -ForegroundColor Cyan
}

# Step 7: Run verification
Write-Host "`n🔍 Step 7: Running verification..." -ForegroundColor Yellow
if (Test-Path "scripts/fixed-verification.ps1") {
    pwsh -File scripts/fixed-verification.ps1
} else {
    Write-Host "  ⚠️ Verification script not found" -ForegroundColor Yellow
}

Write-Host "`n✅ Setup completed!" -ForegroundColor Green
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check application: http://localhost:3000" -ForegroundColor White
Write-Host "2. Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "3. Check traces: http://localhost:8080/traces" -ForegroundColor White
Write-Host "4. Check logs: http://localhost:8080/logs" -ForegroundColor White
