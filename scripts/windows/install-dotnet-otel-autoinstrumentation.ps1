# Gate #026 Track A: Install OpenTelemetry .NET Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Enable zero-code OTel for .NET apps on Windows

param(
    [string]$InstallDir = "$env:ProgramFiles\OpenTelemetry .NET AutoInstrumentation",
    [string]$Version = "1.7.0"
)

$ErrorActionPreference = "Stop"

Write-Host "=== .NET OTel Auto-Instrumentation Install ===" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if (Test-Path $InstallDir) {
    Write-Host "[OK] Already installed: $InstallDir" -ForegroundColor Green
    Write-Host "To reinstall, delete directory and re-run." -ForegroundColor Gray
    exit 0
}

Write-Host "[1/3] Downloading OpenTelemetry .NET Auto-Instrumentation v$Version..." -ForegroundColor White

$downloadUrl = "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v$Version/opentelemetry-dotnet-instrumentation-windows.zip"
$zipPath = "$env:TEMP\otel-dotnet-auto.zip"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "  [OK] Downloaded to $zipPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to download: $_"
    exit 1
}

Write-Host ""
Write-Host "[2/3] Extracting to $InstallDir..." -ForegroundColor White

try {
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Write-Host "  [OK] Extracted successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to extract: $_"
    exit 1
}

Write-Host ""
Write-Host "[3/3] Configuring environment..." -ForegroundColor White

$profilerDll = Join-Path $InstallDir "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
$startupHookDll = Join-Path $InstallDir "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"

if (!(Test-Path $profilerDll)) {
    Write-Error "Profiler DLL not found: $profilerDll"
    exit 1
}

if (!(Test-Path $startupHookDll)) {
    Write-Error "StartupHook DLL not found: $startupHookDll"
    exit 1
}

Write-Host "  [OK] Components verified" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Install Directory: $InstallDir" -ForegroundColor White
Write-Host ""
Write-Host "Required Environment Variables:" -ForegroundColor White
Write-Host "  CORECLR_ENABLE_PROFILING=1" -ForegroundColor Gray
Write-Host "  CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}" -ForegroundColor Gray
Write-Host "  CORECLR_PROFILER_PATH=$profilerDll" -ForegroundColor Gray
Write-Host "  DOTNET_STARTUP_HOOKS=$startupHookDll" -ForegroundColor Gray
Write-Host "  OTEL_DOTNET_AUTO_HOME=$InstallDir" -ForegroundColor Gray
Write-Host "  OTEL_SERVICE_NAME=<your-service-name>" -ForegroundColor Gray
Write-Host "  OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317" -ForegroundColor Gray
Write-Host "  OTEL_TRACES_EXPORTER=otlp" -ForegroundColor Gray
Write-Host "  OTEL_METRICS_EXPORTER=otlp" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Create test .NET app or use existing service" -ForegroundColor Gray
Write-Host "  2. Set env vars for the process/service" -ForegroundColor Gray
Write-Host "  3. Restart app/service" -ForegroundColor Gray
Write-Host "  4. Verify in SigNoz: traces, metrics, logs" -ForegroundColor Gray
Write-Host ""

