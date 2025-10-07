param(
    [string]$TaskName = "MemX Hardware Audit",
    [string]$Schedule = "Daily",
    [string]$Time = "02:00",
    [string]$OutputDir = "artifacts/memx/hardware"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue)) {
    Write-Error "ScheduledTasks module not available. Run on Windows with admin rights."
    exit 1
}

$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\run-hardware-audit.ps1`" -OutputDir `"$OutputDir`""

switch ($Schedule.ToLower()) {
    'hourly' { $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(5); $trigger.Repetition = (New-TimeSpan -Minutes 60) }
    'daily'  { $trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($Time,'HH:mm',$null)) }
    default  { $trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($Time,'HH:mm',$null)) }
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description "Run MemX hardware audit and persist JSON report" -Force | Out-Null

Write-Host "✅ Scheduled task '$TaskName' registered ($Schedule at $Time)" -ForegroundColor Green
exit 0


