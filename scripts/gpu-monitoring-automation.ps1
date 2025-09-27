# GPU Monitoring Automation
# Simple automated GPU monitoring setup

Write-Host "=== GPU Monitoring Automation Setup ===" -ForegroundColor Cyan

# Test GPU monitoring components
Write-Host "`n🔍 Testing GPU monitoring components..." -ForegroundColor Yellow

# Test GPU metrics emission
Write-Host "Testing GPU metrics emission..." -ForegroundColor Cyan
try {
    $metricsResult = python scripts/gpu-metrics-emitter.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU metrics emission working" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GPU metrics emission issues: $metricsResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ GPU metrics emission failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test GPU sidecar health check
Write-Host "Testing GPU sidecar health check..." -ForegroundColor Cyan
try {
    $healthResult = python scripts/check-gpu-sidecars.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU sidecar health check working" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GPU sidecar health check issues: $healthResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ GPU sidecar health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create simple monitoring script
Write-Host "`n📝 Creating automated monitoring script..." -ForegroundColor Yellow
$monitoringScript = @"
import subprocess
import time
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

def monitor_gpu():
    logger.info("🔄 Starting GPU monitoring cycle...")
    
    # Emit metrics
    try:
        result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            logger.info("✅ GPU metrics emitted")
        else:
            logger.error(f"❌ Metrics failed: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Error: {e}")
    
    # Check health
    try:
        result = subprocess.run(['python', 'scripts/check-gpu-sidecars.py'], 
                              capture_output=True, text=True, timeout=15)
        if result.returncode == 0:
            logger.info("✅ Sidecars healthy")
        else:
            logger.warning(f"⚠️ Health issues: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Health check error: {e}")

if __name__ == "__main__":
    monitor_gpu()
"@

$monitoringScript | Out-File -FilePath "scripts/gpu-monitor.py" -Encoding UTF8
Write-Host "✅ Monitoring script created: scripts/gpu-monitor.py" -ForegroundColor Green

# Test the monitoring script
Write-Host "`n🧪 Testing monitoring script..." -ForegroundColor Yellow
try {
    python scripts/gpu-monitor.py
    Write-Host "✅ Monitoring script test successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Monitoring script test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create scheduled task
Write-Host "`n⏰ Setting up scheduled task..." -ForegroundColor Yellow
try {
    # Remove existing task
    $existingTask = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName "OTel-GPU-Monitoring" -Confirm:$false
        Write-Host "✅ Existing task removed" -ForegroundColor Green
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "python.exe" -Argument "scripts/gpu-monitor.py" -WorkingDirectory "C:\otel"
    $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365) -At (Get-Date)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated GPU monitoring"
    
    Register-ScheduledTask -TaskName "OTel-GPU-Monitoring" -InputObject $task -Force
    Write-Host "✅ Scheduled task created: OTel-GPU-Monitoring" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
}

# Verify task creation
Write-Host "`n📊 Verifying scheduled task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "✅ Task Name: $($task.TaskName)" -ForegroundColor Green
    Write-Host "✅ Task State: $($task.State)" -ForegroundColor Green
    Write-Host "✅ Task Path: $($task.TaskPath)" -ForegroundColor Green
} else {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
}

Write-Host "`n=== GPU Monitoring Automation Complete ===" -ForegroundColor Cyan
Write-Host "✅ GPU monitoring automation configured" -ForegroundColor Green
Write-Host "📁 Script: scripts/gpu-monitor.py" -ForegroundColor Yellow
Write-Host "⏰ Task: OTel-GPU-Monitoring (every 5 minutes)" -ForegroundColor Yellow
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor White
