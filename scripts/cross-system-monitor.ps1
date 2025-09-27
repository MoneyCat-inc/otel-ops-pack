# Cross-System Task Management and Monitoring
# Monitors ECRR reports and agent tasks for automated processing

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("monitor", "generate", "sync", "status", "dashboard")]
    [string]$Action = "monitor",
    
    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 300,
    
    [Parameter(Mandatory=$false)]
    [switch]$Continuous,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "artifacts/cross-system-monitor.json"
)

$EcrrReportsDir = "docs\ECRR_REPORTS"
$TaskQueueDir = ".agent\task_queue\unified"
$WorkingDir = "$EcrrReportsDir\working"
$ReviewedDir = "$EcrrReportsDir\reviewed"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-EcrrReports {
    param([string]$Directory)
    
    if (-not (Test-Path $Directory)) {
        return @()
    }
    
    $reports = Get-ChildItem $Directory -Filter "*.md" | Where-Object { 
        $_.Name -notlike "*INDEX*" -and 
        $_.Name -notlike "*LEDGER*" -and
        $_.Name -notlike "*README*"
    }
    
    return $reports
}

function Get-AgentTasks {
    param([string]$Directory)
    
    if (-not (Test-Path $Directory)) {
        return @()
    }
    
    $tasks = Get-ChildItem $Directory -Filter "*.json"
    return $tasks
}

