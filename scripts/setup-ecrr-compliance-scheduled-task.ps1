# ECRR Compliance Scheduled Task Setup
# Creates a Windows scheduled task to run compliance monitoring every 15 minutes

param(
    [switch]$Install,
    [switch]$Remove,
    [switch]$Status,
    [string]$TaskName = "ECRR-Compliance-Monitor",
    [string]$ScriptPath = "C:\otel\scripts\continuous-ecrr-compliance-monitor.ps1"
)

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-ECRRComplianceTask {
    Write-ECRRLog "Installing ECRR Compliance Monitoring scheduled task..." "INFO"
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ECRRLog "ERROR: This script must be run as Administrator to install scheduled tasks" "ERROR"
        return $false
    }
    
    # Check if script exists
    if (-not (Test-Path $ScriptPath)) {
        Write-ECRRLog "ERROR: Script not found at $ScriptPath" "ERROR"
        return $false
    }
    
    try {
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-ECRRLog "Removing existing task..." "INFO"
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        
        # Create the action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -GenerateReport"
        
        # Create the trigger (every 15 minutes)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 365)
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        
        # Create the principal (run as SYSTEM)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "ECRR Compliance Monitoring - Runs every 15 minutes to check compliance and generate reports"
        
        Write-ECRRLog "Scheduled task '$TaskName' installed successfully" "SUCCESS"
        Write-ECRRLog "Task will run every 15 minutes starting now" "INFO"
        Write-ECRRLog "Script path: $ScriptPath" "INFO"
        
        return $true
    }
    catch {
        Write-ECRRLog "ERROR: Failed to install scheduled task: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-ECRRComplianceTask {
    Write-ECRRLog "Removing ECRR Compliance Monitoring scheduled task..." "INFO"
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ECRRLog "ERROR: This script must be run as Administrator to remove scheduled tasks" "ERROR"
        return $false
    }
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-ECRRLog "Scheduled task '$TaskName' removed successfully" "SUCCESS"
            return $true
        } else {
            Write-ECRRLog "Task '$TaskName' not found" "WARN"
            return $true
        }
    }
    catch {
        Write-ECRRLog "ERROR: Failed to remove scheduled task: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-ECRRComplianceTaskStatus {
    Write-ECRRLog "Checking ECRR Compliance Monitoring task status..." "INFO"
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
            
            Write-Host "`nTask Information:" -ForegroundColor Cyan
            Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
            Write-Host "  State: $($task.State)" -ForegroundColor White
            Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
            Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
            Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor White
            
            if ($task.State -eq "Running") {
                Write-ECRRLog "Task is currently running" "SUCCESS"
            } elseif ($task.State -eq "Ready") {
                Write-ECRRLog "Task is ready and scheduled" "SUCCESS"
            } else {
                Write-ECRRLog "Task state: $($task.State)" "WARN"
            }
            
            return $true
        } else {
            Write-ECRRLog "Task '$TaskName' not found" "WARN"
            return $false
        }
    }
    catch {
        Write-ECRRLog "ERROR: Failed to get task status: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    if ($Install) {
        $success = Install-ECRRComplianceTask
        if ($success) {
            Write-ECRRLog "Installation completed successfully" "SUCCESS"
            exit 0
        } else {
            Write-ECRRLog "Installation failed" "ERROR"
            exit 1
        }
    }
    elseif ($Remove) {
        $success = Remove-ECRRComplianceTask
        if ($success) {
            Write-ECRRLog "Removal completed successfully" "SUCCESS"
            exit 0
        } else {
            Write-ECRRLog "Removal failed" "ERROR"
            exit 1
        }
    }
    elseif ($Status) {
        $success = Get-ECRRComplianceTaskStatus
        exit $(if ($success) { 0 } else { 1 })
    }
    else {
        Write-Host "ECRR Compliance Scheduled Task Manager" -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  -Install    Install the scheduled task" -ForegroundColor White
        Write-Host "  -Remove     Remove the scheduled task" -ForegroundColor White
        Write-Host "  -Status     Check task status" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\setup-ecrr-compliance-scheduled-task.ps1 -Install" -ForegroundColor White
        Write-Host "  .\setup-ecrr-compliance-scheduled-task.ps1 -Status" -ForegroundColor White
        Write-Host "  .\setup-ecrr-compliance-scheduled-task.ps1 -Remove" -ForegroundColor White
        Write-Host ""
        Write-Host "Note: Install and Remove operations require Administrator privileges" -ForegroundColor Yellow
    }
}
catch {
    Write-ECRRLog "ERROR: Unexpected error: $($_.Exception.Message)" "ERROR"
    exit 1
}
