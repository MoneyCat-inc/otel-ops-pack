@echo off
REM Batch script to start a local web server for the dashboard hub
REM This avoids CORS issues when accessing SigNoz APIs from file:// protocol

echo.
echo 🐾 BossCat OEM - Dashboard Web Server
echo =====================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found. Please install Python 3.x
    echo    Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python found
echo.

REM Check if we're in the right directory
if not exist "docs\dashboards\index.html" (
    echo ❌ Dashboard files not found. Please run from the repo root directory.
    echo    Current directory: %CD%
    echo    Expected files: docs\dashboards\index.html
    pause
    exit /b 1
)

echo 🚀 Starting web server on port 3000...
echo.
echo 📊 Dashboard Hub will be available at:
echo    http://localhost:3000/docs/dashboards/
echo.
echo 🔧 Prerequisites:
echo    • SigNoz running on localhost:8080
echo    • OTel Collector on localhost:5318
echo.
echo ⏹️  Press Ctrl+C to stop the server
echo.

REM Start the Python HTTP server
python -m http.server 3000

pause
