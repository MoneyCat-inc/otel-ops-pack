# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Gate #029: .NET Service Deployment Orchestrator
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Robust, reusable deployment automation for .NET services with OTel instrumentation

param(
    [Parameter(Mandatory=$true)]
    [string]$SpecPath,              # Path to service spec JSON
    
    [switch]$Stop,                  # Stop mode: gracefully shutdown service
    [switch]$Force                  # Force kill if graceful fails
)

$ErrorActionPreference = "Stop"
$global:ServicePID = $null
$global:ServiceName = ""

# Evidence logging
function Ecrr-Log {
    param([string]$Phase, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $logEntry = "[$timestamp] [Gate029-$Phase] $Message"
    Write-Host $logEntry -ForegroundColor Cyan
    Add-Content -Path ".agent/EVIDENCE.log" -Value $logEntry -ErrorAction SilentlyContinue
}

# Preflight checks
function Preflight-Or-Exit {
    Ecrr-Log "preflight" "Starting preflight checks"
    
    # Check if .NET runtime available
    try {
        $dotnetVersion = dotnet --version
        Ecrr-Log "preflight" ".NET runtime: $dotnetVersion"
    } catch {
        Write-Host "❌ .NET runtime not found" -ForegroundColor Red
        exit 20  # RED
    }
    
    # Check if OTel auto-instrumentation installed
    $otelHome = "C:\otel\dotnet-autoinstrumentation"
    if (-not (Test-Path $otelHome)) {
        Write-Host "❌ OTel auto-instrumentation not found at: $otelHome" -ForegroundColor Red
        exit 20  # RED
    }
    
    Ecrr-Log "preflight" "OTel instrumentation: $otelHome"
    Ecrr-Log "preflight" "Preflight checks passed ✅"
}

# Ensure binaries exist
function Ensure-Binaries {
    param($Spec)
    
    Ecrr-Log "binaries" "Checking application binary: $($Spec.appPath)"
    
    $fullPath = Join-Path $PSScriptRoot "..\..\$($Spec.appPath)"
    if (-not (Test-Path $fullPath)) {
        Write-Host "❌ Application binary not found: $fullPath" -ForegroundColor Red
        Write-Host "   Building application..." -ForegroundColor Yellow
        
        $projectDir = Split-Path (Split-Path $fullPath -Parent) -Parent
        Push-Location $projectDir
        try {
            dotnet build -c Debug
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed"
            }
        } finally {
            Pop-Location
        }
    }
    
    if (-not (Test-Path $fullPath)) {
        Write-Host "❌ Binary still not found after build" -ForegroundColor Red
        exit 20  # RED
    }
    
    Ecrr-Log "binaries" "Binary verified ✅: $fullPath"
}

# Check port availability
function Ensure-Port-Free {
    param([int]$Port)
    
    Ecrr-Log "port" "Checking port availability: $Port"
    
    $listener = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($listener) {
        Write-Host "❌ Port $Port already in use" -ForegroundColor Red
        Write-Host "   PID: $($listener.OwningProcess)" -ForegroundColor Yellow
        exit 10  # AMBER - port conflict
    }
    
    Ecrr-Log "port" "Port $Port available ✅"
}

