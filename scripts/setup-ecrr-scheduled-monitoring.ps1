# Setup ECRR Scheduled Monitoring
param(
    [string]$TaskName = "ECRR Compliance Monitor",
    [string]$ScriptPath = "scripts/ecrr-compliance-monitor.ps1",
    [string]$WorkingDirectory = (Get-Location).Path,
    [int]$IntervalHours = 6,
    [switch]$Force = $false
)

Write-Host "🔧 Setting up ECRR Scheduled Monitoring" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires administrator privileges to create scheduled tasks." -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Validate script path
$fullScriptPath = Join-Path $WorkingDirectory $ScriptPath
if (-not (Test-Path $fullScriptPath)) {
    Write-Host "❌ Script not found: $fullScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Working Directory: $WorkingDirectory" -ForegroundColor Gray
Write-Host "📜 Script Path: $fullScriptPath" -ForegroundColor Gray
Write-Host "⏰ Interval: Every $IntervalHours hours" -ForegroundColor Gray
Write-Host ""

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    if ($Force) {
        Write-Host "🗑️  Removing existing task: $TaskName" -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    } else {
        Write-Host "⚠️  Task '$TaskName' already exists. Use -Force to replace it." -ForegroundColor Yellow
        exit 1
    }
}

# Create the action
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$fullScriptPath`"" -WorkingDirectory $WorkingDirectory

# Create the trigger (every 6 hours)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $IntervalHours) -RepetitionDuration ([TimeSpan]::MaxValue)

# Create the settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create the principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the task
Write-Host "🔧 Creating scheduled task: $TaskName" -ForegroundColor Cyan
$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated ECRR compliance monitoring and reporting"

# Register the task
Register-ScheduledTask -TaskName $TaskName -InputObject $task | Out-Null

Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName" -ForegroundColor Gray
Write-Host "  Script: $fullScriptPath" -ForegroundColor Gray
Write-Host "  Interval: Every $IntervalHours hours" -ForegroundColor Gray
Write-Host "  User: SYSTEM" -ForegroundColor Gray
Write-Host "  Logon Type: Service Account" -ForegroundColor Gray
Write-Host ""

# Test the task
Write-Host "🧪 Testing the task..." -ForegroundColor Cyan
try {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "✅ Task started successfully!" -ForegroundColor Green
    
    # Wait a moment and check status
    Start-Sleep -Seconds 3
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "  Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Gray
    Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error starting task: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 Management Commands:" -ForegroundColor Cyan
Write-Host "  View Task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Start Task: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Stop Task:  Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Delete Task: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Gray
Write-Host ""
Write-Host "📁 Output Location: artifacts/ecrr-compliance-report-*.json" -ForegroundColor Gray
Write-Host "🌐 Dashboard: artifacts/ecrr-compliance-dashboard.html" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 ECRR Scheduled Monitoring setup complete!" -ForegroundColor Green
