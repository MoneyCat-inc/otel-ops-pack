# Task Cleanup Script for Agent System
# Manages completed task files and maintains system hygiene

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("completed", "failed", "old", "all")]
    [string]$Type = "completed",
    
    [Parameter(Mandatory=$false)]
    [int]$DaysOld = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$TaskQueueDir = ".agent\task_queue"
$StateDir = ".agent\state"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Clean-CompletedTasks {
    Write-Log "Cleaning completed tasks older than $DaysOld days"
    
    $completedDir = Join-Path $TaskQueueDir "completed"
    if (-not (Test-Path $completedDir)) {
        Write-Log "Completed directory does not exist: $completedDir" "WARN"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $oldTasks = Get-ChildItem $completedDir -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldTasks.Count -eq 0) {
        Write-Log "No completed tasks older than $DaysOld days found"
        return
    }
    
    Write-Log "Found $($oldTasks.Count) completed tasks to clean up"
    
    foreach ($task in $oldTasks) {
        if ($DryRun) {
            Write-Log "DRY RUN: Would remove $($task.Name) (last modified: $($task.LastWriteTime))"
        } else {
            try {
                Remove-Item $task.FullName -Force
                Write-Log "Removed completed task: $($task.Name)"
            } catch {
                Write-Log "Failed to remove $($task.Name): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

function Clean-FailedTasks {
    Write-Log "Cleaning failed tasks older than $DaysOld days"
    
    $failedDir = Join-Path $TaskQueueDir "failed"
    if (-not (Test-Path $failedDir)) {
        Write-Log "Failed directory does not exist: $failedDir" "WARN"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $oldTasks = Get-ChildItem $failedDir -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldTasks.Count -eq 0) {
        Write-Log "No failed tasks older than $DaysOld days found"
        return
    }
    
    Write-Log "Found $($oldTasks.Count) failed tasks to clean up"
    
    foreach ($task in $oldTasks) {
        if ($DryRun) {
            Write-Log "DRY RUN: Would remove $($task.Name) (last modified: $($task.LastWriteTime))"
        } else {
            try {
                Remove-Item $task.FullName -Force
                Write-Log "Removed failed task: $($task.Name)"
            } catch {
                Write-Log "Failed to remove $($task.Name): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

function Clean-OldResults {
    Write-Log "Cleaning old results from state directory"
    
    $resultsFile = Join-Path $StateDir "results.jsonl"
    if (-not (Test-Path $resultsFile)) {
        Write-Log "Results file does not exist: $resultsFile" "WARN"
        return
    }
    
    # Keep only last 100 results or results from last 30 days
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $results = Get-Content $resultsFile | ConvertFrom-Json
    
    if ($results.Count -le 100) {
        Write-Log "Results file has $($results.Count) entries, no cleanup needed"
        return
    }
    
    $recentResults = $results | Where-Object { 
        [DateTime]::Parse($_.timestamp) -gt $cutoffDate 
    } | Select-Object -Last 100
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would keep $($recentResults.Count) recent results, remove $($results.Count - $recentResults.Count) old results"
    } else {
        try {
            $recentResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding utf8
            Write-Log "Cleaned results file: kept $($recentResults.Count) recent results"
        } catch {
            Write-Log "Failed to clean results file: $($_.Exception.Message)" "ERROR"
        }
    }
}

function Show-TaskStats {
    Write-Log "Current task statistics:"
    
    # Count tasks in each directory
    $pendingCount = (Get-ChildItem (Join-Path $TaskQueueDir "pending") -Filter "*.json" -ErrorAction SilentlyContinue).Count
    $processingCount = (Get-ChildItem (Join-Path $TaskQueueDir "processing") -Filter "*.json" -ErrorAction SilentlyContinue).Count
    $completedCount = (Get-ChildItem (Join-Path $TaskQueueDir "completed") -Filter "*.json" -ErrorAction SilentlyContinue).Count
    $failedCount = (Get-ChildItem (Join-Path $TaskQueueDir "failed") -Filter "*.json" -ErrorAction SilentlyContinue).Count
    
    Write-Log "  Pending: $pendingCount tasks"
    Write-Log "  Processing: $processingCount tasks"
    Write-Log "  Completed: $completedCount tasks"
    Write-Log "  Failed: $failedCount tasks"
    
    # Count results
    $resultsFile = Join-Path $StateDir "results.jsonl"
    if (Test-Path $resultsFile) {
        $resultsCount = (Get-Content $resultsFile | ConvertFrom-Json).Count
        Write-Log "  Results: $resultsCount entries"
    }
}

# Main execution
Write-Log "Starting task cleanup (Type: $Type, DaysOld: $DaysOld, DryRun: $DryRun)"

Show-TaskStats

switch ($Type) {
    "completed" { Clean-CompletedTasks }
    "failed" { Clean-FailedTasks }
    "old" { 
        Clean-CompletedTasks
        Clean-FailedTasks
        Clean-OldResults
    }
    "all" {
        Clean-CompletedTasks
        Clean-FailedTasks
        Clean-OldResults
    }
}

Write-Log "Task cleanup completed"

# Show final stats
Write-Log "Final task statistics:"
Show-TaskStats
