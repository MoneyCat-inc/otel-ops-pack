# Performance Monitor for Production Operations
# Monitors system performance metrics and generates performance reports

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("monitor", "report", "alert", "status")]
    [string]$Action = "monitor",
    
    [Parameter(Mandatory=$false)]
    [int]$DurationMinutes = 60,
    
    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "artifacts/performance-metrics.json"
)

$LogDir = "logs/performance-monitor"
$MetricsDir = "artifacts/performance"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    
    # File output
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    $logMessage | Out-File "$LogDir/performance-monitor.log" -Append -Encoding utf8
}

function Get-SystemMetrics {
    $metrics = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        cpu = @{
            usage_percent = 0
            cores = 0
        }
        memory = @{
            total_gb = 0
            used_gb = 0
            available_gb = 0
            usage_percent = 0
        }
        disk = @{
            total_gb = 0
            used_gb = 0
            available_gb = 0
            usage_percent = 0
        }
        processes = @{
            total = 0
            powershell = 0
            otel = 0
        }
        network = @{
            connections = 0
            listening_ports = 0
        }
    }
    
    try {
        # CPU metrics
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($cpu) {
            $metrics.cpu.usage_percent = [math]::Round($cpu.CounterSamples[0].CookedValue, 2)
        }
        
        $metrics.cpu.cores = (Get-WmiObject -Class Win32_Processor).NumberOfCores
        
        # Memory metrics
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $metrics.memory.total_gb = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $metrics.memory.available_gb = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $metrics.memory.used_gb = $metrics.memory.total_gb - $metrics.memory.available_gb
        $metrics.memory.usage_percent = [math]::Round(($metrics.memory.used_gb / $metrics.memory.total_gb) * 100, 2)
        
        # Disk metrics
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        if ($disk) {
            $metrics.disk.total_gb = [math]::Round($disk.Size / 1GB, 2)
            $metrics.disk.free_gb = [math]::Round($disk.FreeSpace / 1GB, 2)
            $metrics.disk.used_gb = $metrics.disk.total_gb - $metrics.disk.free_gb
            $metrics.disk.usage_percent = [math]::Round(($metrics.disk.used_gb / $metrics.disk.total_gb) * 100, 2)
        }
        
        # Process metrics
        $processes = Get-Process
        $metrics.processes.total = $processes.Count
        $metrics.processes.powershell = ($processes | Where-Object { $_.ProcessName -like "*powershell*" }).Count
        $metrics.processes.otel = ($processes | Where-Object { $_.ProcessName -like "*otel*" }).Count
        
        # Network metrics
        $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
        $metrics.network.connections = $connections.Count
        $metrics.network.listening_ports = ($connections | Where-Object { $_.State -eq "Listen" }).Count
        
    }
    catch {
        Write-Log "Error collecting system metrics: $($_.Exception.Message)" "ERROR"
    }
    
    return $metrics
}

