# Cross-System Alerts and Notifications
# Monitors ECRR-Agent bridge for failures and generates alerts

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("monitor", "alert", "test", "status")]
    [string]$Action = "monitor",
    
    [Parameter(Mandatory=$false)]
    [int]$ThresholdMinutes = 60,
    
    [Parameter(Mandatory=$false)]
    [string]$AlertChannel = "console",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$TaskQueueDir = ".agent\task_queue\unified"
$EcrrReportsDir = "docs\ECRR_REPORTS"
$AlertsDir = "alerts"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Send-Alert {
    param([string]$Message, [string]$Severity = "warning", [string]$Channel = "console")
    
    $alert = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        severity = $Severity
        message = $Message
        channel = $Channel
        source = "cross-system-monitor"
    }
    
    switch ($Channel) {
        "console" {
            $color = switch ($Severity) {
                "critical" { "Red" }
                "error" { "Red" }
                "warning" { "Yellow" }
                "info" { "Cyan" }
                default { "White" }
            }
            Write-Host "🚨 ALERT [$($severity.ToUpper())]: $Message" -ForegroundColor $color
        }
        "file" {
            $alertFile = Join-Path $AlertsDir "alert-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            if (-not (Test-Path $AlertsDir)) {
                New-Item -ItemType Directory -Path $AlertsDir -Force | Out-Null
            }
            $alert | ConvertTo-Json -Depth 10 | Out-File $alertFile -Encoding utf8
            Write-Log "Alert saved to $alertFile"
        }
        "signoz" {
            # Send to SigNoz via OTLP
            try {
                $logEntry = @{
                    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    severity = $Severity
                    message = $Message
                    source = "cross-system-monitor"
                    alert_type = "bridge_monitoring"
                }
                
                $otlpPayload = @{
                    resourceLogs = @(
                        @{
                            resource = @{
                                attributes = @(
                                    @{ key = "service.name"; value = @{ stringValue = "cross-system-monitor" } }
                                    @{ key = "service.version"; value = @{ stringValue = "1.0.0" } }
                                )
                            }
                            scopeLogs = @(
                                @{
                                    scope = @{ name = "cross-system-monitor" }
                                    logRecords = @(
                                        @{
                                            timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                            severityText = $Severity.ToUpper()
                                            body = @{ stringValue = $Message }
                                            attributes = @(
                                                @{ key = "alert.type"; value = @{ stringValue = "bridge_monitoring" } }
                                                @{ key = "alert.severity"; value = @{ stringValue = $Severity } }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                
                $jsonPayload = $otlpPayload | ConvertTo-Json -Depth 10
                $response = Invoke-RestMethod -Uri "http://localhost:5318/v1/logs" -Method Post -Body $jsonPayload -ContentType "application/json"
                Write-Log "Alert sent to SigNoz successfully"
            }
            catch {
                Write-Log "Failed to send alert to SigNoz: $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    return $alert
}

function Monitor-BridgeHealth {
    $issues = @()
    
    # Check ECRR system health
    try {
        $ecrrStatus = pwsh -File scripts/ecrr-command.ps1 -Action status 2>&1
        if ($LASTEXITCODE -ne 0) {
            $issues += "ECRR system unhealthy: $ecrrStatus"
        }
    }
    catch {
        $issues += "ECRR system error: $($_.Exception.Message)"
    }
    
    # Check agent system health
    if (-not (Test-Path $TaskQueueDir)) {
        $issues += "Agent task queue directory missing"
    }
    
    # Check bridge scripts
    if (-not (Test-Path "scripts/ecrr-to-agent.ps1")) {
        $issues += "ECRR to Agent bridge script missing"
    }
    
    if (-not (Test-Path ".agent/scripts/agent-to-ecrr.ps1")) {
        $issues += "Agent to ECRR bridge script missing"
    }
    
    # Check for stuck tasks
    $stuckTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($content.status -eq "in-progress" -and $content.started_at) {
            $startedAt = [DateTime]::Parse($content.started_at)
            $elapsed = (Get-Date) - $startedAt
            $elapsed.TotalMinutes -gt $ThresholdMinutes
        } else {
            $false
        }
    }
    
    if ($stuckTasks.Count -gt 0) {
        $issues += "Found $($stuckTasks.Count) stuck tasks (running > $ThresholdMinutes minutes)"
    }
    
    return $issues
}

function Monitor-TaskProcessing {
    $alerts = @()
    
    # Check for high-priority pending tasks
    $highPriorityTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending" -and $content.priority -eq "H"
    }
    
    if ($highPriorityTasks.Count -gt 5) {
        $alerts += Send-Alert -Message "High priority task backlog: $($highPriorityTasks.Count) H-priority tasks pending" -Severity "warning"
    }
    
    # Check for overdue tasks
    $overdueTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($content.deadline) {
            $deadline = [DateTime]::Parse($content.deadline)
            $deadline -lt (Get-Date)
        } else {
            $false
        }
    }
    
    if ($overdueTasks.Count -gt 0) {
        $alerts += Send-Alert -Message "Overdue tasks detected: $($overdueTasks.Count) tasks past deadline" -Severity "error"
    }
    
    # Check for failed tasks
    $failedTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "failed"
    }
    
    if ($failedTasks.Count -gt 0) {
        $alerts += Send-Alert -Message "Failed tasks detected: $($failedTasks.Count) tasks failed validation" -Severity "error"
    }
    
    return $alerts
}

function Monitor-ECRRReports {
    $alerts = @()
    
    # Check for working reports that haven't been converted
    $workingDir = "$EcrrReportsDir\working"
    if (Test-Path $workingDir) {
        $workingReports = Get-ChildItem $workingDir -Filter "*.md" | Where-Object {
            $_.Name -notlike "*INDEX*" -and $_.Name -notlike "*LEDGER*"
        }
        
        if ($workingReports.Count -gt 3) {
            $alerts += Send-Alert -Message "ECRR working reports backlog: $($workingReports.Count) reports need task generation" -Severity "warning"
        }
    }
    
    # Check for reports without corresponding tasks
    $reviewedDir = "$EcrrReportsDir\reviewed"
    if (Test-Path $reviewedDir) {
        $reviewedReports = Get-ChildItem $reviewedDir -Filter "*.md" | Where-Object {
            $_.Name -notlike "*INDEX*" -and $_.Name -notlike "*LEDGER*"
        }
        
        # Check if reports have corresponding tasks
        $reportsWithoutTasks = 0
        foreach ($report in $reviewedReports) {
            $reportName = $report.BaseName
            $correspondingTask = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
                $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $content.ecrr_report_id -eq $reportName
            }
            
            if (-not $correspondingTask) {
                $reportsWithoutTasks++
            }
        }
        
        if ($reportsWithoutTasks -gt 5) {
            $alerts += Send-Alert -Message "ECRR reports without tasks: $reportsWithoutTasks reports need task generation" -Severity "info"
        }
    }
    
    return $alerts
}

function Test-AlertSystem {
    Write-Log "Testing alert system"
    
    $testAlerts = @(
        @{ Message = "Test info alert"; Severity = "info" }
        @{ Message = "Test warning alert"; Severity = "warning" }
        @{ Message = "Test error alert"; Severity = "error" }
        @{ Message = "Test critical alert"; Severity = "critical" }
    )
    
    foreach ($testAlert in $testAlerts) {
        Send-Alert -Message $testAlert.Message -Severity $testAlert.Severity -Channel $AlertChannel
        Start-Sleep 1
    }
    
    Write-Log "Alert system test completed"
}

function Get-AlertStatus {
    $status = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        bridge_health = @{
            ecrr_system = "unknown"
            agent_system = "unknown"
            bridge_scripts = "unknown"
            stuck_tasks = 0
        }
        task_processing = @{
            high_priority_pending = 0
            overdue_tasks = 0
            failed_tasks = 0
        }
        ecrr_reports = @{
            working_reports = 0
            reports_without_tasks = 0
        }
        alerts_generated = 0
    }
    
    # Check bridge health
    $healthIssues = Monitor-BridgeHealth
    $status.bridge_health.ecrr_system = if ($healthIssues -match "ECRR") { "unhealthy" } else { "healthy" }
    $status.bridge_health.agent_system = if ($healthIssues -match "Agent") { "unhealthy" } else { "healthy" }
    $status.bridge_health.bridge_scripts = if ($healthIssues -match "bridge script") { "missing" } else { "present" }
    $status.bridge_health.stuck_tasks = ($healthIssues -match "stuck tasks").Count
    
    # Check task processing
    $highPriorityTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending" -and $content.priority -eq "H"
    }
    $status.task_processing.high_priority_pending = $highPriorityTasks.Count
    
    $overdueTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($content.deadline) {
            $deadline = [DateTime]::Parse($content.deadline)
            $deadline -lt (Get-Date)
        } else {
            $false
        }
    }
    $status.task_processing.overdue_tasks = $overdueTasks.Count
    
    $failedTasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "failed"
    }
    $status.task_processing.failed_tasks = $failedTasks.Count
    
    # Check ECRR reports
    $workingDir = "$EcrrReportsDir\working"
    if (Test-Path $workingDir) {
        $workingReports = Get-ChildItem $workingDir -Filter "*.md" | Where-Object {
            $_.Name -notlike "*INDEX*" -and $_.Name -notlike "*LEDGER*"
        }
        $status.ecrr_reports.working_reports = $workingReports.Count
    }
    
    return $status
}