function Convert-EcrrToTask {
    param([string]$ReportPath, [string]$Type = "remediation", [string]$Priority = "M")
    
    try {
        $reportName = [System.IO.Path]::GetFileNameWithoutExtension($ReportPath)
        Write-Log "Converting ECRR report to task: $reportName"
        
        # Use the bridge script to convert
        $result = pwsh -File scripts/ecrr-to-agent.ps1 -Report $ReportPath -Type $Type -Priority $Priority -AssignedTo "codex" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully converted ECRR report to agent task" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to convert ECRR report: $result" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Exception during ECRR to task conversion: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Convert-TaskToEcrr {
    param([string]$TaskId, [string]$ReportType = "implementation", [string]$Impact = "medium")
    
    try {
        Write-Log "Converting agent task to ECRR report: $TaskId"
        
        # Use the bridge script to convert
        $result = pwsh -File .agent/scripts/agent-to-ecrr.ps1 -Task $TaskId -ReportType $ReportType -Impact $Impact 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully converted agent task to ECRR report" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to convert agent task: $result" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Exception during task to ECRR conversion: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-SystemStatus {
    $status = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        ecrr = @{
            working_reports = 0
            reviewed_reports = 0
            total_reports = 0
        }
        agent = @{
            pending_tasks = 0
            total_tasks = 0
        }
        bridge = @{
            conversions_today = 0
            last_conversion = $null
        }
        health = @{
            ecrr_system = "unknown"
            agent_system = "unknown"
            bridge_system = "unknown"
        }
    }
    
    # Count ECRR reports
    $workingReports = Get-EcrrReports $WorkingDir
    $reviewedReports = Get-EcrrReports $ReviewedDir
    $status.ecrr.working_reports = $workingReports.Count
    $status.ecrr.reviewed_reports = $reviewedReports.Count
    $status.ecrr.total_reports = $workingReports.Count + $reviewedReports.Count
    
    # Count agent tasks
    $agentTasks = Get-AgentTasks $TaskQueueDir
    $status.agent.total_tasks = $agentTasks.Count
    $status.agent.pending_tasks = ($agentTasks | Where-Object { 
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending"
    }).Count
    
    # Check ECRR system health
    try {
        $ecrrStatus = pwsh -File scripts/ecrr-command.ps1 -Action status 2>&1
        if ($LASTEXITCODE -eq 0) {
            $status.health.ecrr_system = "healthy"
        } else {
            $status.health.ecrr_system = "degraded"
        }
    }
    catch {
        $status.health.ecrr_system = "error"
    }
    
    # Check agent system health
    if (Test-Path $TaskQueueDir) {
        $status.health.agent_system = "healthy"
    } else {
        $status.health.agent_system = "error"
    }
    
    # Check bridge system health
    if ((Test-Path "scripts/ecrr-to-agent.ps1") -and (Test-Path ".agent/scripts/agent-to-ecrr.ps1")) {
        $status.health.bridge_system = "healthy"
    } else {
        $status.health.bridge_system = "error"
    }
    
    return $status
}

function Monitor-Systems {
    param([int]$Interval, [bool]$Continuous)
    
    Write-Log "Starting cross-system monitoring (Interval: $Interval seconds, Continuous: $Continuous)"
    
    do {
        $status = Get-SystemStatus
        
        # Display current status
        Write-Host "`n=== Cross-System Status ===" -ForegroundColor Cyan
        Write-Host "ECRR Reports: $($status.ecrr.total_reports) total ($($status.ecrr.working_reports) working, $($status.ecrr.reviewed_reports) reviewed)" -ForegroundColor Green
        Write-Host "Agent Tasks: $($status.agent.total_tasks) total ($($status.agent.pending_tasks) pending)" -ForegroundColor Green
        Write-Host "System Health: ECRR=$($status.health.ecrr_system), Agent=$($status.health.agent_system), Bridge=$($status.health.bridge_system)" -ForegroundColor Yellow
        
        # Check for new working reports that need conversion
        $workingReports = Get-EcrrReports $WorkingDir
        if ($workingReports.Count -gt 0) {
            Write-Host "`nFound $($workingReports.Count) working ECRR reports:" -ForegroundColor Yellow
            foreach ($report in $workingReports) {
                Write-Host "  - $($report.Name)" -ForegroundColor White
            }
        }
        
        # Check for pending tasks that might need ECRR reports
        $pendingTasks = Get-AgentTasks $TaskQueueDir | Where-Object {
            $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $content.status -eq "pending"
        }
        
        if ($pendingTasks.Count -gt 0) {
            Write-Host "`nFound $($pendingTasks.Count) pending agent tasks:" -ForegroundColor Yellow
            foreach ($task in $pendingTasks) {
                $content = Get-Content $task.FullName -Raw | ConvertFrom-Json
                Write-Host "  - $($content.id): $($content.title) (Priority: $($content.priority))" -ForegroundColor White
            }
        }
        
        # Save status to file
        $status | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
        
        if ($Continuous) {
            Write-Host "`nWaiting $Interval seconds for next check..." -ForegroundColor Gray
            Start-Sleep $Interval
        }
        
    } while ($Continuous)
    
    Write-Log "Cross-system monitoring completed"
}

function Generate-TasksFromEcrr {
    Write-Log "Generating agent tasks from ECRR reports"
    
    $workingReports = Get-EcrrReports $WorkingDir
    $converted = 0
    
    foreach ($report in $workingReports) {
        Write-Log "Processing ECRR report: $($report.Name)"
        
        # Determine task type and priority based on report content
        $content = Get-Content $report.FullName -Raw
        $type = "remediation"
        $priority = "M"
        
        if ($content -match "alert|monitoring|canary") {
            $type = "alert"
            $priority = "H"
        } elseif ($content -match "maintenance|cleanup|optimization") {
            $type = "maintenance"
            $priority = "M"
        } elseif ($content -match "review|analysis|audit") {
            $type = "review"
            $priority = "L"
        }
        
        if (Convert-EcrrToTask -ReportPath $report.FullName -Type $type -Priority $priority) {
            $converted++
        }
    }
    
    Write-Log "Generated $converted agent tasks from ECRR reports" "SUCCESS"
    return $converted
}

function Sync-Status {
    Write-Log "Synchronizing status between ECRR and Agent systems"
    
    # Get current status
    $status = Get-SystemStatus
    
    # Update ECRR system
    try {
        pwsh -File scripts/ecrr-command.ps1 -Action RegenerateIndex 2>&1 | Out-Null
        Write-Log "ECRR index regenerated" "SUCCESS"
    }
    catch {
        Write-Log "Failed to regenerate ECRR index: $($_.Exception.Message)" "ERROR"
    }
    
    # Update agent system status
    $status | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
    Write-Log "Cross-system status synchronized" "SUCCESS"
}

function Show-Dashboard {
    $status = Get-SystemStatus
    
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    Cross-System Dashboard                    ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # ECRR System Status
    $ecrrColor = if ($status.health.ecrr_system -eq "healthy") { "Green" } else { "Red" }
    Write-Host "║ ECRR System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.ecrr_system.ToUpper())" -NoNewline -ForegroundColor $ecrrColor
    Write-Host " ($($status.ecrr.total_reports) reports)" -ForegroundColor White
    Write-Host "║   Working: $($status.ecrr.working_reports) | Reviewed: $($status.ecrr.reviewed_reports)" -ForegroundColor Gray
    
    # Agent System Status
    $agentColor = if ($status.health.agent_system -eq "healthy") { "Green" } else { "Red" }
    Write-Host "║ Agent System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.agent_system.ToUpper())" -NoNewline -ForegroundColor $agentColor
    Write-Host " ($($status.agent.total_tasks) tasks)" -ForegroundColor White
    Write-Host "║   Pending: $($status.agent.pending_tasks)" -ForegroundColor Gray
    
    # Bridge System Status
    $bridgeColor = if ($status.health.bridge_system -eq "healthy") { "Green" } else { "Red" }
    Write-Host "║ Bridge System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.bridge_system.ToUpper())" -NoNewline -ForegroundColor $bridgeColor
    Write-Host " (Bidirectional sync)" -ForegroundColor White
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Recent Activity
    Write-Host "║ Recent Activity:" -ForegroundColor White
    Write-Host "║   Conversions Today: $($status.bridge.conversions_today)" -ForegroundColor Gray
    if ($status.bridge.last_conversion) {
        Write-Host "║   Last Conversion: $($status.bridge.last_conversion)" -ForegroundColor Gray
    }
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Quick Actions
    Write-Host "║ Quick Actions:" -ForegroundColor White
    Write-Host "║   Generate Tasks: pwsh -File scripts/cross-system-monitor.ps1 -Action generate" -ForegroundColor Gray
    Write-Host "║   Monitor: pwsh -File scripts/cross-system-monitor.ps1 -Action monitor -Continuous" -ForegroundColor Gray
    Write-Host "║   Sync Status: pwsh -File scripts/cross-system-monitor.ps1 -Action sync" -ForegroundColor Gray
    
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
Write-Log "Cross-System Task Management and Monitoring"
Write-Log "Action: $Action, Interval: $IntervalSeconds seconds, Continuous: $Continuous"

switch ($Action) {
    "monitor" {
        Monitor-Systems -Interval $IntervalSeconds -Continuous $Continuous
    }
    "generate" {
        Generate-TasksFromEcrr
    }
    "sync" {
        Sync-Status
    }
    "status" {
        $status = Get-SystemStatus
        $status | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
        Write-Log "Status saved to $OutputPath"
    }
    "dashboard" {
        Show-Dashboard
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Cross-system task management completed"
