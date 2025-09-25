# Setup IONA Scheduled Verification
# Creates Windows Task Scheduler job for daily IONA SigNoz verification
# Requires administrator privileges

param(
    [string]$TaskName = "IONA-SigNoz-Daily-Verification",
    [string]$RunTime = "09:00",
    [int]$JobCount = 2,
    [switch]$EnableTracing = $false,
    [switch]$Force = $false
)

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host "⚠️  Task '$TaskName' already exists. Use -Force to overwrite." -ForegroundColor Yellow
    exit 1
}

# Remove existing task if force is specified
if ($existingTask -and $Force) {
    Write-Host "🗑️  Removing existing task '$TaskName'" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Get script paths
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$dailyScript = "$scriptDir\daily-iona-verification.ps1"
$projectRoot = Split-Path $scriptDir

# Verify daily script exists
if (-not (Test-Path $dailyScript)) {
    Write-Host "❌ Daily verification script not found: $dailyScript" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Setting up scheduled IONA verification task" -ForegroundColor Cyan
Write-Host "   Task Name: $TaskName" -ForegroundColor Gray
Write-Host "   Run Time: Daily at $RunTime" -ForegroundColor Gray
Write-Host "   Job Count: $JobCount" -ForegroundColor Gray
Write-Host "   Tracing: $EnableTracing" -ForegroundColor Gray
Write-Host ""

try {
    # Create action
    $actionArgs = "-NoProfile -File `"$dailyScript`" -JobCount $JobCount"
    if ($EnableTracing) {
        $actionArgs += " -EnableTracing"
    }
    
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument $actionArgs -WorkingDirectory $projectRoot
    
    # Create trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $RunTime
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Create principal (run as SYSTEM with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Daily verification of IONA Supervisor SigNoz integration"
    
    Write-Host "✅ Scheduled task '$TaskName' created successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Task Details:" -ForegroundColor Cyan
    Write-Host "   Name: $TaskName" -ForegroundColor Gray
    Write-Host "   Schedule: Daily at $RunTime" -ForegroundColor Gray
    Write-Host "   Command: pwsh.exe $actionArgs" -ForegroundColor Gray
    Write-Host "   Working Directory: $projectRoot" -ForegroundColor Gray
    Write-Host "   Run As: SYSTEM (Highest Privileges)" -ForegroundColor Gray
    Write-Host ""
    
    # Test the task
    Write-Host "🧪 Testing the scheduled task..." -ForegroundColor Cyan
    try {
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        
        $taskInfo = Get-ScheduledTask -TaskName $TaskName
        $taskState = $taskInfo.State
        
        if ($taskState -eq "Running") {
            Write-Host "✅ Task started successfully (State: $taskState)" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  Task state: $taskState" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️  Could not test task: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📊 Management Commands:" -ForegroundColor Cyan
    Write-Host "   View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Run now: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Stop task: Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Remove task: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   View logs: Get-Content artifacts/daily-iona-verification-*.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📁 Logs will be saved to: artifacts/daily-iona-verification-YYYYMMDD-HHMMSS.log" -ForegroundColor Gray
    Write-Host "📈 Summary reports: artifacts/daily-iona-summary-YYYYMMDD-HHMMSS.json" -ForegroundColor Gray
    
}
catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
