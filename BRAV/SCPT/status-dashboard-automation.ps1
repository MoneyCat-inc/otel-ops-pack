# BossCat Status Dashboard Automation Script
# PowerShell script for automated status updates

param(
    [int]$IntervalMinutes = 5,
    [switch]$CreateTask,
    [switch]$RemoveTask,
    [switch]$RunNow
)

$ScriptPath = $PSScriptRoot
$PythonScript = Join-Path $ScriptPath "generate_status_jsons.py"
$TaskName = "BossCat-StatusDashboard"
$TaskDescription = "BossCat OEM Status Dashboard - Automated JSON generation for real-time monitoring"

function Write-BossCatLog {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] BossCat: $Message"
}

function Test-PythonAvailable {
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-BossCatLog "Python available: $pythonVersion"
            return $true
        }
    }
    catch {
        Write-BossCatLog "Python not found in PATH"
        return $false
    }
    return $false
}

function Invoke-StatusUpdate {
    Write-BossCatLog "Starting status dashboard update..."
    
    if (-not (Test-PythonAvailable)) {
        Write-BossCatLog "ERROR: Python not available. Please install Python and ensure it's in PATH."
        return $false
    }
    
    try {
        # Change to the repository root directory
        $RepoRoot = Split-Path $ScriptPath -Parent
        Set-Location $RepoRoot
        
        # Run the Python script
        $output = python $PythonScript 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-BossCatLog "Status update completed successfully"
            Write-BossCatLog "Output: $output"
            return $true
        } else {
            Write-BossCatLog "Status update failed with exit code: $exitCode"
            Write-BossCatLog "Error: $output"
            return $false
        }
    }
    catch {
        Write-BossCatLog "Exception during status update: $($_.Exception.Message)"
        return $false
    }
}

function New-ScheduledTask {
    Write-BossCatLog "Creating Windows Scheduled Task: $TaskName"
    
    try {
        # Create the action
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`" -RunNow"
        
        # Create the trigger (every N minutes)
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)
        
        # Create task settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        
        # Create the principal (run as current user)
        $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description $TaskDescription -Force
        
        Write-BossCatLog "Scheduled task created successfully"
        Write-BossCatLog "Task will run every $IntervalMinutes minutes"
        
        # Start the task immediately
        Start-ScheduledTask -TaskName $TaskName
        Write-BossCatLog "Task started immediately"
        
        return $true
    }
    catch {
        Write-BossCatLog "Failed to create scheduled task: $($_.Exception.Message)"
        return $false
    }
}

function Remove-ScheduledTask {
    Write-BossCatLog "Removing Windows Scheduled Task: $TaskName"
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-BossCatLog "Scheduled task removed successfully"
        return $true
    }
    catch {
        Write-BossCatLog "Failed to remove scheduled task: $($_.Exception.Message)"
        return $false
    }
}

function Show-TaskStatus {
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Write-BossCatLog "Task Status: $($task.State)"
            Write-BossCatLog "Last Run: $($task.LastRunTime)"
            Write-BossCatLog "Next Run: $($task.NextRunTime)"
        } else {
            Write-BossCatLog "Task not found"
        }
    }
    catch {
        Write-BossCatLog "Error checking task status: $($_.Exception.Message)"
    }
}

# Main execution
Write-BossCatLog "BossCat Status Dashboard Automation"
Write-BossCatLog "====================================="

if ($CreateTask) {
    New-ScheduledTask
}
elseif ($RemoveTask) {
    Remove-ScheduledTask
}
elseif ($RunNow) {
    Invoke-StatusUpdate
}
else {
    # Show help
    Write-BossCatLog "Usage:"
    Write-BossCatLog "  -CreateTask    : Create Windows Scheduled Task"
    Write-BossCatLog "  -RemoveTask    : Remove Windows Scheduled Task"
    Write-BossCatLog "  -RunNow        : Run status update immediately"
    Write-BossCatLog "  -IntervalMinutes : Set update interval (default: 5 minutes)"
    Write-BossCatLog ""
    Write-BossCatLog "Examples:"
    Write-BossCatLog "  .\status-dashboard-automation.ps1 -CreateTask -IntervalMinutes 5"
    Write-BossCatLog "  .\status-dashboard-automation.ps1 -RunNow"
    Write-BossCatLog "  .\status-dashboard-automation.ps1 -RemoveTask"
    Write-BossCatLog ""
    Show-TaskStatus
}
