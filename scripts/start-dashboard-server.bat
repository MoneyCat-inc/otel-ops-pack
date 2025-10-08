@echo off
REM Batch script to start a local web server for the dashboard hub
REM This avoids CORS issues when accessing SigNoz APIs from file:// protocol

set PORT=3000
set MODULE=http.server
set TARGET_DIR=C:\otel
REM Adjust TARGET_DIR to your repository root if different

echo.
echo =====================================
echo 🐾 BossCat OEM - Dashboard Web Server
echo =====================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Python not found. Please install Python 3.x
    echo    Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "docs\dashboards\index.html" (
    echo ❌ Dashboard files not found. Please run from the repo root directory.
    echo    Current directory: %CD%
    echo    Expected files: docs\dashboards\index.html
    pause
    exit /b 1
)

echo ✅ Python found
echo.
echo 🚀 Starting web server on port %PORT%...
echo.
echo 📊 Dashboard Hub will be available at:
echo    http://localhost:%PORT%/docs/dashboards/
echo.
echo 🔧 Prerequisites:
echo    • SigNoz running on localhost:8080
echo    • OTel Collector on localhost:5318
echo.
echo ⏹️  Press Ctrl+C to stop the server
echo.

REM Navigate to the target directory
cd /d %TARGET_DIR%

REM Start the Python web server
python -m %MODULE% %PORT%

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Failed to start Python web server. Make sure Python is installed and in your PATH.
    pause
)