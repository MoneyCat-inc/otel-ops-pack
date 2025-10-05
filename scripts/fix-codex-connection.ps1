# Fix Codex Connection Issues
# Cat Nap Control Room - Low-Latency Observability Pipeline

Write-Host "🐾 Fixing Codex Connection Issues" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check GPU memory usage
Write-Host "`n🔍 Checking GPU memory..." -ForegroundColor Yellow
$GPUInfo = nvidia-smi --query-gpu=memory.total,memory.used --format=csv,noheader,nounits
$GPUData = $GPUInfo.Split(',')
$TotalVRAM = [int]$GPUData[0].Trim()
$UsedVRAM = [int]$GPUData[1].Trim()
$AvailableVRAM = $TotalVRAM - $UsedVRAM

Write-Host "Total VRAM: ${TotalVRAM}MB" -ForegroundColor White
Write-Host "Used VRAM: ${UsedVRAM}MB" -ForegroundColor White
Write-Host "Available VRAM: ${AvailableVRAM}MB" -ForegroundColor White

if ($AvailableVRAM -lt 2000) {
    Write-Host "⚠️  Low VRAM available (${AvailableVRAM}MB). Consider closing other applications." -ForegroundColor Yellow
    Write-Host "   Close Discord, ChatGPT, or other GPU-intensive applications" -ForegroundColor Yellow
}

# Check Ollama service
Write-Host "`n🌐 Checking Ollama service..." -ForegroundColor Yellow
try {
    $OllamaExe = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"
    if (Test-Path $OllamaExe) {
        Write-Host "✅ Ollama executable found" -ForegroundColor Green
        
        # Test if service is responding
        try {
            $Response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
            Write-Host "✅ Ollama service is responding" -ForegroundColor Green
        } catch {
            Write-Host "❌ Ollama service not responding" -ForegroundColor Red
            Write-Host "   Starting Ollama service..." -ForegroundColor Yellow
            Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden
            Start-Sleep -Seconds 3
        }
    } else {
        Write-Host "❌ Ollama not found. Please install first." -ForegroundColor Red
        return
    }
} catch {
    Write-Host "❌ Error checking Ollama: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Codex configuration
Write-Host "`n🧪 Testing Codex configuration..." -ForegroundColor Yellow
try {
    # Test with a simple command
    $TestResult = & $OllamaExe run codellama:7b "Hello, test connection" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Codex GPU models working" -ForegroundColor Green
    } else {
        Write-Host "❌ Codex GPU models not working" -ForegroundColor Red
        Write-Host "Error: $TestResult" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error testing Codex: $($_.Exception.Message)" -ForegroundColor Red
}

# Restart Cursor/VS Code recommendations
Write-Host "`n🔄 Connection Fix Recommendations" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "1. **Restart Cursor completely** (close all windows and restart)" -ForegroundColor White
Write-Host "2. **Clear Cursor cache** if the issue persists" -ForegroundColor White
Write-Host "3. **Use cloud model temporarily** if GPU is too busy:" -ForegroundColor White
Write-Host "   codex -m gpt-5-codex" -ForegroundColor Green
Write-Host "4. **Use GPU when available**:" -ForegroundColor White
Write-Host "   codex --profile codellama-7b-gpu" -ForegroundColor Green

# Quick test commands
Write-Host "`n🎯 Quick Test Commands" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "# Test cloud model (should work)" -ForegroundColor Gray
Write-Host "codex -m gpt-5-codex 'test connection'" -ForegroundColor Green
Write-Host ""
Write-Host "# Test GPU model (if VRAM available)" -ForegroundColor Gray
Write-Host "codex --profile codellama-7b-gpu 'test connection'" -ForegroundColor Green

Write-Host "`n💡 If connection issues persist:" -ForegroundColor Yellow
Write-Host "1. Restart Cursor completely" -ForegroundColor White
Write-Host "2. Check if antivirus is blocking connections" -ForegroundColor White
Write-Host "3. Try running Cursor as administrator" -ForegroundColor White
Write-Host "4. Use cloud model until GPU memory is freed up" -ForegroundColor White

Write-Host "`n🎉 Connection fix complete!" -ForegroundColor Green
