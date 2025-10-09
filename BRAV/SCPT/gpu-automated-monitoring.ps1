# GPU Automated Monitoring Integration
# Integrates GPU monitoring into the existing automated workflow system
# Follows ECRR methodology and integrates with scheduled tasks

param(
    [switch]$EnableScheduledTasks,
    [switch]$EnableHealthChecks,
    [switch]$EnableMetricsCollection,
    [switch]$EnableAlerting,
    [switch]$EnableDashboard,
    [string]$ScheduleInterval = "5",  # minutes
    [string]$MetricsInterval = "15",  # seconds
    [string]$HealthThreshold = "95",  # percent
    [switch]$DryRun
)

# ECRR Framework Integration
$ECRRReport = @{
    Examine = @{}
    Clean = @{}
    Report = @{}
    Role = "GPU Automated Monitoring"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"})
    $ECRRReport.Report[$timestamp] = $logEntry
}

function Install-GPUScheduledTasks {
    Write-ECRRLog "Installing GPU monitoring scheduled tasks..."
    
    $scriptDir = $PSScriptRoot
    $workingDir = Split-Path $scriptDir -Parent
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-ECRRLog "Warning: Not running as Administrator - scheduled tasks may require elevation" "WARN"
    }
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would install GPU monitoring scheduled tasks"
        return
    }
    
    # Task 1: GPU Health Check (every 5 minutes)
    Write-ECRRLog "Creating GPU Health Check task (every $ScheduleInterval minutes)..."
    $gpuHealthAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptDir\gpu-workflow-orchestrator.ps1`" -Action health" -WorkingDirectory $workingDir
    $gpuHealthTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes ([int]$ScheduleInterval))
    $gpuHealthSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
    
    try {
        Register-ScheduledTask -TaskName "OTel-GPUHealthCheck" -Action $gpuHealthAction -Trigger $gpuHealthTrigger -Settings $gpuHealthSettings -User "SYSTEM" -Description "GPU sidecar health check every $ScheduleInterval minutes" -Force
        Write-ECRRLog "Created: OTel-GPUHealthCheck"
    } catch {
        Write-ECRRLog "Failed to create OTel-GPUHealthCheck: $($_.Exception.Message)" "ERROR"
    }
    
    # Task 2: GPU Metrics Collection (every 15 minutes)
    Write-ECRRLog "Creating GPU Metrics Collection task (every 15 minutes)..."
    $gpuMetricsAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptDir\gpu-workflow-orchestrator.ps1`" -Action metrics -DurationMinutes 15" -WorkingDirectory $workingDir
    $gpuMetricsTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
    $gpuMetricsSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    
    try {
        Register-ScheduledTask -TaskName "OTel-GPUMetricsCollection" -Action $gpuMetricsAction -Trigger $gpuMetricsTrigger -Settings $gpuMetricsSettings -User "SYSTEM" -Description "GPU metrics collection every 15 minutes" -Force
        Write-ECRRLog "Created: OTel-GPUMetricsCollection"
    } catch {
        Write-ECRRLog "Failed to create OTel-GPUMetricsCollection: $($_.Exception.Message)" "ERROR"
    }
    
    # Task 3: GPU Integration Test (every hour)
    Write-ECRRLog "Creating GPU Integration Test task (every hour)..."
    $gpuTestAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptDir\gpu-workflow-orchestrator.ps1`" -Action test" -WorkingDirectory $workingDir
    $gpuTestTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    $gpuTestSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    
    try {
        Register-ScheduledTask -TaskName "OTel-GPUIntegrationTest" -Action $gpuTestAction -Trigger $gpuTestTrigger -Settings $gpuTestSettings -User "SYSTEM" -Description "GPU integration test every hour" -Force
        Write-ECRRLog "Created: OTel-GPUIntegrationTest"
    } catch {
        Write-ECRRLog "Failed to create OTel-GPUIntegrationTest: $($_.Exception.Message)" "ERROR"
    }
    
    # Task 4: GPU Status Report (daily at 9 AM)
    Write-ECRRLog "Creating GPU Status Report task (daily at 9 AM)..."
    $gpuReportAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptDir\gpu-workflow-orchestrator.ps1`" -Action status" -WorkingDirectory $workingDir
    $gpuReportTrigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
    $gpuReportSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    
    try {
        Register-ScheduledTask -TaskName "OTel-GPUStatusReport" -Action $gpuReportAction -Trigger $gpuReportTrigger -Settings $gpuReportSettings -User "SYSTEM" -Description "Daily GPU status report at 9 AM" -Force
        Write-ECRRLog "Created: OTel-GPUStatusReport"
    } catch {
        Write-ECRRLog "Failed to create OTel-GPUStatusReport: $($_.Exception.Message)" "ERROR"
    }
    
    Write-ECRRLog "GPU monitoring scheduled tasks installed successfully"
}

