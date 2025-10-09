[CmdletBinding()]
param(
    [ValidateSet("TaskScheduler", "Cron", "Manual")]
    [string]$ScheduleType = "TaskScheduler",
    [switch]$DryRun
)

# Import progress indicators module
. .\BRAV\SCPT\progress-indicators.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

$tasks = @(
    [pscustomobject]@{
        Name = "OTel-Daily-Health-Check"
        Description = "Daily health verification for the Windows to SigNoz pipeline"
        Script = "scripts/simple-optimization-test.ps1"
        Frequency = "Daily"
        Time = "09:00"
        RepeatMinutes = $null
        Enabled = $true
    },
    [pscustomobject]@{
        Name = "OTel-Analytics-Monitoring"
        Description = "Continuous analytics ingestion monitor"
        Script = "scripts/enhanced-analytics-monitor.ps1"
        Frequency = "Periodic"
        Time = "00:00"
        RepeatMinutes = 30
        Enabled = $true
    },
    [pscustomobject]@{
        Name = "OTel-Canary-Test"
        Description = "Hourly canary event to validate end to end path"
        Script = "scripts/canary-ecrr.ps1"
        Frequency = "Periodic"
        Time = "00:00"
        RepeatMinutes = 60
        Enabled = $true
    }
)

Write-Host "[INFO] Configuring monitoring automation ($ScheduleType)" -ForegroundColor Cyan

switch ($ScheduleType) {
    "TaskScheduler" {
        foreach ($task in $tasks) {
            if (-not $task.Enabled) { continue }

            $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NoProfile -File `"$projectRoot\$($task.Script)`""

            switch ($task.Frequency) {
                "Daily" {
                    $trigger = New-ScheduledTaskTrigger -Daily -At $task.Time
                }
                "Periodic" {
                    $startTime = (Get-Date).AddMinutes(1)
                    $interval = if ($task.RepeatMinutes) { New-TimeSpan -Minutes $task.RepeatMinutes } else { New-TimeSpan -Minutes 30 }
                    $trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval $interval -RepetitionDuration (New-TimeSpan -Days 365)
                }
                default {
                    $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
                }
            }

            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

            if ($DryRun) {
                Write-Host "[INFO] Dry run - would register task $($task.Name)" -ForegroundColor Cyan
            } else {
                $spinnerJob = Start-SpinnerJob -Message "Registering task $($task.Name)..." -UpdateIntervalMs 150
                if (Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue) {
                    Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
                }
                Register-ScheduledTask -TaskName $task.Name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $task.Description | Out-Null
                Stop-SpinnerJob -Job $spinnerJob
                Write-Host "[INFO] Registered task $($task.Name)" -ForegroundColor Green
            }
        }
    }
    "Cron" {
        $cronLines = @()
        foreach ($task in $tasks) {
            if (-not $task.Enabled) { continue }
            switch ($task.Frequency) {
                "Daily" { $cron = "0 9 * * *" }
                "Periodic" {
                    if ($task.RepeatMinutes -eq 60) { $cron = "0 * * * *" }
                    else { $cron = "*/30 * * * *" }
                }
                default { $cron = "0 9 * * *" }
            }
            $cronLines += "$cron cd '$projectRoot' && pwsh -NoLogo -NoProfile -File '$projectRoot/$($task.Script)'"
            Write-Host "[INFO] Cron entry for $($task.Name): $cron" -ForegroundColor White
        }
        $cronPath = "config/monitoring-crontab.txt"
        $cronLines | Out-File -FilePath $cronPath -Encoding utf8NoBOM
        Write-Host "[INFO] Cron template written to $cronPath" -ForegroundColor Green
    }
    "Manual" {
        foreach ($task in $tasks) {
            if (-not $task.Enabled) { continue }
            Write-Host "[INFO] Manual task $($task.Name): run pwsh -File $($task.Script)" -ForegroundColor White
        }
    }
}

$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = "artifacts/monitoring-automation-$timestamp.json"
$tasks | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding utf8NoBOM
Write-Host "[INFO] Report saved to $reportPath" -ForegroundColor Green

Write-Host "[NEXT] Verify tasks with Get-ScheduledTask -TaskName 'OTel-*'" -ForegroundColor White
Write-Host "[NEXT] Review task history in Event Viewer after first run" -ForegroundColor White
