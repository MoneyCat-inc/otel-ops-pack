# Schedule ECRR Trend Visualization
# This script sets up automated scheduling for ECRR compliance trend monitoring

param(
    [string]$ScheduleType = "TaskScheduler",  # TaskScheduler, Cron, or Manual
    [string]$Frequency = "Daily",             # Daily, Weekly, or Hourly
    [string]$Time = "06:00",                  # Time to run (HH:MM format)
    [string]$OutputDir = "artifacts",
    [switch]$CreateTask = $false,
    [switch]$GenerateCron = $false,
    [switch]$ShowInstructions = $true
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Trend Scheduling Setup" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Get current directory for script paths
$ScriptPath = (Get-Location).Path
$TrendScript = Join-Path $ScriptPath "scripts\visualize-ecrr-trends.ps1"
$MonitorScript = Join-Path $ScriptPath "scripts\monitor-ecrr-compliance.ps1"

Write-Host "Script Path: $ScriptPath" -ForegroundColor Yellow
Write-Host "Trend Script: $TrendScript" -ForegroundColor Yellow
Write-Host "Monitor Script: $MonitorScript" -ForegroundColor Yellow

if ($CreateTask -and $ScheduleType -eq "TaskScheduler") {
    Write-Host "`nCreating Windows Task Scheduler task..." -ForegroundColor Yellow
    
    $TaskName = "ECRR-Compliance-Trends"
    $TaskDescription = "Generate ECRR compliance trend visualization and update history"
    
    # Create the task action
    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$TrendScript`""
    
    # Create the task trigger
    $Trigger = switch ($Frequency) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -At $Time }
        "Hourly" { New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365) }
        default { New-ScheduledTaskTrigger -Daily -At $Time }
    }
    
    # Create the task settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description $TaskDescription -Force
        Write-Host "✅ Task '$TaskName' created successfully!" -ForegroundColor Green
        Write-Host "   Frequency: $Frequency" -ForegroundColor White
        Write-Host "   Time: $Time" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Failed to create task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($GenerateCron -and $ScheduleType -eq "Cron") {
    Write-Host "`nGenerating cron configuration..." -ForegroundColor Yellow
    
    $CronExpression = switch ($Frequency) {
        "Daily" { "0 6 * * *" }  # Daily at 6 AM
        "Weekly" { "0 6 * * 0" } # Weekly on Sunday at 6 AM
        "Hourly" { "0 * * * *" } # Every hour
        default { "0 6 * * *" }
    }
    
    $CronConfig = @"
# ECRR Compliance Trend Monitoring
# Add this line to your crontab (run 'crontab -e' to edit)
$CronExpression pwsh -File "$TrendScript"

# To add to crontab, run:
# echo '$CronExpression pwsh -File "$TrendScript"' | crontab -
"@
    
    $CronConfig | Out-File -FilePath "$OutputDir/cron-config.txt" -Encoding UTF8
    Write-Host "✅ Cron configuration saved to $OutputDir/cron-config.txt" -ForegroundColor Green
}

if ($ShowInstructions) {
    Write-Host "`nScheduling Instructions:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    
    Write-Host "`n1. Windows Task Scheduler:" -ForegroundColor Cyan
    Write-Host "   - Run this script with -CreateTask to create a scheduled task" -ForegroundColor White
    Write-Host "   - Or manually create a task pointing to: $TrendScript" -ForegroundColor White
    Write-Host "   - Recommended frequency: Daily at 6 AM" -ForegroundColor White
    
    Write-Host "`n2. Linux/macOS Cron:" -ForegroundColor Cyan
    Write-Host "   - Run this script with -GenerateCron to get cron configuration" -ForegroundColor White
    Write-Host "   - Add the cron entry to your crontab" -ForegroundColor White
    Write-Host "   - Recommended: Daily at 6 AM (0 6 * * *)" -ForegroundColor White
    
    Write-Host "`n3. Manual Execution:" -ForegroundColor Cyan
    Write-Host "   - Run: pwsh -File `"$TrendScript`"" -ForegroundColor White
    Write-Host "   - Run: pwsh -File `"$MonitorScript`" (to update history first)" -ForegroundColor White
    
    Write-Host "`n4. CI/CD Integration:" -ForegroundColor Cyan
    Write-Host "   - Add to your CI pipeline to run on schedule" -ForegroundColor White
    Write-Host "   - Use GitHub Actions, Azure DevOps, or Jenkins scheduling" -ForegroundColor White
}

# Note: Linux/macOS monitoring script created separately as scripts/ecrr-trend-monitoring.sh

Write-Host "`nGenerated Files:" -ForegroundColor Green
Write-Host "- $OutputDir/ecrr-trend-monitoring.sh (Linux/macOS monitoring script)" -ForegroundColor White
if ($GenerateCron) {
    Write-Host "- $OutputDir/cron-config.txt (Cron configuration)" -ForegroundColor White
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Choose your scheduling method (Task Scheduler, Cron, or CI/CD)" -ForegroundColor White
Write-Host "2. Set up the schedule for daily trend monitoring" -ForegroundColor White
Write-Host "3. Test the scheduled execution" -ForegroundColor White
Write-Host "4. Set up alerts for compliance drops" -ForegroundColor White
Write-Host "5. Publish the HTML chart for ongoing visibility" -ForegroundColor White
