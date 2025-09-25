#Requires -Version 7.0

<#
.SYNOPSIS
    Schedule JSON parser error monitoring as a canary for long-term noise detection
.DESCRIPTION
    Creates a scheduled task to run parser error monitoring every 15 minutes
    to detect regressions and long-term noise patterns.
.EXAMPLE
    pwsh -File scripts/schedule-parser-monitoring.ps1
#>

param(
    [switch]$Create,
    [switch]$Remove,
    [switch]$Status
)

$TaskName = "OTel-Parser-Monitoring"
$ScriptPath = Join-Path $PSScriptRoot "monitor-parser-errors.ps1"

function Create-ScheduledTask {
    Write-Host "Creating scheduled task: $TaskName" -ForegroundColor Green
    
    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 365)
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Monitor JSON parser errors every 15 minutes"
    
    Write-Host "✅ Scheduled task created successfully" -ForegroundColor Green
    Write-Host "   - Runs every 15 minutes" -ForegroundColor Cyan
    Write-Host "   - Executes: $ScriptPath" -ForegroundColor Cyan
}

function Remove-ScheduledTask {
    Write-Host "Removing scheduled task: $TaskName" -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "✅ Scheduled task removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to remove task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-TaskStatus {
    Write-Host "Checking scheduled task status: $TaskName" -ForegroundColor Cyan
    
    try {
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        Write-Host "✅ Task exists: $($Task.State)" -ForegroundColor Green
        Write-Host "   - Last Run: $($Task.LastRunTime)" -ForegroundColor Cyan
        Write-Host "   - Next Run: $($Task.NextRunTime)" -ForegroundColor Cyan
        
        $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "   - Last Result: $($TaskInfo.LastTaskResult)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Task not found: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
if ($Create) {
    Create-ScheduledTask
}
elseif ($Remove) {
    Remove-ScheduledTask
}
elseif ($Status) {
    Get-TaskStatus
}
else {
    Write-Host "Usage: pwsh -File scripts/schedule-parser-monitoring.ps1 [-Create|-Remove|-Status]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Create    Create scheduled monitoring task" -ForegroundColor White
    Write-Host "  -Remove    Remove scheduled monitoring task" -ForegroundColor White
    Write-Host "  -Status    Check task status" -ForegroundColor White
}
