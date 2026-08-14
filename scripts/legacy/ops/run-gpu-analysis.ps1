# GPU-Accelerated Voice Analysis Runner
# Wrapper script for running GPU-accelerated ML tasks

param(
    [string]$AudioDir = "C:\logs\audio_samples",
    [string]$OutputDir = "C:\otel\.agent\reports",
    [switch]$TestMode
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
        Write-Log "GPU not available: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Test-PythonEnvironment {
    try {
        $pythonVersion = python --version
        Write-Log "Python version: $pythonVersion" "INFO"
        
        $torchInfo = python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
        Write-Log "PyTorch info: $torchInfo" "INFO"
        return $true
    }
    catch {
        Write-Log "Python/PyTorch not available: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-GPUAnalysis {
    param([string]$AudioDirectory, [string]$OutputDirectory)
    
    Write-Log "Starting GPU-accelerated voice analysis..." "INFO"
    Write-Log "Audio directory: $AudioDirectory" "INFO"
    Write-Log "Output directory: $OutputDirectory" "INFO"
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        Write-Log "Created output directory: $OutputDirectory" "INFO"
    }
    
    # Run the Python analysis
    $pythonScript = Join-Path $PSScriptRoot "gpu-voice-analysis.py"
    if (-not (Test-Path $pythonScript)) {
        throw "Python script not found: $pythonScript"
    }
    
    try {
        $startTime = Get-Date
        Write-Log "Executing GPU analysis..." "INFO"
        
        # Set environment variables for GPU optimization
        $env:CUDA_VISIBLE_DEVICES = "0"
        $env:PYTORCH_CUDA_ALLOC_CONF = "max_split_size_mb:512"
        
        # Run the analysis
        $output = python $pythonScript 2>&1
        $exitCode = $LASTEXITCODE
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($exitCode -eq 0) {
            Write-Log "GPU analysis completed successfully in $([math]::Round($duration, 2)) seconds" "INFO"
            Write-Log "Output: $output" "INFO"
        } else {
            Write-Log "GPU analysis failed with exit code $exitCode" "ERROR"
            Write-Log "Error output: $output" "ERROR"
        }
        
        return $exitCode -eq 0
    }
    catch {
        Write-Log "Failed to run GPU analysis: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "=== GPU Voice Analysis Runner ===" "INFO"
    
    # Check prerequisites
    if (-not (Test-GPUAvailability)) {
        Write-Log "GPU not available, but continuing with CPU fallback..." "WARN"
    }
    
    if (-not (Test-PythonEnvironment)) {
        throw "Python environment not properly configured"
    }
    
    # Run analysis
    $success = Start-GPUAnalysis -AudioDirectory $AudioDir -OutputDirectory $OutputDir
    
    if ($success) {
        Write-Log "GPU analysis completed successfully!" "INFO"
        
        # Check for results
        $resultsFile = Join-Path $OutputDir "voice_analysis_results.json"
        if (Test-Path $resultsFile) {
            $results = Get-Content $resultsFile | ConvertFrom-Json
            Write-Log "Analysis results: $($results.Count) files processed" "INFO"
        }
        
        exit 0
    } else {
        Write-Log "GPU analysis failed!" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}