function Get-TaskMetrics {
    $taskMetrics = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        queue = @{
            total_tasks = 0
            high_priority = 0
            medium_priority = 0
            low_priority = 0
            pending = 0
            in_progress = 0
            completed = 0
            failed = 0
        }
        processing = @{
            tasks_processed_today = 0
            average_processing_time = 0
            success_rate = 0
        }
        ecrr = @{
            total_reports = 0
            working_reports = 0
            reviewed_reports = 0
            reports_converted_today = 0
        }
    }
    
    try {
        # Task queue metrics
        $taskQueueDir = ".agent\task_queue\unified"
        if (Test-Path $taskQueueDir) {
            $tasks = Get-ChildItem $taskQueueDir -Filter "*.json"
            $taskMetrics.queue.total_tasks = $tasks.Count
            
            foreach ($task in $tasks) {
                $taskContent = Get-Content $task.FullName -Raw | ConvertFrom-Json
                
                # Priority counts
                switch ($taskContent.priority) {
                    "H" { $taskMetrics.queue.high_priority++ }
                    "M" { $taskMetrics.queue.medium_priority++ }
                    "L" { $taskMetrics.queue.low_priority++ }
                }
                
                # Status counts
                switch ($taskContent.status) {
                    "pending" { $taskMetrics.queue.pending++ }
                    "in-progress" { $taskMetrics.queue.in_progress++ }
                    "completed" { $taskMetrics.queue.completed++ }
                    "failed" { $taskMetrics.queue.failed++ }
                }
            }
        }
        
        # ECRR metrics
        $ecrrDir = "docs\ECRR_REPORTS"
        if (Test-Path $ecrrDir) {
            $allReports = Get-ChildItem $ecrrDir -Filter "*.md" -Recurse
            $taskMetrics.ecrr.total_reports = $allReports.Count
            
            $workingReports = Get-ChildItem "$ecrrDir\working" -Filter "*.md" -ErrorAction SilentlyContinue
            $taskMetrics.ecrr.working_reports = if ($workingReports) { $workingReports.Count } else { 0 }
            
            $reviewedReports = Get-ChildItem "$ecrrDir\reviewed" -Filter "*.md" -ErrorAction SilentlyContinue
            $taskMetrics.ecrr.reviewed_reports = if ($reviewedReports) { $reviewedReports.Count } else { 0 }
        }
        
    }
    catch {
        Write-Log "Error collecting task metrics: $($_.Exception.Message)" "ERROR"
    }
    
    return $taskMetrics
}

function Get-AutomationMetrics {
    $automationMetrics = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        jobs = @{
            total_jobs = 0
            running_jobs = 0
            failed_jobs = 0
            completed_jobs = 0
        }
        schedules = @{
            task_generation_enabled = $false
            task_processing_enabled = $false
            health_check_enabled = $false
            daily_status_enabled = $false
        }
        performance = @{
            average_job_runtime = 0
            job_success_rate = 0
            last_execution_time = $null
        }
    }
    
    try {
        # Job metrics
        $jobs = Get-Job
        $automationMetrics.jobs.total_jobs = $jobs.Count
        $automationMetrics.jobs.running_jobs = ($jobs | Where-Object { $_.State -eq "Running" }).Count
        $automationMetrics.jobs.failed_jobs = ($jobs | Where-Object { $_.State -eq "Failed" }).Count
        $automationMetrics.jobs.completed_jobs = ($jobs | Where-Object { $_.State -eq "Completed" }).Count
        
        # Schedule metrics
        $schedulesDir = ".agent\schedules"
        $automationMetrics.schedules.task_generation_enabled = Test-Path "$schedulesDir\task-generation.ps1"
        $automationMetrics.schedules.task_processing_enabled = Test-Path "$schedulesDir\task-processing.ps1"
        $automationMetrics.schedules.health_check_enabled = Test-Path "$schedulesDir\health-check.ps1"
        $automationMetrics.schedules.daily_status_enabled = Test-Path "$schedulesDir\daily-status.ps1"
        
    }
    catch {
        Write-Log "Error collecting automation metrics: $($_.Exception.Message)" "ERROR"
    }
    
    return $automationMetrics
}

