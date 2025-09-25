#Requires -Version 7.0

<#
.SYNOPSIS
    Schedule SigNoz canary monitoring as a Windows scheduled task

.DESCRIPTION
    Creates a Windows scheduled task to run the SigNoz canary monitor every hour.
    The task will alert if canary ingestion drops to 0 or spikes unexpectedly.

.PARAMETER Action
    Action to perform: "install", "uninstall", "run", "status"

.PARAMETER TaskName
    Name of the scheduled task (default: "SigNoz-Canary-Monitor")

.PARAMETER IntervalMinutes
    Monitoring interval in minutes (default: 60)

.EXAMPLE
    .\schedule-signoz-canary-monitor.ps1 -Action install
    .\schedule-signoz-canary-monitor.ps1 -Action run
    .\schedule-signoz-canary-monitor.ps1 -Action uninstall
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "uninstall", "run", "status")]
    [string]$Action,
    
    [string]$TaskName = "SigNoz-Canary-Monitor",
    [int]$IntervalMinutes = 60
)

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MonitorScript = Join-Path $ScriptDir "monitor-signoz-canary.ps1"

function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

switch ($Action) {
    "install" {
        Write-Info "Installing SigNoz canary monitoring scheduled task..."
        
        # Check if monitor script exists
        if (-not (Test-Path $MonitorScript)) {
            throw "Monitor script not found: $MonitorScript"
        }
        
        # Create scheduled task action
        $TaskAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$MonitorScript`""
        
        # Create scheduled task trigger (every hour)
        $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)
        
        # Create scheduled task settings
        $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        
        # Create principal (run as SYSTEM with highest privileges)
        $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register the task
        try {
            Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Principal $TaskPrincipal -Force
            Write-Success "Scheduled task '$TaskName' installed successfully"
            Write-Info "Task will run every $IntervalMinutes minutes"
            Write-Info "Monitor script: $MonitorScript"
            
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
        Write-Info "Uninstalling SigNoz canary monitoring scheduled task..."
        
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
        Write-Info "Running SigNoz canary monitor manually..."
        
        if (-not (Test-Path $MonitorScript)) {
            Write-Error "Monitor script not found: $MonitorScript"
            exit 1
        }
        
        try {
            & $MonitorScript
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0) {
                Write-Success "Canary monitoring completed successfully"
            } elseif ($exitCode -eq 1) {
                Write-Warning "Canary monitoring completed with warnings"
            } elseif ($exitCode -eq 2) {
                Write-Error "Canary monitoring detected critical issues"
            } else {
                Write-Error "Canary monitoring failed with exit code: $exitCode"
            }
            exit $exitCode
        } catch {
            Write-Error "Failed to run monitor script: $($_.Exception.Message)"
            exit 3
        }
    }
    
    "status" {
        Write-Info "Checking SigNoz canary monitoring status..."
        
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
            
            Write-Success "Scheduled task '$TaskName' is installed"
            Write-Info "Task state: $($task.State)"
            Write-Info "Last run time: $($taskInfo.LastRunTime)"
            Write-Info "Last result: $($taskInfo.LastTaskResult)"
            Write-Info "Next run time: $($taskInfo.NextRunTime)"
            
            # Check if monitor script exists
            if (Test-Path $MonitorScript) {
                Write-Success "Monitor script found: $MonitorScript"
            } else {
                Write-Warning "Monitor script not found: $MonitorScript"
            }
            
            # Check recent artifacts
            $artifactsDir = Join-Path (Split-Path -Parent $ScriptDir) "artifacts"
            if (Test-Path $artifactsDir) {
                $recentReports = Get-ChildItem -Path $artifactsDir -Filter "signoz-canary-monitor-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
                if ($recentReports) {
                    Write-Info "Recent monitoring reports:"
                    foreach ($report in $recentReports) {
                        Write-Info "  - $($report.Name) ($($report.LastWriteTime))"
                    }
                } else {
                    Write-Warning "No recent monitoring reports found"
                }
            }
            
        } catch {
            Write-Warning "Scheduled task '$TaskName' is not installed"
            Write-Info "Run with -Action install to set up monitoring"
        }
    }
}
