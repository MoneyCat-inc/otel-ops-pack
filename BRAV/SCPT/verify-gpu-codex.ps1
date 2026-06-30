param(
    [switch]$TestModels,
    [switch]$Benchmark
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-DirectoryIfMissing {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $root '..')
Set-Location $repoRoot

$outDir = Join-Path $repoRoot 'artifacts/gpu_diag'
New-DirectoryIfMissing $outDir
$stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')

Write-Host "Verifying Triton and GPU sidecars..." -ForegroundColor Cyan

# Triton model metadata
try {
    $modelMeta = Invoke-RestMethod -Method GET -Uri 'http://localhost:8000/v2/models/simple_identity' -TimeoutSec 5
    $modelMeta | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir "triton_model_meta_$stamp.json") -Encoding utf8
    Write-Host "Saved triton model metadata" -ForegroundColor Green
} catch { $_ | Out-String | Set-Content -Path (Join-Path $outDir "triton_model_meta_error_$stamp.txt") -Encoding utf8 }

# Triton readiness
try {
    $ready = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8000/v2/health/ready' -TimeoutSec 5
    $ready.Content | Set-Content -Path (Join-Path $outDir "triton_ready_$stamp.txt") -Encoding utf8
    Write-Host "Saved triton readiness" -ForegroundColor Green
} catch { $_ | Out-String | Set-Content -Path (Join-Path $outDir "triton_ready_error_$stamp.txt") -Encoding utf8 }

# Sample inference (identity)
try {
    $inferBody = @{ inputs = @(@{ name = 'INPUT_0'; datatype = 'FP32'; shape = @(1,4); data = @(1.0,2.0,3.0,4.0) }); outputs = @(@{ name = 'OUTPUT_0' }) } | ConvertTo-Json -Depth 6
    $resp = Invoke-RestMethod -Method POST -Uri 'http://localhost:8000/v2/models/simple_identity/versions/1/infer' -ContentType 'application/json' -Body $inferBody -TimeoutSec 10
    $resp | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir "triton_infer_$stamp.json") -Encoding utf8
    Write-Host "Saved triton inference response" -ForegroundColor Green
} catch { $_ | Out-String | Set-Content -Path (Join-Path $outDir "triton_infer_error_$stamp.txt") -Encoding utf8 }

# Inference sidecar health
try {
    $health = Invoke-RestMethod -Method GET -Uri 'http://localhost:8003/health' -TimeoutSec 5
    $health | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir "sidecar_health_$stamp.json") -Encoding utf8
    Write-Host "Saved sidecar health" -ForegroundColor Green
} catch { $_ | Out-String | Set-Content -Path (Join-Path $outDir "sidecar_health_error_$stamp.txt") -Encoding utf8 }

# Inference sidecar deep health (if available)
try {
    $deep = Invoke-RestMethod -Method GET -Uri 'http://localhost:8003/health/deep' -TimeoutSec 5
    $deep | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $outDir "sidecar_health_deep_$stamp.json") -Encoding utf8
    Write-Host "Saved sidecar deep health" -ForegroundColor Green
} catch { $_ | Out-String | Set-Content -Path (Join-Path $outDir "sidecar_health_deep_error_$stamp.txt") -Encoding utf8 }

Write-Host "GPU verification artifacts saved to $outDir" -ForegroundColor Cyan
# Codex GPU Configuration Verification Script
# Cat Nap Control Room - Low-Latency Observability Pipeline

Write-Host "🐾 Codex GPU Configuration Verification" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$Issues = @()
$Warnings = @()
$Success = @()

# Check GPU availability
Write-Host "`n🔍 Checking GPU setup..." -ForegroundColor Yellow
try {
    $GPUInfo = nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader,nounits
    if ($LASTEXITCODE -eq 0) {
        $GPUData = $GPUInfo.Split(',')
        $GPUNamed = $GPUData[0].Trim()
        $TotalVRAM = [int]$GPUData[1].Trim()
        $UsedVRAM = [int]$GPUData[2].Trim()
        $AvailableVRAM = $TotalVRAM - $UsedVRAM
        
        Write-Host "✅ GPU: $GPUNamed" -ForegroundColor Green
        Write-Host "✅ Total VRAM: ${TotalVRAM}MB" -ForegroundColor Green
        Write-Host "✅ Available VRAM: ${AvailableVRAM}MB" -ForegroundColor Green
        
        if ($AvailableVRAM -lt 4000) {
            $Warnings += "Low VRAM availability (${AvailableVRAM}MB). Consider closing other GPU applications."
            Write-Host "⚠️  Low VRAM availability" -ForegroundColor Yellow
        } else {
            $Success += "GPU has sufficient VRAM for 7B models"
        }
    } else {
        $Issues += "NVIDIA GPU not detected"
        Write-Host "❌ NVIDIA GPU not detected" -ForegroundColor Red
    }
} catch {
    $Issues += "Could not detect GPU: $($_.Exception.Message)"
    Write-Host "❌ GPU detection failed" -ForegroundColor Red
}

