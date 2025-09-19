# GPU Metrics Emitter for SigNoz Integration
# PowerShell wrapper for gpu-metrics-emitter.py

param(
    [string]$OtlpEndpoint = "http://localhost:4317",
    [int]$Duration = 300,
    [int]$Interval = 15,
    [switch]$Background,
    [switch]$NoFile
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
}

function Test-GPUAvailability {
    try {
        $gpuInfo = nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
        Write-Log "GPU Status: $gpuInfo" "INFO"
        return $true
    }
    catch {
        Write-Log "GPU not available: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PythonEnvironment {
    try {
        $pythonVersion = python --version
        Write-Log "Python version: $pythonVersion" "INFO"
        
        $deps = python -c "import pynvml, opentelemetry.sdk; print('Dependencies OK')"
        Write-Log "Dependencies: $deps" "INFO"
        return $true
    }
    catch {
        Write-Log "Python/dependencies not available: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-GPUMetricsEmission {
    param(
        [string]$Endpoint,
        [int]$Duration,
        [int]$Interval,
        [bool]$Background,
        [bool]$NoFile
    )
    
    Write-Log "Starting GPU metrics emission..." "INFO"
    Write-Log "OTLP endpoint: $Endpoint" "INFO"
    Write-Log "Duration: $Duration seconds" "INFO"
    Write-Log "Interval: $Interval seconds" "INFO"
    
    $pythonScript = Join-Path $PSScriptRoot "gpu-metrics-simple.py"
    if (-not (Test-Path $pythonScript)) {
        throw "Python script not found: $pythonScript"
    }
    
    # Build command arguments
    $args = @(
        "--endpoint", $Endpoint,
        "--duration", $Duration,
        "--interval", $Interval
    )
    
    if ($NoFile) {
        $args += "--no-file"
    }
    
    try {
        if ($Background) {
            Write-Log "Starting GPU metrics in background..." "INFO"
            Start-Process -FilePath "python" -ArgumentList $pythonScript, $args -WindowStyle Hidden
            Write-Log "GPU metrics started in background process" "INFO"
            return $true
        } else {
            Write-Log "Executing GPU metrics emission..." "INFO"
            & python $pythonScript @args
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Log "GPU metrics emission completed successfully" "INFO"
                return $true
            } else {
                Write-Log "GPU metrics emission failed with exit code $exitCode" "ERROR"
                return $false
            }
        }
    }
    catch {
        Write-Log "Failed to run GPU metrics: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Stop-GPUMetricsProcesses {
    Write-Log "Stopping any running GPU metrics processes..." "INFO"
    try {
        Get-Process | Where-Object { $_.ProcessName -eq "python" -and $_.CommandLine -like "*gpu-metrics-emitter*" } | Stop-Process -Force
        Write-Log "GPU metrics processes stopped" "INFO"
    }
    catch {
        Write-Log "No GPU metrics processes found or error stopping: $($_.Exception.Message)" "INFO"
    }
}

# Main execution
try {
    Write-Log "=== GPU Metrics Emitter for SigNoz ===" "INFO"
    
    # Check prerequisites
    if (-not (Test-GPUAvailability)) {
        throw "GPU not available"
    }
    
    if (-not (Test-PythonEnvironment)) {
        throw "Python environment not properly configured"
    }
    
    # Stop any existing processes if not running in background
    if (-not $Background) {
        Stop-GPUMetricsProcesses
    }
    
    # Run metrics emission
    $success = Start-GPUMetricsEmission -Endpoint $OtlpEndpoint -Duration $Duration -Interval $Interval -Background $Background -NoFile $NoFile
    
    if ($success) {
        if ($Background) {
            Write-Log "GPU metrics emission started in background!" "INFO"
            Write-Log "Use 'Get-Process | Where-Object {`$_.ProcessName -eq \"python\"}' to check status" "INFO"
        } else {
            Write-Log "GPU metrics emission completed successfully!" "INFO"
        }
        exit 0
    } else {
        Write-Log "GPU metrics emission failed!" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}