function Start-GPUHealthMonitoring {
    Write-ECRRLog "Starting GPU health monitoring..."
    
    $healthScript = @"
# GPU Health Monitoring Script
# Generated by GPU Automated Monitoring

`$LogPath = "artifacts\gpu-health-monitor-`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
`$Threshold = $HealthThreshold

Write-Host "🏥 Starting GPU Health Monitoring" -ForegroundColor Cyan

# Create log file
"GPU Health Monitoring Started - `$(Get-Date)" | Out-File -FilePath `$LogPath -Encoding UTF8

while (`$true) {
    `$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    `$healthStatus = @{}
    
    try {
        # Check GPU sidecar health
        `$sidecars = @(
            @{Name="Compression"; Port=8001},
            @{Name="Aggregation"; Port=8002},
            @{Name="Inference"; Port=8003}
        )
        
        `$healthyCount = 0
        foreach (`$sidecar in `$sidecars) {
            try {
                `$healthResponse = Invoke-WebRequest -Uri "http://localhost:`$(`$sidecar.Port)/health" -UseBasicParsing -TimeoutSec 5
                if (`$healthResponse.StatusCode -eq 200) {
                    `$healthData = `$healthResponse.Content | ConvertFrom-Json
                    `$healthStatus[`$sidecar.Name] = @{
                        status = `$healthData.status
                        gpu_available = `$healthData.gpu_available
                        healthy = `$true
                    }
                    `$healthyCount++
                    Write-Host "`[$timestamp`] `$(`$sidecar.Name): HEALTHY" -ForegroundColor Green
                    "`$timestamp - `$(`$sidecar.Name): HEALTHY" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
                } else {
                    `$healthStatus[`$sidecar.Name] = @{healthy = `$false; error = "HTTP `$(`$healthResponse.StatusCode)"}
                    Write-Host "`[$timestamp`] `$(`$sidecar.Name): HTTP `$(`$healthResponse.StatusCode)" -ForegroundColor Red
                    "`$timestamp - `$(`$sidecar.Name): HTTP `$(`$healthResponse.StatusCode)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
                }
            } catch {
                `$healthStatus[`$sidecar.Name] = @{healthy = `$false; error = `$_.Exception.Message}
                Write-Host "`[$timestamp`] `$(`$sidecar.Name): ERROR - `$(`$_.Exception.Message)" -ForegroundColor Red
                "`$timestamp - `$(`$sidecar.Name): ERROR - `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
            }
        }
        
        # Calculate health percentage
        `$healthPercentage = if (`$sidecars.Count -gt 0) { (`$healthyCount / `$sidecars.Count) * 100 } else { 0 }
        
        # Check threshold
        if (`$healthPercentage -lt `$Threshold) {
            Write-Host "`[$timestamp`] GPU Health: `$(`$healthPercentage.ToString('F1'))% (BELOW THRESHOLD `$Threshold%)" -ForegroundColor Red
            "`$timestamp - GPU Health: `$(`$healthPercentage.ToString('F1'))% (BELOW THRESHOLD `$Threshold%)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
            
            # Trigger alert if enabled
            if (`$env:ENABLE_GPU_ALERTS -eq "true") {
                # Send alert notification
                Write-Host "`[$timestamp`] GPU Health Alert Triggered" -ForegroundColor Red
                "`$timestamp - GPU Health Alert Triggered" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
            }
        } else {
            Write-Host "`[$timestamp`] GPU Health: `$(`$healthPercentage.ToString('F1'))% (HEALTHY)" -ForegroundColor Green
            "`$timestamp - GPU Health: `$(`$healthPercentage.ToString('F1'))% (HEALTHY)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        }
        
        # Check GPU hardware
        try {
            `$nvidiaOutput = nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>$null
            if (`$nvidiaOutput) {
                `$gpuStats = `$nvidiaOutput.Split(',')
                `$utilization = [int]`$gpuStats[0].Trim()
                `$memoryUsed = [int]`$gpuStats[1].Trim()
                `$memoryTotal = [int]`$gpuStats[2].Trim()
                `$temperature = [int]`$gpuStats[3].Trim()
                
                Write-Host "`[$timestamp`] GPU Hardware: `$utilization% util, `$memoryUsed/`$memoryTotal MB, `$temperature°C" -ForegroundColor Cyan
                "`$timestamp - GPU Hardware: `$utilization% util, `$memoryUsed/`$memoryTotal MB, `$temperature°C" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
            }
        } catch {
            Write-Host "`[$timestamp`] GPU Hardware: Not available" -ForegroundColor Yellow
            "`$timestamp - GPU Hardware: Not available" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        }
        
    } catch {
        Write-Host "`[$timestamp`] GPU Health Monitoring Error: `$(`$_.Exception.Message)" -ForegroundColor Red
        "`$timestamp - GPU Health Monitoring Error: `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
    
    Start-Sleep -Seconds 60  # Check every minute
}
"@
    
    $healthScript | Out-File -FilePath ".artifacts/gpu-health-monitor.ps1" -Encoding UTF8
    Write-ECRRLog "Created GPU health monitoring script"
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would start GPU health monitoring"
    } else {
        Start-Process -FilePath "pwsh" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", ".artifacts/gpu-health-monitor.ps1") -WindowStyle Hidden
        Write-ECRRLog "Started GPU health monitoring"
    }
}

