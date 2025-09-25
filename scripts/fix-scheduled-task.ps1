# fix-scheduled-task.ps1 - Fix OTelHealthCanary scheduled task 0x40 error
param(
    [string]$TaskName = "OTelHealthCanary",
    [string]$ScriptPath = "C:\otel\scripts\OTelHealthCanary.ps1",
    [string]$WorkingDir = "C:\otel\scripts",
    [string]$PwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
)

Write-Host "🔧 Fixing scheduled task: $TaskName" -ForegroundColor Cyan

# Check if PowerShell 7 exists
if (-not (Test-Path $PwshPath)) {
    Write-Host "❌ PowerShell 7 not found at: $PwshPath" -ForegroundColor Red
    Write-Host "   Please install PowerShell 7 or update the path" -ForegroundColor Yellow
    exit 1
}

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ Script not found at: $ScriptPath" -ForegroundColor Red
    Write-Host "   Please ensure the script exists" -ForegroundColor Yellow
    exit 1
}

# Check if working directory exists
if (-not (Test-Path $WorkingDir)) {
    Write-Host "❌ Working directory not found: $WorkingDir" -ForegroundColor Red
    Write-Host "   Please ensure the directory exists" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ All paths verified" -ForegroundColor Green

# Remove existing task if it exists
Write-Host "🧹 Removing existing task..." -ForegroundColor Yellow
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "✅ Existing task removed" -ForegroundColor Green
} catch {
    Write-Host "ℹ️ No existing task to remove" -ForegroundColor Gray
}

# Unblock the script file
Write-Host "🔓 Unblocking script file..." -ForegroundColor Yellow
Unblock-File -Path $ScriptPath -ErrorAction SilentlyContinue

# Create new action with local NTFS paths
Write-Host "🚀 Creating new scheduled task..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction `
    -Execute $PwshPath `
    -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory $WorkingDir

# Create trigger (run every 15 minutes)
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration ([TimeSpan]::MaxValue)

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -RunLevel Highest `
        -User "SYSTEM" `
        -Force
    
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    
    # Start the task
    Write-Host "▶️ Starting task..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $TaskName
    
    # Wait a moment and check status
    Start-Sleep -Seconds 3
    
    $taskInfo = Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo
    Write-Host "📊 Task Status:" -ForegroundColor Cyan
    Write-Host "   Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Gray
    Write-Host "   Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor Gray
    Write-Host "   Next Run Time: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    
    if ($taskInfo.LastTaskResult -eq 0) {
        Write-Host "✅ Task is running successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Task result: $($taskInfo.LastTaskResult)" -ForegroundColor Yellow
        Write-Host "   Check Windows Event Log for details" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Scheduled task fix complete!" -ForegroundColor Green
