# WER PhoneExperienceHost Task Scheduler Helper
# Creates/updates scheduled task for automated WER crash monitoring
# Usage: .\schedule-wer-phoneexperience.ps1 -IntervalMinutes 15

param(
    [int]$IntervalMinutes = 15,
    [switch]$Remove
)

$TaskName = "SigNoz-WER-PhoneExperience"
$ScriptPath = Join-Path $PSScriptRoot "capture-wer-phoneexperience.ps1"

# Ensure script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ Capture script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

if ($Remove) {
    Write-Host "🗑️  Removing scheduled task: $TaskName" -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "✅ Task removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Task may not exist or removal failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "⚙️  Setting up WER monitoring task: $TaskName (every $IntervalMinutes minutes)" -ForegroundColor Cyan

# Create task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Create task trigger (repeating every N minutes)
$Trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365) -Once -At (Get-Date).AddMinutes(1)

# Create task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -WakeToRun

# Create task principal (highest privileges)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try {
    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Monitor PhoneExperienceHost WER crashes for SigNoz observability" -Force
    
    Write-Host "✅ Scheduled task created successfully" -ForegroundColor Green
    Write-Host "📋 Task Details:" -ForegroundColor Magenta
    Write-Host "   Name: $TaskName" -ForegroundColor White
    Write-Host "   Interval: Every $IntervalMinutes minutes" -ForegroundColor White
    Write-Host "   Script: $ScriptPath" -ForegroundColor White
    Write-Host "   Principal: SYSTEM (Highest privileges)" -ForegroundColor White
    
    # Show task status
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($Task) {
        Write-Host "   Status: $($Task.State)" -ForegroundColor White
        Write-Host "   Last Run: $($Task.LastRunTime)" -ForegroundColor White
        Write-Host "   Next Run: $($Task.NextRunTime)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 To verify the task:" -ForegroundColor Cyan
Write-Host "   Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "`n🗑️  To remove the task:" -ForegroundColor Cyan
Write-Host "   pwsh -File '$PSCommandPath' -Remove" -ForegroundColor White