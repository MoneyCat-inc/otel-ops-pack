# CI Fixes Verification Script
# Verifies all applied fixes and checks CI run status

Write-Host "🔍 Verifying CI Fixes..." -ForegroundColor Cyan

# 1. Check config.yaml uses debug exporter
Write-Host "`n1. Checking config.yaml..." -ForegroundColor Yellow
$loggingRefs = Select-String -Path config.yaml -Pattern 'logging' -AllMatches
if ($loggingRefs) {
    Write-Host "❌ Found logging references:" -ForegroundColor Red
    $loggingRefs | ForEach-Object { Write-Host "  $($_.Line)" }
} else {
    Write-Host "✅ No logging references found" -ForegroundColor Green
}

$debugRefs = Select-String -Path config.yaml -Pattern 'debug' -AllMatches
if ($debugRefs) {
    Write-Host "✅ Found debug exporter references:" -ForegroundColor Green
    $debugRefs | ForEach-Object { Write-Host "  $($_.Line)" }
} else {
    Write-Host "❌ No debug exporter found" -ForegroundColor Red
}

# 2. Check CI workflow has debug exporter and gated reviewdog
Write-Host "`n2. Checking CI workflow..." -ForegroundColor Yellow
$verbosityCheck = Select-String -Path .github/workflows/ci.yml -Pattern 'verbosity: detailed'
if ($verbosityCheck) {
    Write-Host "✅ Found debug exporter with detailed verbosity" -ForegroundColor Green
} else {
    Write-Host "❌ No debug exporter verbosity found" -ForegroundColor Red
}

$gatedReviewdog = Select-String -Path .github/workflows/ci.yml -Pattern "if: steps.npm-setup.outputs.has_package_json == 'true'"
if ($gatedReviewdog) {
    Write-Host "✅ Found gated reviewdog step" -ForegroundColor Green
} else {
    Write-Host "❌ No gated reviewdog found" -ForegroundColor Red
}

# 3. Check observability-cron.yml has quoted COLLECTOR_PID
Write-Host "`n3. Checking observability-cron.yml..." -ForegroundColor Yellow
$quotedPid = Select-String -Path .github/workflows/observability-cron.yml -Pattern 'kill "\$COLLECTOR_PID"'
if ($quotedPid) {
    Write-Host "✅ Found quoted COLLECTOR_PID" -ForegroundColor Green
} else {
    Write-Host "❌ COLLECTOR_PID not properly quoted" -ForegroundColor Red
}

# 4. Check latest CI run status
Write-Host "`n4. Checking latest CI run..." -ForegroundColor Yellow
try {
    $runs = gh run list --workflow="CI - quality gates" --limit 1 --json databaseId,status,conclusion,displayTitle,createdAt
    if ($runs) {
        $run = $runs | ConvertFrom-Json | Select-Object -First 1
        Write-Host "Latest run: $($run.databaseId)" -ForegroundColor Cyan
        Write-Host "Status: $($run.status)" -ForegroundColor Cyan
        Write-Host "Conclusion: $($run.conclusion)" -ForegroundColor Cyan
        Write-Host "Title: $($run.displayTitle)" -ForegroundColor Cyan
        Write-Host "Created: $($run.createdAt)" -ForegroundColor Cyan
        
        if ($run.status -eq "completed" -and $run.conclusion -eq "success") {
            Write-Host "✅ Latest CI run completed successfully!" -ForegroundColor Green
            
            # Try to download and verify artifact
            Write-Host "`n5. Verifying collector logs artifact..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force otel_art -ErrorAction SilentlyContinue
            New-Item -ItemType Directory otel_art | Out-Null
            
            try {
                gh run download $run.databaseId --name otel-collector-logs --dir otel_art | Out-Null
                $log = Get-ChildItem otel_art -Recurse -Filter collector.log | Select-Object -First 1
                
                if ($log) {
                    Write-Host "✅ Artifact downloaded successfully" -ForegroundColor Green
                    Write-Host "Log file: $($log.FullName)" -ForegroundColor Cyan
                    
                    # Check for ci-cat span
                    $ciCatSpan = Select-String -Path $log.FullName -Pattern 'service\.name.*ci-cat'
                    if ($ciCatSpan) {
                        Write-Host "✅ Found ci-cat span in collector logs:" -ForegroundColor Green
                        $ciCatSpan | ForEach-Object { Write-Host "  $($_.Line)" }
                    } else {
                        Write-Host "❌ No ci-cat span found in collector logs" -ForegroundColor Red
                    }
                    
                    # Check for deprecation warnings
                    $deprecationWarnings = Select-String -Path $log.FullName -Pattern 'logging exporter has been deprecated'
                    if ($deprecationWarnings) {
                        Write-Host "❌ Found deprecation warnings:" -ForegroundColor Red
                        $deprecationWarnings | ForEach-Object { Write-Host "  $($_.Line)" }
                    } else {
                        Write-Host "✅ No deprecation warnings found" -ForegroundColor Green
                    }
                    
                    # Show sample log content
                    Write-Host "`nSample log content:" -ForegroundColor Cyan
                    Get-Content $log.FullName -Head 10 | ForEach-Object { Write-Host "  $_" }
                } else {
                    Write-Host "❌ No collector.log found in artifact" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Failed to download artifact: $($_.Exception.Message)" -ForegroundColor Red
            }
        } elseif ($run.status -eq "in_progress") {
            Write-Host "⏳ CI run still in progress..." -ForegroundColor Yellow
        } else {
            Write-Host "❌ Latest CI run failed or incomplete" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ No CI runs found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to check CI run status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Verification complete!" -ForegroundColor Cyan
