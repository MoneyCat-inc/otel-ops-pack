# PowerShell script to start a local web server for the dashboard hub
# This avoids CORS issues when accessing SigNoz APIs from file:// protocol

param(
    [int]$Port = 3000,
    [string]$Path = "."
)

Write-Host "🐾 BossCat OEM - Dashboard Web Server" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
Write-Host ""

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found. Please install Python 3.x" -ForegroundColor Red
    Write-Host "   Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Check if we're in the right directory
if (-not (Test-Path "docs/dashboards/index.html")) {
    Write-Host "❌ Dashboard files not found. Please run from the repo root directory." -ForegroundColor Red
    Write-Host "   Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "   Expected files: docs/dashboards/index.html" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Starting web server on port $Port..." -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Dashboard Hub will be available at:" -ForegroundColor Yellow
Write-Host "   http://localhost:$Port/docs/dashboards/" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Prerequisites:" -ForegroundColor Yellow
Write-Host "   • SigNoz running on localhost:8080" -ForegroundColor White
Write-Host "   • OTel Collector on localhost:5321" -ForegroundColor White
Write-Host ""
Write-Host "⏹️  Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

# Start the Python HTTP server
try {
    python -m http.server $Port
} catch {
    Write-Host "❌ Failed to start web server: $_" -ForegroundColor Red
    exit 1
}