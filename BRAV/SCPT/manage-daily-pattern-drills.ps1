# Daily Pattern Drills Management Script
# Use this script to manage the automated daily pattern drills

param(
    [ValidateSet("start", "stop", "status", "logs", "run-now")]
    [string]$Action = "status"
)

$TaskName = "Daily Canary Pattern Drills"

switch ($Action) {
    "start" {
        Write-Host "🚀 Starting daily pattern drills task..." -ForegroundColor Green
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "✅ Task started" -ForegroundColor Green
    }
    "stop" {
        Write-Host "🛑 Stopping daily pattern drills task..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Write-Host "✅ Task stopped" -ForegroundColor Green
    }
    "status" {
        Write-Host "📊 Daily Pattern Drills Task Status:" -ForegroundColor Cyan
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($Task) {
            Write-Host "  State: $($Task.State)" -ForegroundColor White
            Write-Host "  Last Run: $($Task.LastRunTime)" -ForegroundColor White
            Write-Host "  Next Run: $($Task.NextRunTime)" -ForegroundColor White
            Write-Host "  Last Result: $($Task.LastTaskResult)" -ForegroundColor White
        } else {
            Write-Host "  Task not found" -ForegroundColor Red
        }
    }
    "logs" {
        Write-Host "📋 Recent Pattern Drill Results:" -ForegroundColor Cyan
        $LatestResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($LatestResults) {
            Write-Host "  Latest Results: $($LatestResults.Name) ($($LatestResults.LastWriteTime))" -ForegroundColor White
            $Results = Get-Content $LatestResults.FullName -Raw | ConvertFrom-Json
            Write-Host "  Total Events: $($Results.pattern_results | Measure-Object count -Sum).Sum" -ForegroundColor White
            Write-Host "  Test Duration: $($Results.total_duration) seconds" -ForegroundColor White
        } else {
            Write-Host "  No results found" -ForegroundColor Yellow
        }
    }
    "run-now" {
        Write-Host "🏃 Running pattern drills now..." -ForegroundColor Green
        pwsh -File "scripts\canary-pattern-drills.ps1" -Pattern All -Duration 300 -Analyze
    }
}
