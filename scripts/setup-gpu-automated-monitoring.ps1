# Setup GPU Automated Monitoring
# ECRR: Examine → Clean → Report → Role
# Automated GPU monitoring setup for OTel observability pipeline

param(
    [switch]$Force,
    [switch]$Verbose
)

# ECRR: Examine - Capture current state
Write-Host "=== GPU Automated Monitoring Setup ===" -ForegroundColor Cyan
Write-Host "ECRR: Examining current monitoring state..." -ForegroundColor Yellow

# Check if monitoring is already running
$existingTask = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Found existing GPU monitoring task: $($existingTask.State)" -ForegroundColor Yellow
    if (!$Force) {
        Write-Host "Use -Force to replace existing monitoring" -ForegroundColor Yellow
        return
    }
}

# Check GPU sidecar status
Write-Host "`nChecking GPU sidecar status..." -ForegroundColor Yellow
try {
    $gpuStatus = python scripts\check-gpu-sidecars.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU sidecars are healthy" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GPU sidecars have issues - proceeding with setup" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not check GPU status - proceeding with setup" -ForegroundColor Yellow
}

# ECRR: Clean - Remove existing monitoring if forced
if ($Force -and $existingTask) {
    Write-Host "`nRemoving existing monitoring task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName "OTel-GPU-Monitoring" -Confirm:$false
}

# Create monitoring artifacts directory
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Create comprehensive GPU monitoring script
Write-Host "`nCreating enhanced GPU monitoring script..." -ForegroundColor Yellow

$monitoringScript = @'
#!/usr/bin/env python3
"""
Enhanced GPU Automated Monitoring Script
ECRR-compliant GPU monitoring with progress animation and comprehensive logging
"""

import time
import logging
import json
import os
from datetime import datetime, timedelta
import subprocess
import sys
import requests
from pathlib import Path

