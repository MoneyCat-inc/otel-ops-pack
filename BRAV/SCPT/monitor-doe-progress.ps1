#Requires -Version 7.0

<#
.SYNOPSIS
    Background monitoring agent for DOE experiment progress

.DESCRIPTION
    Monitors DOE batch progress and logs completion events.
    Runs in background and can notify when runs complete.

.PARAMETER BatchDir
    DOE batch directory to monitor (e.g., artifacts/doe/stage1-20250922-030818)

.PARAMETER NotifyOnComplete
    Write notification when each run completes

.PARAMETER CheckInterval
    Seconds between progress checks. Default: 30

.EXAMPLE
    .\monitor-doe-progress.ps1 -BatchDir "artifacts/doe/stage1-20250922-030818"
    Monitor DOE batch progress with 30-second intervals
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BatchDir,
    
    [switch]$NotifyOnComplete = $true,
    
    [int]$CheckInterval = 30
)

# Validate batch directory exists
if (-not (Test-Path $BatchDir)) {
    Write-Error "Batch directory not found: $BatchDir"
    exit 1
}

$planFile = Join-Path $BatchDir "batch-plan.json"
$logsDir = Join-Path $BatchDir "logs"

if (-not (Test-Path $planFile)) {
    Write-Error "Batch plan not found: $planFile"
    exit 1
}

Write-Host "DOE Progress Monitor started for: $BatchDir" -ForegroundColor Green
Write-Host "Check interval: $CheckInterval seconds" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$lastCompletedCount = 0

try {
    while ($true) {
        # Load batch plan
        try {
            $plan = Get-Content $planFile | ConvertFrom-Json
            $totalRuns = $plan.runs.Count
            $completedRuns = ($plan.runs | Where-Object { $_.status -eq "completed" }).Count
            $failedRuns = ($plan.runs | Where-Object { $_.status -eq "failed" }).Count
            $pendingRuns = ($plan.runs | Where-Object { $_.status -eq "pending" }).Count
            
            # Check for new completions
            if ($completedRuns -gt $lastCompletedCount) {
                $newCompletions = $completedRuns - $lastCompletedCount
                Write-Host "$(Get-Date): ✅ $newCompletions new run(s) completed!" -ForegroundColor Green
                
                if ($NotifyOnComplete) {
                    # Get details of newly completed runs
                    $recentCompleted = $plan.runs | 
                        Where-Object { $_.status -eq "completed" } | 
                        Sort-Object endTime -Descending | 
                        Select-Object -First $newCompletions
                    
                    foreach ($run in $recentCompleted) {
                        Write-Host "  • $($run.runId) completed at $($run.endTime)" -ForegroundColor Green
                    }
                }
                
                $lastCompletedCount = $completedRuns
            }
            
            # Show current status
            $timestamp = Get-Date -Format "HH:mm:ss"
            Write-Host "[$timestamp] Progress: $completedRuns/$totalRuns completed ($failedRuns failed, $pendingRuns pending)" -ForegroundColor Cyan
            
            # Check if experiment is complete
            if ($pendingRuns -eq 0) {
                Write-Host ""
                Write-Host "🎉 DOE Experiment Complete!" -ForegroundColor Green
                Write-Host "Total runs: $totalRuns" -ForegroundColor Cyan
                Write-Host "Completed: $completedRuns" -ForegroundColor Green
                Write-Host "Failed: $failedRuns" -ForegroundColor Red
                break
            }
            
            # Show next pending run
            $nextRun = $plan.runs | Where-Object { $_.status -eq "pending" } | Select-Object -First 1
            if ($nextRun) {
                if ($nextRun.startTime) {
                    Write-Host "  → Currently running: $($nextRun.runId) (started $($nextRun.startTime))" -ForegroundColor Yellow
                } else {
                    Write-Host "  → Next run: $($nextRun.runId) (waiting to start)" -ForegroundColor Yellow
                }
            }
            
        } catch {
            Write-Warning "Failed to read batch plan: $($_.Exception.Message)"
        }
        
        Write-Host ""
        Start-Sleep -Seconds $CheckInterval
        
    }
} catch {
    if ($_.Exception.Message -notlike "*Cancel*") {
        Write-Error "Monitor error: $($_.Exception.Message)"
    }
} finally {
    Write-Host "DOE Progress Monitor stopped." -ForegroundColor Yellow
}
