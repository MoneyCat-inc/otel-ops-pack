#Requires -Version 7.0

<#
.SYNOPSIS
    Schedule adaptive SigNoz canary monitoring agent

.DESCRIPTION
    Creates a Windows scheduled task to run the adaptive canary monitor daily.
    The adaptive agent analyzes traffic patterns and adjusts monitoring thresholds
    automatically to maintain optimal alerting.

.PARAMETER Action
    Action to perform: "install", "uninstall", "run", "status"

.PARAMETER TaskName
    Name of the scheduled task (default: "SigNoz-Adaptive-Monitor")

.PARAMETER RunTime
    Daily run time in HH:MM format (default: "02:00")

.EXAMPLE
    .\schedule-adaptive-monitor.ps1 -Action install
    .\schedule-adaptive-monitor.ps1 -Action run -RunTime "03:00"
    .\schedule-adaptive-monitor.ps1 -Action uninstall
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "uninstall", "run", "status")]
    [string]$Action,
    
    [string]$TaskName = "SigNoz-Adaptive-Monitor",
    [string]$RunTime = "02:00"
)

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AdaptiveScript = Join-Path $ScriptDir "adaptive-canary-monitor.ps1"

function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

switch ($Action) {
    "install" {
        Write-Info "Installing adaptive SigNoz canary monitoring scheduled task..."
        
        # Check if adaptive script exists
        if (-not (Test-Path $AdaptiveScript)) {
            throw "Adaptive monitor script not found: $AdaptiveScript"
        }
        
        # Create scheduled task action
        $TaskAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$AdaptiveScript`""
        
        # Create scheduled task trigger (daily at specified time)
        $triggerTime = [DateTime]::ParseExact($RunTime, "HH:mm", $null)
        $TaskTrigger = New-ScheduledTaskTrigger -Daily -At $triggerTime
        
        # Create scheduled task settings
        $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
        
        # Create principal (run as SYSTEM with highest privileges)
        $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register the task
        try {
            Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Principal $TaskPrincipal -Force
            Write-Success "Scheduled task '$TaskName' installed successfully"
            Write-Info "Task will run daily at $RunTime"
            Write-Info "Adaptive script: $AdaptiveScript"
            
            # Show task details
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            if ($task) {
                Write-Info "Task status: $($task.State)"
                Write-Info "Next run time: $((Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo).NextRunTime)"
            }
            
        } catch {
            Write-Error "Failed to install scheduled task: $($_.Exception.Message)"
            exit 1
        }
    }
    
    "uninstall" {
        Write-Info "Uninstalling adaptive SigNoz canary monitoring scheduled task..."
        
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Success "Scheduled task '$TaskName' uninstalled successfully"
        } catch {
            if ($_.Exception.Message -like "*not found*") {
                Write-Warning "Scheduled task '$TaskName' was not found"
            } else {
                Write-Error "Failed to uninstall scheduled task: $($_.Exception.Message)"
                exit 1
            }
        }
    }
    
    "run" {
        Write-Info "Running adaptive SigNoz canary monitor manually..."
        
        if (-not (Test-Path $AdaptiveScript)) {
            Write-Error "Adaptive script not found: $AdaptiveScript"
            exit 1
        }
        
        try {
            & $AdaptiveScript
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0) {
                Write-Success "Adaptive monitoring completed successfully"
            } else {
                Write-Warning "Adaptive monitoring completed with issues (exit code: $exitCode)"
            }
            exit $exitCode
        } catch {
            Write-Error "Failed to run adaptive script: $($_.Exception.Message)"
            exit 3
        }
    }
    
    "status" {
        Write-Info "Checking adaptive SigNoz canary monitoring status..."
        
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
            
            Write-Success "Scheduled task '$TaskName' is installed"
            Write-Info "Task state: $($task.State)"
            Write-Info "Last run time: $($taskInfo.LastRunTime)"
            Write-Info "Last result: $($taskInfo.LastTaskResult)"
            Write-Info "Next run time: $($taskInfo.NextRunTime)"
            
            # Check if adaptive script exists
            if (Test-Path $AdaptiveScript) {
                Write-Success "Adaptive script found: $AdaptiveScript"
            } else {
                Write-Warning "Adaptive script not found: $AdaptiveScript"
            }
            
            # Check recent analysis reports
            $artifactsDir = Join-Path (Split-Path -Parent $ScriptDir) "artifacts"
            if (Test-Path $artifactsDir) {
                $recentReports = Get-ChildItem -Path $artifactsDir -Filter "adaptive-canary-analysis-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
                if ($recentReports) {
                    Write-Info "Recent analysis reports:"
                    foreach ($report in $recentReports) {
                        Write-Info "  - $($report.Name) ($($report.LastWriteTime))"
                    }
                } else {
                    Write-Warning "No recent analysis reports found"
                }
                
                # Check for analysis errors
                $errorReports = Get-ChildItem -Path $artifactsDir -Filter "adaptive-canary-analysis-error-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($errorReports) {
                    Write-Warning "Recent analysis error found: $($errorReports[0].Name)"
                }
            }
            
        } catch {
            Write-Warning "Scheduled task '$TaskName' is not installed"
            Write-Info "Run with -Action install to set up adaptive monitoring"
        }
    }
}