# Check Ollama installation
Write-Host "`n🔧 Checking Ollama installation..." -ForegroundColor Yellow
try {
    $OllamaVersion = ollama --version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ollama installed: $OllamaVersion" -ForegroundColor Green
        $Success += "Ollama is properly installed"
    } else {
        $Issues += "Ollama not found in PATH"
        Write-Host "❌ Ollama not found" -ForegroundColor Red
    }
} catch {
    $Issues += "Ollama not installed or not in PATH"
    Write-Host "❌ Ollama not found in PATH" -ForegroundColor Red
}

# Check Ollama service
Write-Host "`n🌐 Checking Ollama service..." -ForegroundColor Yellow
try {
    $ServiceResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    if ($ServiceResponse) {
        Write-Host "✅ Ollama service is running" -ForegroundColor Green
        $Success += "Ollama service is accessible"
    }
} catch {
    $Warnings += "Ollama service not running. Start with: ollama serve"
    Write-Host "⚠️  Ollama service not running" -ForegroundColor Yellow
}

# Check installed models
Write-Host "`n📦 Checking installed models..." -ForegroundColor Yellow
try {
    $Models = ollama list
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Installed models:" -ForegroundColor Green
        $ModelList = $Models | ForEach-Object { $_.Split()[0] }
        
        $RecommendedModels = @("codellama:7b", "qwen2.5:7b", "deepseek-coder:6.7b")
        $InstalledRecommended = @()
        
        foreach ($Model in $ModelList) {
            Write-Host "   • $Model" -ForegroundColor White
            if ($RecommendedModels -contains $Model) {
                $InstalledRecommended += $Model
                $Success += "Recommended model $Model is installed"
            }
        }
        
        if ($InstalledRecommended.Count -eq 0) {
            $Warnings += "No recommended models installed. Run: pwsh -File scripts\install-ollama-gpu.ps1"
            Write-Host "⚠️  No recommended models found" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Found $($InstalledRecommended.Count) recommended models" -ForegroundColor Green
        }
    } else {
        $Issues += "Could not list Ollama models"
        Write-Host "❌ Could not list models" -ForegroundColor Red
    }
} catch {
    $Issues += "Error checking models: $($_.Exception.Message)"
    Write-Host "❌ Error checking models" -ForegroundColor Red
}

# Check Codex configuration
Write-Host "`n📄 Checking Codex configuration..." -ForegroundColor Yellow
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"
if (Test-Path $ConfigPath) {
    $ConfigContent = Get-Content $ConfigPath -Raw
    
    # Check for GPU providers
    if ($ConfigContent -match '\[model_providers\.ollama\]') {
        Write-Host "✅ Ollama provider configured" -ForegroundColor Green
        $Success += "Ollama model provider is configured"
    } else {
        $Issues += "Ollama provider not configured"
        Write-Host "❌ Ollama provider not found" -ForegroundColor Red
    }
    
    # Check for GPU profiles
    $GPUProfiles = @("codellama-7b-gpu", "qwen-7b-gpu", "deepseek-coder-gpu")
    $ConfiguredProfiles = @()
    
    foreach ($Profile in $GPUProfiles) {
        if ($ConfigContent -match "\[profiles\.$Profile\]") {
            $ConfiguredProfiles += $Profile
            Write-Host "✅ Profile $Profile configured" -ForegroundColor Green
        }
    }
    
    if ($ConfiguredProfiles.Count -gt 0) {
        $Success += "$($ConfiguredProfiles.Count) GPU profiles configured"
    } else {
        $Issues += "No GPU profiles configured"
        Write-Host "❌ No GPU profiles found" -ForegroundColor Red
    }
} else {
    $Issues += "Codex configuration file not found"
    Write-Host "❌ Codex config not found" -ForegroundColor Red
}

