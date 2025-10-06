# Manual Ollama Installation Script - More Reliable Approach
# Cat Nap Control Room - Low-Latency Observability Pipeline

param(
    [switch]$SkipDownload,
    [switch]$ForceReinstall
)

Write-Host "🐾 Manual Ollama Installation for RTX 2080 SUPER" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Kill any stuck Ollama processes
Write-Host "`n🔧 Cleaning up any stuck processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*ollama*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Check if Ollama is already installed
$OllamaPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama"
if (Test-Path $OllamaPath) {
    if ($ForceReinstall) {
        Write-Host "🔄 Force reinstalling Ollama..." -ForegroundColor Yellow
        Remove-Item $OllamaPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "✅ Ollama already installed at: $OllamaPath" -ForegroundColor Green
        Write-Host "Use -ForceReinstall to reinstall" -ForegroundColor Yellow
    }
}

# Download Ollama manually with better error handling
if (-not $SkipDownload) {
    Write-Host "`n📥 Downloading Ollama installer..." -ForegroundColor Yellow
    
    $OllamaUrl = "https://ollama.ai/download/windows"
    $DownloadPath = "$env:TEMP\ollama-windows-installer.exe"
    
    try {
        # Remove any existing download
        if (Test-Path $DownloadPath) {
            Remove-Item $DownloadPath -Force
        }
        
        Write-Host "Downloading from: $OllamaUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $OllamaUrl -OutFile $DownloadPath -UseBasicParsing -TimeoutSec 60
        
        if (Test-Path $DownloadPath) {
            $FileSize = (Get-Item $DownloadPath).Length
            Write-Host "✅ Downloaded: $DownloadPath ($([math]::Round($FileSize/1MB, 2)) MB)" -ForegroundColor Green
        } else {
            throw "Download failed - file not found"
        }
    } catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "🔗 Please download manually from: https://ollama.ai/download/windows" -ForegroundColor Yellow
        Write-Host "Then run: pwsh -File scripts\install-ollama-manual.ps1 -SkipDownload" -ForegroundColor Yellow
        return
    }
}

# Install Ollama with manual approach
Write-Host "`n🔧 Installing Ollama..." -ForegroundColor Yellow

if (-not (Test-Path $DownloadPath)) {
    Write-Host "❌ Installer not found at: $DownloadPath" -ForegroundColor Red
    return
}

try {
    Write-Host "Running installer with silent mode..." -ForegroundColor Gray
    
    # Try silent installation first
    $InstallProcess = Start-Process -FilePath $DownloadPath -ArgumentList "/S" -PassThru -Wait -NoNewWindow
    
    if ($InstallProcess.ExitCode -eq 0) {
        Write-Host "✅ Ollama installed successfully (silent mode)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Silent installation failed, trying interactive..." -ForegroundColor Yellow
        
        # Try interactive installation
        $InstallProcess = Start-Process -FilePath $DownloadPath -Wait -NoNewWindow
        
        if ($InstallProcess.ExitCode -eq 0) {
            Write-Host "✅ Ollama installed successfully (interactive mode)" -ForegroundColor Green
        } else {
            Write-Host "❌ Installation failed with exit code: $($InstallProcess.ExitCode)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Installation error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Try running the installer manually: $DownloadPath" -ForegroundColor Yellow
}

# Clean up installer
if (Test-Path $DownloadPath) {
    Remove-Item $DownloadPath -Force -ErrorAction SilentlyContinue
    Write-Host "🧹 Cleaned up installer file" -ForegroundColor Gray
}

# Wait for installation to complete
Write-Host "`n⏳ Waiting for installation to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Add Ollama to PATH if needed
Write-Host "`n🔍 Checking Ollama installation..." -ForegroundColor Yellow

$OllamaExe = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"
if (Test-Path $OllamaExe) {
    Write-Host "✅ Ollama executable found: $OllamaExe" -ForegroundColor Green
    
    # Test if it's in PATH
    try {
        $Version = & $OllamaExe --version
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Ollama working: $Version" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Ollama found but not working properly" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Ollama found but not in PATH" -ForegroundColor Yellow
        Write-Host "💡 You may need to restart your terminal or add to PATH manually" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Ollama installation not found" -ForegroundColor Red
    Write-Host "💡 Try manual installation from: https://ollama.ai/download/windows" -ForegroundColor Yellow
    return
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
        & $OllamaExe pull $Model.Name
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

# Test Ollama service
Write-Host "`n🧪 Testing Ollama service..." -ForegroundColor Yellow
try {
    # Start service in background
    Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden
    
    # Wait for service to start
    Start-Sleep -Seconds 3
    
    # Test API
    $TestResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Ollama service is running and accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Ollama service test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "💡 You may need to start it manually: ollama serve" -ForegroundColor Yellow
}

# Usage instructions
Write-Host "`n🎯 Next Steps" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "1. Restart your terminal to ensure Ollama is in PATH" -ForegroundColor White
Write-Host "2. Start Ollama service: ollama serve" -ForegroundColor White
Write-Host "3. Test with: ollama list" -ForegroundColor White
Write-Host "4. Use Codex with GPU: codex --profile codellama-7b-gpu" -ForegroundColor White

Write-Host "`n🎉 Installation complete!" -ForegroundColor Green
Write-Host "Your RTX 2080 SUPER is ready for local GPU coding models." -ForegroundColor Green
