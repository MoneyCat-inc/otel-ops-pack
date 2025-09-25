# Task Cleanup Guide - Agent System

## Overview

The agent system manages tasks through two parallel systems with different cleanup processes:

1. **Agent State System** (`.agent/state/`) - Simple queue-based system
2. **Task Queue System** (`.agent/task_queue/`) - Full lifecycle management system

## Task Cleanup Processes

### 1. Agent State System Cleanup

**Location**: `.agent/state/`
**Files**:
- `queue.jsonl` - Active task queue (JSONL format)
- `results.jsonl` - Completed task results

**Cleanup Process**:
```powershell
# Manual cleanup after task completion
Remove-Item ".agent\state\queue.jsonl" -Force

# Automated cleanup of old results (via cleanup script)
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "old" -DaysOld 30
```

**When to Clean**:
- After each task completion (queue.jsonl)
- Periodically for results.jsonl (keep last 100 entries or 30 days)

### 2. Task Queue System Cleanup

**Location**: `.agent/task_queue/`
**Directories**:
- `pending/` - New tasks waiting for processing
- `processing/` - Tasks currently being worked on
- `completed/` - Successfully completed tasks
- `failed/` - Tasks that failed processing

**Cleanup Process**:
```powershell
# Clean completed tasks older than 30 days
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "completed" -DaysOld 30

# Clean failed tasks older than 30 days
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "failed" -DaysOld 30

# Clean all old tasks and results
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "all" -DaysOld 30
```

**When to Clean**:
- Completed tasks: After 30 days (configurable)
- Failed tasks: After 30 days (configurable)
- Processing tasks: Never (should be moved to completed/failed)

## Cleanup Script Usage

### Basic Usage
```powershell
# Show current task statistics
pwsh -File .agent/scripts/cleanup-tasks.ps1

# Clean completed tasks (default: 30 days old)
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "completed"

# Clean failed tasks
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "failed"

# Clean all old tasks and results
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "all"
```

### Advanced Usage
```powershell
# Custom age threshold (7 days)
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "completed" -DaysOld 7

# Dry run (see what would be cleaned without actually cleaning)
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "all" -DryRun

# Clean only old results
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "old"
```

### Parameters
- `-Type`: What to clean (`completed`, `failed`, `old`, `all`)
- `-DaysOld`: Age threshold in days (default: 30)
- `-DryRun`: Show what would be cleaned without actually cleaning

## Task Lifecycle Management

### Proper Task Flow
1. **Creation**: Tasks created in `pending/` or `queue.jsonl`
2. **Processing**: Tasks moved to `processing/` (task queue system)
3. **Completion**: Tasks moved to `completed/` or `failed/`
4. **Cleanup**: Old completed/failed tasks removed after retention period

### Manual Task Management
```powershell
# Move task from pending to processing
Move-Item ".agent\task_queue\pending\task.json" ".agent\task_queue\processing\"

# Move completed task to completed directory
Move-Item ".agent\task_queue\processing\task.json" ".agent\task_queue\completed\"

# Move failed task to failed directory
Move-Item ".agent\task_queue\processing\task.json" ".agent\task_queue\failed\"
```

## Automated Cleanup Scheduling

### Windows Task Scheduler
Create a scheduled task to run cleanup weekly:

```powershell
# Create scheduled task for weekly cleanup
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\otel\.agent\scripts\cleanup-tasks.ps1 -Type all -DaysOld 30"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "Agent Task Cleanup" -Action $action -Trigger $trigger -Settings $settings
```

### Manual Scheduling
Add to your maintenance routine:
- **Daily**: Check for stuck processing tasks
- **Weekly**: Run cleanup script for completed/failed tasks
- **Monthly**: Review and adjust retention periods

## Best Practices

### Retention Policies
- **Completed Tasks**: Keep for 30 days (configurable)
- **Failed Tasks**: Keep for 30 days (configurable)
- **Results**: Keep last 100 entries or 30 days
- **Processing Tasks**: Never auto-clean (investigate manually)

### Monitoring
- Monitor task queue sizes regularly
- Set up alerts for stuck processing tasks
- Review failed tasks for patterns

### Safety
- Always use `-DryRun` first to see what will be cleaned
- Keep backups of important task files
- Test cleanup scripts in non-production environments

## Troubleshooting

### Common Issues
1. **Stuck Processing Tasks**: Move manually to completed/failed
2. **Large Results File**: Run cleanup with smaller retention period
3. **Missing Directories**: Create missing directories as needed

### Recovery
```powershell
# Recreate missing directories
New-Item -ItemType Directory -Path ".agent\task_queue\processing" -Force
New-Item -ItemType Directory -Path ".agent\task_queue\completed" -Force
New-Item -ItemType Directory -Path ".agent\task_queue\failed" -Force

# Reset agent state (emergency)
Remove-Item ".agent\state\queue.jsonl" -Force
Remove-Item ".agent\state\results.jsonl" -Force
```

## Integration with ECRR

The task cleanup process integrates with the ECRR methodology:

1. **Examine**: Check current task statistics and cleanup needs
2. **Clean**: Remove old completed/failed tasks according to retention policy
3. **Report**: Document cleanup actions and results
4. **Role**: Assign responsibility for ongoing maintenance

---

*Task Cleanup Guide v1.0*  
*Last updated: 2025-09-23*
