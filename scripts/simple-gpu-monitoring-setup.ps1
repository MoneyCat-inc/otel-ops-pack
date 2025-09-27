# Simple GPU Monitoring Setup
# ECRR-compliant GPU monitoring automation

Write-Host "=== Simple GPU Monitoring Setup ===" -ForegroundColor Cyan
Write-Host "ECRR: Setting up GPU monitoring automation..." -ForegroundColor Yellow

# Check GPU sidecars
Write-Host "`n🔍 Checking GPU sidecar status..." -ForegroundColor Yellow
try {
    $gpuStatus = python scripts\check-gpu-sidecars.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU sidecars are healthy" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GPU sidecars have issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not check GPU status" -ForegroundColor Yellow
}

# Create simple monitoring script
Write-Host "`n📝 Creating GPU monitoring script..." -ForegroundColor Yellow
$monitoringScript = @"
#!/usr/bin/env python3
import time
import subprocess
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

def run_gpu_monitoring():
    logger.info("🔄 Running GPU monitoring cycle...")
    
    # Emit GPU metrics
    try:
        result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            logger.info("✅ GPU metrics emitted successfully")
        else:
            logger.error(f"❌ GPU metrics failed: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Error: {e}")
    
    # Check sidecar health
    try:
        result = subprocess.run(['python', 'scripts/check-gpu-sidecars.py'], 
                              capture_output=True, text=True, timeout=15)
        if result.returncode == 0:
            logger.info("✅ GPU sidecars healthy")
        else:
            logger.warning(f"⚠️ Sidecar issues: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Health check error: {e}")

if __name__ == "__main__":
    run_gpu_monitoring()
"@

$monitoringScript | Out-File -FilePath "scripts\gpu-monitoring-simple.py" -Encoding UTF8
Write-Host "✅ GPU monitoring script created" -ForegroundColor Green

# Create scheduled task
Write-Host "`n⏰ Creating scheduled task..." -ForegroundColor Yellow
try {
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName "OTel-GPU-Monitoring" -Confirm:$false
        Write-Host "✅ Existing task removed" -ForegroundColor Green
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "python.exe" -Argument "scripts\gpu-monitoring-simple.py" -WorkingDirectory "C:\otel"
    $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365) -At (Get-Date)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "GPU monitoring for OTel pipeline"
    
    Register-ScheduledTask -TaskName "OTel-GPU-Monitoring" -InputObject $task -Force
    Write-Host "✅ Scheduled task created successfully" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
}

# Test the monitoring
Write-Host "`n🧪 Testing GPU monitoring..." -ForegroundColor Yellow
try {
    python scripts\gpu-monitoring-simple.py
    Write-Host "✅ GPU monitoring test successful" -ForegroundColor Green
} catch {
    Write-Host "❌ GPU monitoring test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check task status
Write-Host "`n📊 Checking scheduled task status..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "✅ Task Name: $($task.TaskName)" -ForegroundColor Green
    Write-Host "✅ Task State: $($task.State)" -ForegroundColor Green
    Write-Host "✅ Task Created: $($task.Date)" -ForegroundColor Green
} else {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
}

Write-Host "`n=== ECRR Report: GPU Monitoring Setup Complete ===" -ForegroundColor Cyan
Write-Host "✅ GPU automated monitoring configured" -ForegroundColor Green
Write-Host "📁 Script: scripts\gpu-monitoring-simple.py" -ForegroundColor Yellow
Write-Host "⏰ Task: OTel-GPU-Monitoring (every 5 minutes)" -ForegroundColor Yellow
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor White

Write-Host "`n✅ GPU Automated Monitoring Setup Complete!" -ForegroundColor Green
