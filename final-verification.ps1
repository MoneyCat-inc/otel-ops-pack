# Final CI Verification Script
# Run this once the CI - quality gates workflow completes

Write-Host "🔍 Final CI Verification - All Fixes Applied" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Verify all fixes are in place
Write-Host "`n1. Verifying Applied Fixes..." -ForegroundColor Yellow

# Check config.yaml has no logging exporter
$loggingRefs = Select-String -Path config.yaml -Pattern 'logging exporter'
if ($loggingRefs) {
    Write-Host "❌ Found logging exporter references:" -ForegroundColor Red
    $loggingRefs | ForEach-Object { Write-Host "  $($_.Line)" }
} else {
    Write-Host "✅ No logging exporter references found" -ForegroundColor Green
}

# Check CI workflow has debug exporter
$debugVerbosity = Select-String -Path .github/workflows/ci.yml -Pattern 'verbosity: detailed'
if ($debugVerbosity) {
    Write-Host "✅ Found debug exporter with detailed verbosity" -ForegroundColor Green
} else {
    Write-Host "❌ No debug exporter verbosity found" -ForegroundColor Red
}

# Check gated reviewdog
$gatedReviewdog = Select-String -Path .github/workflows/ci.yml -Pattern "if: steps.npm-setup.outputs.has_package_json == 'true'"
if ($gatedReviewdog) {
    Write-Host "✅ Found gated reviewdog implementation" -ForegroundColor Green
} else {
    Write-Host "❌ No gated reviewdog found" -ForegroundColor Red
}

# 2. Check latest CI run status
Write-Host "`n2. Checking Latest CI Run..." -ForegroundColor Yellow

try {
    $runs = gh run list --workflow="CI - quality gates" --limit 1 --json databaseId,status,conclusion,displayTitle,createdAt
    if ($runs) {
        $run = $runs | ConvertFrom-Json | Select-Object -First 1
        Write-Host "Run ID: $($run.databaseId)" -ForegroundColor Cyan
        Write-Host "Status: $($run.status)" -ForegroundColor Cyan
        Write-Host "Conclusion: $($run.conclusion)" -ForegroundColor Cyan
        Write-Host "Title: $($run.displayTitle)" -ForegroundColor Cyan
        Write-Host "Created: $($run.createdAt)" -ForegroundColor Cyan
        
        if ($run.status -eq "completed" -and $run.conclusion -eq "success") {
            Write-Host "✅ Latest CI run completed successfully!" -ForegroundColor Green
            
            # 3. Download and verify artifact
            Write-Host "`n3. Verifying Collector Logs Artifact..." -ForegroundColor Yellow
            
            # Clean up previous artifacts
            Remove-Item -Recurse -Force otel_art -ErrorAction SilentlyContinue
            New-Item -ItemType Directory otel_art | Out-Null
            
            try {
                Write-Host "Downloading otel-collector-logs artifact..." -ForegroundColor Cyan
                gh run download $run.databaseId --name otel-collector-logs --dir otel_art | Out-Null
                
                $log = Get-ChildItem otel_art -Recurse -Filter collector.log | Select-Object -First 1
                
                if ($log) {
                    Write-Host "✅ Artifact downloaded successfully" -ForegroundColor Green
                    Write-Host "Log file: $($log.FullName)" -ForegroundColor Cyan
                    
                    # Check for ci-cat span
                    Write-Host "`nChecking for ci-cat span..." -ForegroundColor Cyan
                    $ciCatSpan = Select-String -Path $log.FullName -Pattern 'service\.name.*ci-cat'
                    if ($ciCatSpan) {
                        Write-Host "✅ Found ci-cat span in collector logs!" -ForegroundColor Green
                        $ciCatSpan | ForEach-Object { Write-Host "  $($_.Line)" }
                    } else {
                        Write-Host "❌ No ci-cat span found in collector logs" -ForegroundColor Red
                    }
                    
                    # Check for ci-smoke
                    Write-Host "`nChecking for ci-smoke references..." -ForegroundColor Cyan
                    $ciSmoke = Select-String -Path $log.FullName -Pattern 'ci-smoke'
                    if ($ciSmoke) {
                        Write-Host "✅ Found ci-smoke references:" -ForegroundColor Green
                        $ciSmoke | ForEach-Object { Write-Host "  $($_.Line)" }
                    } else {
                        Write-Host "⚠️  No ci-smoke references found" -ForegroundColor Yellow
                    }
                    
                    # Check for deprecation warnings
                    Write-Host "`nChecking for deprecation warnings..." -ForegroundColor Cyan
                    $deprecationWarnings = Select-String -Path $log.FullName -Pattern 'logging exporter has been deprecated'
                    if ($deprecationWarnings) {
                        Write-Host "❌ Found deprecation warnings:" -ForegroundColor Red
                        $deprecationWarnings | ForEach-Object { Write-Host "  $($_.Line)" }
                    } else {
                        Write-Host "✅ No deprecation warnings found!" -ForegroundColor Green
                    }
                    
                    # Show sample log content
                    Write-Host "`nSample log content (first 15 lines):" -ForegroundColor Cyan
                    Get-Content $log.FullName -Head 15 | ForEach-Object { Write-Host "  $_" }
                    
                    # Show log file size
                    $logSize = (Get-Item $log.FullName).Length
                    Write-Host "`nLog file size: $logSize bytes" -ForegroundColor Cyan
                    
                } else {
                    Write-Host "❌ No collector.log found in artifact" -ForegroundColor Red
                    Write-Host "Available files in otel_art:" -ForegroundColor Cyan
                    Get-ChildItem otel_art -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }
                }
            } catch {
                Write-Host "❌ Failed to download artifact: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        } elseif ($run.status -eq "in_progress") {
            Write-Host "⏳ CI run still in progress..." -ForegroundColor Yellow
            Write-Host "Run this script again once it completes." -ForegroundColor Yellow
        } else {
            Write-Host "❌ Latest CI run failed or incomplete" -ForegroundColor Red
            Write-Host "Status: $($run.status), Conclusion: $($run.conclusion)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ No CI runs found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to check CI run status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Final Verification Complete!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan


