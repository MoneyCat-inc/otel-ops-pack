# Setup Ollama Models for RTX 2080 SUPER
# Cat Nap Control Room - Low-Latency Observability Pipeline

$OllamaExe = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"

Write-Host "🐾 Setting up Ollama Models for RTX 2080 SUPER" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if Ollama is installed
if (-not (Test-Path $OllamaExe)) {
    Write-Host "❌ Ollama not found at: $OllamaExe" -ForegroundColor Red
    Write-Host "Please install Ollama first: pwsh -File scripts\install-ollama-winget.ps1" -ForegroundColor Yellow
    return
}

Write-Host "✅ Ollama found: $OllamaExe" -ForegroundColor Green

# Start Ollama service in background
Write-Host "`n🚀 Starting Ollama service..." -ForegroundColor Yellow
try {
    Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden
    Write-Host "✅ Ollama service started" -ForegroundColor Green
    Start-Sleep -Seconds 3
} catch {
    Write-Host "⚠️  Could not start Ollama service: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Download models optimized for RTX 2080 SUPER (8GB VRAM)
Write-Host "`n📦 Downloading coding models for RTX 2080 SUPER..." -ForegroundColor Yellow

$Models = @(
    @{Name="codellama:7b"; Description="Code Llama 7B - Fast coding model"},
    @{Name="qwen2.5:7b"; Description="Qwen 2.5 7B - Excellent coding performance"},
    @{Name="deepseek-coder:6.7b"; Description="DeepSeek Coder 6.7B - Specialized coding model"}
)

foreach ($Model in $Models) {
    Write-Host "`n📥 Downloading $($Model.Name)..." -ForegroundColor Yellow
    Write-Host "   $($Model.Description)" -ForegroundColor Gray
    
    try {
        & $OllamaExe pull $Model.Name
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $($Model.Name) downloaded successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to download $($Model.Name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error downloading $($Model.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# List installed models
Write-Host "`n📋 Installed models:" -ForegroundColor Yellow
try {
    & $OllamaExe list
} catch {
    Write-Host "❌ Could not list models: $($_.Exception.Message)" -ForegroundColor Red
}

# Test a model
Write-Host "`n🧪 Testing model..." -ForegroundColor Yellow
try {
    $TestPrompt = "Write a simple Python function to add two numbers."
    Write-Host "Testing with: $TestPrompt" -ForegroundColor Gray
    
    $TestResult = & $OllamaExe run codellama:7b $TestPrompt
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Model test successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Model test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Model test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Verify Codex configuration
Write-Host "`n🔧 Verifying Codex configuration..." -ForegroundColor Yellow
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"
if (Test-Path $ConfigPath) {
    $ConfigContent = Get-Content $ConfigPath -Raw
    
    if ($ConfigContent -match '\[model_providers\.ollama\]') {
        Write-Host "✅ Ollama provider configured" -ForegroundColor Green
    } else {
        Write-Host "❌ Ollama provider not configured" -ForegroundColor Red
    }
    
    if ($ConfigContent -match '\[profiles\.codellama-7b-gpu\]') {
        Write-Host "✅ GPU profiles configured" -ForegroundColor Green
    } else {
        Write-Host "❌ GPU profiles not configured" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Codex config not found" -ForegroundColor Red
}

# Usage instructions
Write-Host "`n🎯 Ready to Use!" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "To use Codex with your RTX 2080 SUPER:" -ForegroundColor White
Write-Host "1. Start Ollama: ollama serve" -ForegroundColor White
Write-Host "2. Use Codex with GPU profiles:" -ForegroundColor White
Write-Host "   codex --profile codellama-7b-gpu" -ForegroundColor Green
Write-Host "   codex --profile qwen-7b-gpu" -ForegroundColor Green
Write-Host "   codex --profile deepseek-coder-gpu" -ForegroundColor Green

Write-Host "`n📊 Monitor GPU usage: nvidia-smi" -ForegroundColor White

Write-Host "`n🎉 Setup complete! Your RTX 2080 SUPER is ready for local GPU coding." -ForegroundColor Green