# Start service process
function Start-ServiceProcess {
    param($Spec)
    
    Ecrr-Log "start" "Starting service: $($Spec.name)"
    
    # OTel auto-instrumentation environment
    $otelHome = "C:\otel\dotnet-autoinstrumentation"
    $env:CORECLR_ENABLE_PROFILING = "1"
    $env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    $env:CORECLR_PROFILER_PATH = Join-Path $otelHome "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
    $env:DOTNET_STARTUP_HOOKS = Join-Path $otelHome "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"
    $env:OTEL_DOTNET_AUTO_HOME = $otelHome
    $env:DOTNET_ADDITIONAL_DEPS = Join-Path $otelHome "AdditionalDeps"
    $env:DOTNET_SHARED_STORE = Join-Path $otelHome "store"
    
    # Service identity
    $env:OTEL_SERVICE_NAME = $Spec.otelServiceName
    $env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=gate029,service.version=1.0.0,team=bosscat"
    
    # Exporters
    $env:OTEL_TRACES_EXPORTER = "otlp"
    $env:OTEL_METRICS_EXPORTER = "otlp"
    $env:OTEL_LOGS_EXPORTER = "otlp"
    
    # Endpoint (5317 via Windows Collector OR 4317 direct to SigNoz)
    if ($Spec.useCollector) {
        $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:5317"
        Ecrr-Log "start" "OTLP endpoint: 5317 (via Windows Collector)"
    } else {
        $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317"
        Ecrr-Log "start" "OTLP endpoint: 4317 (direct to SigNoz)"
    }
    $env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
    
    # Instrumentation
    $env:OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_METRICS_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_LOGS_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_TRACES_ASPNETCORE_INSTRUMENTATION_ENABLED = "true"
    $env:OTEL_DOTNET_AUTO_TRACES_HTTPCLIENT_INSTRUMENTATION_ENABLED = "true"
    
    # App port
    $env:ASPNETCORE_URLS = "http://localhost:$($Spec.port)"
    
    # Start process
    $appPath = Join-Path $PSScriptRoot "..\..\$($Spec.appPath)"
    $process = Start-Process -FilePath "dotnet" -ArgumentList "exec `"$appPath`"" -NoNewWindow -PassThru
    
    $global:ServicePID = $process.Id
    $global:ServiceName = $Spec.name
    
    Ecrr-Log "start" "Service started: PID=$($process.Id), Port=$($Spec.port)"
    
    return $process
}

# Wait for health check
function Wait-Healthy {
    param(
        [string]$Url,
        [int]$TimeoutSec = 30,
        [int]$Retries = 3
    )
    
    Ecrr-Log "health" "Waiting for health check: $Url"
    
    $attempt = 0
    $maxAttempts = $Retries
    $delaySec = 3
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        Start-Sleep -Seconds $delaySec
        
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Ecrr-Log "health" "Health check passed ✅ (attempt $attempt/$maxAttempts)"
                return $true
            }
        } catch {
            Ecrr-Log "health" "Health check attempt $attempt/$maxAttempts failed: $($_.Exception.Message)"
        }
        
        # Exponential backoff
        $delaySec = [Math]::Min($delaySec * 2, 10)
    }
    
    Write-Host "❌ Health check failed after $maxAttempts attempts" -ForegroundColor Red
    return $false
}

# Stop service process
function Stop-ServiceProcess {
    param([int]$ProcessId, [switch]$Force)
    
    if (-not $ProcessId) {
        Write-Host "⚠️  No PID to stop" -ForegroundColor Yellow
        return
    }
    
    Ecrr-Log "stop" "Stopping service: PID=$ProcessId"
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        
        if (-not $Force) {
            # Graceful shutdown
            $process.CloseMainWindow() | Out-Null
            $process.WaitForExit(10000)  # 10 second timeout
        }
        
        if (-not $process.HasExited) {
            Ecrr-Log "stop" "Force killing process: PID=$ProcessId"
            Stop-Process -Id $ProcessId -Force
        }
        
        Ecrr-Log "stop" "Service stopped ✅"
    } catch {
        Ecrr-Log "stop" "Process not found or already stopped: PID=$ProcessId"
    }
}

# Main execution
Write-Host "=== Gate #029: Service Deployment Orchestrator ===" -ForegroundColor Cyan
Write-Host ""

# Load spec
if (-not (Test-Path $SpecPath)) {
    Write-Host "❌ Spec file not found: $SpecPath" -ForegroundColor Red
    exit 20  # RED
}

$spec = Get-Content $SpecPath | ConvertFrom-Json
Ecrr-Log "plan" "Loaded spec: $($spec.name)"

# Stop mode
if ($Stop) {
    Write-Host "🛑 Stop mode activated" -ForegroundColor Yellow
    # TODO: Implement PID tracking/storage for stop mode
    Write-Host "⚠️  Manual stop: Find PID and run: Stop-Process -Id <PID>" -ForegroundColor Yellow
    exit 0
}

# Deployment mode
try {
    Preflight-Or-Exit
    Ensure-Binaries $spec
    Ensure-Port-Free $spec.port
    
    $process = Start-ServiceProcess $spec
    
    $healthy = Wait-Healthy -Url $spec.healthUrl -TimeoutSec 30 -Retries 3
    
    if (-not $healthy) {
        Write-Host "❌ Service failed health check" -ForegroundColor Red
        Stop-ServiceProcess -ProcessId $global:ServicePID -Force
        exit 20  # RED
    }
    
    Write-Host ""
    Write-Host "✅ Service deployed successfully" -ForegroundColor Green
    Write-Host "   Name: $($spec.name)" -ForegroundColor White
    Write-Host "   PID: $($global:ServicePID)" -ForegroundColor White
    Write-Host "   Port: $($spec.port)" -ForegroundColor White
    Write-Host "   Health: $($spec.healthUrl)" -ForegroundColor White
    Write-Host "   OTel: $(if ($spec.useCollector) { '5317 (collector)' } else { '4317 (direct)' })" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Service running in background. Press Ctrl+C to stop or manually kill PID." -ForegroundColor Yellow
    
    Ecrr-Log "complete" "Deployment successful: $($spec.name) PID=$($global:ServicePID)"
    
    # Keep script alive to maintain process (for manual testing)
    # In production, this would return and let process run as background service
    Write-Host "Press any key to stop service and exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Stop-ServiceProcess -ProcessId $global:ServicePID
    
    exit 0  # GREEN
    
} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Ecrr-Log "error" "Deployment failed: $($_.Exception.Message)"
    
    if ($global:ServicePID) {
        Stop-ServiceProcess -ProcessId $global:ServicePID -Force
    }
    
    exit 20  # RED
}

