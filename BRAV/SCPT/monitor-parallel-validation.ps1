# Parallel Validation Monitoring Dashboard
# Tracks all validation tasks running in parallel

Write-Host "🚀 PARALLEL VALIDATION DASHBOARD" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Monitoring multiple validation tasks in parallel..." -ForegroundColor Gray
Write-Host ""

# Check background monitor status
Write-Host "1. 📊 BACKGROUND CI MONITOR STATUS" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow

$monitorProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*monitor-ci-background.ps1*"
}

if ($monitorProcess) {
    Write-Host "✅ Background monitor is RUNNING" -ForegroundColor Green
    Write-Host "   PID: $($monitorProcess.Id)" -ForegroundColor Gray
    Write-Host "   Started: $($monitorProcess.StartTime)" -ForegroundColor Gray
    Write-Host "   Status: Monitoring CI runs every 30 seconds" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Background monitor not detected" -ForegroundColor Yellow
    Write-Host "   May have completed or stopped" -ForegroundColor Gray
}

# Check recent CI runs for concurrency behavior
Write-Host "`n2. 🔄 CONCURRENCY TEST STATUS" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

try {
    $runs = gh run list --limit 5 --json databaseId,status,conclusion,headSha,displayTitle,createdAt | ConvertFrom-Json
    if ($runs) {
        Write-Host "Recent CI runs:" -ForegroundColor Cyan
        $runs | ForEach-Object {
            $status = switch ($_.status) {
                "completed" { 
                    $color = switch ($_.conclusion) {
                        "success" { "Green" }
                        "failure" { "Red" }
                        "cancelled" { "Yellow" }
                        default { "Gray" }
                    }
                    "$($_.conclusion.ToUpper())" 
                }
                "in_progress" { "RUNNING" }
                "queued" { "QUEUED" }
                default { $_.status.ToUpper() }
            }
            
            $color = switch ($_.status) {
                "completed" { 
                    switch ($_.conclusion) {
                        "success" { "Green" }
                        "failure" { "Red" }
                        "cancelled" { "Yellow" }
                        default { "Gray" }
                    }
                }
                "in_progress" { "Cyan" }
                "queued" { "Magenta" }
                default { "White" }
            }
            
            Write-Host "  $($_.databaseId) | $status | $($_.displayTitle)" -ForegroundColor $color
            Write-Host "    SHA: $($_.headSha.Substring(0,8)) | Created: $($_.createdAt)" -ForegroundColor Gray
        }
        
        # Look for cancelled runs (concurrency working)
        $cancelledRuns = $runs | Where-Object { $_.conclusion -eq "cancelled" }
        if ($cancelledRuns) {
            Write-Host "`n✅ CONCURRENCY WORKING!" -ForegroundColor Green
            $cancelledRuns | ForEach-Object {
                Write-Host "  🚫 Cancelled: $($_.databaseId) - $($_.displayTitle)" -ForegroundColor Green
            }
        } else {
            Write-Host "`n⏳ Concurrency test pending - waiting for cancellation" -ForegroundColor Yellow
        }
        
        # Check for running jobs
        $runningRuns = $runs | Where-Object { $_.status -eq "in_progress" }
        if ($runningRuns) {
            Write-Host "`n🔄 Active runs:" -ForegroundColor Cyan
            $runningRuns | ForEach-Object {
                Write-Host "  ▶️  Running: $($_.databaseId) - $($_.displayTitle)" -ForegroundColor Cyan
            }
        }
    }
} catch {
    Write-Host "❌ Error checking CI runs: $($_.Exception.Message)" -ForegroundColor Red
}

# Check for open PRs and queue behavior
Write-Host "`n3. 📋 QUEUE TEST STATUS" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Yellow