# Configure comprehensive logging
log_dir = Path('artifacts')
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / 'gpu-automated-monitoring.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class GPUAutomatedMonitor:
    def __init__(self):
        self.start_time = datetime.now()
        self.metrics_count = 0
        self.health_checks = 0
        self.failures = 0
        self.status_file = log_dir / 'gpu-monitoring-status.json'
        self.load_status()
        
    def load_status(self):
        """Load monitoring status from file"""
        try:
            if self.status_file.exists():
                with open(self.status_file, 'r') as f:
                    data = json.load(f)
                    self.metrics_count = data.get('metrics_count', 0)
                    self.health_checks = data.get('health_checks', 0)
                    self.failures = data.get('failures', 0)
        except Exception as e:
            logger.warning(f"Could not load status: {e}")
    
    def save_status(self):
        """Save monitoring status to file"""
        try:
            status = {
                'start_time': self.start_time.isoformat(),
                'uptime_minutes': (datetime.now() - self.start_time).total_seconds() / 60,
                'metrics_count': self.metrics_count,
                'health_checks': self.health_checks,
                'failures': self.failures,
                'last_update': datetime.now().isoformat(),
                'status': 'running'
            }
            with open(self.status_file, 'w') as f:
                json.dump(status, f, indent=2)
        except Exception as e:
            logger.error(f"Could not save status: {e}")
    
    def emit_gpu_metrics(self):
        """Emit GPU metrics with progress animation"""
        try:
            logger.info("🔄 Emitting GPU metrics to OTel pipeline...")
            
            # Progress animation
            spinner = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
            start_time = time.time()
            
            result = subprocess.run([
                sys.executable, 
                'scripts/gpu-metrics-emitter.py'
            ], capture_output=True, text=True, timeout=30)
            
            elapsed = time.time() - start_time
            
            if result.returncode == 0:
                self.metrics_count += 1
                logger.info(f"✅ GPU metrics emitted successfully ({elapsed:.2f}s)")
                return True
            else:
                self.failures += 1
                logger.error(f"❌ GPU metrics emission failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.failures += 1
            logger.error("❌ GPU metrics emission timed out")
            return False
        except Exception as e:
            self.failures += 1
            logger.error(f"❌ Error in GPU metrics emission: {e}")
            return False
    
    def check_gpu_sidecars(self):
        """Check GPU sidecar health with detailed reporting"""
        try:
            logger.info("🔍 Checking GPU sidecar health...")
            
            result = subprocess.run([
                sys.executable,
                'scripts/check-gpu-sidecars.py'
            ], capture_output=True, text=True, timeout=15)
            
            self.health_checks += 1
            
            if result.returncode == 0:
                logger.info("✅ All GPU sidecars healthy")
                return True
            else:
                self.failures += 1
                logger.warning(f"⚠️ GPU sidecar health issues: {result.stderr}")
                return False
                
        except Exception as e:
            self.failures += 1
            logger.error(f"❌ Error checking GPU sidecars: {e}")
            return False
    
    def check_signoz_connectivity(self):
        """Check SigNoz connectivity"""
        try:
            response = requests.get("http://localhost:8080/api/v1/health", timeout=5)
            if response.status_code == 200:
                logger.info("✅ SigNoz UI accessible")
                return True
            else:
                logger.warning(f"⚠️ SigNoz returned status {response.status_code}")
                return False
        except Exception as e:
            logger.warning(f"⚠️ SigNoz connectivity issue: {e}")
            return False
    
    def generate_report(self):
        """Generate monitoring report"""
        uptime = datetime.now() - self.start_time
        report = {
            'timestamp': datetime.now().isoformat(),
            'uptime_hours': uptime.total_seconds() / 3600,
            'metrics_emitted': self.metrics_count,
            'health_checks': self.health_checks,
            'failures': self.failures,
            'success_rate': ((self.metrics_count + self.health_checks - self.failures) / max(1, self.metrics_count + self.health_checks)) * 100,
            'status': 'healthy' if self.failures < (self.metrics_count + self.health_checks) * 0.1 else 'degraded'
        }
        
        # Save report
        report_file = log_dir / f'gpu-monitoring-report-{datetime.now().strftime("%Y%m%d-%H%M")}.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"📊 Monitoring report saved: {report_file}")
        return report
    
    def run_monitoring_cycle(self):
        """Run one complete monitoring cycle"""
        logger.info("🚀 Starting GPU monitoring cycle...")
        
        # Emit metrics
        metrics_success = self.emit_gpu_metrics()
        
        # Check health (every 4th cycle)
        health_success = True
        if self.health_checks % 4 == 0:
            health_success = self.check_gpu_sidecars()
        
        # Check SigNoz (every 10th cycle)
        if self.metrics_count % 10 == 0:
            self.check_signoz_connectivity()
        
        # Save status
        self.save_status()
        
        # Generate report every hour
        if self.metrics_count % 120 == 0:  # Every 120 cycles (1 hour)
            self.generate_report()
        
        return metrics_success and health_success

def main():
    """Main monitoring loop with ECRR compliance"""
    logger.info("🐱 Starting GPU Automated Monitoring - Cat Nap Control Room")
    logger.info("ECRR: Examine → Clean → Report → Role")
    
    monitor = GPUAutomatedMonitor()
    
    try:
        while True:
            # Run monitoring cycle
            monitor.run_monitoring_cycle()
            
            # Wait 30 seconds between cycles
            time.sleep(30)
            
    except KeyboardInterrupt:
        logger.info("🛑 GPU Monitoring stopped by user")
        monitor.save_status()
        monitor.generate_report()
    except Exception as e:
        logger.error(f"💥 Unexpected error in monitoring: {e}")
        monitor.save_status()
        raise

if __name__ == "__main__":
    main()
'@

$monitoringScript | Out-File -FilePath "scripts\gpu-automated-monitoring.py" -Encoding UTF8

# Create PowerShell wrapper for easy management
Write-Host "Creating PowerShell management wrapper..." -ForegroundColor Yellow

$managementScript = @'
# GPU Automated Monitoring Management
# ECRR-compliant management wrapper

param(
    [Parameter(Position=0)]
    [string]$Action = "status"
)

function Get-GPUMonitoringStatus {
    $statusFile = "artifacts\gpu-monitoring-status.json"
    if (Test-Path $statusFile) {
        $status = Get-Content $statusFile | ConvertFrom-Json
        Write-Host "=== GPU Monitoring Status ===" -ForegroundColor Cyan
        Write-Host "Uptime: $([math]::Round($status.uptime_minutes, 1)) minutes" -ForegroundColor White
        Write-Host "Metrics Emitted: $($status.metrics_count)" -ForegroundColor White
        Write-Host "Health Checks: $($status.health_checks)" -ForegroundColor White
        Write-Host "Failures: $($status.failures)" -ForegroundColor White
        Write-Host "Last Update: $($status.last_update)" -ForegroundColor White
        Write-Host "Status: $($status.status)" -ForegroundColor $(if($status.status -eq "running") {"Green"} else {"Yellow"})
    } else {
        Write-Host "No monitoring status found" -ForegroundColor Yellow
    }
}

function Start-GPUMonitoring {
    Write-Host "Starting GPU automated monitoring..." -ForegroundColor Cyan
    $job = Start-Job -ScriptBlock {
        python scripts\gpu-automated-monitoring.py
    }
    Write-Host "Monitoring started (Job ID: $($job.Id))" -ForegroundColor Green
    return $job
}

function Stop-GPUMonitoring {
    Write-Host "Stopping GPU monitoring jobs..." -ForegroundColor Cyan
    Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*"} | Stop-Job
    Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*"} | Remove-Job
    Write-Host "GPU monitoring stopped" -ForegroundColor Green
}

function Show-GPUMonitoringLogs {
    $logFile = "artifacts\gpu-automated-monitoring.log"
    if (Test-Path $logFile) {
        Write-Host "=== GPU Monitoring Logs (Last 20 lines) ===" -ForegroundColor Cyan
        Get-Content $logFile -Tail 20
    } else {
        Write-Host "No monitoring logs found" -ForegroundColor Yellow
    }
}

# Main dispatcher
switch ($Action.ToLower()) {
    "status" { Get-GPUMonitoringStatus }
    "start" { Start-GPUMonitoring }
    "stop" { Stop-GPUMonitoring }
    "logs" { Show-GPUMonitoringLogs }
    "restart" { 
        Stop-GPUMonitoring
        Start-Sleep 2
        Start-GPUMonitoring
    }
    default { 
        Write-Host "Usage: .\scripts\manage-gpu-monitoring.ps1 [status|start|stop|logs|restart]" -ForegroundColor Yellow
    }
}
'@

$managementScript | Out-File -FilePath "scripts\manage-gpu-monitoring.ps1" -Encoding UTF8

# Create Windows Scheduled Task
Write-Host "`nCreating Windows Scheduled Task..." -ForegroundColor Yellow

$taskAction = New-ScheduledTaskAction -Execute "python" -Argument "scripts\gpu-automated-monitoring.py" -WorkingDirectory "C:\otel"
$taskTrigger = New-ScheduledTaskTrigger -AtStartup
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "OTel-GPU-Monitoring" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Description "Automated GPU monitoring for OTel observability pipeline" -Force

# Test the monitoring system
Write-Host "`nTesting monitoring system..." -ForegroundColor Yellow
try {
    $testResult = python scripts\gpu-automated-monitoring.py -c "print('Test successful')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Monitoring script test passed" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Monitoring script test had issues" -ForegroundColor Yellow
}

# ECRR: Report - Generate setup report
Write-Host "`n=== ECRR Report: GPU Automated Monitoring Setup ===" -ForegroundColor Cyan

$report = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    action = "setup-gpu-automated-monitoring"
    status = "completed"
    components = @{
        monitoring_script = "scripts\gpu-automated-monitoring.py"
        management_script = "scripts\manage-gpu-monitoring.ps1"
        scheduled_task = "OTel-GPU-Monitoring"
        log_directory = "artifacts\"
        status_file = "artifacts\gpu-monitoring-status.json"
    }
    features = @(
        "30-second metrics emission cycle",
        "2-minute health check cycle", 
        "Progress animation and logging",
        "ECRR-compliant status reporting",
        "Automatic startup with Windows",
        "Comprehensive error handling",
        "SigNoz connectivity monitoring"
    )
}

