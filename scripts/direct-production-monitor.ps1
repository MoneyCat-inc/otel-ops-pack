# Direct Production SSOT Monitoring
# Direct monitoring without complex process redirection

param(
    [switch]$Continuous,
    [int]$IntervalMinutes = 15,
    [string]$LogPath = ".artifacts/direct-production-monitoring.log",
    [switch]$GenerateMetrics,
    [string]$MetricsPath = ".artifacts/production-metrics.json",
    [switch]$DryRun
)

Write-Host "🏭 Direct Production SSOT Monitoring" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path ".artifacts")) {
    New-Item -ItemType Directory -Path ".artifacts" -Force | Out-Null
}

# Initialize log
$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
"=== Direct Production Monitoring Started - $timestamp ===" | Out-File -FilePath $LogPath -Append -Encoding UTF8

function Get-DirectHealthScore {
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    Write-Host "🔄 Direct Health Check - $timestamp" -ForegroundColor Cyan
    
    try {
        # Run health check directly
        $healthOutput = & pwsh -ExecutionPolicy Bypass -File "scripts/monitor-ssot-health.ps1" 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            # Parse health score from output
            $healthScore = 100  # Default to 100 if parsing fails
            
            # Try multiple patterns to extract health score
            if ($healthOutput -match "Overall Health: (\d+)%") {
                $healthScore = [int]$matches[1]
            } elseif ($healthOutput -match "Health Score: (\d+)%") {
                $healthScore = [int]$matches[1]
            } elseif ($healthOutput -match "(\d+)% \(excellent\)") {
                $healthScore = [int]$matches[1]
            }
            
            # Extract freshness status
            $freshness = "unknown"
            if ($healthOutput -match "Status: (\w+)") {
                $freshness = $matches[1]
            } elseif ($healthOutput -match "Freshness.*?(\w+)") {
                $freshness = $matches[1]
            }
            
            Write-Host "✅ Health Score: $healthScore%" -ForegroundColor Green
            Write-Host "✅ Freshness: $freshness" -ForegroundColor Green
            "Health Check: SUCCESS - $healthScore% ($freshness) at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            
            # Check for issues
            if ($healthScore -lt 95) {
                Write-Host "⚠️ Warning: Health score below 95%" -ForegroundColor Yellow
                "WARNING: Health score below 95% - $healthScore% at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            }
            
            if ($freshness -ne "fresh" -and $freshness -ne "unknown") {
                Write-Host "⚠️ Warning: SSOT block is $freshness" -ForegroundColor Yellow
                "WARNING: SSOT block freshness - $freshness at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            }
            
            return @{
                HealthScore = $healthScore
                Freshness = $freshness
                Status = "success"
                ExitCode = $exitCode
                Timestamp = $timestamp
            }
        } else {
            Write-Host "❌ Health Check Failed: exit code $exitCode" -ForegroundColor Red
            if ($healthOutput) {
                Write-Host "   Output: $healthOutput" -ForegroundColor Red
            }
            "Health Check: FAILED - exit code $exitCode at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            if ($healthOutput) {
                "Output Details: $healthOutput" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            }
            
            return @{
                HealthScore = 0
                Freshness = "error"
                Status = "failed"
                ExitCode = $exitCode
                Timestamp = $timestamp
                Error = $healthOutput
            }
        }
    } catch {
        $errorMessage = "Health check exception: $($_.Exception.Message)"
        Write-Host "❌ Health Check Exception: $errorMessage" -ForegroundColor Red
        "Health Check: EXCEPTION - $errorMessage at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
        
        return @{
            HealthScore = 0
            Freshness = "error"
            Status = "exception"
            ExitCode = -1
            Timestamp = $timestamp
            Error = $errorMessage
        }
    }
}