# Main execution
Write-Log "Cross-System Alerts and Notifications"
Write-Log "Action: $Action, Threshold: $ThresholdMinutes minutes, Channel: $AlertChannel, DryRun: $DryRun"

switch ($Action) {
    "monitor" {
        Write-Log "Monitoring cross-system health and generating alerts"
        
        $alerts = @()
        
        # Monitor bridge health
        $healthIssues = Monitor-BridgeHealth
        foreach ($issue in $healthIssues) {
            $alerts += Send-Alert -Message $issue -Severity "error" -Channel $AlertChannel
        }
        
        # Monitor task processing
        $taskAlerts = Monitor-TaskProcessing
        $alerts += $taskAlerts
        
        # Monitor ECRR reports
        $reportAlerts = Monitor-ECRRReports
        $alerts += $reportAlerts
        
        Write-Log "Monitoring completed: $($alerts.Count) alerts generated"
    }
    "alert" {
        $message = "Manual alert from cross-system monitor"
        $alert = Send-Alert -Message $message -Severity "info" -Channel $AlertChannel
        Write-Log "Manual alert sent"
    }
    "test" {
        Test-AlertSystem
    }
    "status" {
        $status = Get-AlertStatus
        $status | ConvertTo-Json -Depth 10 | Out-File "artifacts/alert-status.json" -Encoding utf8
        Write-Log "Alert status saved to artifacts/alert-status.json"
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Cross-system alert monitoring completed"
