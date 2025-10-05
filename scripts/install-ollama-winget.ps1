# Ollama Installation via Windows Package Manager (winget)
# Cat Nap Control Room - Low-Latency Observability Pipeline

Write-Host "🐾 Installing Ollama via Windows Package Manager" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if winget is available
Write-Host "`n🔍 Checking Windows Package Manager..." -ForegroundColor Yellow
try {
    $WingetVersion = winget --version
    Write-Host "✅ Winget available: $WingetVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Windows Package Manager (winget) not available" -ForegroundColor Red
    Write-Host "💡 Try running: pwsh -File scripts\install-ollama-manual.ps1" -ForegroundColor Yellow
    return
}

# Install Ollama via winget
Write-Host "`n📦 Installing Ollama via winget..." -ForegroundColor Yellow
try {
    winget install --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ollama installed successfully via winget" -ForegroundColor Green
    } else {
        Write-Host "❌ Winget installation failed" -ForegroundColor Red
        Write-Host "💡 Try manual installation: pwsh -File scripts\install-ollama-manual.ps1" -ForegroundColor Yellow
        return
    }
} catch {
    Write-Host "❌ Winget installation error: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Wait for installation
Write-Host "`n⏳ Waiting for installation to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test Ollama installation
Write-Host "`n🧪 Testing Ollama installation..." -ForegroundColor Yellow
try {
    $Version = ollama --version
    Write-Host "✅ Ollama installed: $Version" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Ollama not found in PATH. Try restarting your terminal." -ForegroundColor Yellow
    Write-Host "💡 Or run: refreshenv" -ForegroundColor Yellow
}

# Download models for RTX 2080 SUPER
Write-Host "`n📦 Downloading models for RTX 2080 SUPER..." -ForegroundColor Yellow

$Models = @(
    @{Name="codellama:7b"; Description="Code Llama 7B - Fast coding model"},
    @{Name="qwen2.5:7b"; Description="Qwen 2.5 7B - Excellent coding performance"},
    @{Name="deepseek-coder:6.7b"; Description="DeepSeek Coder 6.7B - Specialized coding model"}
)

foreach ($Model in $Models) {
    Write-Host "`n📥 Downloading $($Model.Name)..." -ForegroundColor Yellow
    try {
        ollama pull $Model.Name
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $($Model.Name) downloaded successfully" -ForegroundColor Green
            Write-Host "   $($Model.Description)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Failed to download $($Model.Name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error downloading $($Model.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎯 Next Steps" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "1. Restart your terminal" -ForegroundColor White
Write-Host "2. Start Ollama: ollama serve" -ForegroundColor White
Write-Host "3. Use Codex: codex --profile codellama-7b-gpu" -ForegroundColor White

Write-Host "`n🎉 Winget installation complete!" -ForegroundColor Green
