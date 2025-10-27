# Gate #027 Track 27B: Deploy .NET Service #3 with Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Demonstrate .NET pattern on third service

param(
    [string]$ServiceName = "bosscat-svc3-worker",
    [int]$Port = 5557,
    [string]$InstallPath = "C:\otel\dotnet-autoinstrumentation"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #027 Track 27B: Service #3 Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Verify installation
if (-not (Test-Path $InstallPath)) {
    Write-Host "❌ .NET Auto-Instrumentation not installed" -ForegroundColor Red
    exit 1
}

# Build paths
$profilerPath = Join-Path $InstallPath "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
$startupHookPath = Join-Path $InstallPath "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"

# Set environment (Gate #027: Canonical pattern)
Write-Host "[CONFIG] Setting OTel environment for: $ServiceName" -ForegroundColor Cyan

$env:CORECLR_ENABLE_PROFILING = "1"
$env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
$env:CORECLR_PROFILER_PATH = $profilerPath
$env:DOTNET_STARTUP_HOOKS = $startupHookPath
$env:OTEL_DOTNET_AUTO_HOME = $InstallPath
$env:DOTNET_ADDITIONAL_DEPS = Join-Path $InstallPath "AdditionalDeps"
$env:DOTNET_SHARED_STORE = Join-Path $InstallPath "store"

# Service Identity
$env:OTEL_SERVICE_NAME = $ServiceName
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=staging,service.version=1.1.0,team=bosscat"

# Exporters (PRIMARY path)
$env:OTEL_TRACES_EXPORTER = "otlp"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"
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

# Launch
$appPath = Join-Path $PSScriptRoot "..\..\dotnet-test-app\bin\Debug\net8.0\dotnet-test-app.dll"

Write-Host ""
Write-Host "[LAUNCH] Starting service on port $Port..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Gray
Write-Host ""

try {
    $env:ASPNETCORE_URLS = "http://localhost:$Port"
    dotnet exec $appPath
} catch {
    Write-Host "❌ Service crashed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

