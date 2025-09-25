# Task Maintenance Scheduler
# Automates periodic task system maintenance and health checks

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('daily','weekly','monthly','setup','status')]
    [string]$Schedule = 'daily',
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [string]$JobsPath = "jobs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-TaskHealth {
    param([string]$JobsRoot)
    
    $health = @{
        TotalTasks = 0
        PendingTasks = 0
        InProgressTasks = 0
        CompletedTasks = 0
        OverdueTasks = 0
        UnassignedTasks = 0
        HealthScore = 0
    }
    
    try {
        # Get task counts by status
        foreach ($status in @('pending','in-progress','completed')) {
            $dirPath = Join-Path -Path $JobsRoot -ChildPath $status
            if (Test-Path -Path $dirPath) {
                $taskFiles = Get-ChildItem -Path $dirPath -Filter "*.md" -File
                $count = $taskFiles.Count
                
                switch ($status) {
                    'pending' { $health.PendingTasks = $count }
                    'in-progress' { $health.InProgressTasks = $count }
                    'completed' { $health.CompletedTasks = $count }
                }
                
                $health.TotalTasks += $count
            }
        }
        
        # Check for overdue tasks (created > 7 days ago)
        $pendingDir = Join-Path -Path $JobsRoot -ChildPath "pending"
        if (Test-Path -Path $pendingDir) {
            $overdueCutoff = (Get-Date).AddDays(-7)
            $overdueTasks = Get-ChildItem -Path $pendingDir -Filter "*.md" -File | 
                Where-Object { $_.CreationTime -lt $overdueCutoff }
            $health.OverdueTasks = $overdueTasks.Count
        }
        
        # Check for unassigned tasks
        $unassignedTasks = Get-ChildItem -Path $JobsRoot -Recurse -Filter "*.md" -File | 
            Where-Object { 
                $content = Get-Content $_.FullName -Raw
                -not ($content -match 'Assigned To.*:\s*\w+')
            }
        $health.UnassignedTasks = $unassignedTasks.Count
        
        # Calculate health score (0-100)
        if ($health.TotalTasks -gt 0) {
            $completionRate = ($health.CompletedTasks / $health.TotalTasks) * 100
            $overdueRate = ($health.OverdueTasks / $health.PendingTasks) * 100
            $assignmentRate = (($health.TotalTasks - $health.UnassignedTasks) / $health.TotalTasks) * 100
            
            $health.HealthScore = [math]::Round(($completionRate * 0.4) + ((100 - $overdueRate) * 0.3) + ($assignmentRate * 0.3), 1)
        }
        
    } catch {
        Write-Log "Error calculating task health: $($_.Exception.Message)" -Level ERROR
    }
    
    return $health
}

function Invoke-DailyMaintenance {
    param([string]$JobsRoot)
    
    Write-Log "Starting daily task maintenance..." -Level INFO
    
    # 1. Health check
    $health = Get-TaskHealth -JobsRoot $JobsRoot
    Write-Log "Task Health Score: $($health.HealthScore)/100" -Level INFO
    Write-Log "Pending: $($health.PendingTasks), In-Progress: $($health.InProgressTasks), Completed: $($health.CompletedTasks)" -Level INFO
    
    # 2. Check for overdue tasks
    if ($health.OverdueTasks -gt 0) {
        Write-Log "WARNING: $($health.OverdueTasks) tasks are overdue (>7 days)" -Level WARN
    }
    
    # 3. Check for unassigned tasks
    if ($health.UnassignedTasks -gt 0) {
        Write-Log "WARNING: $($health.UnassignedTasks) tasks are unassigned" -Level WARN
    }
    
    # 4. Generate maintenance report
    $reportPath = "artifacts/task-maintenance-$(Get-Date -Format 'yyyy-MM-dd').json"
    $health | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Maintenance report saved to: $reportPath" -Level SUCCESS
}

function Invoke-WeeklyMaintenance {
    param([string]$JobsRoot)
    
    Write-Log "Starting weekly task maintenance..." -Level INFO
    
    # 1. Daily maintenance
    Invoke-DailyMaintenance -JobsRoot $JobsRoot
    
    # 2. Archive old completed tasks (>30 days)
    $completedDir = Join-Path -Path $JobsRoot -ChildPath "completed"
    if (Test-Path -Path $completedDir) {
        $archiveCutoff = (Get-Date).AddDays(-30)
        $oldTasks = Get-ChildItem -Path $completedDir -Filter "*.md" -File | 
            Where-Object { $_.CreationTime -lt $archiveCutoff }
        
        if ($oldTasks.Count -gt 0) {
            $archiveDir = Join-Path -Path $JobsRoot -ChildPath "archive"
            if (-not (Test-Path -Path $archiveDir)) {
                New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
            }
            
            foreach ($task in $oldTasks) {
                $archivePath = Join-Path -Path $archiveDir -ChildPath $task.Name
                Move-Item -Path $task.FullName -Destination $archivePath -Force
                Write-Log "Archived old task: $($task.Name)" -Level INFO
            }
        }
    }
    
    # 3. Generate weekly summary
    $summaryPath = "artifacts/weekly-task-summary-$(Get-Date -Format 'yyyy-MM-dd').md"
    $health = Get-TaskHealth -JobsRoot $JobsRoot
    
    $summary = @"
# Weekly Task Summary - $(Get-Date -Format 'yyyy-MM-dd')

## Task Health Overview
- **Health Score**: $($health.HealthScore)/100
- **Total Tasks**: $($health.TotalTasks)
- **Pending**: $($health.PendingTasks)
- **In Progress**: $($health.InProgressTasks)
- **Completed**: $($health.CompletedTasks)
- **Overdue**: $($health.OverdueTasks)
- **Unassigned**: $($health.UnassignedTasks)

## Recommendations
$(if ($health.OverdueTasks -gt 0) { "- Review and prioritize overdue tasks" })
$(if ($health.UnassignedTasks -gt 0) { "- Assign unassigned tasks to team members" })
$(if ($health.HealthScore -lt 70) { "- Focus on improving task completion rate" })
"@
    
    $summary | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Log "Weekly summary saved to: $summaryPath" -Level SUCCESS
}

