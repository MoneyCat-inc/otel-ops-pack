# GPU Monitoring Management Script
# Easy commands for GPU monitoring automation

param(
    [Parameter(Position=0)]
    [string]$Action = "help",
    
    [Parameter(Position=1)]
    [string]$Interval = "30"
)

function Show-GPUHelp {
    Write-Host "=== GPU Monitoring Management ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE: manage-gpu-monitoring <action> [interval]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ACTIONS:" -ForegroundColor Yellow
    Write-Host "=========" -ForegroundColor Yellow
    Write-Host "  setup           - Set up GPU monitoring automation" -ForegroundColor White
    Write-Host "  start            - Start GPU monitoring daemon" -ForegroundColor White
    Write-Host "  stop             - Stop GPU monitoring daemon" -ForegroundColor White
    Write-Host "  status           - Check GPU monitoring status" -ForegroundColor White
    Write-Host "  install-task     - Install Windows Task Scheduler task" -ForegroundColor White
    Write-Host "  uninstall-task   - Remove Windows Task Scheduler task" -ForegroundColor White
    Write-Host "  logs             - View monitoring logs" -ForegroundColor White
    Write-Host "  alerts           - Show alert configuration" -ForegroundColor White
    Write-Host "  test             - Test GPU monitoring pipeline" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "==========" -ForegroundColor Yellow
    Write-Host "  manage-gpu-monitoring setup              # Set up automation" -ForegroundColor Green
    Write-Host "  manage-gpu-monitoring start 60          # Start with 60s interval" -ForegroundColor Green
    Write-Host "  manage-gpu-monitoring install-task      # Install scheduled task" -ForegroundColor Green
    Write-Host "  manage-gpu-monitoring status            # Check status" -ForegroundColor Green
    Write-Host "  manage-gpu-monitoring logs              # View logs" -ForegroundColor Green
    Write-Host ""
}

function Start-GPUMonitoring {
    param([int]$IntervalSeconds)
    
    Write-Host "🚀 Starting GPU monitoring daemon..." -ForegroundColor Cyan
    Write-Host "Interval: $IntervalSeconds seconds" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        & python scripts\gpu-monitoring-daemon.py --interval $IntervalSeconds
    } catch {
        Write-Host "❌ Failed to start GPU monitoring: $_" -ForegroundColor Red
    }
}

function Stop-GPUMonitoring {
    Write-Host "🛑 Stopping GPU monitoring daemon..." -ForegroundColor Cyan
    
    # Find and stop Python processes running GPU monitoring
    $processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*gpu-monitoring-daemon*"
    }
    
    if ($processes) {
        foreach ($process in $processes) {
            Write-Host "Stopping process $($process.Id)..." -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force
        }
        Write-Host "✅ GPU monitoring daemon stopped" -ForegroundColor Green
    } else {
        Write-Host "⚠️ No GPU monitoring daemon processes found" -ForegroundColor Yellow
    }
}

function Get-GPUMonitoringStatus {
    Write-Host "=== GPU Monitoring Status ===" -ForegroundColor Cyan
    
    # Check if daemon is running
    $processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*gpu-monitoring-daemon*"
    }
    
    if ($processes) {
        Write-Host "✅ GPU monitoring daemon is running" -ForegroundColor Green
        foreach ($process in $processes) {
            Write-Host "   Process ID: $($process.Id)" -ForegroundColor White
        }
    } else {
        Write-Host "❌ GPU monitoring daemon is not running" -ForegroundColor Red
    }
    
    # Check GPU sidecars
    Write-Host "`n=== GPU Sidecar Status ===" -ForegroundColor Cyan
    try {
        $gpuContainers = docker ps --format "{{.Names}}\t{{.Status}}" | Where-Object { $_ -like "*gpu*" }
        if ($gpuContainers) {
            Write-Host "✅ GPU sidecars running:" -ForegroundColor Green
            $gpuContainers | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        } else {
            Write-Host "❌ No GPU sidecars detected" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to check GPU sidecars: $_" -ForegroundColor Red
    }
    
    # Check OTel pipeline
    Write-Host "`n=== OTel Pipeline Status ===" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5318/v1/metrics" -Method POST -Body '{}' -ContentType "application/json" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 400) {
            Write-Host "✅ OTel collector responding on port 5318" -ForegroundColor Green
        } else {
            Write-Host "⚠️ OTel collector responding with status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ OTel collector not responding" -ForegroundColor Red
    }
    
    # Check SigNoz
    Write-Host "`n=== SigNoz Status ===" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SigNoz UI accessible on port 8080" -ForegroundColor Green
        } else {
            Write-Host "⚠️ SigNoz UI responding with status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ SigNoz UI not accessible" -ForegroundColor Red
    }
}

