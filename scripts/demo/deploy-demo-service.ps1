# Investor Demo: Enhanced .NET Service Deployment with Full OTel Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 1: Wire Signals & Story - OTel Enhancement
# Budget: Part of 300 LOC Phase 1 target

param(
    [string]$ServiceName = "bosscat-svc2-api",
    [int]$Port = 5556,
    [string]$InstallPath = "C:\otel\dotnet-autoinstrumentation",
    [switch]$EnableDemo = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Investor Demo: .NET Service Deployment ===" -ForegroundColor Cyan
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

# Set environment variables (Enhanced for investor demo)
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

# Service Identity (Demo-enhanced with rich attributes)
$env:OTEL_SERVICE_NAME = $ServiceName
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=investor-demo,service.version=1.0.0-demo,team=bosscat,demo.phase=phase1"

# Exporters
$env:OTEL_TRACES_EXPORTER = "otlp"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"

# OTLP Endpoint (Direct to SigNoz for demo visibility)
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:14317"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"

# Core Instrumentation (all enabled)
$env:OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_METRICS_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_LOGS_INSTRUMENTATION_ENABLED = "true"

# HTTP Instrumentation (ASP.NET Core + HttpClient)
$env:OTEL_DOTNET_AUTO_TRACES_ASPNETCORE_INSTRUMENTATION_ENABLED = "true"
$env:OTEL_DOTNET_AUTO_TRACES_HTTPCLIENT_INSTRUMENTATION_ENABLED = "true"

# Database Instrumentation (ADO.NET / SqlClient)
$env:OTEL_DOTNET_AUTO_TRACES_SQLCLIENT_INSTRUMENTATION_ENABLED = "true"

# Cache Instrumentation (Redis)
$env:OTEL_DOTNET_AUTO_TRACES_STACKEXCHANGEREDIS_INSTRUMENTATION_ENABLED = "true"

# Additional Sources (Custom application code tracing)
# Add custom ActivitySource names for app-level tracing
$env:OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES = "InvestorDemo.*,BossCat.*,DemoApp.*"

# Log Correlation (ILogger integration)
$env:OTEL_DOTNET_AUTO_LOGS_INCLUDE_FORMATTED_MESSAGE = "true"

# Demo Mode Enhancements
if ($EnableDemo) {
    Write-Host "   🎯 Demo mode enabled - enhanced telemetry" -ForegroundColor Yellow
    # More verbose spans for demo clarity
    $env:OTEL_TRACES_SAMPLER = "always_on"
    # Add demo-specific resource attributes
    $env:OTEL_RESOURCE_ATTRIBUTES += ",demo.enabled=true,demo.timestamp=$((Get-Date).ToUniversalTime().ToString('o'))"
}

Write-Host "   ✅ Service: $ServiceName" -ForegroundColor Green
Write-Host "   ✅ Endpoint: http://127.0.0.1:14317 (SigNoz)" -ForegroundColor Green
Write-Host "   ✅ Port: $Port" -ForegroundColor Green
Write-Host "   ✅ Instrumentation: ASP.NET Core, HttpClient, SqlClient, Redis" -ForegroundColor Green
Write-Host "   ✅ Custom Sources: InvestorDemo.*, BossCat.*, DemoApp.*" -ForegroundColor Green

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
Write-Host "   Health: http://localhost:$Port/health" -ForegroundColor White
Write-Host ""
Write-Host "Investor Demo Ready - Telemetry flowing to SigNoz:8080" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Gray
Write-Host ""

try {
    $env:ASPNETCORE_URLS = "http://localhost:$Port"
    dotnet exec $appPath
} catch {
    Write-Host "❌ Service crashed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