function Start-GPUMetricsCollection {
    Write-ECRRLog "Starting automated GPU metrics collection..."
    
    $metricsScript = @"
# GPU Metrics Collection Script
# Generated by GPU Automated Monitoring

`$LogPath = "artifacts\gpu-metrics-collector-`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
`$Interval = $MetricsInterval

Write-Host "📊 Starting GPU Metrics Collection" -ForegroundColor Cyan

# Create log file
"GPU Metrics Collection Started - `$(Get-Date)" | Out-File -FilePath `$LogPath -Encoding UTF8

while (`$true) {
    `$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    try {
        # Start GPU metrics collection for 5 minutes
        `$metricsProcess = Start-Process -FilePath "python" -ArgumentList @("gpu-metrics-simple.py", "--duration", "300", "--interval", `$Interval, "--no-file") -PassThru -WindowStyle Hidden
        
        Write-Host "`[$timestamp`] GPU Metrics Collection Started (PID: `$(`$metricsProcess.Id))" -ForegroundColor Green
        "`$timestamp - GPU Metrics Collection Started (PID: `$(`$metricsProcess.Id))" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        
        # Wait for metrics collection to complete
        `$metricsProcess.WaitForExit()
        
        `$exitCode = `$metricsProcess.ExitCode
        if (`$exitCode -eq 0) {
            Write-Host "`[$timestamp`] GPU Metrics Collection Completed Successfully" -ForegroundColor Green
            "`$timestamp - GPU Metrics Collection Completed Successfully" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        } else {
            Write-Host "`[$timestamp`] GPU Metrics Collection Failed (Exit Code: `$exitCode)" -ForegroundColor Red
            "`$timestamp - GPU Metrics Collection Failed (Exit Code: `$exitCode)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
        }
        
    } catch {
        Write-Host "`[$timestamp`] GPU Metrics Collection Error: `$(`$_.Exception.Message)" -ForegroundColor Red
        "`$timestamp - GPU Metrics Collection Error: `$(`$_.Exception.Message)" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
    
    # Wait 10 minutes before next collection cycle
    Start-Sleep -Seconds 600
}
"@
    
    $metricsScript | Out-File -FilePath ".artifacts/gpu-metrics-collector.ps1" -Encoding UTF8
    Write-ECRRLog "Created GPU metrics collection script"
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would start GPU metrics collection"
    } else {
        Start-Process -FilePath "pwsh" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", ".artifacts/gpu-metrics-collector.ps1") -WindowStyle Hidden
        Write-ECRRLog "Started GPU metrics collection"
    }
}