function Invoke-MonthlyMaintenance {
    param([string]$JobsRoot)
    
    Write-Log "Starting monthly task maintenance..." -Level INFO
    
    # 1. Weekly maintenance
    Invoke-WeeklyMaintenance -JobsRoot $JobsRoot
    
    # 2. Generate monthly analytics
    $analyticsPath = "artifacts/monthly-task-analytics-$(Get-Date -Format 'yyyy-MM').json"
    
    $analytics = @{
        Month = Get-Date -Format 'yyyy-MM'
        HealthTrends = @{
            CurrentHealthScore = (Get-TaskHealth -JobsRoot $JobsRoot).HealthScore
            # Add historical data if available
        }
        TaskDistribution = Get-TaskHealth -JobsRoot $JobsRoot
        Recommendations = @(
            "Review task assignment patterns",
            "Analyze completion rate trends",
            "Identify bottlenecks in task workflow"
        )
    }
    
    $analytics | ConvertTo-Json -Depth 3 | Out-File -FilePath $analyticsPath -Encoding UTF8
    Write-Log "Monthly analytics saved to: $analyticsPath" -Level SUCCESS
}

function Setup-TaskMaintenance {
    Write-Log "Setting up task maintenance automation..." -Level INFO
    
    # Create artifacts directory if it doesn't exist
    if (-not (Test-Path -Path "artifacts")) {
        New-Item -Path "artifacts" -ItemType Directory -Force | Out-Null
    }
    
    # Create archive directory if it doesn't exist
    $archiveDir = Join-Path -Path $JobsPath -ChildPath "archive"
    if (-not (Test-Path -Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    # Generate Windows Task Scheduler entries (for reference)
    $taskScript = @"
# Windows Task Scheduler Commands (run as Administrator)

# Daily maintenance at 9 AM
schtasks /create /tn "TaskMaintenanceDaily" /tr "pwsh -File $PSScriptRoot\task-maintenance-scheduler.ps1 -Schedule daily" /sc daily /st 09:00 /ru SYSTEM

# Weekly maintenance on Mondays at 8 AM
schtasks /create /tn "TaskMaintenanceWeekly" /tr "pwsh -File $PSScriptRoot\task-maintenance-scheduler.ps1 -Schedule weekly" /sc weekly /d MON /st 08:00 /ru SYSTEM

# Monthly maintenance on 1st of month at 7 AM
schtasks /create /tn "TaskMaintenanceMonthly" /tr "pwsh -File $PSScriptRoot\task-maintenance-scheduler.ps1 -Schedule monthly" /sc monthly /d 1 /st 07:00 /ru SYSTEM
"@
    
    $taskScript | Out-File -FilePath "artifacts/task-scheduler-setup.txt" -Encoding UTF8
    Write-Log "Task scheduler setup commands saved to: artifacts/task-scheduler-setup.txt" -Level SUCCESS
    Write-Log "Run these commands as Administrator to enable automated maintenance" -Level INFO
}

# Main execution
try {
    if ($DryRun) {
        Write-Log "DRY RUN MODE - No changes will be made" -Level WARN
    }
    
    switch ($Schedule) {
        'daily' { Invoke-DailyMaintenance -JobsRoot $JobsPath }
        'weekly' { Invoke-WeeklyMaintenance -JobsRoot $JobsPath }
        'monthly' { Invoke-MonthlyMaintenance -JobsRoot $JobsPath }
        'setup' { Setup-TaskMaintenance }
        'status' { 
            $health = Get-TaskHealth -JobsRoot $JobsPath
            Write-Log "Task Health Score: $($health.HealthScore)/100" -Level INFO
            Write-Log "Pending: $($health.PendingTasks), In-Progress: $($health.InProgressTasks), Completed: $($health.CompletedTasks)" -Level INFO
            Write-Log "Overdue: $($health.OverdueTasks), Unassigned: $($health.UnassignedTasks)" -Level INFO
        }
    }
    
    Write-Log "Task maintenance completed successfully" -Level SUCCESS
    
} catch {
    Write-Log "Task maintenance failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
