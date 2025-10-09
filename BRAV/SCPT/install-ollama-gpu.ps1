# Ollama GPU Installation Script for OTel Observability Kit
# Cat Nap Control Room - Low-Latency Observability Pipeline

param(
    [switch]$SkipDownload,
    [switch]$SkipModels
)

Write-Host "🐾 Installing Ollama for Local GPU Coding" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check GPU availability
Write-Host "`n🔍 Checking GPU setup..." -ForegroundColor Yellow
try {
    $GPUInfo = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ NVIDIA GPU detected: $GPUInfo" -ForegroundColor Green
    } else {
        Write-Host "❌ NVIDIA GPU not detected. Ollama will use CPU." -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️  Could not detect GPU. Ollama will use CPU." -ForegroundColor Yellow
}

# Download and install Ollama
if (-not $SkipDownload) {
    Write-Host "`n📥 Downloading Ollama..." -ForegroundColor Yellow
    $OllamaUrl = "https://ollama.ai/download/windows"
    $DownloadPath = "$env:TEMP\ollama-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $OllamaUrl -OutFile $DownloadPath -UseBasicParsing
        Write-Host "✅ Ollama installer downloaded" -ForegroundColor Green
        
        Write-Host "`n🔧 Installing Ollama..." -ForegroundColor Yellow
        Start-Process -FilePath $DownloadPath -ArgumentList "/S" -Wait
        Write-Host "✅ Ollama installed successfully" -ForegroundColor Green
        
        # Clean up installer
        Remove-Item $DownloadPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "❌ Failed to download Ollama: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please download manually from: https://ollama.ai/download/windows" -ForegroundColor Yellow
        return
    }
}

# Wait for Ollama service to start
Write-Host "`n⏳ Waiting for Ollama service to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test Ollama installation
Write-Host "`n🧪 Testing Ollama installation..." -ForegroundColor Yellow
try {
    $Version = ollama --version
    Write-Host "✅ Ollama installed: $Version" -ForegroundColor Green
} catch {
    Write-Host "❌ Ollama not found in PATH. Please restart your terminal or add Ollama to PATH." -ForegroundColor Red
    return
}

# Download coding models optimized for RTX 2080 (8GB VRAM)
if (-not $SkipModels) {
    Write-Host "`n📦 Downloading coding models for RTX 2080 (8GB VRAM)..." -ForegroundColor Yellow
    
    # Models optimized for 8GB VRAM
    $Models = @(
        @{Name="codellama:7b"; Description="Code Llama 7B - Fast coding model"},
        @{Name="qwen2.5:7b"; Description="Qwen 2.5 7B - Excellent coding performance"},
        @{Name="deepseek-coder:6.7b"; Description="DeepSeek Coder 6.7B - Specialized coding model"}
    )
    
    foreach ($Model in $Models) {
        Write-Host "`n📥 Downloading $($Model.Name)..." -ForegroundColor Yellow
        try {
            ollama pull $Model.Name
            Write-Host "✅ $($Model.Name) downloaded successfully" -ForegroundColor Green
            Write-Host "   $($Model.Description)" -ForegroundColor Gray
        } catch {
            Write-Host "❌ Failed to download $($Model.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Update Codex configuration with optimal models for RTX 2080
Write-Host "`n🔧 Updating Codex configuration for RTX 2080..." -ForegroundColor Yellow
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

# Create optimized profiles for RTX 2080
$OptimizedProfiles = @'

# RTX 2080 Optimized Profiles (8GB VRAM)
[profiles.codellama-7b-gpu]
model_provider = "ollama"
model = "codellama:7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"

[profiles.qwen-7b-gpu]
model_provider = "ollama"
model = "qwen2.5:7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"

[profiles.deepseek-coder-gpu]
model_provider = "ollama"
model = "deepseek-coder:6.7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"
'@

# Append optimized profiles to config
Add-Content -Path $ConfigPath -Value $OptimizedProfiles
Write-Host "✅ Codex configuration updated with RTX 2080 optimized profiles" -ForegroundColor Green

# Test model loading
Write-Host "`n🧪 Testing model loading..." -ForegroundColor Yellow
try {
    $TestResult = ollama run codellama:7b "Hello, can you help me with coding?" --verbose
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Model loading test successful" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Model loading test had issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not test model loading: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Usage instructions
Write-Host "`n🎯 Usage Instructions" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "To use Codex with local GPU models:" -ForegroundColor White
Write-Host "1. Start Ollama service: ollama serve" -ForegroundColor White
Write-Host "2. Run Codex with GPU profile:" -ForegroundColor White
Write-Host "   codex --profile codellama-7b-gpu" -ForegroundColor Green
Write-Host "   codex --profile qwen-7b-gpu" -ForegroundColor Green
Write-Host "   codex --profile deepseek-coder-gpu" -ForegroundColor Green
Write-Host "3. Or use in VS Code/Cursor with the profile setting" -ForegroundColor White

Write-Host "`n📊 GPU Memory Usage" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Monitor GPU usage with: nvidia-smi" -ForegroundColor White
Write-Host "Models are optimized for 8GB VRAM on RTX 2080" -ForegroundColor White

Write-Host "`n🎉 Ollama GPU setup complete!" -ForegroundColor Green
Write-Host "Your RTX 2080 is ready for local coding model inference." -ForegroundColor Green