function Monitor-Performance {
    param([int]$Duration, [int]$Interval)
    
    Write-Log "Starting performance monitoring (Duration: $Duration minutes, Interval: $Interval seconds)"
    
    $startTime = Get-Date
    $endTime = $startTime.AddMinutes($Duration)
    $metricsHistory = @()
    
    do {
        $currentTime = Get-Date
        
        # Collect metrics
        $systemMetrics = Get-SystemMetrics
        $taskMetrics = Get-TaskMetrics
        $automationMetrics = Get-AutomationMetrics
        
        $combinedMetrics = @{
            timestamp = $currentTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
            system = $systemMetrics
            tasks = $taskMetrics
            automation = $automationMetrics
        }
        
        $metricsHistory += $combinedMetrics
        
        # Display current metrics
        Write-Host "`n=== Performance Metrics ($($currentTime.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan
        Write-Host "CPU: $($systemMetrics.cpu.usage_percent)% | Memory: $($systemMetrics.memory.usage_percent)% | Disk: $($systemMetrics.disk.usage_percent)%" -ForegroundColor Green
        Write-Host "Tasks: $($taskMetrics.queue.total_tasks) total ($($taskMetrics.queue.high_priority)H, $($taskMetrics.queue.medium_priority)M, $($taskMetrics.queue.low_priority)L)" -ForegroundColor Yellow
        Write-Host "Jobs: $($automationMetrics.jobs.running_jobs) running, $($automationMetrics.jobs.failed_jobs) failed" -ForegroundColor $(if ($automationMetrics.jobs.failed_jobs -gt 0) { "Red" } else { "Green" })
        
        # Save metrics
        if (-not (Test-Path $MetricsDir)) {
            New-Item -ItemType Directory -Path $MetricsDir -Force | Out-Null
        }
        
        $metricsFile = "$MetricsDir/performance-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $combinedMetrics | ConvertTo-Json -Depth 10 | Out-File $metricsFile -Encoding utf8
        
        # Check for alerts
        if ($systemMetrics.cpu.usage_percent -gt 80) {
            Write-Log "High CPU usage detected: $($systemMetrics.cpu.usage_percent)%" "WARNING"
        }
        
        if ($systemMetrics.memory.usage_percent -gt 85) {
            Write-Log "High memory usage detected: $($systemMetrics.memory.usage_percent)%" "WARNING"
        }
        
        if ($systemMetrics.disk.usage_percent -gt 90) {
            Write-Log "High disk usage detected: $($systemMetrics.disk.usage_percent)%" "WARNING"
        }
        
        if ($automationMetrics.jobs.failed_jobs -gt 0) {
            Write-Log "Failed automation jobs detected: $($automationMetrics.jobs.failed_jobs)" "ERROR"
        }
        
        # Wait for next interval
        Start-Sleep $Interval
        
    } while ($currentTime -lt $endTime)
    
    Write-Log "Performance monitoring completed. Collected $($metricsHistory.Count) metric samples."
    
    # Save summary
    $summary = @{
        monitoring_start = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        monitoring_end = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        duration_minutes = $Duration
        interval_seconds = $Interval
        samples_collected = $metricsHistory.Count
        metrics_history = $metricsHistory
    }
    
    $summary | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
    Write-Log "Performance metrics saved to $OutputPath"
}