function Setup-GPUAlerting {
    Write-ECRRLog "Setting up GPU alerting system..."
    
    $alertScript = @"
# GPU Alerting System
# Generated by GPU Automated Monitoring

`$LogPath = "artifacts\gpu-alerts-`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
`$Threshold = $HealthThreshold

Write-Host "🚨 Starting GPU Alerting System" -ForegroundColor Cyan

# Create log file
"GPU Alerting System Started - `$(Get-Date)" | Out-File -FilePath `$LogPath -Encoding UTF8

function Send-GPUAlert {
    param(
        [string]`$AlertType,
        [string]`$Message,
        [hashtable]`$Details = @{}
    )
    
    `$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    `$alert = @{
        timestamp = `$timestamp
        type = `$AlertType
        message = `$Message
        details = `$Details
    }
    
    `$alertJson = `$alert | ConvertTo-Json -Depth 3
    
    Write-Host "`[$timestamp`] ALERT: `$AlertType - `$Message" -ForegroundColor Red
    "`$timestamp - ALERT: `$AlertType - `$Message" | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    `$alertJson | Out-File -FilePath "artifacts\gpu-alert-`$(Get-Date -Format 'yyyyMMdd_HHmmss').json" -Encoding UTF8
    
    # Send to webhook if configured
    if (`$env:GPU_WEBHOOK_URL) {
        try {
            Invoke-WebRequest -Uri `$env:GPU_WEBHOOK_URL -Method POST -Body `$alertJson -ContentType "application/json" -UseBasicParsing
            Write-Host "`[$timestamp`] Alert sent to webhook" -ForegroundColor Green
        } catch {
            Write-Host "`[$timestamp`] Failed to send alert to webhook: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    }
}

while (`$true) {
    `$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    try {
        # Check GPU sidecar health
        `$sidecars = @(
            @{Name="Compression"; Port=8001},
            @{Name="Aggregation"; Port=8002},
            @{Name="Inference"; Port=8003}
        )
        
        `$unhealthyServices = @()
        foreach (`$sidecar in `$sidecars) {
            try {
                `$healthResponse = Invoke-WebRequest -Uri "http://localhost:`$(`$sidecar.Port)/health" -UseBasicParsing -TimeoutSec 5
                if (`$healthResponse.StatusCode -ne 200) {
                    `$unhealthyServices += `$sidecar.Name
                }
            } catch {
                `$unhealthyServices += `$sidecar.Name
            }
        }
        
        if (`$unhealthyServices.Count -gt 0) {
            Send-GPUAlert -AlertType "SERVICE_DOWN" -Message "GPU sidecar services down: `$(`$unhealthyServices -join ', ')" -Details @{unhealthy_services = `$unhealthyServices}
        }
        
        # Check GPU hardware
        try {
            `$nvidiaOutput = nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>$null
            if (`$nvidiaOutput) {
                `$gpuStats = `$nvidiaOutput.Split(',')
                `$utilization = [int]`$gpuStats[0].Trim()
                `$temperature = [int]`$gpuStats[1].Trim()
                
                if (`$temperature -gt 85) {
                    Send-GPUAlert -AlertType "HIGH_TEMPERATURE" -Message "GPU temperature critical: `$temperature°C" -Details @{temperature = `$temperature; threshold = 85}
                }
                
                if (`$utilization -gt 95) {
                    Send-GPUAlert -AlertType "HIGH_UTILIZATION" -Message "GPU utilization critical: `$utilization%" -Details @{utilization = `$utilization; threshold = 95}
                }
            }
        } catch {
            Send-GPUAlert -AlertType "GPU_UNAVAILABLE" -Message "GPU hardware not available" -Details @{error = `$_.Exception.Message}
        }
        
    } catch {
        Send-GPUAlert -AlertType "ALERTING_SYSTEM_ERROR" -Message "GPU alerting system error: `$(`$_.Exception.Message)" -Details @{error = `$_.Exception.Message}
    }
    
    Start-Sleep -Seconds 300  # Check every 5 minutes
}
"@
    
    $alertScript | Out-File -FilePath ".artifacts/gpu-alerting-system.ps1" -Encoding UTF8
    Write-ECRRLog "Created GPU alerting system script"
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would start GPU alerting system"
    } else {
        Start-Process -FilePath "pwsh" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", ".artifacts/gpu-alerting-system.ps1") -WindowStyle Hidden
        Write-ECRRLog "Started GPU alerting system"
    }
}

function Import-GPUDashboard {
    Write-ECRRLog "Importing GPU dashboard to SigNoz..."
    
    $dashboardFile = "artifacts/signoz-gpu-sidecar-dashboard.json"
    
    if (-not (Test-Path $dashboardFile)) {
        Write-ECRRLog "GPU dashboard file not found: $dashboardFile" "ERROR"
        return $false
    }
    
    if ($DryRun) {
        Write-ECRRLog "DRY RUN: Would import GPU dashboard from $dashboardFile"
        return $true
    }
    
    try {
        # Use existing dashboard import script
        $importResult = & pwsh -ExecutionPolicy Bypass -File "scripts/import-dashboard.ps1" -DashboardFile $dashboardFile
        if ($LASTEXITCODE -eq 0) {
            Write-ECRRLog "GPU dashboard imported successfully"
            return $true
        } else {
            Write-ECRRLog "Failed to import GPU dashboard" "ERROR"
            return $false
        }
    } catch {
        Write-ECRRLog "Error importing GPU dashboard: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Host "🤖 GPU Automated Monitoring Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Enable Scheduled Tasks: $EnableScheduledTasks" -ForegroundColor Yellow
Write-Host "Enable Health Checks: $EnableHealthChecks" -ForegroundColor Yellow
Write-Host "Enable Metrics Collection: $EnableMetricsCollection" -ForegroundColor Yellow
Write-Host "Enable Alerting: $EnableAlerting" -ForegroundColor Yellow
Write-Host "Enable Dashboard: $EnableDashboard" -ForegroundColor Yellow
Write-Host "Dry Run: $DryRun" -ForegroundColor Yellow
Write-Host ""

# ECRR: Examine
Write-ECRRLog "Examining current GPU monitoring setup..."

# Check existing scheduled tasks
$existingTasks = Get-ScheduledTask -TaskName "*OTel*" -ErrorAction SilentlyContinue
$gpuTasks = $existingTasks | Where-Object { $_.TaskName -match "GPU" }
Write-ECRRLog "Found $($gpuTasks.Count) existing GPU-related scheduled tasks"

# ECRR: Clean
if ($EnableScheduledTasks) {
    Install-GPUScheduledTasks
}

if ($EnableHealthChecks) {
    Start-GPUHealthMonitoring
}

if ($EnableMetricsCollection) {
    Start-GPUMetricsCollection
}

if ($EnableAlerting) {
    Setup-GPUAlerting
}

if ($EnableDashboard) {
    $dashboardResult = Import-GPUDashboard
    if ($dashboardResult) {
        Write-ECRRLog "GPU dashboard setup complete"
    } else {
        Write-ECRRLog "GPU dashboard setup failed" "ERROR"
    }
}

# ECRR: Report
$reportFile = "artifacts/gpu-automated-monitoring-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$ECRRReport | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
Write-ECRRLog "ECRR report saved to: $reportFile"

Write-Host "`n🤖 GPU Automated Monitoring Setup Complete" -ForegroundColor Green
Write-Host "ECRR Report: $reportFile" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. View scheduled tasks: Get-ScheduledTask -TaskName '*OTel*'" -ForegroundColor Yellow
Write-Host "2. Check GPU status: .\scripts\gpu-workflow-orchestrator.ps1 -Action status" -ForegroundColor Yellow
Write-Host "3. View SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
Write-Host "4. Monitor logs: Get-Content artifacts\gpu-*.log -Tail 20" -ForegroundColor Yellow
