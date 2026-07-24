# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Gate #029: .NET Service Deployment Orchestrator
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Idempotent service deployment with lifecycle management

<#
.SYNOPSIS
    Deploy and manage a .NET service with health checks and lifecycle control.

.DESCRIPTION
    Orchestrates deployment with:
    - Pre-flight checks (paths, ports, dependencies)
    - Process lifecycle (start → health → monitor → stop)
    - Bounded retries with exponential backoff
    - Structured logging with JSON output
    - Exit codes: 0 (GREEN), 1 (AMBER), 2 (RED)

.PARAMETER ServiceName
    Name of the service to deploy (used in logs and process tracking)

.PARAMETER Port
    Port number the service will listen on

.PARAMETER BinaryPath
    Path to the .NET application DLL or EXE

.PARAMETER HealthUrl
    URL to check for service health (e.g., http://localhost:5556/health)

.PARAMETER StartTimeout
    Seconds to wait for service startup (default: 30)

.PARAMETER HealthRetries
    Number of health check attempts (default: 10)

.PARAMETER StopOnly
    If set, only stops the service (doesn't start)

.PARAMETER EnableOTel
    If set, configures OpenTelemetry instrumentation pointing to Collector (5317)

.EXAMPLE
    .\deploy-dotnet-service.ps1 -ServiceName "svc2-api" -Port 5556 -BinaryPath ".\svc2\svc2.dll" -HealthUrl "http://localhost:5556/health" -EnableOTel
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [int]$Port,
    
    [Parameter(Mandatory=$false)]
    [string]$BinaryPath,
    
    [Parameter(Mandatory=$false)]
    [string]$HealthUrl,
    
    [Parameter(Mandatory=$false)]
    [int]$StartTimeout = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$HealthRetries = 10,
    
    [Parameter(Mandatory=$false)]
    [switch]$StopOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableOTel
)

$ErrorActionPreference = "Stop"

# Structured logging
function Write-StructuredLog {
    param(
        [string]$Level,
        [string]$Message,
        [hashtable]$Data = @{}
    )
    
    $logEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        level = $Level
        service_name = $ServiceName
        message = $Message
    }
    
    # Merge additional data
    foreach ($key in $Data.Keys) {
        $logEntry[$key] = $Data[$key]
    }
    
    $json = $logEntry | ConvertTo-Json -Compress
    Write-Host $json
}

# Exit with structured status
function Exit-WithStatus {
    param(
        [int]$Code,
        [string]$Status,
        [string]$Message
    )
    
    Write-StructuredLog -Level "INFO" -Message "Deployment $Status" -Data @{
        exit_code = $Code
        status = $Status
        final_message = $Message
    }
    
    exit $Code
}

# Check if port is in use
function Test-PortAvailable {
    param([int]$PortNumber)
    
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $PortNumber)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        Write-StructuredLog -Level "WARN" -Message "Port $PortNumber is in use" -Data @{
            port = $PortNumber
            error = $_.Exception.Message
        }
        
        # Try to find which process is using the port
        $netstat = netstat -ano | Select-String ":$PortNumber" | Select-Object -First 1
        if ($netstat) {
            $processId = ($netstat -split '\s+')[-1]
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            if ($process) {
                Write-StructuredLog -Level "INFO" -Message "Port held by process" -Data @{
                    port = $PortNumber
                    process_id = $processId
                    process_name = $process.ProcessName
                }
            }
        }
        
        return $false
    }
}

# Stop existing service instance
function Stop-ServiceInstance {
    Write-StructuredLog -Level "INFO" -Message "Stopping existing instances of $ServiceName"
    
    # Find processes by port
    $netstat = netstat -ano | Select-String ":$Port\s" | Select-String "LISTENING"
    if ($netstat) {
        foreach ($line in $netstat) {
            $processId = ($line -split '\s+')[-1]
            if ($processId -match '^\d+$') {
                try {
                    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                    if ($process) {
                        Write-StructuredLog -Level "INFO" -Message "Stopping process" -Data @{
                            process_id = $processId
                            process_name = $process.ProcessName
                        }
                        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                    }
                } catch {
                    Write-StructuredLog -Level "WARN" -Message "Could not stop process" -Data @{
                        process_id = $processId
                        error = $_.Exception.Message
                    }
                }
            }
        }
    }
    
    # Wait for port to be released
    $attempts = 0
    while ((-not (Test-PortAvailable -PortNumber $Port)) -and ($attempts -lt 10)) {
        Write-StructuredLog -Level "INFO" -Message "Waiting for port to be released" -Data @{
            port = $Port
            attempt = $attempts + 1
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
}

# Health check with retries
function Test-ServiceHealth {
    param(
        [string]$Url,
        [int]$Retries = 10,
        [int]$DelaySeconds = 2
    )
    
    Write-StructuredLog -Level "INFO" -Message "Starting health checks" -Data @{
        url = $Url
        max_retries = $Retries
    }
    
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-StructuredLog -Level "INFO" -Message "Health check passed" -Data @{
                    attempt = $i + 1
                    status_code = $response.StatusCode
                    response_time_ms = $response.RawContentLength
                }
                return $true
            }
        } catch {
            $backoff = [Math]::Min(2 * [Math]::Pow(1.5, $i), 10)
            Write-StructuredLog -Level "WARN" -Message "Health check failed, retrying" -Data @{
                attempt = $i + 1
                error = $_.Exception.Message
                backoff_seconds = $backoff
            }
            Start-Sleep -Seconds $backoff
        }
    }
    
    Write-StructuredLog -Level "ERROR" -Message "Health checks exhausted" -Data @{
        url = $Url
        total_attempts = $Retries
    }
    return $false
}

