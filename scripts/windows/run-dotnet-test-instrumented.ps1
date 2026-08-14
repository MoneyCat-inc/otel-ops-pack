# Gate #026 Track A: Run .NET Test App with Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Launch test app with OTel profiler enabled

param(
    [string]$AppPath = ".\dotnet-test-app",
    [string]$ServiceName = "dotnet-test-gate026",
    [int]$DurationSeconds = 60
)

$ErrorActionPreference = "Stop"

Write-Host "=== .NET Auto-Instrumentation Test ===" -ForegroundColor Cyan
Write-Host ""

# Set OTel environment variables
$installDir = "$env:ProgramFiles\OpenTelemetry .NET AutoInstrumentation"

if (!(Test-Path $installDir)) {
    Write-Error "Auto-instrumentation not installed. Run install-dotnet-otel-autoinstrumentation.ps1 first."
    exit 1
}

$profilerDll = Join-Path $installDir "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
$startupHookDll = Join-Path $installDir "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"

Write-Host "[1/4] Configuring OTel environment..." -ForegroundColor White
$env:CORECLR_ENABLE_PROFILING = "1"
$env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
$env:CORECLR_PROFILER_PATH = $profilerDll
$env:DOTNET_STARTUP_HOOKS = $startupHookDll
$env:OTEL_DOTNET_AUTO_HOME = $installDir
$env:OTEL_SERVICE_NAME = $ServiceName
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:5321"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
$env:OTEL_TRACES_EXPORTER = "otlp"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=local"
$env:OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED = "false"
$env:OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED = "false"

Write-Host "  Service name: $ServiceName" -ForegroundColor Gray
Write-Host "  OTLP endpoint: http://127.0.0.1:4317" -ForegroundColor Gray
Write-Host "  Profiler: Enabled" -ForegroundColor Gray

Write-Host ""
Write-Host "[2/4] Starting instrumented app..." -ForegroundColor White
Write-Host "  App will run for $DurationSeconds seconds" -ForegroundColor Gray
Write-Host "  Listening on: http://localhost:5555" -ForegroundColor Gray
Write-Host ""

# Start app in background
$appJob = Start-Job -ScriptBlock {
    param($path, $envVars)
    foreach ($key in $envVars.Keys) {
        Set-Item "env:$key" $envVars[$key]
    }
    Set-Location $path
    dotnet run
} -ArgumentList $AppPath, @{
    CORECLR_ENABLE_PROFILING = "1"
    CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    CORECLR_PROFILER_PATH = $profilerDll
    DOTNET_STARTUP_HOOKS = $startupHookDll
    OTEL_DOTNET_AUTO_HOME = $installDir
    OTEL_SERVICE_NAME = $ServiceName
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317"
    OTEL_TRACES_EXPORTER = "otlp"
    OTEL_METRICS_EXPORTER = "otlp"
    OTEL_LOGS_EXPORTER = "otlp"
    OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED = "false"
    OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED = "false"
}

# Wait for app to start
Write-Host "  Waiting for app to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Check if app is running
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5555/health" -TimeoutSec 5
    Write-Host "  [OK] App running: $($health.service)" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] App may not be ready yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/4] Generating test traffic..." -ForegroundColor White

# Generate incoming HTTP requests
for ($i = 1; $i -le 10; $i++) {
    try {
        Invoke-RestMethod -Uri "http://localhost:5555/" -TimeoutSec 2 | Out-Null
        if ($i % 3 -eq 0) {
            Write-Host "  -> Request $i (incoming)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Request $i failed" -ForegroundColor Yellow
    }
    Start-Sleep -Milliseconds 500
}

# Generate requests with outbound calls
for ($i = 1; $i -le 5; $i++) {
    try {
        $result = Invoke-RestMethod -Uri "http://localhost:5555/test" -TimeoutSec 5
        Write-Host "  -> Request with outbound call: $($result.status)" -ForegroundColor Gray
    } catch {
        Write-Host "  [WARN] Outbound test $i failed: $($_.Exception.Message.Substring(0, 50))..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "[4/4] Waiting for telemetry ingestion..." -ForegroundColor White
Start-Sleep -Seconds 10

# Stop app
Write-Host "  Stopping app..." -ForegroundColor Gray
Stop-Job -Job $appJob
Remove-Job -Job $appJob

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Check SigNoz Traces: http://localhost:8080/traces-explorer" -ForegroundColor Gray
Write-Host "  2. Filter by service.name = '$ServiceName'" -ForegroundColor Gray
Write-Host "  3. Look for incoming HTTP spans and outbound HttpClient spans" -ForegroundColor Gray
Write-Host "  4. Check Metrics: http://localhost:8080/metrics-explorer" -ForegroundColor Gray
Write-Host ""

