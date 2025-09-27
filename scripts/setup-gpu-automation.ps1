# GPU Automation Setup Script
# Simple setup for GPU monitoring automation

param(
    [int]$IntervalSeconds = 30,
    [switch]$InstallTask,
    [switch]$StartNow,
    [switch]$Verbose
)

function Write-ColorLog {
    param([string]$Message, [string]$Color = "Green")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-GPUPrerequisites {
    Write-ColorLog "🔍 Checking GPU monitoring prerequisites" "Cyan"
    
    $checks = @{
        "Python" = $false
        "Docker" = $false
        "GPU Containers" = $false
        "OTel Collector" = $false
        "SigNoz" = $false
    }
    
    # Check Python
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $checks["Python"] = $true
            Write-ColorLog "✅ Python: $pythonVersion" "Green"
        }
    } catch {
        Write-ColorLog "❌ Python not available" "Red"
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $checks["Docker"] = $true
            Write-ColorLog "✅ Docker: $dockerVersion" "Green"
        }
    } catch {
        Write-ColorLog "❌ Docker not available" "Red"
    }
    
    # Check GPU containers
    try {
        $gpuContainers = docker ps --format "{{.Names}}" | Where-Object { $_ -like "*gpu*" }
        if ($gpuContainers.Count -gt 0) {
            $checks["GPU Containers"] = $true
            Write-ColorLog "✅ GPU containers: $($gpuContainers -join ', ')" "Green"
        } else {
            Write-ColorLog "⚠️ No GPU containers detected" "Yellow"
        }
    } catch {
        Write-ColorLog "❌ Failed to check GPU containers" "Red"
    }
    
    # Check OTel collector
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5318/v1/metrics" -Method POST -Body '{}' -ContentType "application/json" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 400) {
            $checks["OTel Collector"] = $true
            Write-ColorLog "✅ OTel collector responding" "Green"
        }
    } catch {
        Write-ColorLog "⚠️ OTel collector not responding" "Yellow"
    }
    
    # Check SigNoz
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $checks["SigNoz"] = $true
            Write-ColorLog "✅ SigNoz UI accessible" "Green"
        }
    } catch {
        Write-ColorLog "⚠️ SigNoz UI not accessible" "Yellow"
    }
    
    return $checks
}

function Install-GPUMonitoringTask {
    param([int]$IntervalSeconds)
    
    Write-ColorLog "🔧 Installing Windows Task Scheduler task" "Cyan"
    
    $taskName = "GPU-Automated-Monitoring"
    $scriptPath = (Get-Location).Path + "\scripts\gpu-monitoring-daemon.py"
    
    # Create task action
    $action = New-ScheduledTaskAction -Execute "python" -Argument "`"$scriptPath`" --interval $IntervalSeconds"
    
    # Create task trigger (every 5 minutes)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Create task principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated GPU monitoring" -Force
        Write-ColorLog "✅ Task '$taskName' installed successfully" "Green"
        return $true
    } catch {
        Write-ColorLog "❌ Failed to install task: $_" "Red"
        return $false
    }
}

function Start-GPUMonitoringDaemon {
    param([int]$IntervalSeconds)
    
    Write-ColorLog "🚀 Starting GPU monitoring daemon" "Cyan"
    
    try {
        $scriptPath = "scripts\gpu-monitoring-daemon.py"
        Write-ColorLog "🔄 Starting continuous monitoring (Ctrl+C to stop)" "Yellow"
        & python $scriptPath --interval $IntervalSeconds
        Write-ColorLog "✅ GPU monitoring daemon completed" "Green"
        return $true
    } catch {
        Write-ColorLog "❌ Failed to start daemon: $_" "Red"
        return $false
    }
}

function New-GPUAlertsConfig {
    Write-ColorLog "📊 Creating GPU alerting configuration" "Cyan"
    
    $alertsConfig = @{
        alerts = @(
            @{
                name = "GPU High Utilization"
                description = "GPU utilization exceeds 80%"
                query = "gpu.utilization.percent > 80"
                severity = "warning"
                duration = "5m"
            },
            @{
                name = "GPU Critical Utilization"
                description = "GPU utilization exceeds 95%"
                query = "gpu.utilization.percent > 95"
                severity = "critical"
                duration = "2m"
            },
            @{
                name = "GPU High Memory Usage"
                description = "GPU memory usage exceeds 90%"
                query = "gpu.memory.utilization.percent > 90"
                severity = "warning"
                duration = "5m"
            },
            @{
                name = "GPU Overheating"
                description = "GPU temperature exceeds 85°C"
                query = "gpu.temperature.celsius > 85"
                severity = "critical"
                duration = "2m"
            },
            @{
                name = "GPU Sidecar Unhealthy"
                description = "GPU sidecar service is unhealthy"
                query = "gpu.sidecar.health == 0"
                severity = "critical"
                duration = "1m"
            }
        )
    }
    
    # Ensure artifacts directory exists
    $logDir = "artifacts/gpu-monitoring"
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $alertsFile = "$logDir/gpu-alerts-config.json"
    $alertsConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $alertsFile -Encoding UTF8
    Write-ColorLog "✅ GPU alerts configuration saved to $alertsFile" "Green"
    
    return $alertsFile
}

# Main execution
Write-Host "=== GPU Automation Setup ===" -ForegroundColor Cyan
Write-Host "Setting up automated GPU monitoring" -ForegroundColor Yellow
Write-Host ""

# Check prerequisites
$prerequisites = Test-GPUPrerequisites

# Create alerts configuration
$alertsFile = New-GPUAlertsConfig

# Install task scheduler if requested
$taskInstalled = $false
if ($InstallTask) {
    $taskInstalled = Install-GPUMonitoringTask -IntervalSeconds $IntervalSeconds
}

# Start daemon if requested
$daemonStarted = $false
if ($StartNow) {
    $daemonStarted = Start-GPUMonitoringDaemon -IntervalSeconds $IntervalSeconds
}

# Summary
Write-Host ""
Write-Host "=== GPU Automation Setup Complete ===" -ForegroundColor Green
Write-Host "✅ Monitoring interval: $IntervalSeconds seconds" -ForegroundColor White
Write-Host "✅ Prerequisites: $($prerequisites.Values | Where-Object {$_} | Measure-Object).Count/$($prerequisites.Count) passed" -ForegroundColor White
Write-Host "✅ Task scheduler: $(if($taskInstalled){'Installed'}else{'Skipped'})" -ForegroundColor White
Write-Host "✅ Daemon started: $(if($daemonStarted){'Yes'}else{'No'})" -ForegroundColor White
Write-Host "✅ Alerts config: $alertsFile" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Monitor GPU metrics: http://localhost:8080" -ForegroundColor White
Write-Host "2. Check logs: artifacts/gpu-monitoring/" -ForegroundColor White
Write-Host "3. Configure alerts using: $alertsFile" -ForegroundColor White
Write-Host "4. Use 'python scripts/gpu-monitoring-daemon.py' to start monitoring" -ForegroundColor White
