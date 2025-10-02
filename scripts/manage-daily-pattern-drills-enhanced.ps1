# Enhanced Daily Pattern Drills Management Script
# Updated with enhanced statistical validation capabilities

param(
    [ValidateSet("start", "stop", "status", "logs", "run-now", "run-enhanced", "validate")]
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
        Write-Host "📊 Enhanced Daily Pattern Drills Task Status:" -ForegroundColor Cyan
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($Task) {
            Write-Host "  State: $($Task.State)" -ForegroundColor White
            Write-Host "  Last Run: $($Task.LastRunTime)" -ForegroundColor White
            Write-Host "  Next Run: $($Task.NextRunTime)" -ForegroundColor White
            Write-Host "  Last Result: $($Task.LastTaskResult)" -ForegroundColor White
            Write-Host "  Duration: 600 seconds (Enhanced)" -ForegroundColor White
        } else {
            Write-Host "  Task not found" -ForegroundColor Red
        }
    }
    "logs" {
        Write-Host "📋 Recent Enhanced Pattern Drill Results:" -ForegroundColor Cyan
        $LatestResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($LatestResults) {
            Write-Host "  Latest Results: $($LatestResults.Name) ($($LatestResults.LastWriteTime))" -ForegroundColor White
            $Results = Get-Content $LatestResults.FullName -Raw | ConvertFrom-Json
            Write-Host "  Total Events: $($Results.pattern_results | Measure-Object count -Sum).Sum" -ForegroundColor White
            Write-Host "  Test Duration: $($Results.total_duration) seconds" -ForegroundColor White
            
            # Show Hurst values with interpretation
            Write-Host "
  Pattern Analysis:" -ForegroundColor Yellow
            foreach ($Pattern in $Results.pattern_results) {
                $Hurst = $Pattern.hurst_estimate
                $Interpretation = if ($Hurst -lt 0.4) { "Anti-persistent" } 
                                  elseif ($Hurst -gt 0.6) { "Persistent" }
                                  else { "Random walk" }
                Write-Host "    $($Pattern.pattern): H=$Hurst ($Interpretation)" -ForegroundColor White
            }
        } else {
            Write-Host "  No results found" -ForegroundColor Yellow
        }
    }
    "run-now" {
        Write-Host "🏃 Running pattern drills now (standard)..." -ForegroundColor Green
        pwsh -File "scripts/canary-pattern-drills.ps1" -Pattern All -Duration 300 -Analyze
    }
    "run-enhanced" {
        Write-Host "🚀 Running enhanced pattern drills now..." -ForegroundColor Green
        pwsh -File "scripts/canary-pattern-drills.ps1" -Pattern All -Duration 600 -Analyze
        Write-Host "
📊 Running enhanced statistical validation..." -ForegroundColor Cyan
        pwsh -File "scripts/enhanced-statistical-validation.ps1" -MinSampleSize 50 -TestDuration 600 -GenerateReport
    }
    "validate" {
        Write-Host "🔍 Running enhanced statistical validation..." -ForegroundColor Green
        pwsh -File "scripts/enhanced-statistical-validation.ps1" -MinSampleSize 50 -TestDuration 600 -GenerateReport
        
        Write-Host "
📋 Validation Summary:" -ForegroundColor Cyan
        $ValidationResults = Get-Content "artifacts\enhanced-statistical-validation.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($ValidationResults) {
            Write-Host "  Validations: $($ValidationResults.enhanced_results.Count)" -ForegroundColor White
            Write-Host "  Reliable Samples: $($ValidationResults.reliability_metrics.reliable_samples)" -ForegroundColor White
            Write-Host "  Mean Hurst: $($ValidationResults.statistical_summary.hurst_mean)" -ForegroundColor White
            Write-Host "  Mean CV: $($ValidationResults.statistical_summary.cv_mean)" -ForegroundColor White
        }
    }
}
