param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('List','Stat','Asgn','Star','Comp','Summ','Help')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [string]$Assignee,

    [Parameter(Mandatory = $false)]
    [string]$Category,

    [Parameter(Mandatory = $false)]
    [string]$Priority,

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

function Get-TaskFiles {
    param([string]$Root)

    $records = @()
    foreach ($status in @('pending','in-progress','completed')) {
        $dirPath = Join-Path -Path $Root -ChildPath $status
        if (-not (Test-Path -Path $dirPath)) {
            continue
        }

        $files = Get-ChildItem -Path $dirPath -File -Filter '*.md' -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $records += [PSCustomObject]@{
                Path = $file.FullName
                Status = $status
            }
        }
    }

    return $records
}

function Read-TaskMetadata {
    param(
        [string]$TaskPath,
        [string]$DefaultStatus
    )

    try {
        $content = Get-Content -Path $TaskPath -Raw -ErrorAction Stop
    }
    catch {
        Write-Log (("Failed to read task file {0}: {1}" -f $TaskPath, $_.Exception.Message)) 'ERROR'
        return $null
    }

    $lines = $content -split "`r?`n"
    $metadata = [ordered]@{
        Id = $null
        Title = $null
        Priority = $null
        Category = $null
        Effort = $null
        Status = $DefaultStatus
        Assignee = $null
        Created = $null
        Path = $TaskPath
        FolderStatus = $DefaultStatus
    }

    foreach ($line in $lines) {
        if (-not $metadata.Title -and $line -match '^#\s*Task:\s*(?<value>.+)$') {
            $metadata.Title = $Matches['value'].Trim()
            continue
        }

        if ($line -match '^\*\*(.+?)\*\*:\s*(.+)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim().Trim('`',' ')

            switch ($key.ToLowerInvariant()) {
                'task id' {
                    if (-not $metadata.Id) { $metadata.Id = $value }
                }
                'priority' {
                    if (-not $metadata.Priority) { $metadata.Priority = $value }
                }
                'category' {
                    if (-not $metadata.Category) { $metadata.Category = $value }
                }
                'estimated effort' {
                    if (-not $metadata.Effort) { $metadata.Effort = $value }
                }
                'status' {
                    if (-not $metadata.Status -or $metadata.Status -eq $metadata.FolderStatus) { $metadata.Status = $value }
                }
                'assigned to' {
                    if (-not $metadata.Assignee) { $metadata.Assignee = $value }
                }
                'created' {
                    if (-not $metadata.Created) { $metadata.Created = $value }
                }
            }
        }
    }

    if (-not $metadata.Id) {
        $metadata.Id = [System.IO.Path]::GetFileNameWithoutExtension($TaskPath)
    }

    if (-not $metadata.Title) {
        $metadata.Title = $metadata.Id
    }

    return [PSCustomObject]$metadata
}

function Get-Tasks {
    param([string]$Root)

    $tasks = [System.Collections.Generic.List[object]]::new()
    foreach ($record in Get-TaskFiles -Root $Root) {
        $metadata = Read-TaskMetadata -TaskPath $record.Path -DefaultStatus $record.Status
        if ($metadata) {
            $tasks.Add($metadata)
        }
    }

    return $tasks
}

function Update-TaskMetadata {
    param(
        [string]$TaskPath,
        [hashtable]$Updates
    )

    $lines = Get-Content -Path $TaskPath -ErrorAction Stop

    foreach ($key in $Updates.Keys) {
        $value = $Updates[$key]
        $pattern = "^\\*\\*" + [regex]::Escape($key) + "\\*\\*:\s*.*$"
        $found = $false

        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match $pattern) {
                $lines[$i] = "**$key**: $value"
                $found = $true
                break
            }
        }

        if (-not $found) {
            $lines = ,("**$key**: $value") + $lines
        }
    }

    Set-Content -Path $TaskPath -Value $lines -Encoding UTF8
}

function Move-TaskToStatus {
    param(
        [PSCustomObject]$Task,
        [string]$TargetStatus,
        [string]$JobsPath
    )

    $targetDir = Join-Path -Path $JobsPath -ChildPath $TargetStatus
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $destination = Join-Path -Path $targetDir -ChildPath ([System.IO.Path]::GetFileName($Task.Path))
    Move-Item -Path $Task.Path -Destination $destination -Force
    return $destination
}

function Invoke-ListAction {
    param(
        [System.Collections.Generic.List[object]]$Tasks,
        [string]$CategoryFilter,
        [string]$PriorityFilter
    )

    if ($Tasks.Count -eq 0) {
        Write-Log "No tasks found" 'WARN'
        return
    }

    $filteredTasks = $Tasks
    if ($CategoryFilter) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Category -eq $CategoryFilter }
    }
    if ($PriorityFilter) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Priority -eq $PriorityFilter }
    }

    if ($filteredTasks.Count -eq 0) {
        Write-Log "No tasks match the specified filters" 'WARN'
        return
    }

    Write-Host "`nFound $($filteredTasks.Count) task(s)" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan

    foreach ($task in $filteredTasks) {
        Write-Host ""
        $statusColor = switch ($task.Status) {
            'pending'     { 'Yellow' }
            'in-progress' { 'Cyan' }
            'completed'   { 'Green' }
            default       { 'White' }
        }
        Write-Host "[$($task.Status.ToUpper())] $($task.Title)" -ForegroundColor $statusColor
        
        Write-Host "  ID: $($task.Id)" -ForegroundColor Gray
        Write-Host "  Category: $($task.Category) | Priority: $($task.Priority) | Effort: $($task.Effort)" -ForegroundColor Gray
        Write-Host "  Assignee: $($task.Assignee) | Created: $($task.Created)" -ForegroundColor Gray
        Write-Host "  Path: $($task.Path)" -ForegroundColor DarkGray
    }
}

function Invoke-StatusAction {
    param([System.Collections.Generic.List[object]]$Tasks)

    if ($Tasks.Count -eq 0) {
        Write-Log "No tasks found" 'WARN'
        return
    }

    Write-Host "`nTask Status Overview" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan

    Write-Host "`nBy status:" -ForegroundColor Cyan
    foreach ($group in $Tasks | Group-Object Status | Sort-Object Name) {
        $color = switch ($group.Name) {
            'pending'     { 'Yellow' }
            'in-progress' { 'Cyan' }
            'completed'   { 'Green' }
            default       { 'White' }
        }
        Write-Host ("  {0,-12}: {1,3}" -f $group.Name, $group.Count) -ForegroundColor $color
    }

    Write-Host "`nBy category:" -ForegroundColor Cyan
    foreach ($group in $Tasks | Group-Object Category | Sort-Object Name) {
        Write-Host ("  {0,-15}: {1,3}" -f $group.Name, $group.Count) -ForegroundColor White
    }

    Write-Host "`nBy priority:" -ForegroundColor Cyan
    foreach ($group in $Tasks | Group-Object Priority | Sort-Object Name) {
        $color = switch ($group.Name) {
            'critical' { 'Red' }
            'high'     { 'Yellow' }
            'medium'   { 'Cyan' }
            'low'      { 'Green' }
            default    { 'White' }
        }
        Write-Host ("  {0,-8}: {1,3}" -f $group.Name, $group.Count) -ForegroundColor $color
    }

    Write-Host "`nBy effort:" -ForegroundColor Cyan
    foreach ($group in $Tasks | Group-Object Effort | Sort-Object Name) {
        Write-Host ("  {0,-3}: {1,3}" -f $group.Name, $group.Count) -ForegroundColor White
    }

    # Show unassigned tasks
    $unassigned = $Tasks | Where-Object { -not $_.Assignee -or $_.Assignee -eq 'unassigned' }
    if ($unassigned -and $unassigned.Count -gt 0) {
        Write-Host "`nUnassigned tasks: $($unassigned.Count)" -ForegroundColor Yellow
        foreach ($task in $unassigned | Select-Object -First 5) {
            Write-Host ("  - {0} ({1})" -f $task.Id, $task.Category) -ForegroundColor Gray
        }
        if ($unassigned.Count -gt 5) {
            Write-Host ("  ... and {0} more" -f ($unassigned.Count - 5)) -ForegroundColor Gray
        }
    }
}

function Invoke-AssignAction {
    param(
        [System.Collections.Generic.List[object]]$Tasks,
        [string]$TaskId,
        [string]$Assignee,
        [string]$JobsPath
    )

    if (-not $TaskId) {
        Write-Log "Provide -TaskId to assign a task" 'ERROR'
        return
    }

    if (-not $Assignee) {
        Write-Log "Provide -Assignee to assign a task" 'ERROR'
        return
    }

    $task = $Tasks | Where-Object { $_.Id.ToLowerInvariant() -eq $TaskId.ToLowerInvariant() } | Select-Object -First 1
    if (-not $task) {
        Write-Log "Task not found: $TaskId" 'ERROR'
        return
    }

    Update-TaskMetadata -TaskPath $task.Path -Updates @{ 'Assigned To' = $Assignee }
    Write-Log "Assigned $TaskId to $Assignee" 'SUCCESS'
}

function Invoke-StartAction {
    param(
        [System.Collections.Generic.List[object]]$Tasks,
        [string]$TaskId,
        [string]$JobsPath
    )

    if (-not $TaskId) {
        Write-Log "Provide -TaskId to start a task" 'ERROR'
        return
    }

    $task = $Tasks | Where-Object { $_.Id.ToLowerInvariant() -eq $TaskId.ToLowerInvariant() } | Select-Object -First 1
    if (-not $task) {
        Write-Log "Task not found: $TaskId" 'ERROR'
        return
    }

    $newPath = Move-TaskToStatus -Task $task -TargetStatus 'in-progress' -JobsPath $JobsPath
    Update-TaskMetadata -TaskPath $newPath -Updates @{ 'Status' = 'in-progress' }
    Write-Log "Moved $TaskId to in-progress" 'SUCCESS'
}

function Invoke-CompleteAction {
    param(
        [System.Collections.Generic.List[object]]$Tasks,
        [string]$TaskId,
        [string]$JobsPath
    )

    if (-not $TaskId) {
        Write-Log "Provide -TaskId to complete a task" 'ERROR'
        return
    }

    $task = $Tasks | Where-Object { $_.Id.ToLowerInvariant() -eq $TaskId.ToLowerInvariant() } | Select-Object -First 1
    if (-not $task) {
        Write-Log "Task not found: $TaskId" 'ERROR'
        return
    }

    $newPath = Move-TaskToStatus -Task $task -TargetStatus 'completed' -JobsPath $JobsPath
    Update-TaskMetadata -TaskPath $newPath -Updates @{ 'Status' = 'completed' }
    Write-Log "Completed $TaskId" 'SUCCESS'
}

function Invoke-SummaryAction {
    param([System.Collections.Generic.List[object]]$Tasks)

    if ($Tasks.Count -eq 0) {
        Write-Log "No tasks found" 'WARN'
        return
    }

    $total = $Tasks.Count
    $pendingTasks = $Tasks | Where-Object { $_.Status -eq 'pending' }
    $inProgressTasks = $Tasks | Where-Object { $_.Status -eq 'in-progress' }
    $completedTasks = $Tasks | Where-Object { $_.Status -eq 'completed' }
    
    $pending = if ($pendingTasks) { $pendingTasks.Count } else { 0 }
    $inProgress = if ($inProgressTasks) { $inProgressTasks.Count } else { 0 }
    $completed = if ($completedTasks) { $completedTasks.Count } else { 0 }

    Write-Host "`nTask Summary Dashboard" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan

    Write-Host "`nOverall Progress:" -ForegroundColor Cyan
    Write-Host "  Total Tasks: $total" -ForegroundColor White
    Write-Host "  Pending: $pending" -ForegroundColor Yellow
    Write-Host "  In Progress: $inProgress" -ForegroundColor Cyan
    Write-Host "  Completed: $completed" -ForegroundColor Green

    if ($total -gt 0) {
        $rate = [math]::Round(($completed / $total) * 100, 1)
        $rateColor = if ($rate -ge 80) { 'Green' } elseif ($rate -ge 60) { 'Yellow' } else { 'Red' }
        Write-Host "  Completion Rate: $rate%" -ForegroundColor $rateColor
    }

    # Priority breakdown
    $criticalPending = $Tasks | Where-Object { $_.Status -eq 'pending' -and $_.Priority -eq 'critical' }
    $highPending = $Tasks | Where-Object { $_.Status -eq 'pending' -and $_.Priority -eq 'high' }
    
    if (($criticalPending -and $criticalPending.Count -gt 0) -or ($highPending -and $highPending.Count -gt 0)) {
        Write-Host "`nPriority Alerts:" -ForegroundColor Yellow
        if ($criticalPending -and $criticalPending.Count -gt 0) {
            Write-Host "  CRITICAL pending: $($criticalPending.Count)" -ForegroundColor Red
            foreach ($task in $criticalPending | Select-Object -First 3) {
                Write-Host ("    - {0} ({1})" -f $task.Id, $task.Category) -ForegroundColor Red
            }
        }
        if ($highPending -and $highPending.Count -gt 0) {
            Write-Host "  HIGH pending: $($highPending.Count)" -ForegroundColor Yellow
            foreach ($task in $highPending | Select-Object -First 3) {
                Write-Host ("    - {0} ({1})" -f $task.Id, $task.Category) -ForegroundColor Yellow
            }
        }
    }

    # Workload distribution
    $unassigned = $Tasks | Where-Object { -not $_.Assignee -or $_.Assignee -eq 'unassigned' }
    if ($unassigned -and $unassigned.Count -gt 0) {
        Write-Host "`nWorkload Distribution:" -ForegroundColor Cyan
        Write-Host "  Unassigned: $($unassigned.Count)" -ForegroundColor Yellow
        
        $assigned = $Tasks | Where-Object { $_.Assignee -and $_.Assignee -ne 'unassigned' }
        if ($assigned -and $assigned.Count -gt 0) {
            Write-Host "  Assigned: $($assigned.Count)" -ForegroundColor Green
            $assigneeGroups = $assigned | Group-Object Assignee | Sort-Object Count -Descending
            foreach ($group in $assigneeGroups | Select-Object -First 3) {
                Write-Host ("    {0}: {1}" -f $group.Name, $group.Count) -ForegroundColor White
            }
        }
    }

    # Category insights
    $categoryBreakdown = $Tasks | Group-Object Category | Sort-Object Count -Descending
    if ($categoryBreakdown.Count -gt 1) {
        Write-Host "`nCategory Distribution:" -ForegroundColor Cyan
        foreach ($group in $categoryBreakdown | Select-Object -First 5) {
            $pendingInCategory = ($group.Group | Where-Object { $_.Status -eq 'pending' }).Count
            Write-Host ("  {0,-15}: {1,3} total ({2,2} pending)" -f $group.Name, $group.Count, $pendingInCategory) -ForegroundColor White
        }
    }

    # Next actions
    Write-Host "`nRecommended Actions:" -ForegroundColor Cyan
    if ($criticalPending -and $criticalPending.Count -gt 0) {
        Write-Host "  • Address $($criticalPending.Count) critical task(s) immediately" -ForegroundColor Red
    }
    if ($unassigned -and $unassigned.Count -gt 0) {
        Write-Host "  • Assign $($unassigned.Count) unassigned task(s)" -ForegroundColor Yellow
    }
    if ($inProgress -gt 5) {
        Write-Host "  • Consider completing some in-progress tasks before starting new ones" -ForegroundColor Yellow
    }
    if ($completed -gt 0 -and $pending -eq 0) {
        Write-Host "  • All tasks completed! Consider generating new tasks from ECRR reports" -ForegroundColor Green
    }
}

function Show-Help {
    Write-Host "`nECRR Task Management Commands" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "`nList tasks:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action List" -ForegroundColor White
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action List -Category observability" -ForegroundColor White
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action List -Priority high" -ForegroundColor White
    Write-Host "`nStatus summary:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Status" -ForegroundColor White
    Write-Host "`nAssign a task:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId TASK-20250923-123456-001 -Assignee observability-engineer" -ForegroundColor White
    Write-Host "`nStart a task:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Start -TaskId TASK-20250923-123456-001" -ForegroundColor White
    Write-Host "`nComplete a task:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Complete -TaskId TASK-20250923-123456-001" -ForegroundColor White
    Write-Host "`nTask summary:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Summary" -ForegroundColor White
    Write-Host "`nGenerate tasks from ECRR reports:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 3 -DryRun" -ForegroundColor White
    Write-Host "  pwsh -File scripts/simple-task-generator.ps1 -MaxTasks 5" -ForegroundColor White
    Write-Host "`nQuick wrappers:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/simple-task-manager.ps1 -Action Status" -ForegroundColor White
    Write-Host "  pwsh -File scripts/simple-task-manager.ps1 -Action List" -ForegroundColor White
}

try {
    $tasks = Get-Tasks -Root $JobsPath

    switch ($Action) {
        'List' {
            Invoke-ListAction -Tasks $tasks -CategoryFilter $Category -PriorityFilter $Priority
        }
        'Stat' {
            Invoke-StatusAction -Tasks $tasks
        }
        'Asgn' {
            Invoke-AssignAction -Tasks $tasks -TaskId $TaskId -Assignee $Assignee -JobsPath $JobsPath
        }
        'Star' {
            Invoke-StartAction -Tasks $tasks -TaskId $TaskId -JobsPath $JobsPath
        }
        'Comp' {
            Invoke-CompleteAction -Tasks $tasks -TaskId $TaskId -JobsPath $JobsPath
        }
        'Summ' {
            Invoke-SummaryAction -Tasks $tasks
        }
        # Legacy support for old commands
        'Status' {
            Invoke-StatusAction -Tasks $tasks
        }
        'Assign' {
            Invoke-AssignAction -Tasks $tasks -TaskId $TaskId -Assignee $Assignee -JobsPath $JobsPath
        }
        'Start' {
            Invoke-StartAction -Tasks $tasks -TaskId $TaskId -JobsPath $JobsPath
        }
        'Complete' {
            Invoke-CompleteAction -Tasks $tasks -TaskId $TaskId -JobsPath $JobsPath
        }
        'Summary' {
            Invoke-SummaryAction -Tasks $tasks
        }
        'Help' {
            Show-Help
        }
    }
}
catch {
    Write-Log "Task management failed: $($_.Exception.Message)" 'ERROR'
    throw
}
