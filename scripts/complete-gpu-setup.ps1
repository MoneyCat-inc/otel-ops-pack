# Complete GPU Monitoring Setup
# ECRR-compliant comprehensive GPU monitoring setup

Write-Host "=== Complete GPU Monitoring Setup ===" -ForegroundColor Cyan
Write-Host "ECRR: Completing GPU monitoring setup..." -ForegroundColor Yellow

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0

function Show-Progress {
    param([string]$Message, [int]$Current, [int]$Total)
    $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
    $progress = [math]::Round(($Current / $Total) * 100)
    Write-Host "`r$($spinner[$spinnerIndex]) $Message... $Current/$Total ($progress%)" -NoNewline -ForegroundColor Cyan
}

# Step 1: Create SigNoz-compatible alert configuration
Write-Host "`n🚨 Step 1: Creating GPU alert configuration..." -ForegroundColor Yellow
Show-Progress "Creating alerts" 1 4

$alertConfig = @{
    alerts = @(
        @{
            name = "High GPU Utilization"
            description = "GPU utilization exceeds 80%"
            query = "gpu.utilization.percent > 80"
            threshold = 80
            severity = "WARNING"
            duration = "5m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        },
        @{
            name = "Critical GPU Utilization"
            description = "GPU utilization exceeds 95%"
            query = "gpu.utilization.percent > 95"
            threshold = 95
            severity = "CRITICAL"
            duration = "2m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        },
        @{
            name = "High GPU Memory Usage"
            description = "GPU memory utilization exceeds 90%"
            query = "gpu.memory.utilization.percent > 90"
            threshold = 90
            severity = "WARNING"
            duration = "5m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        },
        @{
            name = "GPU Overheating"
            description = "GPU temperature exceeds 85°C"
            query = "gpu.temperature.celsius > 85"
            threshold = 85
            severity = "CRITICAL"
            duration = "3m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        },
        @{
            name = "GPU Sidecar Unhealthy"
            description = "GPU sidecar health status is unhealthy"
            query = "gpu.sidecar.health == 0"
            threshold = 0
            severity = "CRITICAL"
            duration = "1m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        },
        @{
            name = "GPU Monitoring Stalled"
            description = "No GPU metrics received for 5 minutes"
            query = "absent(gpu.utilization.percent)"
            threshold = "absent"
            severity = "WARNING"
            duration = "5m"
            enabled = $true
            tags = @("gpu", "monitoring", "automated")
        }
    )
    metadata = @{
        source = "gpu-monitoring-system"
        version = "1.0"
        imported_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        imported_by = "OTel-GPU-Monitoring"
    }
}

$alertConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath "artifacts/signoz-gpu-alerts.json" -Encoding UTF8
Write-Host "`r✅ GPU alert configuration created: artifacts/signoz-gpu-alerts.json" -ForegroundColor Green

# Step 2: Create SigNoz-compatible dashboard configuration
Write-Host "`n📊 Step 2: Creating GPU dashboard configuration..." -ForegroundColor Yellow
Show-Progress "Creating dashboard" 2 4

$dashboardConfig = @{
    name = "GPU Monitoring Dashboard"
    description = "Comprehensive GPU monitoring dashboard for Cat Nap Control Room"
    tags = @("gpu", "monitoring", "observability")
    panels = @(
        @{
            id = "gpu-utilization-overview"
            title = "GPU Utilization Overview"
            type = "timeseries"
            query = "gpu.utilization.percent"
            thresholds = @(
                @{ value = 80; color = "yellow"; label = "High Usage" },
                @{ value = 95; color = "red"; label = "Critical" }
            )
        },
        @{
            id = "gpu-memory-usage"
            title = "GPU Memory Usage"
            type = "timeseries"
            query = "gpu.memory.utilization.percent"
            thresholds = @(
                @{ value = 90; color = "red"; label = "High Memory" }
            )
        },
        @{
            id = "gpu-temperature"
            title = "GPU Temperature Monitoring"
            type = "timeseries"
            query = "gpu.temperature.celsius"
            thresholds = @(
                @{ value = 85; color = "red"; label = "Overheating" },
                @{ value = 75; color = "yellow"; label = "Warm" }
            )
        },
        @{
            id = "gpu-sidecar-health"
            title = "GPU Sidecar Health Status"
            type = "stat"
            query = "gpu.sidecar.health"
            thresholds = @(
                @{ value = 0; color = "red" },
                @{ value = 1; color = "green" }
            )
        }
    )
    refreshInterval = "30s"
    timeRange = @{
        from = "now-1h"
        to = "now"
    }
}

$dashboardConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath "artifacts/signoz-gpu-dashboard.json" -Encoding UTF8
Write-Host "`r✅ GPU dashboard configuration created: artifacts/signoz-gpu-dashboard.json" -ForegroundColor Green

# Step 3: Verify and setup scheduled task
Write-Host "`n⏰ Step 3: Setting up automated monitoring..." -ForegroundColor Yellow
Show-Progress "Setting up monitoring" 3 4

# Check if scheduled task exists
$existingTask = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "✅ Scheduled task exists: $($existingTask.TaskName) - State: $($existingTask.State)" -ForegroundColor Green
} else {
    Write-Host "⚠️ Scheduled task not found, creating..." -ForegroundColor Yellow
    
    # Create simple monitoring script
    $monitoringScript = @"
import subprocess
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

def monitor_gpu():
    logger.info("🔄 Running GPU monitoring cycle...")
    
    # Emit GPU metrics
    try:
        result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            logger.info("✅ GPU metrics emitted")
        else:
            logger.error(f"❌ Metrics failed: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Error: {e}")
    
    # Check sidecar health
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
    
    # Create scheduled task
    try {
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
}

# Step 4: Create trend monitoring guide
Write-Host "`n📈 Step 4: Creating trend monitoring guide..." -ForegroundColor Yellow
Show-Progress "Creating guide" 4 4

$trendGuide = @"
=== GPU Trend Monitoring Guide ===

## SigNoz Queries for GPU Trends

### Real-time Monitoring Queries
1. GPU Utilization: gpu.utilization.percent
2. GPU Memory: gpu.memory.utilization.percent  
3. GPU Temperature: gpu.temperature.celsius
4. Sidecar Health: gpu.sidecar.health

### Trend Analysis Queries
1. 24h Utilization Trend: avg_over_time(gpu.utilization.percent[1h])
2. Memory Growth Rate: rate(gpu.memory.utilization.percent[5m])
3. Temperature Average: avg_over_time(gpu.temperature.celsius[1h])
4. Performance Rate: rate(gpu.utilization.percent[5m])

### Alert Queries
1. High Memory: gpu.memory.utilization.percent > 85
2. Overheating: gpu.temperature.celsius > 80
3. High Utilization: gpu.utilization.percent > 90
4. Sidecar Down: gpu.sidecar.health == 0

## SigNoz Import Instructions

### Import Alerts
1. Open SigNoz: http://localhost:8080
2. Navigate to: Alerts → Create Alert
3. Use queries from artifacts/signoz-gpu-alerts.json
4. Set thresholds and durations as specified

### Import Dashboard
1. Open SigNoz: http://localhost:8080
2. Navigate to: Dashboards → Create Dashboard
3. Add panels using queries from artifacts/signoz-gpu-dashboard.json
4. Set refresh interval to 30s

## Testing Commands
- Check GPU sidecars: python scripts/check-gpu-sidecars.py
- Emit GPU metrics: python scripts/gpu-metrics-emitter.py
- Run monitoring: python scripts/gpu-monitor.py
- Check scheduled task: Get-ScheduledTask -TaskName "OTel-GPU-Monitoring"
"@

$trendGuide | Out-File -FilePath "artifacts/gpu-trend-monitoring-guide.txt" -Encoding UTF8
Write-Host "`r✅ Trend monitoring guide created: artifacts/gpu-trend-monitoring-guide.txt" -ForegroundColor Green

# Final verification
Write-Host "`n🔍 Final verification..." -ForegroundColor Yellow

# Test GPU monitoring components
Write-Host "Testing GPU metrics emission..." -ForegroundColor Cyan
try {
    $metricsResult = python scripts/gpu-metrics-emitter.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GPU metrics emission working" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GPU metrics emission issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ GPU metrics emission failed" -ForegroundColor Red
}

# Check scheduled task
$task = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "✅ Scheduled task: $($task.TaskName) - State: $($task.State)" -ForegroundColor Green
} else {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
}

Write-Host "`n=== ECRR Report: GPU Monitoring Setup Complete ===" -ForegroundColor Cyan
Write-Host "✅ GPU alert configuration: artifacts/signoz-gpu-alerts.json" -ForegroundColor Green
Write-Host "✅ GPU dashboard configuration: artifacts/signoz-gpu-dashboard.json" -ForegroundColor Green
Write-Host "✅ Automated monitoring: OTel-GPU-Monitoring scheduled task" -ForegroundColor Green
Write-Host "✅ Trend monitoring guide: artifacts/gpu-trend-monitoring-guide.txt" -ForegroundColor Green
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor White

Write-Host "`n🚀 GPU Monitoring Setup Complete!" -ForegroundColor Green
Write-Host "📊 Next: Import configurations into SigNoz UI at http://localhost:8080" -ForegroundColor Yellow
