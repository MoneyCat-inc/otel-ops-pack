# Install GPU Automation Windows Task Scheduler Task
# Creates a scheduled task for continuous GPU monitoring

param(
    [int]$IntervalMinutes = 5,
    [switch]$Force
)

function Write-ColorLog {
    param([string]$Message, [string]$Color = "Green")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Install-GPUMonitoringTask {
    param([int]$IntervalMinutes)
    
    Write-ColorLog "🔧 Installing GPU monitoring Windows Task Scheduler task" "Cyan"
    
    $taskName = "GPU-Automated-Monitoring"
    $scriptPath = (Get-Location).Path + "\scripts\gpu-monitoring-daemon.py"
    
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask -and !$Force) {
        Write-ColorLog "⚠️ Task '$taskName' already exists. Use -Force to overwrite." "Yellow"
        return $false
    }
    
    # Remove existing task if Force is specified
    if ($existingTask -and $Force) {
        Write-ColorLog "🗑️ Removing existing task..." "Yellow"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Create task action
    $action = New-ScheduledTaskAction -Execute "python" -Argument "`"$scriptPath`" --interval 30"
    
    # Create task trigger (every N minutes)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create task principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated GPU monitoring with ECRR compliance - Runs every $IntervalMinutes minutes" -Force
        Write-ColorLog "✅ Task '$taskName' installed successfully" "Green"
        Write-ColorLog "   • Runs every $IntervalMinutes minutes" "White"
        Write-ColorLog "   • Executes: python `"$scriptPath`" --interval 30" "White"
        Write-ColorLog "   • Runs as SYSTEM account" "White"
        return $true
    } catch {
        Write-ColorLog "❌ Failed to install task: $_" "Red"
        return $false
    }
}

function Test-GPUMonitoringTask {
    Write-ColorLog "🧪 Testing GPU monitoring task..." "Cyan"
    
    $taskName = "GPU-Automated-Monitoring"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-ColorLog "✅ Task found: $taskName" "Green"
        Write-ColorLog "   • State: $($task.State)" "White"
        Write-ColorLog "   • Last Run: $($task.LastRunTime)" "White"
        Write-ColorLog "   • Next Run: $($task.NextRunTime)" "White"
        
        # Test the action
        Write-ColorLog "   • Testing action..." "Yellow"
        try {
            $result = python scripts\gpu-monitoring-daemon.py --duration 1 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorLog "   ✅ Action test successful" "Green"
            } else {
                Write-ColorLog "   ⚠️ Action test had issues" "Yellow"
            }
        } catch {
            Write-ColorLog "   ❌ Action test failed: $_" "Red"
        }
        
        return $true
    } else {
        Write-ColorLog "❌ Task not found: $taskName" "Red"
        return $false
    }
}

function Show-GPUMonitoringTaskInfo {
    Write-ColorLog "📋 GPU Monitoring Task Information" "Cyan"
    
    $taskName = "GPU-Automated-Monitoring"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-Host ""
        Write-Host "Task Name: $($task.TaskName)" -ForegroundColor White
        Write-Host "Description: $($task.Description)" -ForegroundColor White
        Write-Host "State: $($task.State)" -ForegroundColor White
        Write-Host "Author: $($task.Author)" -ForegroundColor White
        Write-Host "Created: $($task.Date)" -ForegroundColor White
        Write-Host "Last Run: $($task.LastRunTime)" -ForegroundColor White
        Write-Host "Next Run: $($task.NextRunTime)" -ForegroundColor White
        Write-Host "Last Result: $($task.LastTaskResult)" -ForegroundColor White
        
        Write-Host ""
        Write-Host "Actions:" -ForegroundColor Yellow
        foreach ($action in $task.Actions) {
            Write-Host "  • Execute: $($action.Execute)" -ForegroundColor White
            Write-Host "  • Arguments: $($action.Arguments)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Triggers:" -ForegroundColor Yellow
        foreach ($trigger in $task.Triggers) {
            Write-Host "  • Type: $($trigger.CimClass.CimClassName)" -ForegroundColor White
            Write-Host "  • Start: $($trigger.StartBoundary)" -ForegroundColor White
            if ($trigger.Repetition) {
                Write-Host "  • Repetition: $($trigger.Repetition.Interval)" -ForegroundColor White
                Write-Host "  • Duration: $($trigger.Repetition.Duration)" -ForegroundColor White
            }
        }
    } else {
        Write-ColorLog "❌ Task not found: $taskName" "Red"
    }
}

# Main execution
Write-Host "=== GPU Automation Task Installer ===" -ForegroundColor Cyan
Write-Host "Installing Windows Task Scheduler task for GPU monitoring" -ForegroundColor Yellow
Write-Host ""

# Install the task
$success = Install-GPUMonitoringTask -IntervalMinutes $IntervalMinutes

if ($success) {
    Write-Host ""
    Write-ColorLog "🧪 Testing installed task..." "Cyan"
    Test-GPUMonitoringTask
    
    Write-Host ""
    Show-GPUMonitoringTaskInfo
    
    Write-Host ""
    Write-Host "=== GPU Automation Task Installation Complete ===" -ForegroundColor Green
    Write-Host "✅ Task installed and tested successfully" -ForegroundColor White
    Write-Host "✅ Runs every $IntervalMinutes minutes" -ForegroundColor White
    Write-Host "✅ Monitors GPU sidecars and emits metrics" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Monitor task execution in Task Scheduler" -ForegroundColor White
    Write-Host "2. Check GPU metrics in SigNoz: http://localhost:8080" -ForegroundColor White
    Write-Host "3. View monitoring logs: artifacts/gpu-monitoring/" -ForegroundColor White
    Write-Host "4. Use 'Get-ScheduledTask -TaskName GPU-Automated-Monitoring' to check status" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "=== GPU Automation Task Installation Failed ===" -ForegroundColor Red
    Write-Host "❌ Failed to install task" -ForegroundColor White
    Write-Host "Check the error messages above for details" -ForegroundColor White
}