# Test model loading (if requested)
if ($TestModels) {
    Write-Host "`n🧪 Testing model loading..." -ForegroundColor Yellow
    
    if ($InstalledRecommended.Count -gt 0) {
        $TestModel = $InstalledRecommended[0]
        Write-Host "Testing model: $TestModel" -ForegroundColor White
        
        try {
            $TestPrompt = "Write a simple Python function to add two numbers."
            $StartTime = Get-Date
            
            # Run a quick test (limit output to avoid long waits)
            $TestResult = ollama run $TestModel $TestPrompt --verbose 2>&1
            
            $EndTime = Get-Date
            $Duration = ($EndTime - $StartTime).TotalSeconds
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Model test successful (${Duration}s)" -ForegroundColor Green
                $Success += "Model loading test passed"
            } else {
                Write-Host "❌ Model test failed" -ForegroundColor Red
                $Issues += "Model loading test failed"
            }
        } catch {
            Write-Host "❌ Model test error: $($_.Exception.Message)" -ForegroundColor Red
            $Issues += "Model test error: $($_.Exception.Message)"
        }
    } else {
        Write-Host "⚠️  No models available for testing" -ForegroundColor Yellow
    }
}

# Benchmark GPU performance (if requested)
if ($Benchmark) {
    Write-Host "`n⚡ Running GPU benchmark..." -ForegroundColor Yellow
    
    if ($InstalledRecommended.Count -gt 0) {
        $BenchmarkModel = $InstalledRecommended[0]
        Write-Host "Benchmarking model: $BenchmarkModel" -ForegroundColor White
        
        $BenchmarkPrompts = @(
            "Write a Python function to calculate fibonacci numbers.",
            "Create a JavaScript class for a simple calculator.",
            "Write a PowerShell script to list all files in a directory."
        )
        
        $TotalTime = 0
        $SuccessCount = 0
        
        foreach ($Prompt in $BenchmarkPrompts) {
            try {
                $StartTime = Get-Date
                $Result = ollama run $BenchmarkModel $Prompt --verbose 2>&1
                $EndTime = Get-Date
                $Duration = ($EndTime - $StartTime).TotalSeconds
                $TotalTime += $Duration
                
                if ($LASTEXITCODE -eq 0) {
                    $SuccessCount++
                    Write-Host "   ✅ Prompt completed in ${Duration}s" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ Prompt failed" -ForegroundColor Red
                }
            } catch {
                Write-Host "   ❌ Prompt error" -ForegroundColor Red
            }
        }
        
        if ($SuccessCount -gt 0) {
            $AvgTime = $TotalTime / $SuccessCount
            Write-Host "✅ Benchmark completed: $SuccessCount/$($BenchmarkPrompts.Count) successful" -ForegroundColor Green
            Write-Host "   Average response time: ${AvgTime}s" -ForegroundColor White
            $Success += "GPU benchmark completed successfully"
        } else {
            $Issues += "GPU benchmark failed"
        }
    } else {
        Write-Host "⚠️  No models available for benchmarking" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📋 Verification Summary" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($Success.Count -gt 0) {
    Write-Host "✅ Successes:" -ForegroundColor Green
    foreach ($Item in $Success) {
        Write-Host "   • $Item" -ForegroundColor Green
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($Warning in $Warnings) {
        Write-Host "   • $Warning" -ForegroundColor Yellow
    }
}

if ($Issues.Count -gt 0) {
    Write-Host "`n❌ Issues:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host "   • $Issue" -ForegroundColor Red
    }
}

# Usage instructions
Write-Host "`n🎯 Usage Instructions" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

if ($Issues.Count -eq 0) {
    Write-Host "✅ GPU setup is ready!" -ForegroundColor Green
    Write-Host "To use Codex with GPU:" -ForegroundColor White
    Write-Host "1. Start Ollama: ollama serve" -ForegroundColor White
    Write-Host "2. Run Codex: codex --profile codellama-7b-gpu" -ForegroundColor White
    Write-Host "3. Monitor GPU: nvidia-smi" -ForegroundColor White
} else {
    Write-Host "❌ Setup incomplete. Please resolve issues above." -ForegroundColor Red
    Write-Host "Run: pwsh -File scripts\install-ollama-gpu.ps1" -ForegroundColor Yellow
}

# ECRR Report
Write-Host "`n📝 ECRR Report Generated" -ForegroundColor Cyan
$ReportPath = "C:\otel\artifacts\gpu-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Report = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    gpu_info = @{
        name = $GPUNamed
        total_vram = $TotalVRAM
        available_vram = $AvailableVRAM
    }
    ollama_status = ($OllamaVersion -ne $null)
    models_installed = $InstalledRecommended.Count
    config_valid = ($Issues.Count -eq 0)
    issues = $Issues
    warnings = $Warnings
    successes = $Success
}

$Report | ConvertTo-Json -Depth 3 | Out-File $ReportPath -Encoding UTF8
Write-Host "Report saved to: $ReportPath" -ForegroundColor Green

if ($Issues.Count -eq 0) {
    Write-Host "`n🎉 GPU setup verification complete!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ GPU setup needs attention" -ForegroundColor Red
    exit 1
}
