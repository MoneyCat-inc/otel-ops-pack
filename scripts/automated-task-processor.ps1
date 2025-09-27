# Automated Task Processor
# Processes agent tasks and generates ECRR reports for completed work

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("process", "monitor", "report", "cleanup")]
    [string]$Action = "process",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId,
    
    [Parameter(Mandatory=$false)]
    [string]$Assignee = "codex",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$TaskQueueDir = ".agent\task_queue\unified"
$CompletedDir = ".agent\task_queue\completed"
$EcrrReportsDir = "docs\ECRR_REPORTS"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-PendingTasks {
    if (-not (Test-Path $TaskQueueDir)) {
        return @()
    }
    
    $tasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending"
    }
    
    return $tasks
}

function Process-Task {
    param([string]$TaskPath, [string]$Assignee, [bool]$DryRun)
    
    try {
        $taskContent = Get-Content $TaskPath -Raw | ConvertFrom-Json
        $taskId = $taskContent.id
        
        Write-Log "Processing task: $taskId - $($taskContent.title)"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would process task $taskId" "INFO"
            return $true
        }
        
        # Update task status to in-progress
        $taskContent.status = "in-progress"
        $taskContent.assigned_to = $Assignee
        $taskContent.started_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Save updated task
        $taskContent | ConvertTo-Json -Depth 10 | Out-File $TaskPath -Encoding utf8
        
        # Execute validation commands
        $validationSuccess = $true
        foreach ($command in $taskContent.validation_commands) {
            Write-Log "Executing validation: $command"
            try {
                $result = Invoke-Expression $command 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Validation failed: $command" "ERROR"
                    $validationSuccess = $false
                    break
                }
            }
            catch {
                Write-Log "Validation exception: $($_.Exception.Message)" "ERROR"
                $validationSuccess = $false
                break
            }
        }
        
        if ($validationSuccess) {
            # Mark task as completed
            $taskContent.status = "completed"
            $taskContent.completed_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            $taskContent | ConvertTo-Json -Depth 10 | Out-File $TaskPath -Encoding utf8
            
            # Move to completed directory
            if (-not (Test-Path $CompletedDir)) {
                New-Item -ItemType Directory -Path $CompletedDir -Force | Out-Null
            }
            
            $completedPath = Join-Path $CompletedDir "$taskId.json"
            Move-Item $TaskPath $completedPath
            
            Write-Log "Task completed successfully: $taskId" "SUCCESS"
            
            # Generate ECRR report for completed task
            Generate-EcrrReport -TaskId $taskId -TaskContent $taskContent
            
            return $true
        } else {
            # Mark task as failed
            $taskContent.status = "failed"
            $taskContent.failed_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            $taskContent | ConvertTo-Json -Depth 10 | Out-File $TaskPath -Encoding utf8
            
            Write-Log "Task failed validation: $taskId" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Exception processing task: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Generate-EcrrReport {
    param([string]$TaskId, [object]$TaskContent)
    
    try {
        Write-Log "Generating ECRR report for completed task: $TaskId"
        
        # Use the bridge script to convert completed task to ECRR report
        $result = pwsh -File .agent/scripts/agent-to-ecrr.ps1 -Task $TaskId -ReportType "implementation" -Impact "medium" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "ECRR report generated for task: $TaskId" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to generate ECRR report: $result" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Exception generating ECRR report: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Monitor-Tasks {
    Write-Log "Monitoring agent tasks for processing"
    
    $pendingTasks = Get-PendingTasks
    Write-Log "Found $($pendingTasks.Count) pending tasks"
    
    foreach ($task in $pendingTasks) {
        $taskContent = Get-Content $task.FullName -Raw | ConvertFrom-Json
        Write-Log "Pending: $($taskContent.id) - $($taskContent.title) (Priority: $($taskContent.priority))"
    }
    
    return $pendingTasks.Count
}

function Generate-Report {
    Write-Log "Generating task processing report"
    
    $pendingTasks = Get-PendingTasks
    $completedTasks = if (Test-Path $CompletedDir) { 
        (Get-ChildItem $CompletedDir -Filter "*.json").Count 
    } else { 0 }
    
    $report = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        summary = @{
            pending_tasks = $pendingTasks.Count
            completed_tasks = $completedTasks
            total_tasks = $pendingTasks.Count + $completedTasks
        }
        pending_tasks = @()
        recent_activity = @()
    }
    
    foreach ($task in $pendingTasks) {
        $taskContent = Get-Content $task.FullName -Raw | ConvertFrom-Json
        $report.pending_tasks += @{
            id = $taskContent.id
            title = $taskContent.title
            priority = $taskContent.priority
            assigned_to = $taskContent.assigned_to
            created_at = $taskContent.created_at
            deadline = $taskContent.deadline
        }
    }
    
    # Save report
    $reportPath = "artifacts/task-processing-report.json"
    $report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding utf8
    
    Write-Log "Task processing report saved to $reportPath"
    return $report
}

function Cleanup-OldTasks {
    param([int]$DaysOld = 30)
    
    Write-Log "Cleaning up tasks older than $DaysOld days"
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $cleaned = 0
    
    if (Test-Path $CompletedDir) {
        $oldTasks = Get-ChildItem $CompletedDir -Filter "*.json" | Where-Object {
            $taskContent = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $taskDate = [DateTime]::Parse($taskContent.completed_at)
            $taskDate -lt $cutoffDate
        }
        
        foreach ($task in $oldTasks) {
            Write-Log "Archiving old task: $($task.Name)"
            # Move to archive instead of deleting
            $archiveDir = Join-Path $CompletedDir "archive"
            if (-not (Test-Path $archiveDir)) {
                New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            }
            Move-Item $task.FullName $archiveDir
            $cleaned++
        }
    }
    
    Write-Log "Cleaned up $cleaned old tasks"
    return $cleaned
}

# Main execution
Write-Log "Automated Task Processor"
Write-Log "Action: $Action, TaskId: $TaskId, Assignee: $Assignee, DryRun: $DryRun"

switch ($Action) {
    "process" {
        if ($TaskId) {
            # Process specific task
            $taskPath = Join-Path $TaskQueueDir "$TaskId.json"
            if (Test-Path $taskPath) {
                $success = Process-Task -TaskPath $taskPath -Assignee $Assignee -DryRun $DryRun
                if ($success) {
                    Write-Log "Task processing completed successfully" "SUCCESS"
                } else {
                    Write-Log "Task processing failed" "ERROR"
                    exit 1
                }
            } else {
                Write-Log "Task not found: $TaskId" "ERROR"
                exit 1
            }
        } else {
            # Process all pending tasks
            $pendingTasks = Get-PendingTasks
            $processed = 0
            $failed = 0
            
            foreach ($task in $pendingTasks) {
                $success = Process-Task -TaskPath $task.FullName -Assignee $Assignee -DryRun $DryRun
                if ($success) {
                    $processed++
                } else {
                    $failed++
                }
            }
            
            Write-Log "Processing completed: $processed successful, $failed failed" "INFO"
        }
    }
    "monitor" {
        $count = Monitor-Tasks
        Write-Log "Monitoring completed: $count pending tasks found"
    }
    "report" {
        $report = Generate-Report
        Write-Log "Report generated: $($report.summary.pending_tasks) pending, $($report.summary.completed_tasks) completed"
    }
    "cleanup" {
        $cleaned = Cleanup-OldTasks
        Write-Log "Cleanup completed: $cleaned tasks archived"
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Automated task processing completed"
