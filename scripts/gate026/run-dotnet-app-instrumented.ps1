# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Gate #026 Track A: Run .NET App with Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Launch .NET test app with OTel auto-instrumentation enabled

param(
    [string]$InstallPath = "C:\otel\dotnet-autoinstrumentation",
    [string]$ServiceName = "dotnet-test-gate026",
    [switch]$Baseline  # Run without instrumentation for overhead comparison
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #026 Track A: Running .NET App with Auto-Instrumentation ===" -ForegroundColor Cyan
Write-Host ""

# Verify installation
if (-not (Test-Path $InstallPath)) {
    Write-Host "❌ .NET Auto-Instrumentation not installed" -ForegroundColor Red
    Write-Host "   Run: .\scripts\gate026\install-dotnet-autoinstrumentation.ps1" -ForegroundColor Yellow
    exit 1
}

# Build paths
$profilerPath = Join-Path $InstallPath "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
$startupHookPath = Join-Path $InstallPath "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"

# Set environment variables
if (-not $Baseline) {
    Write-Host "[CONFIG] Setting OTel environment variables..." -ForegroundColor Cyan
    
    # .NET Profiler (CLR Profiling API)
    $env:CORECLR_ENABLE_PROFILING = "1"
    $env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    $env:CORECLR_PROFILER_PATH = $profilerPath
    
    # .NET Startup Hook
    $env:DOTNET_STARTUP_HOOKS = $startupHookPath
    
    # OTel Auto-Instrumentation Home
    $env:OTEL_DOTNET_AUTO_HOME = $InstallPath
    
    # Additional dependencies (Gate #026A: Full agent support)
    $env:DOTNET_ADDITIONAL_DEPS = Join-Path $InstallPath "AdditionalDeps"
    $env:DOTNET_SHARED_STORE = Join-Path $InstallPath "store"
    
    # Debug logging (Gate #026A: Investigation mode)
    $env:OTEL_LOG_LEVEL = "debug"
    $env:OTEL_DOTNET_AUTO_LOG_DIRECTORY = "C:\otel\artifacts\otel-logs"
    
    # Service configuration (Gate #026A: Direct to SigNoz)
    $env:OTEL_SERVICE_NAME = "bosscat-026a-dotnet"
    $env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=gate026,service.version=0.0.1,team=bosscat"
    
    # Exporters
    $env:OTEL_TRACES_EXPORTER = "otlp"
    $env:OTEL_METRICS_EXPORTER = "otlp"
    $env:OTEL_LOGS_EXPORTER = "otlp"
    
    # OTLP Endpoint (Gate #026A: Direct to SigNoz port 4317, not Windows Collector 5317)
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317"
    $env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
    
    # Instrumentation configuration
    $env:OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_METRICS_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_LOGS_INSTRUMENTATION_ENABLED = "true"
    
    # Enable specific instrumentations
    $env:OTEL_DOTNET_AUTO_TRACES_ASPNETCORE_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_TRACES_HTTPCLIENT_INSTRUMENTATION_ENABLED = "true"
    
    Write-Host "   ✅ OTel configured for: $ServiceName" -ForegroundColor Green
    Write-Host "   ✅ Exporting to: http://127.0.0.1:5317 (gRPC)" -ForegroundColor Green
} else {
    Write-Host "[BASELINE] Running WITHOUT instrumentation (baseline mode)" -ForegroundColor Yellow
}

# App path
$appPath = Join-Path $PSScriptRoot "..\..\dotnet-test-app\bin\Debug\net8.0\dotnet-test-app.dll"
if (-not (Test-Path $appPath)) {
    Write-Host "❌ App not built. Building..." -ForegroundColor Yellow
    Push-Location (Join-Path $PSScriptRoot "..\..\dotnet-test-app")
    try {
        dotnet build -c Debug
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Build failed" -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }
}

# Launch app
Write-Host ""
Write-Host "[LAUNCH] Starting .NET app..." -ForegroundColor Cyan
Write-Host "   App: $appPath" -ForegroundColor White
Write-Host "   URL: http://localhost:5555" -ForegroundColor White
if (-not $Baseline) {
    Write-Host "   Mode: AUTO-INSTRUMENTED ✨" -ForegroundColor Green
} else {
    Write-Host "   Mode: BASELINE (no instrumentation)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "🎯 Test endpoints:" -ForegroundColor Yellow
Write-Host "   GET http://localhost:5555/         (root)" -ForegroundColor White
Write-Host "   GET http://localhost:5555/test     (outbound HttpClient call)" -ForegroundColor White
Write-Host "   GET http://localhost:5555/health   (health check)" -ForegroundColor White
Write-Host ""
Write-Host "📊 Verify in SigNoz: http://localhost:8080" -ForegroundColor Yellow
Write-Host "   Service: $ServiceName" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Gray
Write-Host ""

# Run the app
try {
    dotnet exec $appPath
} catch {
    Write-Host ""
    Write-Host "❌ App crashed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

