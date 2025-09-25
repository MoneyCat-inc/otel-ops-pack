# OTel One-Glance Status Script
# ECRR Compliant: Examine → Clean → Report → Role

param(
    [string]$ReportPath = "artifacts/status-report.json"
)

# ECRR: Examine - Capture system state
$examineStart = Get-Date
$statusReport = @{
    timestamp = $examineStart.ToString("yyyy-MM-dd HH:mm:ss")
    examine = @{}
    clean = @{}
    report = @{}
    role = "OTel Status Monitor"
}

Write-Host "🔍 ECRR Examine: Capturing OTel system status..." -ForegroundColor Cyan

# 1. C: Drive Free Space
$drive = Get-Volume -DriveLetter C
$freeSpaceGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
$totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
$freeSpacePercent = [math]::Round(($drive.SizeRemaining / $drive.Size) * 100, 1)

Write-Host "💾 C: Drive: $freeSpaceGB GB free ($freeSpacePercent%) of $totalSpaceGB GB" -ForegroundColor $(if ($freeSpacePercent -lt 20) { "Red" } elseif ($freeSpacePercent -lt 35) { "Yellow" } else { "Green" })

# 2. Top 10 Largest Directories under artifacts
$artifactsPath = Join-Path $PSScriptRoot "..\artifacts"
$topDirs = @()
if (Test-Path $artifactsPath) {
    $topDirs = Get-ChildItem $artifactsPath -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum).Sum
        [PSCustomObject]@{
            Name = $_.Name
            SizeGB = [math]::Round($size / 1GB, 2)
            Path = $_.FullName
        }
    } | Sort-Object SizeGB -Descending | Select-Object -First 10
}

Write-Host "📁 Top Artifacts Directories:" -ForegroundColor Cyan
if ($topDirs.Count -gt 0) {
    $topDirs | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeGB) GB" -ForegroundColor White }
} else {
    Write-Host "  No artifacts directories found" -ForegroundColor Yellow
}

# 3. Scheduled Task Last Results
Write-Host "⏰ Scheduled Tasks Status:" -ForegroundColor Cyan
$tasks = Get-ScheduledTask -TaskName *otel* | Get-ScheduledTaskInfo | Select TaskName, LastRunTime, LastTaskResult, NextRunTime
$successTasks = $tasks | Where-Object { $_.LastTaskResult -eq 0 }
$failedTasks = $tasks | Where-Object { $_.LastTaskResult -ne 0 }

Write-Host "  ✅ Successful: $($successTasks.Count)" -ForegroundColor Green
Write-Host "  ❌ Failed: $($failedTasks.Count)" -ForegroundColor Red

if ($failedTasks.Count -gt 0) {
    Write-Host "  Failed Tasks:" -ForegroundColor Red
    $failedTasks | ForEach-Object { 
        Write-Host "    $($_.TaskName): $($_.LastTaskResult)" -ForegroundColor Yellow 
    }
}

# 4. Docker SigNoz Stack Status
Write-Host "🐳 Docker SigNoz Stack:" -ForegroundColor Cyan
try {
    $dockerContainers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
    if ($dockerContainers) {
        $dockerContainers | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        # Check specific services
        $signozHealthy = $dockerContainers | Select-String "signoz.*healthy"
        $collectorRunning = $dockerContainers | Select-String "otel-collector"
        $gpuServices = $dockerContainers | Select-String "gpu.*healthy"
        
        Write-Host "  SigNoz UI: $(if ($signozHealthy) { '✅ Healthy' } else { '❌ Unhealthy' })" -ForegroundColor $(if ($signozHealthy) { "Green" } else { "Red" })
        Write-Host "  OTel Collector: $(if ($collectorRunning) { '✅ Running' } else { '❌ Not Running' })" -ForegroundColor $(if ($collectorRunning) { "Green" } else { "Red" })
        Write-Host "  GPU Services: $($gpuServices.Count) healthy" -ForegroundColor $(if ($gpuServices.Count -eq 3) { "Green" } else { "Yellow" })
    } else {
        Write-Host "  ❌ Docker not responding" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Docker check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Collector Log Analysis (last 100 lines filtered for errors/warnings)
Write-Host "📋 Collector Log Analysis:" -ForegroundColor Cyan
try {
    $logLines = docker logs signoz-otel-collector --tail 100 2>$null
    if ($logLines) {
        $errorLines = $logLines | Select-String -Pattern "error|warn|fail" -CaseSensitive:$false
        $errorCount = $errorLines.Count
        
        Write-Host "  Recent Errors/Warnings: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Yellow" })
        
        if ($errorCount -gt 0) {
            Write-Host "  Recent Issues:" -ForegroundColor Yellow
            $errorLines | Select-Object -First 5 | ForEach-Object { 
                Write-Host "    $($_.Line.Trim())" -ForegroundColor Yellow 
            }
        }
    } else {
        Write-Host "  ❌ No collector logs available" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Log analysis failed: $($_.Exception.Message)" -ForegroundColor Red
}

# ECRR: Clean - Identify issues
$issues = @()
if ($freeSpacePercent -lt 20) { $issues += "Low disk space: $freeSpacePercent%" }
if ($failedTasks.Count -gt 0) { $issues += "$($failedTasks.Count) scheduled tasks failing" }
if (-not $collectorRunning) { $issues += "OTel collector not running" }
if ($gpuServices.Count -ne 3) { $issues += "GPU services unhealthy: $($gpuServices.Count)/3" }

if ($issues.Count -eq 0) {
    Write-Host "✅ No critical issues detected" -ForegroundColor Green
} else {
    Write-Host "⚠️  Issues detected:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

# ECRR: Report - Generate status report
$statusReport.examine = @{
    disk_free_gb = $freeSpaceGB
    disk_free_percent = $freeSpacePercent
    artifacts_dirs = $topDirs.Count
    scheduled_tasks_total = $tasks.Count
    scheduled_tasks_success = $successTasks.Count
    scheduled_tasks_failed = $failedTasks.Count
    docker_containers = $dockerContainers.Count
    signoz_healthy = $signozHealthy -ne $null
    collector_running = $collectorRunning -ne $null
    gpu_services_healthy = $gpuServices.Count
    recent_errors = $errorCount
}

$statusReport.clean = @{
    issues_detected = $issues.Count
    issues = $issues
}

$statusReport.report = @{
    report_path = $ReportPath
    execution_time_seconds = [math]::Round(((Get-Date) - $examineStart).TotalSeconds, 2)
    success = $true
}

# Ensure artifacts directory exists
$reportDir = Split-Path $ReportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$statusReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "📝 ECRR Report: Status report saved to $ReportPath" -ForegroundColor Green
Write-Host "🎭 ECRR Role: $($statusReport.role)" -ForegroundColor Magenta

# Summary
Write-Host "`n=== STATUS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Disk Free: $freeSpacePercent%" -ForegroundColor White
Write-Host "Tasks: $($successTasks.Count)/$($tasks.Count) successful" -ForegroundColor White
Write-Host "Services: SigNoz $(if ($signozHealthy) { '✅' } else { '❌' }), Collector $(if ($collectorRunning) { '✅' } else { '❌' }), GPU $($gpuServices.Count)/3" -ForegroundColor White
Write-Host "Issues: $($issues.Count)" -ForegroundColor White
Write-Host "Execution time: $($statusReport.report.execution_time_seconds) seconds" -ForegroundColor White