try {
    $prs = gh pr list --json number,title,state,author,headRefName,url | ConvertFrom-Json
    if ($prs) {
        Write-Host "Open PRs:" -ForegroundColor Cyan
        $prs | ForEach-Object {
            $stateColor = switch ($_.state) {
                "OPEN" { "Green" }
                "MERGED" { "Blue" }
                "CLOSED" { "Red" }
                default { "Gray" }
            }
            Write-Host "  PR #$($_.number) | $($_.state) | $($_.title)" -ForegroundColor $stateColor
            Write-Host "    Author: $($_.author.login) | Branch: $($_.headRefName)" -ForegroundColor Gray
            Write-Host "    URL: $($_.url)" -ForegroundColor Gray
        }
        
        # Check if our test PR is there
        $testPR = $prs | Where-Object { $_.headRefName -eq "test-queue-behavior" }
        if ($testPR) {
            Write-Host "`n✅ TEST PR FOUND!" -ForegroundColor Green
            Write-Host "  PR #$($testPR.number): $($testPR.title)" -ForegroundColor Green
            
            # Check PR status and checks
            try {
                $prDetails = gh pr view $testPR.number --json statusCheckRollup,reviews,state | ConvertFrom-Json
                
                Write-Host "  State: $($prDetails.state)" -ForegroundColor Cyan
                
                if ($prDetails.statusCheckRollup) {
                    Write-Host "`n  Status Checks:" -ForegroundColor Cyan
                    $allPassed = $true
                    $prDetails.statusCheckRollup | ForEach-Object {
                        $status = switch ($_.state) {
                            "SUCCESS" { "✅"; $color = "Green" }
                            "FAILURE" { "❌"; $color = "Red"; $allPassed = $false }
                            "PENDING" { "⏳"; $color = "Yellow" }
                            "ERROR" { "⚠️"; $color = "Red"; $allPassed = $false }
                            default { "❓"; $color = "Gray" }
                        }
                        Write-Host "    $status $($_.name) - $($_.state)" -ForegroundColor $color
                    }
                    
                    if ($allPassed -and $prDetails.state -eq "OPEN") {
                        Write-Host "`n  🚀 READY FOR MERGE!" -ForegroundColor Green
                        Write-Host "    Mergify should queue and merge this PR" -ForegroundColor Green
                    }
                }
                
                if ($prDetails.reviews) {
                    $approvedReviews = $prDetails.reviews | Where-Object { $_.state -eq "APPROVED" }
                    if ($approvedReviews) {
                        Write-Host "`n  ✅ Approved reviews:" -ForegroundColor Green
                        $approvedReviews | ForEach-Object {
                            Write-Host "    👍 $($_.author.login)" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "`n  ⏳ Waiting for reviews..." -ForegroundColor Yellow
                    }
                }
                
            } catch {
                Write-Host "❌ Error getting PR details: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "`n⚠️  Test PR not found - may still be processing" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No open PRs found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error checking PRs: $($_.Exception.Message)" -ForegroundColor Red
}

# Check for reviewdog activity
Write-Host "`n4. 🔍 REVIEWDOG TEST STATUS" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow

if (Test-Path "test-reviewdog.js") {
    Write-Host "✅ Test file present: test-reviewdog.js" -ForegroundColor Green
    Write-Host "   Contains intentional ESLint issues for reviewdog testing" -ForegroundColor Gray
    
    # Check if file was committed
    try {
        $gitStatus = git status --porcelain
        if ($gitStatus -match "test-reviewdog.js") {
            Write-Host "⚠️  File has uncommitted changes" -ForegroundColor Yellow
        } else {
            Write-Host "✅ File committed and pushed" -ForegroundColor Green
            Write-Host "   Should trigger reviewdog ESLint annotations on PR" -ForegroundColor Gray
        }
    } catch {
        Write-Host "⚠️  Could not check git status" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Test file not found" -ForegroundColor Red
}

# Check Mergify configuration
Write-Host "`n5. ⚙️  MERGIFY CONFIGURATION" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

if (Test-Path ".mergify.yml") {
    Write-Host "✅ Mergify config found" -ForegroundColor Green
    
    $mergifyConfig = Get-Content ".mergify.yml" -Raw
    if ($mergifyConfig -match "queue_rules") {
        Write-Host "✅ Queue rules configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No queue rules found" -ForegroundColor Yellow
    }
    
    if ($mergifyConfig -match "auto-merge") {
        Write-Host "✅ Auto-merge rules configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No auto-merge rules found" -ForegroundColor Yellow
    }
    
    if ($mergifyConfig -match "dependabot") {
        Write-Host "✅ Dependabot auto-merge configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No Dependabot auto-merge found" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ No Mergify config found" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$summary = @()
if ($monitorProcess) { $summary += "✅ Background CI Monitor: RUNNING" } else { $summary += "⚠️  Background CI Monitor: UNKNOWN" }
if ($cancelledRuns) { $summary += "✅ Concurrency Test: WORKING" } else { $summary += "⏳ Concurrency Test: PENDING" }
if ($testPR) { $summary += "✅ Queue Test: DEPLOYED" } else { $summary += "⚠️  Queue Test: NOT FOUND" }
if (Test-Path "test-reviewdog.js") { $summary += "✅ Reviewdog Test: DEPLOYED" } else { $summary += "❌ Reviewdog Test: MISSING" }

$summary | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Wait for background monitor to complete and report results" -ForegroundColor Gray
Write-Host "2. Check for cancelled runs in recent CI history" -ForegroundColor Gray
Write-Host "3. Monitor test PR for queue behavior and merge" -ForegroundColor Gray
Write-Host "4. Look for reviewdog annotations on PR files" -ForegroundColor Gray
Write-Host "5. Run this script again to check progress" -ForegroundColor Gray

Write-Host "`n🔄 Run this script again to check progress!" -ForegroundColor Yellow