function Install-GPUMonitoringTask {
    Write-Host "🔧 Installing Windows Task Scheduler task..." -ForegroundColor Cyan
    
    $taskName = "GPU-Automated-Monitoring"
    $scriptPath = (Get-Location).Path + "\scripts\gpu-monitoring-daemon.py"
    
    # Create task action
    $action = New-ScheduledTaskAction -Execute "python" -Argument "`"$scriptPath`" --interval 30"
    
    # Create task trigger (every 5 minutes)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Create task principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated GPU monitoring" -Force
        Write-Host "✅ Task '$taskName' installed successfully" -ForegroundColor Green
        Write-Host "   The task will run every 5 minutes" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Failed to install task: $_" -ForegroundColor Red
    }
}

function Uninstall-GPUMonitoringTask {
    Write-Host "🗑️ Removing Windows Task Scheduler task..." -ForegroundColor Cyan
    
    $taskName = "GPU-Automated-Monitoring"
    
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "✅ Task '$taskName' removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to remove task: $_" -ForegroundColor Red
    }
}

function Get-GPUMonitoringLogs {
    Write-Host "=== GPU Monitoring Logs ===" -ForegroundColor Cyan
    
    $logDir = "artifacts/gpu-monitoring"
    if (Test-Path $logDir) {
        $logFiles = Get-ChildItem $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        
        if ($logFiles) {
            Write-Host "Recent log files:" -ForegroundColor Yellow
            foreach ($logFile in $logFiles) {
                Write-Host "   $($logFile.Name) ($($logFile.LastWriteTime))" -ForegroundColor White
            }
            
            Write-Host "`nLatest log entries:" -ForegroundColor Yellow
            $latestLog = $logFiles[0].FullName
            Get-Content $latestLog -Tail 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        } else {
            Write-Host "⚠️ No log files found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Log directory not found: $logDir" -ForegroundColor Red
    }
}

function Show-GPUAlerts {
    Write-Host "=== GPU Alert Configuration ===" -ForegroundColor Cyan
    
    $alertsFile = "artifacts/gpu-monitoring/gpu-alerts-config.json"
    if (Test-Path $alertsFile) {
        Write-Host "✅ Alert configuration found: $alertsFile" -ForegroundColor Green
        Write-Host ""
        Write-Host "Configured alerts:" -ForegroundColor Yellow
        
        $alertsConfig = Get-Content $alertsFile | ConvertFrom-Json
        foreach ($alert in $alertsConfig.alerts) {
            Write-Host "   • $($alert.name)" -ForegroundColor White
            Write-Host "     Query: $($alert.query)" -ForegroundColor Gray
            Write-Host "     Severity: $($alert.severity)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "To configure these alerts in SigNoz:" -ForegroundColor Yellow
        Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
        Write-Host "2. Go to Alerts → New Alert" -ForegroundColor White
        Write-Host "3. Use the queries above to create alerts" -ForegroundColor White
    } else {
        Write-Host "❌ Alert configuration not found: $alertsFile" -ForegroundColor Red
        Write-Host "Run 'manage-gpu-monitoring setup' to create alert configuration" -ForegroundColor Yellow
    }
}

function Test-GPUMonitoringPipeline {
    Write-Host "=== GPU Monitoring Pipeline Test ===" -ForegroundColor Cyan
    
    Write-Host "1. Testing GPU sidecar health..." -ForegroundColor Yellow
    try {
        $result = python scripts\check-gpu-sidecars.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GPU sidecars healthy" -ForegroundColor Green
        } else {
            Write-Host "⚠️ GPU sidecar issues detected" -ForegroundColor Yellow
            Write-Host $result -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to check GPU sidecars: $_" -ForegroundColor Red
    }
    
    Write-Host "`n2. Testing GPU metrics emission..." -ForegroundColor Yellow
    try {
        $result = python scripts\gpu-metrics-emitter.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GPU metrics emitted successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ GPU metrics emission failed" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to emit GPU metrics: $_" -ForegroundColor Red
    }
    
    Write-Host "`n3. Testing SigNoz connectivity..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SigNoz UI accessible" -ForegroundColor Green
        } else {
            Write-Host "⚠️ SigNoz UI responding with status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ SigNoz UI not accessible" -ForegroundColor Red
    }
    
    Write-Host "`n=== Pipeline Test Complete ===" -ForegroundColor Green
}

# Main command dispatcher
switch ($Action.ToLower()) {
    "help" { Show-GPUHelp }
    "setup" { 
        Write-Host "🔧 Setting up GPU monitoring automation..." -ForegroundColor Cyan
        & pwsh -File scripts\setup-gpu-automation.ps1 -StartNow
    }
    "start" { Start-GPUMonitoring -IntervalSeconds ([int]$Interval) }
    "stop" { Stop-GPUMonitoring }
    "status" { Get-GPUMonitoringStatus }
    "install-task" { Install-GPUMonitoringTask }
    "uninstall-task" { Uninstall-GPUMonitoringTask }
    "logs" { Get-GPUMonitoringLogs }
    "alerts" { Show-GPUAlerts }
    "test" { Test-GPUMonitoringPipeline }
    default { 
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Show-GPUHelp
    }
}