function Generate-PerformanceReport {
    Write-Log "Generating performance report"
    
    # Collect current metrics
    $systemMetrics = Get-SystemMetrics
    $taskMetrics = Get-TaskMetrics
    $automationMetrics = Get-AutomationMetrics
    
    $report = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        summary = @{
            system_health = @{
                cpu_usage = $systemMetrics.cpu.usage_percent
                memory_usage = $systemMetrics.memory.usage_percent
                disk_usage = $systemMetrics.disk.usage_percent
                overall_health = if ($systemMetrics.cpu.usage_percent -lt 80 -and $systemMetrics.memory.usage_percent -lt 85 -and $systemMetrics.disk.usage_percent -lt 90) { "HEALTHY" } else { "DEGRADED" }
            }
            task_processing = @{
                total_tasks = $taskMetrics.queue.total_tasks
                high_priority_backlog = $taskMetrics.queue.high_priority
                processing_status = if ($taskMetrics.queue.high_priority -gt 5) { "BACKLOG" } else { "NORMAL" }
            }
            automation = @{
                jobs_running = $automationMetrics.jobs.running_jobs
                jobs_failed = $automationMetrics.jobs.failed_jobs
                automation_status = if ($automationMetrics.jobs.failed_jobs -gt 0) { "DEGRADED" } else { "HEALTHY" }
            }
        }
        detailed_metrics = @{
            system = $systemMetrics
            tasks = $taskMetrics
            automation = $automationMetrics
        }
    }
    
    $reportPath = "artifacts/performance-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding utf8
    
    Write-Log "Performance report generated: $reportPath"
    
    # Display summary
    Write-Host "`n=== Performance Report Summary ===" -ForegroundColor Cyan
    Write-Host "System Health: $($report.summary.system_health.overall_health)" -ForegroundColor $(if ($report.summary.system_health.overall_health -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "Task Processing: $($report.summary.task_processing.processing_status)" -ForegroundColor $(if ($report.summary.task_processing.processing_status -eq "NORMAL") { "Green" } else { "Yellow" })
    Write-Host "Automation: $($report.summary.automation.automation_status)" -ForegroundColor $(if ($report.summary.automation.automation_status -eq "HEALTHY") { "Green" } else { "Red" })
    
    return $report
}

function Get-PerformanceStatus {
    $status = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        monitoring = @{
            active = $false
            duration_minutes = 0
            samples_collected = 0
        }
        system = @{
            health_score = 0
            alerts = @()
        }
        performance = @{
            cpu_usage = 0
            memory_usage = 0
            disk_usage = 0
        }
    }
    
    # Check for active monitoring
    $monitoringJobs = Get-Job | Where-Object { $_.Name -like "*performance*" }
    if ($monitoringJobs.Count -gt 0) {
        $status.monitoring.active = $true
        $status.monitoring.duration_minutes = $DurationMinutes
    }
    
    # Get current metrics
    $systemMetrics = Get-SystemMetrics
    $status.performance.cpu_usage = $systemMetrics.cpu.usage_percent
    $status.performance.memory_usage = $systemMetrics.memory.usage_percent
    $status.performance.disk_usage = $systemMetrics.disk.usage_percent
    
    # Calculate health score
    $healthScore = 100
    if ($systemMetrics.cpu.usage_percent -gt 80) { $healthScore -= 20; $status.system.alerts += "High CPU usage" }
    if ($systemMetrics.memory.usage_percent -gt 85) { $healthScore -= 20; $status.system.alerts += "High memory usage" }
    if ($systemMetrics.disk.usage_percent -gt 90) { $healthScore -= 20; $status.system.alerts += "High disk usage" }
    
    $status.system.health_score = $healthScore
    
    return $status
}

# Main execution
Write-Log "Performance Monitor for Production Operations"
Write-Log "Action: $Action, Duration: $DurationMinutes minutes, Interval: $IntervalSeconds seconds"

switch ($Action) {
    "monitor" {
        Monitor-Performance -Duration $DurationMinutes -Interval $IntervalSeconds
    }
    "report" {
        Generate-PerformanceReport
    }
    "alert" {
        $systemMetrics = Get-SystemMetrics
        $alerts = @()
        
        if ($systemMetrics.cpu.usage_percent -gt 80) {
            $alerts += "High CPU usage: $($systemMetrics.cpu.usage_percent)%"
        }
        
        if ($systemMetrics.memory.usage_percent -gt 85) {
            $alerts += "High memory usage: $($systemMetrics.memory.usage_percent)%"
        }
        
        if ($systemMetrics.disk.usage_percent -gt 90) {
            $alerts += "High disk usage: $($systemMetrics.disk.usage_percent)%"
        }
        
        if ($alerts.Count -gt 0) {
            foreach ($alert in $alerts) {
                Write-Log "PERFORMANCE ALERT: $alert" "WARNING"
            }
        } else {
            Write-Log "No performance alerts detected" "INFO"
        }
    }
    "status" {
        $status = Get-PerformanceStatus
        $status | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
        Write-Log "Performance status saved to $OutputPath"
        
        Write-Host "`n=== Performance Status ===" -ForegroundColor Cyan
        Write-Host "Health Score: $($status.system.health_score)/100" -ForegroundColor $(if ($status.system.health_score -ge 80) { "Green" } else { "Red" })
        Write-Host "CPU: $($status.performance.cpu_usage)% | Memory: $($status.performance.memory_usage)% | Disk: $($status.performance.disk_usage)%" -ForegroundColor Yellow
        if ($status.system.alerts.Count -gt 0) {
            Write-Host "Alerts: $($status.system.alerts -join ', ')" -ForegroundColor Red
        }
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Performance monitoring operation completed"
