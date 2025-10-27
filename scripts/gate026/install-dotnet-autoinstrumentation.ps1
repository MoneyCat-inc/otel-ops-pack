# Gate #026 Track A: Install .NET Auto-Instrumentation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Install OpenTelemetry .NET Auto-Instrumentation for zero-code telemetry

param(
    [string]$InstallPath = "C:\otel\dotnet-autoinstrumentation",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #026 Track A: .NET Auto-Instrumentation Installation ===" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if ((Test-Path $InstallPath) -and -not $Force) {
    Write-Host "✅ .NET Auto-Instrumentation already installed at: $InstallPath" -ForegroundColor Green
    Write-Host "   Use -Force to reinstall" -ForegroundColor Yellow
    exit 0
}

# Create install directory
Write-Host "[1/4] Creating install directory..." -ForegroundColor Cyan
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "   ✅ Created: $InstallPath" -ForegroundColor Green
}

# Download latest release
Write-Host "[2/4] Downloading .NET Auto-Instrumentation..." -ForegroundColor Cyan
$downloadUrl = "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/opentelemetry-dotnet-instrumentation-windows.zip"
$zipPath = Join-Path $env:TEMP "otel-dotnet-autoinstr.zip"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "   ✅ Downloaded to: $zipPath" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "[3/4] Extracting..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
    Write-Host "   ✅ Extracted to: $InstallPath" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Verify installation
Write-Host "[4/4] Verifying installation..." -ForegroundColor Cyan
$profilerPath = Join-Path $InstallPath "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
$startupHookPath = Join-Path $InstallPath "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"

$verified = $true
if (-not (Test-Path $profilerPath)) {
    Write-Host "   ❌ Profiler DLL not found: $profilerPath" -ForegroundColor Red
    $verified = $false
}
if (-not (Test-Path $startupHookPath)) {
    Write-Host "   ❌ Startup Hook DLL not found: $startupHookPath" -ForegroundColor Red
    $verified = $false
}

if ($verified) {
    Write-Host "   ✅ Installation verified" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Installation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Run: .\scripts\gate026\run-dotnet-app-instrumented.ps1" -ForegroundColor White
    Write-Host "   2. Test: curl http://localhost:5555/test" -ForegroundColor White
    Write-Host "   3. Verify spans in SigNoz: http://localhost:8080" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Installation verification failed" -ForegroundColor Red
    exit 1
}