# Main execution
Write-StructuredLog -Level "INFO" -Message "Deployment orchestrator starting" -Data @{
    service = $ServiceName
    port = $Port
    binary = $BinaryPath
    health_url = $HealthUrl
    mode = if ($StopOnly) { "STOP" } else { "DEPLOY" }
}

# Stop mode
if ($StopOnly) {
    Stop-ServiceInstance
    Exit-WithStatus -Code 0 -Status "GREEN" -Message "Service stopped successfully"
}

# Deployment mode - Pre-flight checks
Write-StructuredLog -Level "INFO" -Message "Running pre-flight checks"

# Check binary exists
if (-not (Test-Path $BinaryPath)) {
    Exit-WithStatus -Code 2 -Status "RED" -Message "Binary not found: $BinaryPath"
}

# Check port availability
Stop-ServiceInstance
if (-not (Test-PortAvailable -PortNumber $Port)) {
    Exit-WithStatus -Code 2 -Status "RED" -Message "Port $Port still in use after cleanup attempts"
}

# Start service
Write-StructuredLog -Level "INFO" -Message "Starting service" -Data @{
    binary = $BinaryPath
    port = $Port
    otel_enabled = $EnableOTel
}

try {
    # Configure OTel environment variables if enabled
    $env:OTEL_DOTNET_AUTO_HOME = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation"
    
    if ($EnableOTel) {
        # Gate #029: Route through Windows Collector on port 5317
        $env:OTEL_SERVICE_NAME = $ServiceName
        $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:5317"
        $env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
        $env:OTEL_TRACES_EXPORTER = "otlp"
        $env:OTEL_METRICS_EXPORTER = "otlp"
        $env:OTEL_LOGS_EXPORTER = "otlp"
        $env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=local,team=bosscat,gate=029"
        $env:CORECLR_ENABLE_PROFILING = "1"
        $env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
        $env:CORECLR_PROFILER_PATH = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
        $env:DOTNET_STARTUP_HOOKS = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"
        $env:DOTNET_ADDITIONAL_DEPS = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\AdditionalDeps"
        $env:DOTNET_SHARED_STORE = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\store"
        
        Write-StructuredLog -Level "INFO" -Message "OTel instrumentation configured" -Data @{
            endpoint = "http://127.0.0.1:5317"
            service_name = $ServiceName
        }
    }
    
    $processInfo = Start-Process -FilePath "dotnet" -ArgumentList $BinaryPath,"--urls","http://localhost:$Port" -PassThru -WindowStyle Hidden
    
    Write-StructuredLog -Level "INFO" -Message "Service process started" -Data @{
        pid = $processInfo.Id
        start_time = $processInfo.StartTime
    }
    
    # Wait for startup
    Start-Sleep -Seconds 3
    
    # Verify process is still running
    $process = Get-Process -Id $processInfo.Id -ErrorAction SilentlyContinue
    if (-not $process) {
        Exit-WithStatus -Code 2 -Status "RED" -Message "Service process exited immediately after start"
    }
    
    # Health check
    if ($HealthUrl) {
        $healthy = Test-ServiceHealth -Url $HealthUrl -Retries $HealthRetries
        if (-not $healthy) {
            Stop-Process -Id $processInfo.Id -Force -ErrorAction SilentlyContinue
            Exit-WithStatus -Code 1 -Status "AMBER" -Message "Service started but health checks failed"
        }
    }
    
    Write-StructuredLog -Level "INFO" -Message "Service deployed successfully" -Data @{
        pid = $processInfo.Id
        port = $Port
        health_status = "PASS"
    }
    
    # Write process ID file for later management
    $processIdFile = "artifacts\gate029\$ServiceName.pid"
    New-Item -ItemType Directory -Path "artifacts\gate029" -Force | Out-Null
    $processInfo.Id | Out-File -FilePath $processIdFile -Encoding UTF8
    
    Exit-WithStatus -Code 0 -Status "GREEN" -Message "Deployment complete, service healthy"
    
} catch {
    Write-StructuredLog -Level "ERROR" -Message "Deployment failed" -Data @{
        error = $_.Exception.Message
        stack_trace = $_.ScriptStackTrace
    }
    Exit-WithStatus -Code 2 -Status "RED" -Message "Deployment failed: $($_.Exception.Message)"
}