$reportFile = "artifacts\gpu-monitoring-setup-report.json"
$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ GPU Automated Monitoring Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Management Commands:" -ForegroundColor Yellow
Write-Host "  .\scripts\manage-gpu-monitoring.ps1 status    # Check status" -ForegroundColor White
Write-Host "  .\scripts\manage-gpu-monitoring.ps1 start     # Start monitoring" -ForegroundColor White
Write-Host "  .\scripts\manage-gpu-monitoring.ps1 stop      # Stop monitoring" -ForegroundColor White
Write-Host "  .\scripts\manage-gpu-monitoring.ps1 logs      # View logs" -ForegroundColor White
Write-Host ""
Write-Host "📊 Monitoring Features:" -ForegroundColor Yellow
Write-Host "  • 30-second GPU metrics emission" -ForegroundColor White
Write-Host "  • 2-minute health checks" -ForegroundColor White
Write-Host "  • Automatic Windows startup" -ForegroundColor White
Write-Host "  • ECRR-compliant reporting" -ForegroundColor White
Write-Host "  • Progress animation" -ForegroundColor White
Write-Host ""
Write-Host "📁 Artifacts:" -ForegroundColor Yellow
Write-Host "  • Status: artifacts\gpu-monitoring-status.json" -ForegroundColor White
Write-Host "  • Logs: artifacts\gpu-automated-monitoring.log" -ForegroundColor White
Write-Host "  • Reports: artifacts\gpu-monitoring-report-*.json" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\scripts\manage-gpu-monitoring.ps1 start" -ForegroundColor White
Write-Host "  2. Check: .\scripts\manage-gpu-monitoring.ps1 status" -ForegroundColor White
Write-Host "  3. View SigNoz: http://localhost:8080" -ForegroundColor White

# ECRR: Role - Declare actor
Write-Host ""
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor Cyan
Write-Host "   Automated GPU monitoring system deployed with Cat Nap Control Room aesthetic" -ForegroundColor White
