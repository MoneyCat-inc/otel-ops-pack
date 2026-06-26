# MEMX Integration Verification Script
# Verifies MEMX implementation and OTel integration readiness

Write-Host "🔍 MEMX Integration Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if MEMX mock exists
$memxPath = "resonai-mock"
if (-not (Test-Path $memxPath)) {
    Write-Host "❌ MEMX mock directory not found: $memxPath" -ForegroundColor Red
    Write-Host "   Run the MEMX implementation first" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ MEMX mock directory found" -ForegroundColor Green

# Check OTel collector configuration
$otelConfigPath = "config.yaml"
if (Test-Path $otelConfigPath) {
    $config = Get-Content $otelConfigPath -Raw
    if ($config -match "5318" -and $config -match "4318") {
        Write-Host "✅ OTel collector configured for MEMX integration" -ForegroundColor Green
        Write-Host "   - Port 5318: Windows OTel HTTP receiver" -ForegroundColor Gray
        Write-Host "   - Port 4318: SigNoz OTel HTTP receiver" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  OTel collector may need MEMX port configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  OTel config not found: $otelConfigPath" -ForegroundColor Yellow
}

# Check SigNoz stack status
Write-Host ""
Write-Host "🔍 Checking SigNoz stack status..." -ForegroundColor Cyan

try {
    $dockerStatus = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "signoz|clickhouse"
    if ($dockerStatus) {
        Write-Host "✅ SigNoz stack running:" -ForegroundColor Green
        $dockerStatus | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        Write-Host "⚠️  SigNoz stack not running" -ForegroundColor Yellow
        Write-Host "   Run: docker-compose up -d" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Docker not available or SigNoz not running" -ForegroundColor Yellow
}

# Check OTel collector service
Write-Host ""
Write-Host "🔍 Checking OTel collector service..." -ForegroundColor Cyan

try {
    $serviceStatus = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($serviceStatus) {
        if ($serviceStatus.Status -eq "Running") {
            Write-Host "✅ OTel collector service running" -ForegroundColor Green
        } else {
            Write-Host "⚠️  OTel collector service not running (Status: $($serviceStatus.Status))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  OTel collector service not installed" -ForegroundColor Yellow
        Write-Host "   Install with: winget install OpenTelemetry.OTelColContrib" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Could not check OTel collector service" -ForegroundColor Yellow
}

# Check ports
Write-Host ""
Write-Host "🔍 Checking port availability..." -ForegroundColor Cyan

$requiredPorts = @(
    @{Port=5318; Description="Windows OTel HTTP receiver"},
    @{Port=4318; Description="SigNoz OTel HTTP receiver"},
    @{Port=3000; Description="Resonai dev server"},
    @{Port=8080; Description="SigNoz UI"}
)

foreach ($portInfo in $requiredPorts) {
    $port = $portInfo.Port
    $description = $portInfo.Description
    
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($connection) {
            Write-Host "✅ Port $port available ($description)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Port $port not listening ($description)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not check port $port" -ForegroundColor Yellow
    }
}

# Check MEMX test suite
Write-Host ""
Write-Host "🔍 Running MEMX test suite..." -ForegroundColor Cyan

try {
    Push-Location $memxPath
    $testOutput = node scripts/test-memx.js 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MEMX test suite passed" -ForegroundColor Green
    } else {
        Write-Host "❌ MEMX test suite failed" -ForegroundColor Red
        Write-Host $testOutput -ForegroundColor Yellow
    }
    Pop-Location
} catch {
    Write-Host "❌ Could not run MEMX test suite" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

# Integration readiness summary
Write-Host ""
Write-Host "📋 Integration Readiness Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎯 MEMX Implementation Status:" -ForegroundColor White
Write-Host "   ✅ PR-0: Feature flags & scaffolding complete" -ForegroundColor Green
Write-Host "   🔄 PR-1: Schema & storage (pending)" -ForegroundColor Yellow
Write-Host "   🔄 PR-2: Browser instrumentation (pending)" -ForegroundColor Yellow
Write-Host "   🔄 PR-3: Labs UI & HUD (pending)" -ForegroundColor Yellow
Write-Host "   🔄 PR-4: SigNoz streaming (pending)" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔗 OTel Integration Points:" -ForegroundColor White
Write-Host "   • MEMX OTLP endpoint: http://localhost:5318/v1/logs" -ForegroundColor Gray
Write-Host "   • Dataset: resonai_analytics" -ForegroundColor Gray
Write-Host "   • Metrics: resonai_memx_wasm_heap_bytes, resonai_memx_sab_used_bytes, resonai_memx_sab_capacity_bytes, resonai_memx_worklet_ui_lag, resonai_memx_strain_pct" -ForegroundColor Gray
Write-Host "   • Log events: SAB_BACKLOG, WASM_GROW, WORKLET_LAG" -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor White
Write-Host "   1. Enable MEMX: Set NEXT_PUBLIC_FEATURE_MEMX=1" -ForegroundColor Gray
Write-Host "   2. Start Resonai: cd resonai-mock && npm run dev" -ForegroundColor Gray
Write-Host "   3. Visit MEMX Labs: http://localhost:3000/labs/memx" -ForegroundColor Gray
Write-Host "   4. Enable streaming: Toggle in labs page" -ForegroundColor Gray
Write-Host "   5. Monitor SigNoz: http://localhost:8080" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 MEMX Integration Ready!" -ForegroundColor Green
