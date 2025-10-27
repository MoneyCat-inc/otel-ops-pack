# Gate #027 Track 27B: Deploy .NET Service #2 with Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Demonstrate .NET pattern on second service

param(
    [string]$ServiceName = "bosscat-svc2-api",
    [int]$Port = 5556,
    [string]$InstallPath = "C:\otel\dotnet-autoinstrumentation"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #027 Track 27B: Service #2 Deployment ===" -ForegroundColor Cyan
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

# Set environment variables (Gate #027: Canonical .NET pattern)
Write-Host "[CONFIG] Setting OTel environment for: $ServiceName" -ForegroundColor Cyan

# Profiler
$env:CORECLR_ENABLE_PROFILING = "1"
$env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
$env:CORECLR_PROFILER_PATH = $profilerPath

# Startup Hook
$env:DOTNET_STARTUP_HOOKS = $startupHookPath

# OTel Home & Dependencies
$env:OTEL_DOTNET_AUTO_HOME = $InstallPath
$env:DOTNET_ADDITIONAL_DEPS = Join-Path $InstallPath "AdditionalDeps"
$env:DOTNET_SHARED_STORE = Join-Path $InstallPath "store"

# Service Identity (Gate #027 pattern)
$env:OTEL_SERVICE_NAME = $ServiceName
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=production,service.version=1.0.0,team=bosscat"

# Exporters (Gate #027: PRIMARY path - direct to SigNoz)
$env:OTEL_TRACES_EXPORTER = "otlp"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"

# OTLP Endpoint (PRIMARY: Direct to SigNoz)
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:14317"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"

# Instrumentation
$env:OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_METRICS_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_LOGS_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_TRACES_ASPNETCORE_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_TRACES_HTTPCLIENT_INSTRUMENTATION_ENABLED = "true"

Write-Host "   ✅ Service: $ServiceName" -ForegroundColor Green
Write-Host "   ✅ Endpoint: http://127.0.0.1:14317 (direct to SigNoz)" -ForegroundColor Green
Write-Host "   ✅ Port: $Port" -ForegroundColor Green

# Modify app to listen on specified port
$appPath = Join-Path $PSScriptRoot "..\..\dotnet-test-app\bin\Debug\net8.0\dotnet-test-app.dll"

if (-not (Test-Path $appPath)) {
    Write-Host ""
    Write-Host "Building .NET app..." -ForegroundColor Yellow
    Push-Location (Join-Path $PSScriptRoot "..\..\dotnet-test-app")
    try {
        dotnet build -c Debug
    } finally {
        Pop-Location
    }
}

# Launch
Write-Host ""
Write-Host "[LAUNCH] Starting service on port $Port..." -ForegroundColor Cyan
Write-Host "   Service: $ServiceName" -ForegroundColor White
Write-Host "   URL: http://localhost:$Port" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Gray
Write-Host ""

try {
    $env:ASPNETCORE_URLS = "http://localhost:$Port"
    dotnet exec $appPath
} catch {
    Write-Host "❌ Service crashed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

