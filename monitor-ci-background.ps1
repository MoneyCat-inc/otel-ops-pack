# Background CI Monitoring Script
# This script runs in the background to monitor CI progress

param(
    [int]$MaxWaitMinutes = 10,
    [int]$CheckIntervalSeconds = 30
)

Write-Host "🔍 Background CI Monitor Started" -ForegroundColor Cyan
Write-Host "Max wait time: $MaxWaitMinutes minutes" -ForegroundColor Cyan
Write-Host "Check interval: $CheckIntervalSeconds seconds" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$startTime = Get-Date
$endTime = $startTime.AddMinutes($MaxWaitMinutes)

do {
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Checking CI status (elapsed: $($elapsed.ToString('mm\:ss')))" -ForegroundColor Yellow
    
    try {
        $runs = gh run list --limit 1 --json databaseId,status,conclusion,displayTitle,createdAt | ConvertFrom-Json
        if ($runs) {
            $run = $runs[0]
            Write-Host "Latest run: $($run.databaseId)" -ForegroundColor Cyan
            Write-Host "Status: $($run.status)" -ForegroundColor Cyan
            Write-Host "Conclusion: $($run.conclusion)" -ForegroundColor Cyan
            Write-Host "Title: $($run.displayTitle)" -ForegroundColor Cyan
            
            if ($run.status -eq "completed") {
                if ($run.conclusion -eq "success") {
                    Write-Host "`n✅ CI COMPLETED SUCCESSFULLY!" -ForegroundColor Green
                    Write-Host "Run ID: $($run.databaseId)" -ForegroundColor Green
                    
                    # Download and verify artifact
                    Write-Host "`n📥 Downloading artifact..." -ForegroundColor Yellow
                    Remove-Item -Recurse -Force otel_art -ErrorAction SilentlyContinue
                    New-Item -ItemType Directory otel_art | Out-Null
                    
                    try {
                        gh run download $run.databaseId --name otel-collector-logs --dir otel_art | Out-Null
                        $log = Get-ChildItem otel_art -Recurse -Filter collector.log | Select-Object -First 1
                        
                        if ($log) {
                            Write-Host "✅ Artifact downloaded: $($log.FullName)" -ForegroundColor Green
                            
                            # Check for deprecation warnings
                            $deprecationWarnings = Select-String -Path $log.FullName -Pattern "logging exporter has been deprecated"
                            if ($deprecationWarnings) {
                                Write-Host "❌ Found deprecation warnings:" -ForegroundColor Red
                                $deprecationWarnings | ForEach-Object { Write-Host "  $($_.Line)" }
                            } else {
                                Write-Host "✅ No deprecation warnings found!" -ForegroundColor Green
                            }
                            
                            # Check for ci-cat span
                            $ciCatSpan = Select-String -Path $log.FullName -Pattern 'service\.name.*ci-cat'
                            if ($ciCatSpan) {
                                Write-Host "✅ Found ci-cat span in collector logs!" -ForegroundColor Green
                                $ciCatSpan | ForEach-Object { Write-Host "  $($_.Line)" }
                            } else {
                                Write-Host "❌ No ci-cat span found" -ForegroundColor Red
                            }
                            
                            # Show sample log content
                            Write-Host "`n📋 Sample log content:" -ForegroundColor Cyan
                            Get-Content $log.FullName -Head 10 | ForEach-Object { Write-Host "  $_" }
                            
                        } else {
                            Write-Host "❌ No collector.log found in artifact" -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "❌ Failed to download artifact: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    Write-Host "`n🎉 BACKGROUND MONITORING COMPLETE - SUCCESS!" -ForegroundColor Green
                    exit 0
                    
                } else {
                    Write-Host "`n❌ CI FAILED!" -ForegroundColor Red
                    Write-Host "Conclusion: $($run.conclusion)" -ForegroundColor Red
                    Write-Host "Run ID: $($run.databaseId)" -ForegroundColor Red
                    Write-Host "`n🔍 Check the run logs for details:" -ForegroundColor Yellow
                    Write-Host "gh run view $($run.databaseId) --log" -ForegroundColor Yellow
                    Write-Host "`n❌ BACKGROUND MONITORING COMPLETE - FAILURE!" -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "⏳ CI still running..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ No CI runs found" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error checking CI status: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($currentTime -lt $endTime) {
        Write-Host "⏳ Waiting $CheckIntervalSeconds seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
} while ($currentTime -lt $endTime)

Write-Host "`n⏰ Timeout reached after $MaxWaitMinutes minutes" -ForegroundColor Yellow
Write-Host "❌ BACKGROUND MONITORING TIMEOUT" -ForegroundColor Red
exit 2
