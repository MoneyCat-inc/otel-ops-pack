# Deploy Auto Bot - Automated Bot Deployment and Scheduling
# Sets up the ECRR Auto Bot as a scheduled task for continuous operation

param(
    [switch]$Install = $false,
    [switch]$Uninstall = $false,
    [switch]$Status = $false,
    [int]$CheckIntervalMinutes = 1,
    [switch]$AutoRemediate = $true,
    [string]$TaskName = "ECRR-AutoBot",
    [switch]$Force = $false
)

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Write-Info { param([string]$Message) Write-Host "   [INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "   [SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "   [WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "   [ERROR] $Message" -ForegroundColor Red }

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-AutoBotTask {
    Write-Host "🚀 Installing ECRR Auto Bot as Scheduled Task" -ForegroundColor Green
    Write-Host ""
    
    if (-not (Test-AdminRights)) {
        Write-Error "Administrator rights required to install scheduled task"
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask -and -not $Force) {
        Write-Warning "Scheduled task '$TaskName' already exists"
        Write-Host "Use -Force to overwrite existing task" -ForegroundColor Yellow
        exit 1
    }
    
    # Remove existing task if force is specified
    if ($existingTask -and $Force) {
        Write-Info "Removing existing task '$TaskName'"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Create task action
    $scriptPath = Join-Path $PSScriptRoot "auto-bot.ps1"
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptPath`" -Continuous -AutoRemediate:`$$AutoRemediate"
    
    # Create task trigger (every X minutes)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $CheckIntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 24)
    
    # Create task principal (run as SYSTEM with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "ECRR Auto Bot - Automated Pipeline Monitoring and Remediation"
        
        Write-Success "Auto Bot scheduled task installed successfully"
        Write-Info "Task Name: $TaskName"
        Write-Info "Check Interval: $CheckIntervalMinutes minutes"
        Write-Info "Auto Remediation: $AutoRemediate"
        Write-Info "Runs as: SYSTEM (highest privileges)"
        
        # Start the task immediately
        Write-Info "Starting Auto Bot task..."
        Start-ScheduledTask -TaskName $TaskName
        
        Write-Host ""
        Write-Host "✅ Auto Bot is now running!" -ForegroundColor Green
        Write-Host "   View logs: Get-Content artifacts\auto-bot-*.log -Tail 20" -ForegroundColor White
        Write-Host "   Check status: pwsh -File scripts\deploy-auto-bot.ps1 -Status" -ForegroundColor White
        Write-Host "   Stop bot: pwsh -File scripts\deploy-auto-bot.ps1 -Uninstall" -ForegroundColor White
        
    } catch {
        Write-Error "Failed to install Auto Bot task: $($_.Exception.Message)"
        exit 1
    }
}

function Uninstall-AutoBotTask {
    Write-Host "🛑 Uninstalling ECRR Auto Bot Scheduled Task" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-AdminRights)) {
        Write-Error "Administrator rights required to uninstall scheduled task"
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        exit 1
    }
    
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        Write-Warning "Scheduled task '$TaskName' not found"
        return
    }
    
    try {
        # Stop the task if running
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($taskInfo -and $taskInfo.LastTaskResult -ne 267009) {  # 267009 = task not running
            Write-Info "Stopping running Auto Bot task..."
            Stop-ScheduledTask -TaskName $TaskName
        }
        
        # Unregister the task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        
        Write-Success "Auto Bot scheduled task uninstalled successfully"
        Write-Host ""
        Write-Host "📄 Auto Bot log files are preserved in artifacts\auto-bot-*.log" -ForegroundColor Cyan
        
    } catch {
        Write-Error "Failed to uninstall Auto Bot task: $($_.Exception.Message)"
        exit 1
    }
}

function Show-AutoBotStatus {
    Write-Host "📊 ECRR Auto Bot Status" -ForegroundColor Cyan
    Write-Host ""
    
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        Write-Warning "Auto Bot scheduled task '$TaskName' not found"
        Write-Host "Install with: pwsh -File scripts\deploy-auto-bot.ps1 -Install" -ForegroundColor Yellow
        return
    }
    
    try {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        $taskDetails = Get-ScheduledTask -TaskName $TaskName
        
        Write-Info "Task Name: $($taskDetails.TaskName)"
        Write-Info "Status: $($taskDetails.State)"
        Write-Info "Last Run: $($taskInfo.LastRunTime)"
        Write-Info "Last Result: $($taskInfo.LastTaskResult)"
        Write-Info "Next Run: $($taskInfo.NextRunTime)"
        Write-Info "Run Count: $($taskInfo.NumberOfMissedRuns)"
        
        # Check for recent log files
        $logFiles = Get-ChildItem -Path "artifacts" -Filter "auto-bot-*.log" -ErrorAction SilentlyContinue | 
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($logFiles) {
            Write-Info "Latest Log: $($logFiles.Name) (Updated: $($logFiles.LastWriteTime))"
            
            # Show last few log entries
            Write-Host ""
            Write-Host "📝 Recent Activity:" -ForegroundColor Cyan
            $recentLogs = Get-Content $logFiles.FullName -Tail 5
            foreach ($log in $recentLogs) {
                if ($log -match "\[ERROR\]") {
                    Write-Host "   $log" -ForegroundColor Red
                } elseif ($log -match "\[ACTION\]") {
                    Write-Host "   $log" -ForegroundColor Green
                } elseif ($log -match "\[WARN\]") {
                    Write-Host "   $log" -ForegroundColor Yellow
                } else {
                    Write-Host "   $log" -ForegroundColor White
                }
            }
        }
        
        # Show task configuration
        Write-Host ""
        Write-Host "⚙️ Configuration:" -ForegroundColor Cyan
        $action = $taskDetails.Actions[0]
        Write-Info "Command: $($action.Execute)"
        Write-Info "Arguments: $($action.Arguments)"
        
    } catch {
        Write-Error "Failed to get Auto Bot status: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "🤖 ECRR Auto Bot Deployment Manager" -ForegroundColor Green
Write-Host ""

if ($Install) {
    Install-AutoBotTask
} elseif ($Uninstall) {
    Uninstall-AutoBotTask
} elseif ($Status) {
    Show-AutoBotStatus
} else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Install:    pwsh -File scripts\deploy-auto-bot.ps1 -Install" -ForegroundColor White
    Write-Host "  Uninstall:  pwsh -File scripts\deploy-auto-bot.ps1 -Uninstall" -ForegroundColor White
    Write-Host "  Status:     pwsh -File scripts\deploy-auto-bot.ps1 -Status" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -CheckIntervalMinutes <int>  Check interval in minutes (default: 1)" -ForegroundColor White
    Write-Host "  -AutoRemediate              Enable auto-remediation (default: true)" -ForegroundColor White
    Write-Host "  -TaskName <string>          Custom task name (default: ECRR-AutoBot)" -ForegroundColor White
    Write-Host "  -Force                      Force reinstall existing task" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts\deploy-auto-bot.ps1 -Install -CheckIntervalMinutes 5" -ForegroundColor White
    Write-Host "  pwsh -File scripts\deploy-auto-bot.ps1 -Install -AutoRemediate" -ForegroundColor White
    Write-Host "  pwsh -File scripts\deploy-auto-bot.ps1 -Status" -ForegroundColor White
}
