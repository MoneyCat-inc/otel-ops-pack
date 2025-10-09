# Setup Queue Steward Daily Guardrail Scheduled Task
# Creates a Windows Scheduled Task to run the daily canary guardrail

param(
    [string]$TaskName = "QueueStewardDailyGuardrail",
    [string]$ScriptPath = "C:\otel\scripts\queue-steward-daily-guardrail.ps1",
    [string]$StartTime = "09:00",
    [switch]$Force = $false
)

Write-Host "🔧 Setting up Queue Steward Daily Guardrail Scheduled Task" -ForegroundColor Cyan

# Check if running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator to create scheduled tasks" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host "⚠️ Task '$TaskName' already exists" -ForegroundColor Yellow
    Write-Host "Use -Force to overwrite, or choose a different task name" -ForegroundColor Gray
    exit 1
}

# Remove existing task if Force is specified
if ($existingTask -and $Force) {
    Write-Host "🗑️ Removing existing task '$TaskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

try {
    # Create the action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    # Create the trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Create the principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    Write-Host "📅 Creating scheduled task '$TaskName'..." -ForegroundColor Yellow
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Queue Steward Daily Canary Guardrail - Verifies pipeline health and emits canary logs"
    
    Write-Host "✅ Scheduled task '$TaskName' created successfully" -ForegroundColor Green
    Write-Host "   Runs daily at $StartTime" -ForegroundColor Gray
    Write-Host "   Script: $ScriptPath" -ForegroundColor Gray
    
    # Test the task
    Write-Host "`n🧪 Testing the scheduled task..." -ForegroundColor Yellow
    try {
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        
        $taskInfo = Get-ScheduledTask -TaskName $TaskName
        $taskState = $taskInfo.State
        
        Write-Host "   Task State: $taskState" -ForegroundColor Gray
        
        if ($taskState -eq "Running") {
            Write-Host "✅ Task started successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Task state: $taskState" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Failed to test task: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Show task information
    Write-Host "`n📋 Task Information:" -ForegroundColor Cyan
    $taskInfo = Get-ScheduledTask -TaskName $TaskName
    Write-Host "   Name: $($taskInfo.TaskName)" -ForegroundColor Gray
    Write-Host "   State: $($taskInfo.State)" -ForegroundColor Gray
    Write-Host "   Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
    Write-Host "   Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    
    # Show how to manage the task
    Write-Host "`n🔧 Task Management Commands:" -ForegroundColor Cyan
    Write-Host "   View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Run task: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Stop task: Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "   Remove task: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    
    Write-Host "`n🎉 Queue Steward Daily Guardrail setup complete!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