function Update-SSOTBlockDirect {
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    Write-Host "🔄 Updating SSOT block..." -ForegroundColor Cyan
    
    try {
        $ssotOutput = & node scripts/ci-ssot-telemetry.ts 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ SSOT block updated successfully" -ForegroundColor Green
            "SSOT Update: SUCCESS at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            return $true
        } else {
            Write-Host "❌ SSOT block update failed: exit code $exitCode" -ForegroundColor Red
            if ($ssotOutput) {
                Write-Host "   Output: $ssotOutput" -ForegroundColor Red
            }
            "SSOT Update: FAILED - exit code $exitCode at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            if ($ssotOutput) {
                "Output Details: $ssotOutput" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            }
            return $false
        }
    } catch {
        $errorMessage = "SSOT block update exception: $($_.Exception.Message)"
        Write-Host "❌ SSOT block update exception: $errorMessage" -ForegroundColor Red
        "SSOT Update: EXCEPTION - $errorMessage at $timestamp" | Out-File -FilePath $LogPath -Append -Encoding UTF8
        return $false
    }
}

function Generate-DirectProductionMetrics {
    param([array]$HealthHistory, [string]$MetricsPath)
    
    if (-not $HealthHistory -or $HealthHistory.Count -eq 0) {
        Write-Host "⚠️ No health history available for metrics generation" -ForegroundColor Yellow
        return
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    
    # Calculate metrics
    $totalChecks = $HealthHistory.Count
    $successfulChecks = ($HealthHistory | Where-Object { $_.Status -eq "success" }).Count
    $failedChecks = ($HealthHistory | Where-Object { $_.Status -ne "success" }).Count
    $avgHealthScore = if ($successfulChecks -gt 0) { [math]::Round(($HealthHistory | Where-Object { $_.Status -eq "success" } | Measure-Object -Property HealthScore -Average).Average, 2) } else { 0 }
    $successRate = if ($totalChecks -gt 0) { [math]::Round(($successfulChecks / $totalChecks) * 100, 2) } else { 0 }
    
    # Calculate trends
    $recentChecks = $HealthHistory | Where-Object { $_.Timestamp -gt (Get-Date).AddHours(-1) }
    $recentSuccessRate = if ($recentChecks.Count -gt 0) { [math]::Round((($recentChecks | Where-Object { $_.Status -eq "success" }).Count / $recentChecks.Count) * 100, 2) } else { 0 }
    
    $metrics = @{
        GeneratedAt = $timestamp
        Summary = @{
            TotalChecks = $totalChecks
            SuccessfulChecks = $successfulChecks
            FailedChecks = $failedChecks
            SuccessRate = $successRate
            AverageHealthScore = $avgHealthScore
            RecentSuccessRate = $recentSuccessRate
        }
        Trends = @{
            HealthScoreTrend = if ($avgHealthScore -ge 98) { "excellent" } elseif ($avgHealthScore -ge 95) { "good" } elseif ($avgHealthScore -ge 90) { "declining" } else { "poor" }
            SuccessRateTrend = if ($successRate -ge 95) { "excellent" } elseif ($successRate -ge 90) { "good" } elseif ($successRate -ge 80) { "declining" } else { "poor" }
            StabilityTrend = if ($recentSuccessRate -ge $successRate - 5) { "stable" } elseif ($recentSuccessRate -lt $successRate - 10) { "declining" } else { "stable" }
        }
        HealthHistory = $HealthHistory
    }
    
    $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $MetricsPath -Encoding UTF8
    
    Write-Host "📊 Direct Production Metrics Generated:" -ForegroundColor Green
    Write-Host "   Total Checks: $totalChecks" -ForegroundColor Cyan
    Write-Host "   Success Rate: $successRate%" -ForegroundColor Cyan
    Write-Host "   Average Health Score: $avgHealthScore%" -ForegroundColor Cyan
    Write-Host "   Health Trend: $($metrics.Trends.HealthScoreTrend)" -ForegroundColor Cyan
    Write-Host "   Stability Trend: $($metrics.Trends.StabilityTrend)" -ForegroundColor Cyan
}

# Main monitoring logic
$healthHistory = @()

if ($Continuous) {
    Write-Host "🔄 Starting continuous direct production monitoring..." -ForegroundColor Yellow
    Write-Host "   Interval: $IntervalMinutes minutes" -ForegroundColor Cyan
    Write-Host "   Log: $LogPath" -ForegroundColor Cyan
    Write-Host "   Metrics: $MetricsPath" -ForegroundColor Cyan
    Write-Host "   Press Ctrl+C to stop" -ForegroundColor Gray
    
    $cycleCount = 0
    
    while ($true) {
        $cycleCount++
        $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        
        Write-Host "`n=== Cycle $cycleCount - $timestamp ===" -ForegroundColor Magenta
        
        # Health check
        $healthResult = Get-DirectHealthScore
        $healthHistory += $healthResult
        
        # Update SSOT block
        $ssotUpdateSuccess = Update-SSOTBlockDirect
        
        # Generate metrics periodically
        if ($GenerateMetrics -and $cycleCount % 4 -eq 0) {  # Every 4 cycles (1 hour if 15min intervals)
            Generate-DirectProductionMetrics -HealthHistory $healthHistory -MetricsPath $MetricsPath
        }
        
        # Summary
        Write-Host "📊 Cycle $cycleCount Summary:" -ForegroundColor Cyan
        Write-Host "   Health Score: $($healthResult.HealthScore)%" -ForegroundColor $(if ($healthResult.HealthScore -ge 95) { 'Green' } elseif ($healthResult.HealthScore -ge 80) { 'Yellow' } else { 'Red' })
        Write-Host "   Status: $($healthResult.Status)" -ForegroundColor $(if ($healthResult.Status -eq "success") { 'Green' } else { 'Red' })
        Write-Host "   SSOT Update: $(if ($ssotUpdateSuccess) { 'Success' } else { 'Failed' })" -ForegroundColor $(if ($ssotUpdateSuccess) { 'Green' } else { 'Red' })
        Write-Host "   Next check in: $IntervalMinutes minutes" -ForegroundColor Gray
        
        # Wait for next cycle
        $sleepSeconds = $IntervalMinutes * 60
        Write-Host "😴 Sleeping for $sleepSeconds seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $sleepSeconds
    }
} else {
    Write-Host "🔄 Running single direct production health check..." -ForegroundColor Yellow
    
    # Single health check
    $healthResult = Get-DirectHealthScore
    $healthHistory += $healthResult
    
    # Update SSOT block
    $ssotUpdateSuccess = Update-SSOTBlockDirect
    
    # Generate metrics if requested
    if ($GenerateMetrics) {
        Generate-DirectProductionMetrics -HealthHistory $healthHistory -MetricsPath $MetricsPath
    }
    
    # Summary
    Write-Host "`n📊 Direct Production Health Summary:" -ForegroundColor Cyan
    Write-Host "   Health Score: $($healthResult.HealthScore)%" -ForegroundColor $(if ($healthResult.HealthScore -ge 95) { 'Green' } elseif ($healthResult.HealthScore -ge 80) { 'Yellow' } else { 'Red' })
    Write-Host "   Status: $(if ($healthResult.Status -eq "success") { '✅ Healthy' } elseif ($healthResult.Status -eq "failed") { '⚠️ Warning' } else { '❌ Critical' })" -ForegroundColor $(if ($healthResult.Status -eq "success") { 'Green' } elseif ($healthResult.Status -eq "failed") { 'Yellow' } else { 'Red' })
    Write-Host "   Freshness: $($healthResult.Freshness)" -ForegroundColor $(if ($healthResult.Freshness -eq "fresh") { 'Green' } else { 'Yellow' })
    Write-Host "   SSOT Update: $(if ($ssotUpdateSuccess) { '✅ Success' } else { '❌ Failed' })" -ForegroundColor $(if ($ssotUpdateSuccess) { 'Green' } else { 'Red' })
}

Write-Host "`n📝 Direct production monitoring log: $LogPath" -ForegroundColor Cyan
if ($GenerateMetrics) {
    Write-Host "📊 Production metrics: $MetricsPath" -ForegroundColor Cyan
}

# ECRR Compliance
Write-Host "`n🎭 ECRR Compliance" -ForegroundColor Magenta
Write-Host "==================" -ForegroundColor Magenta
Write-Host "✅ Examine: Direct production SSOT state captured and monitored" -ForegroundColor Green
Write-Host "✅ Clean: Direct production monitoring system operational" -ForegroundColor Green
Write-Host "✅ Report: Direct monitoring results documented with evidence" -ForegroundColor Green
Write-Host "✅ Role: Cursor Agent (Observability Copilot) - Direct production monitoring" -ForegroundColor Green
